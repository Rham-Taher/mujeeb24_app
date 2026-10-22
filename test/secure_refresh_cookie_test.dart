import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/auth/auth_repository.dart';
import 'package:mujeeb24_app/core/auth/refresh_cookie_store.dart';

class _MemorySecureStore implements RefreshCookieStore {
  String? cookie;
  int writes = 0;
  int deletes = 0;
  Completer<String?>? readGate;
  bool fail = false;
  @override
  Future<String?> read() async {
    if (readGate != null) return readGate!.future;
    if (fail) throw StateError('unavailable');
    return cookie;
  }

  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('unavailable');
    writes++;
    cookie = value;
  }

  @override
  Future<void> delete() async {
    if (fail) throw StateError('unavailable');
    deletes++;
    cookie = null;
  }
}

void main() {
  test('refresh cookie is persisted and restored without access token', () async {
    final store = _MemorySecureStore();
    final first = ApiClient(cookieStore: store);
    first.setAccessToken('short-lived-token');
    first.setRefreshCookie('mujeeb_refresh=opaque-one');
    await first.flushCookiePersistence();
    expect(store.cookie, 'mujeeb_refresh=opaque-one');

    final restored = ApiClient(cookieStore: store);
    await restored.restoreRefreshCookie();
    expect(restored.refreshCookie, 'mujeeb_refresh=opaque-one');
    expect(restored.accessToken, isNull);
  });

  test('refresh rotation persists latest backend cookie', () async {
    final store = _MemorySecureStore()..cookie = 'mujeeb_refresh=old';
    final api = ApiClient(
      cookieStore: store,
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/refresh');
        expect(request.headers['Cookie'], 'mujeeb_refresh=old');
        return http.Response(jsonEncode({'data': {
          'access_token': 'new-token',
          'expires_at': '2027-01-01T00:00:00Z',
          'principal': {'principal_id': 'p', 'display_name': 'Merchant'},
        }}), 200, headers: {
          'set-cookie': 'mujeeb_refresh=rotated; HttpOnly; Secure',
        });
      }),
    );
    await api.restoreRefreshCookie();
    final refresh = await AuthRepository(apiClient: api).refreshSession();
    expect(refresh.accessToken, 'new-token');
    expect(api.accessToken, 'new-token');
    expect(store.cookie, 'mujeeb_refresh=rotated');
    expect(store.writes, 1);
  });

  test('logout deletes saved refresh token as well as memory session', () async {
    final store = _MemorySecureStore()..cookie = 'mujeeb_refresh=old';
    final api = ApiClient(
      cookieStore: store,
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/logout');
        return http.Response('', 204);
      }),
    );
    api.setAccessToken('bearer');
    await api.restoreRefreshCookie();
    await AuthRepository(apiClient: api).logout();
    await api.flushCookiePersistence();
    expect(api.refreshCookie, isNull);
    expect(api.accessToken, isNull);
    expect(store.cookie, isNull);
  });

  test('explicit new account login cannot inherit prior user cookie', () async {
    final store = _MemorySecureStore()..cookie = 'mujeeb_refresh=user-a';
    final api = ApiClient(
      cookieStore: store,
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/login');
        expect(request.headers.containsKey('Cookie'), isFalse);
        return http.Response(jsonEncode({'data': {
          'access_token': 'user-b-access',
          'principal': {'principal_id': 'b', 'display_name': 'Second'},
        }}), 200, headers: {
          'set-cookie': 'mujeeb_refresh=user-b; Secure; HttpOnly',
        });
      }),
    );
    await api.restoreRefreshCookie();
    await AuthRepository(apiClient: api).login(email: 'b@test.com', password: 'valid');
    expect(store.cookie, 'mujeeb_refresh=user-b');
    expect(api.refreshCookie, 'mujeeb_refresh=user-b');
    expect(api.accessToken, 'user-b-access');
  });

  test('revoked restored refresh cookie is deleted before next launch', () async {
    final store = _MemorySecureStore()..cookie = 'mujeeb_refresh=revoked';
    final api = ApiClient(cookieStore: store, client: MockClient((request) async {
      return http.Response(jsonEncode({'error': {
        'code': 'UNAUTHENTICATED',
        'message': 'refresh revoked',
        'retryable': false,
      }}), 401);
    }));
    await api.restoreRefreshCookie();
    try {
      await AuthRepository(apiClient: api).refreshSession();
      fail('expected rejected refresh');
    } catch (e) {
      expect(e.toString(), contains('ApiErrorEnvelope'));
    }
    expect(api.accessToken, isNull);
    expect(api.refreshCookie, isNull);
    expect(store.cookie, isNull);
  });

  test('pending storage read never restores after logout', () async {
    final store = _MemorySecureStore();
    final readGate = Completer<String?>();
    store.readGate = readGate;
    final api = ApiClient(cookieStore: store);
    final restore = api.restoreRefreshCookie();
    api.clearSession();
    readGate.complete('mujeeb_refresh=stale');
    await restore;
    await api.flushCookiePersistence();
    expect(api.refreshCookie, isNull);
    expect(store.cookie, isNull);
  });

  test('an unavailable secure store never falls back to plaintext', () async {
    final store = _MemorySecureStore()..fail = true;
    final api = ApiClient(cookieStore: store);
    api.setRefreshCookie('mujeeb_refresh=ephemeral');
    await api.flushCookiePersistence();
    expect(api.refreshCookie, 'mujeeb_refresh=ephemeral');
    expect(api.refreshCookiePersistenceFailed, isTrue);
    final nextProcess = ApiClient(cookieStore: store);
    await nextProcess.restoreRefreshCookie();
    expect(nextProcess.refreshCookie, isNull);
    expect(nextProcess.refreshCookiePersistenceFailed, isTrue);
  });
}
