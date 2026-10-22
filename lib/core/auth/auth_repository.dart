import '../api/api_client.dart';
import '../errors/api_error.dart';
import '../models/auth_models.dart';

/// Authentication Repository implementing:
/// - POST /auth/login
/// - POST /auth/refresh
/// - POST /auth/logout
/// - GET /me
/// - POST /auth/invitations/inspect
/// - POST /auth/invitations/accept-new-account
/// - POST /team/invitations/accept
class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  /// POST /auth/login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    // A different account's saved refresh cookie must NEVER be inherited
    // when a new principal explicitly signs in.
    apiClient.clearSession();
    await apiClient.flushCookiePersistence();
    final response = await apiClient.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
      requiresAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    final authResponse = AuthResponse.fromJson(data);
    apiClient.setAccessToken(authResponse.accessToken);
    await apiClient.flushCookiePersistence();
    return authResponse;
  }

  /// POST /auth/refresh
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await apiClient.post(
        '/auth/refresh',
        requiresAuth: false,
        sendCookie: true,
        timeout: const Duration(seconds: 20),
      );
      final data = response['data'] as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(data);
      apiClient.setAccessToken(authResponse.accessToken);
      await apiClient.flushCookiePersistence();
      return authResponse;
    } on ApiErrorEnvelope catch (e) {
      // Explicit startup refresh bypasses the normal protected 401 handler.
      // Erase a revoked or expired rotating token on definitive rejection.
      if (e.statusCode == 401 || e.statusCode == 403) {
        apiClient.clearSession();
        await apiClient.flushCookiePersistence();
      }
      rethrow;
    }
  }

  /// POST /auth/logout. Clear local secrets immediately after dispatch,
  /// even when the network hangs or the server rejects the logout.
  Future<void> logout() async {
    final hasSession = (apiClient.accessToken?.isNotEmpty ?? false) ||
        (apiClient.refreshCookie?.isNotEmpty ?? false);
    if (!hasSession) {
      apiClient.clearSession();
      return;
    }
    final remoteLogout = apiClient.post(
      '/auth/logout',
      requiresAuth: true,
      sendCookie: true,
      timeout: const Duration(seconds: 10),
    );
    apiClient.clearSession();
    try {
      await remoteLogout;
    } on ApiErrorEnvelope catch (error) {
      // Immediate local logout was already performed before awaiting the server.
      // A late response cannot revoke the next account's newly created session.
      if (error.error.code != 'SESSION_CHANGED') rethrow;
    } finally {
      // Finish removing the encrypted cookie, even if remote revocation fails.
      await apiClient.flushCookiePersistence();
    }
  }

  /// GET /me
  Future<Principal> getCurrentPrincipal() async {
    final response = await apiClient.get('/me', requiresAuth: true);

    final data = response['data'] as Map<String, dynamic>;
    return Principal.fromJson(data);
  }

  /// POST /auth/invitations/inspect
  Future<TeamInvitation> inspectInvitation({
    required String acceptanceToken,
  }) async {
    final response = await apiClient.post(
      '/auth/invitations/inspect',
      body: {'acceptance_token': acceptanceToken.trim()},
      requiresAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    return TeamInvitation.fromJson(data);
  }

  /// POST /auth/invitations/accept-new-account
  Future<TeamInvitation> acceptNewAccountInvitation({
    required String acceptanceToken,
    required String displayName,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/auth/invitations/accept-new-account',
      body: {
        'acceptance_token': acceptanceToken.trim(),
        'display_name': displayName.trim(),
        'password': password,
      },
      requiresAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    return TeamInvitation.fromJson(data);
  }

  /// POST /team/invitations/accept (for existing logged-in members)
  Future<TeamInvitation> acceptTeamInvitation({
    required String acceptanceToken,
  }) async {
    final response = await apiClient.post(
      '/team/invitations/accept',
      body: {'acceptance_token': acceptanceToken.trim()},
      requiresAuth: true,
    );

    final data = response['data'] as Map<String, dynamic>;
    return TeamInvitation.fromJson(data);
  }
}
