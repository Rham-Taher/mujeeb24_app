import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persist only the server's opaque rotating refresh cookie.
/// Never store a bearer access token or credentials on disk.
abstract class RefreshCookieStore {
  Future<String?> read();
  Future<void> write(String cookie);
  Future<void> delete();
}

/// Android Keystore-backed encrypted storage; iOS uses the platform Keychain.
/// No plaintext fallback is allowed if secure storage fails.
class SecureRefreshCookieStore implements RefreshCookieStore {
  final FlutterSecureStorage _storage;
  static const String _key = 'mujeeb24.refresh_cookie.v1';

  SecureRefreshCookieStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String cookie) => _storage.write(key: _key, value: cookie);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}
