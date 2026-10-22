import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/api_error.dart';
import '../auth/refresh_cookie_store.dart';

/// HTTP Client wrapper handling:
/// - Base URL and path prefixes
/// - Automatic cookie header injection for platforms without automatic cookie jar
/// - Parsing Set-Cookie headers (specifically `mujeeb_refresh`)
/// - Handling Bearer auth headers
/// - Translating HTTP errors to ApiErrorEnvelope or NetworkException
class ApiClient {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mujeeb24-api.onrender.com/api/v1',
  );

  final http.Client _client;
  String baseUrl;
  String? _accessToken;
  String? _refreshCookie;
  int _sessionEpoch = 0;
  Future<bool?>? _refreshInFlight;
  final RefreshCookieStore? _cookieStore;
  Future<void> _cookieWriteQueue = Future<void>.value();
  bool _cookiePersistenceError = false;

  /// Called only after the server rejects the refresh cookie (or none exists).
  /// Never called for an ordinary network outage or server 5xx.
  void Function()? onSessionExpired;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    RefreshCookieStore? cookieStore,
  }) : baseUrl = normalizeBaseUrl(baseUrl ?? defaultBaseUrl),
       _client = client ?? http.Client(),
       _cookieStore = cookieStore;

  /// Normalizes base URL ensuring no trailing slashes and appending `/api/v1`
  /// if only the root origin domain is provided.
  static String normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.endsWith('/api/v1')) {
      trimmed = '$trimmed/api/v1';
    }
    return trimmed;
  }

  String? get accessToken => _accessToken;
  String? get refreshCookie => _refreshCookie;
  bool get refreshCookiePersistenceFailed => _cookiePersistenceError;

  /// Serialize writes to avoid restoring a revoked/rotated cookie. Storage
  /// failures never trigger a plaintext fallback and never expose cookie data.
  void _queueCookieWrite(String? value) {
    final store = _cookieStore;
    if (store == null) return;
    _cookieWriteQueue = _cookieWriteQueue.then((_) async {
      try {
        if (value == null) {
          await store.delete();
        } else {
          await store.write(value);
        }
        _cookiePersistenceError = false;
      } catch (_) {
        _cookiePersistenceError = true;
      }
    });
  }

  Future<void> flushCookiePersistence() => _cookieWriteQueue;

  /// Only call during application bootstrap, before any interactive login.
  /// An in-flight storage read cannot replace a more recent login/logout.
  Future<void> restoreRefreshCookie() async {
    final store = _cookieStore;
    if (store == null) return;
    final epoch = _sessionEpoch;
    await _cookieWriteQueue;
    if (epoch != _sessionEpoch || _refreshCookie != null) return;
    try {
      final restored = await store.read();
      if (epoch != _sessionEpoch || _refreshCookie != null) return;
      if (restored != null &&
          RegExp(r'^mujeeb_refresh=[^;\s]+$').hasMatch(restored)) {
        _refreshCookie = restored;
      } else if (restored != null) {
        _queueCookieWrite(null);
      }
    } catch (_) {
      _cookiePersistenceError = true;
    }
  }

  void setAccessToken(String? token) {
    // A deliberate login replaces any previously in-flight refresh generation.
    _sessionEpoch++;
    _refreshInFlight = null;
    _accessToken = token;
  }

  void setRefreshCookie(String? cookie) {
    _refreshCookie = cookie;
    _queueCookieWrite(cookie);
  }

  void clearSession() {
    // A late refresh response must never log the user back in after logout.
    _sessionEpoch++;
    _refreshInFlight = null;
    _accessToken = null;
    _refreshCookie = null;
    _queueCookieWrite(null);
  }

  Uri _resolveUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    var uri = Uri.parse('$cleanBase$cleanPath');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(
        queryParameters: queryParameters.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
    }
    return uri;
  }

  Map<String, String> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool requiresAuth = true,
    bool sendCookie = false,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (sendCookie && _refreshCookie != null && _refreshCookie!.isNotEmpty) {
      headers['Cookie'] = _refreshCookie!;
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  void _extractCookies(http.Response response) {
    final header = response.headers['set-cookie'] ??
        response.headers['Set-Cookie'];
    if (header == null) return;
    // Never copy another website/backend cookie into a refresh request.
    final match = RegExp(r'(?:^|,\s*)mujeeb_refresh=([^;,]*)')
        .firstMatch(header);
    if (match == null) return;
    final value = match.group(1) ?? '';
    if (value.isEmpty || RegExp(r'max-age=0', caseSensitive: false)
        .hasMatch(header)) {
      setRefreshCookie(null);
    } else {
      setRefreshCookie('mujeeb_refresh=$value');
    }
  }

  void _expireAuthenticatedSession(int requestEpoch) {
    if (requestEpoch != _sessionEpoch) return;
    clearSession();
    onSessionExpired?.call();
  }

  Future<bool?> _rotateSession(int requestEpoch) async {
    final cookie = _refreshCookie;
    if (cookie == null || cookie.isEmpty) {
      _expireAuthenticatedSession(requestEpoch);
      return false;
    }
    try {
      final response = await _client.post(
        _resolveUri('/auth/refresh'),
        headers: _buildHeaders(requiresAuth: false, sendCookie: true),
      ).timeout(const Duration(seconds: 20));
      if (requestEpoch != _sessionEpoch) return false;
      if (response.statusCode == 401 || response.statusCode == 403) {
        _expireAuthenticatedSession(requestEpoch);
        return false;
      }
      final result = _processResponse(response);
      if (requestEpoch != _sessionEpoch) return false;
      if (result is! Map || result['data'] is! Map) {
        return null; // malformed refresh response; keep existing session
      }
      final data = result['data'] as Map;
      final access = data['access_token'];
      if (access is! String || access.isEmpty) return null;
      _accessToken = access;
      await flushCookiePersistence();
      if (requestEpoch != _sessionEpoch) return false;
      return true;
    } on ApiErrorEnvelope catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        _expireAuthenticatedSession(requestEpoch);
        return false;
      }
      return null;
    } catch (_) {
      // Never erase a valid session on a temporary timeout or 503.
      return null;
    }
  }

  Future<bool?> _refreshAfter401(int requestEpoch, String? usedToken) async {
    if (requestEpoch != _sessionEpoch) return false;
    if (_accessToken != null && _accessToken != usedToken) return true;
    final active = _refreshInFlight;
    if (active != null) return active;
    final attempt = _rotateSession(requestEpoch);
    _refreshInFlight = attempt;
    try {
      return await attempt;
    } finally {
      if (identical(_refreshInFlight, attempt)) _refreshInFlight = null;
    }
  }

  Future<dynamic> _sendWithSessionRecovery(
    String path,
    Future<http.Response> Function() send, {
    required bool requiresAuth,
    required Duration timeout,
  }) async {
    final requestEpoch = _sessionEpoch;
    final usedToken = _accessToken;
    try {
      var response = await send().timeout(timeout);
      // A 401 from a protected endpoint is safe to retry exactly once
      // *after* the backend confirmed refresh-token rotation.
      if (requiresAuth && response.statusCode == 401 &&
          !path.startsWith('/auth/')) {
        final recovered = await _refreshAfter401(requestEpoch, usedToken);
        if (recovered == true && requestEpoch == _sessionEpoch) {
          response = await send().timeout(timeout);
          if (response.statusCode == 401) {
            _expireAuthenticatedSession(requestEpoch);
          }
        } else if (recovered == null) {
          throw const NetworkException(
            message: 'تعذر تجديد الجلسة مؤقتًا. تحقق من الاتصال ثم أعد المحاولة.',
          );
        }
      }
      if (requestEpoch != _sessionEpoch) {
        throw ApiErrorEnvelope.fromRaw(
          code: 'SESSION_CHANGED',
          message: 'انتهت الجلسة السابقة. أعد تسجيل الدخول.',
          statusCode: 401,
        );
      }
      return _processResponse(response);
    } on ApiErrorEnvelope {
      rethrow;
    } on NetworkException {
      rethrow;
    } on TimeoutException catch (e) {
      throw NetworkException(
        message: 'انتهت مهلة الاتصال بالخادم. حاول مرة أخرى.',
        originalError: e.toString(), isTimeout: true,
      );
    } catch (e) {
      throw NetworkException(
        message: 'تعذر الاتصال بالخادم. تحقق من الشبكة.',
        originalError: e.toString(),
      );
    }
  }

  dynamic _processResponse(http.Response response) {
    _extractCookies(response);

    if (response.statusCode == 204) {
      return null;
    }

    final bodyString = response.body.trim();
    dynamic jsonBody;
    if (bodyString.isNotEmpty) {
      try {
        jsonBody = jsonDecode(bodyString);
      } catch (e) {
        if (response.statusCode >= 400) {
          throw ApiErrorEnvelope.fromRaw(
            code: 'NON_JSON_ERROR',
            message:
                'Server returned error status ${response.statusCode}: $bodyString',
            statusCode: response.statusCode,
          );
        }
        throw ApiErrorEnvelope.fromRaw(
          code: 'JSON_PARSE_ERROR',
          message: 'Failed to parse JSON response: $bodyString',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    // Response is 4xx or 5xx
    if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('error')) {
      throw ApiErrorEnvelope.fromJson(
        jsonBody,
        statusCode: response.statusCode,
      );
    } else {
      String msg = 'HTTP request failed with status ${response.statusCode}';
      if (jsonBody is Map) {
        if (jsonBody['message'] != null) {
          msg = jsonBody['message'].toString();
        } else if (jsonBody['detail'] != null) {
          final detail = jsonBody['detail'].toString();
          if (jsonBody['errors'] is List &&
              (jsonBody['errors'] as List).isNotEmpty) {
            final firstErr = (jsonBody['errors'] as List).first;
            if (firstErr is Map && firstErr['message'] != null) {
              msg = '$detail: ${firstErr['message']}';
            } else {
              msg = detail;
            }
          } else {
            msg = detail;
          }
        } else if (jsonBody['title'] != null) {
          msg = jsonBody['title'].toString();
        }
      }
      throw ApiErrorEnvelope.fromRaw(
        code: 'HTTP_${response.statusCode}',
        message: msg,
        statusCode: response.statusCode,
        requestId: jsonBody is Map && jsonBody['request_id'] != null
            ? jsonBody['request_id'].toString()
            : '',
      );
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    Duration timeout = const Duration(seconds: 45),
  }) => _sendWithSessionRecovery(
    path,
    () => _client.get(
      _resolveUri(path, queryParameters),
      headers: _buildHeaders(extraHeaders: headers, requiresAuth: requiresAuth),
    ),
    requiresAuth: requiresAuth, timeout: timeout,
  );

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = false,
    bool sendCookie = false,
    Duration timeout = const Duration(seconds: 45),
  }) => _sendWithSessionRecovery(
    path,
    () => _client.post(
      _resolveUri(path),
      headers: _buildHeaders(extraHeaders: headers,
        requiresAuth: requiresAuth, sendCookie: sendCookie),
      body: body == null ? null : jsonEncode(body),
    ),
    requiresAuth: requiresAuth, timeout: timeout,
  );

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
    Duration timeout = const Duration(seconds: 45),
  }) => _sendWithSessionRecovery(
    path,
    () => _client.patch(
      _resolveUri(path),
      headers: _buildHeaders(extraHeaders: headers, requiresAuth: requiresAuth),
      body: body == null ? null : jsonEncode(body),
    ),
    requiresAuth: requiresAuth, timeout: timeout,
  );

  void close() {
    _client.close();
  }
}
