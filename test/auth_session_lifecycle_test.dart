import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/auth/auth_repository.dart';
import 'package:mujeeb24_app/core/errors/api_error.dart';

http.Response expired() => http.Response(
  jsonEncode({'error': {
    'code': 'UNAUTHENTICATED', 'message': 'invalid access token',
    'retryable': false,
  }, 'request_id': 'req-401'}), 401,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('simultaneous 401s rotate the single-use refresh cookie once', () async {
    var refreshCalls = 0;
    var protectedCalls = 0;
    final mock = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/refresh') {
        refreshCalls++;
        expect(request.headers['Cookie'], 'mujeeb_refresh=first');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response(jsonEncode({
          'data': {'access_token': 'access-rotated'}
        }), 200, headers: {
          'set-cookie': 'mujeeb_refresh=second; HttpOnly; Secure; Path=/api/v1/auth',
        });
      }
      protectedCalls++;
      if (request.headers['Authorization'] == 'Bearer expired') {
        return expired();
      }
      expect(request.headers['Authorization'], 'Bearer access-rotated');
      return http.Response(jsonEncode({'data': {'ok': true}}), 200);
    });
    final api = ApiClient(client: mock);
    api.setAccessToken('expired');
    api.setRefreshCookie('mujeeb_refresh=first');

    final responses = await Future.wait([
      api.get('/businesses/one/dashboard/overview'),
      api.get('/businesses/one/conversations'),
    ]);
    expect(refreshCalls, 1);
    expect(protectedCalls, 4);
    expect(responses.every((x) => x['data']['ok'] == true), isTrue);
    expect(api.refreshCookie, 'mujeeb_refresh=second');
    expect(api.accessToken, 'access-rotated');
  });

  test('rejected refresh erases local tokens and signals expiration once', () async {
    var expiredEvents = 0;
    final api = ApiClient(client: MockClient((r) async {
      if (r.url.path.endsWith('/auth/refresh')) return expired();
      return expired();
    }));
    api.setAccessToken('expired');
    api.setRefreshCookie('mujeeb_refresh=revoked');
    api.onSessionExpired = () => expiredEvents++;
    await expectLater(api.get('/me'), throwsA(isA<ApiErrorEnvelope>()));
    expect(api.accessToken, isNull);
    expect(api.refreshCookie, isNull);
    expect(expiredEvents, 1);
  });

  test('transient refresh failure preserves credentials and avoids forced sign-out',
      () async {
    var expiredEvents = 0;
    final api = ApiClient(client: MockClient((r) async {
      if (r.url.path.endsWith('/auth/refresh')) {
        return http.Response('{"error":{"code":"UPSTREAM","message":"busy"}}', 503);
      }
      return expired();
    }));
    api.setAccessToken('old');
    api.setRefreshCookie('mujeeb_refresh=valid');
    api.onSessionExpired = () => expiredEvents++;
    await expectLater(api.get('/me'), throwsA(isA<NetworkException>()));
    expect(api.accessToken, 'old');
    expect(api.refreshCookie, 'mujeeb_refresh=valid');
    expect(expiredEvents, 0);
  });

  test('logout clears secrets immediately even if remote logout is pending',
      () async {
    final gate = Completer<http.Response>();
    final api = ApiClient(client: MockClient((r) async {
      expect(r.headers['Authorization'], 'Bearer active');
      expect(r.headers['Cookie'], 'mujeeb_refresh=active');
      return gate.future;
    }));
    api.setAccessToken('active');
    api.setRefreshCookie('mujeeb_refresh=active');
    final future = AuthRepository(apiClient: api).logout();
    expect(api.accessToken, isNull);
    expect(api.refreshCookie, isNull);
    gate.complete(http.Response('', 204));
    await future;
  });

  test('old logout response cannot clear the next user session', () async {
    final gate = Completer<http.Response>();
    final api = ApiClient(client: MockClient((r) async => gate.future));
    api.setAccessToken('old');
    api.setRefreshCookie('mujeeb_refresh=old');
    final logout = AuthRepository(apiClient: api).logout();
    expect(api.accessToken, isNull);
    api.setAccessToken('new-login');
    api.setRefreshCookie('mujeeb_refresh=new-login');
    gate.complete(http.Response('', 204));
    await logout;
    expect(api.accessToken, 'new-login');
    expect(api.refreshCookie, 'mujeeb_refresh=new-login');
  });

  test('logout during refresh never resurrects stale credentials', () async {
    final gate = Completer<http.Response>();
    final refreshSeen = Completer<void>();
    final api = ApiClient(client: MockClient((r) async {
      if (r.url.path.endsWith('/auth/refresh')) {
        refreshSeen.complete();
        return gate.future;
      }
      return expired();
    }));
    api.setAccessToken('old');
    api.setRefreshCookie('mujeeb_refresh=old');
    final request = api.get('/me');
    await refreshSeen.future;
    api.clearSession();
    gate.complete(http.Response(
      jsonEncode({'data': {'access_token': 'resurrected'}}), 200,
      headers: {'set-cookie': 'mujeeb_refresh=resurrected; HttpOnly'},
    ));
    await expectLater(request, throwsA(isA<ApiErrorEnvelope>()));
    expect(api.accessToken, isNull);
    expect(api.refreshCookie, isNull);
  });

  test('ignores unrelated cookies rather than forwarding them as refresh', () async {
    final api = ApiClient(client: MockClient((r) async => http.Response(
      jsonEncode({'data': true}), 200,
      headers: {'set-cookie': 'analytics_session=abc; Path=/; HttpOnly'},
    )));
    await api.get('/health', requiresAuth: false);
    expect(api.refreshCookie, isNull);
  });
}
