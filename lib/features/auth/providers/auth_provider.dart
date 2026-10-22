import 'package:flutter/foundation.dart';
import 'package:mujeeb24_app/core/errors/api_error.dart';
import 'package:mujeeb24_app/core/team/team_invitation_presentation.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/auth/auth_repository.dart';
import 'package:mujeeb24_app/core/auth/workspace_repository.dart';

enum AuthStatus {
  uninitialized,
  unauthenticated,
  authenticating,
  authenticated,
  sessionExpired,
}

/// Central state manager for Phase 1 Authentication & Session
class AuthProvider extends ChangeNotifier {
  final AuthRepository authRepository;
  final WorkspaceRepository workspaceRepository;

  AuthStatus _status = AuthStatus.uninitialized;
  Principal? _currentPrincipal;
  AuthResponse? _authResponse;
  List<BusinessMembership> _accessibleBusinesses = [];
  BusinessMembership? _selectedBusiness;
  String? _errorMessage;
  String? _lastRequestId;
  bool _isLoading = false;

  AuthProvider({
    required this.authRepository,
    required this.workspaceRepository,
  });

  AuthStatus get status => _status;
  Principal? get currentPrincipal => _currentPrincipal;
  AuthResponse? get authResponse => _authResponse;
  List<BusinessMembership> get accessibleBusinesses => _accessibleBusinesses;
  BusinessMembership? get selectedBusiness => _selectedBusiness;
  String? get errorMessage => _errorMessage;
  String? get lastRequestId => _lastRequestId;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isPlatformAdmin => _authResponse?.isPlatformAdmin ?? false;

  void clearError() {
    _errorMessage = null;
    _lastRequestId = null;
    notifyListeners();
  }

  void selectBusiness(BusinessMembership membership) {
    _selectedBusiness = membership;
    notifyListeners();
  }

  /// Initialize and restore session via refresh token if present
  Future<void> initSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final refreshed = await authRepository.refreshSession();
      _authResponse = refreshed;
      _currentPrincipal = refreshed.principal;
      await _loadBusinesses();
      _status = AuthStatus.authenticated;
    } catch (_) {
      // Refresh failed or no session cookie exists -> user must log in
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Perform login with email and password
  Future<bool> login(String email, String password) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    _lastRequestId = null;
    notifyListeners();

    try {
      final res = await authRepository.login(email: email, password: password);
      _authResponse = res;
      _currentPrincipal = res.principal;

      // Fetch accessible businesses
      await _loadBusinesses();

      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _errorMessage = e.error.message;
      _lastRequestId = e.requestId;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadBusinesses() async {
    try {
      final businesses = await workspaceRepository.getAccessibleBusinesses();
      _accessibleBusinesses = businesses;
      if (businesses.length == 1) {
        _selectedBusiness = businesses.first;
      }
    } catch (e) {
      _accessibleBusinesses = [];
    }
  }

  /// Reload businesses manually
  Future<void> reloadBusinesses() async {
    _isLoading = true;
    notifyListeners();
    await _loadBusinesses();
    _isLoading = false;
    notifyListeners();
  }

  /// Server revoked or rejected our refresh session. Shared API client
  /// already erased the stale credentials; never keep workspace privileges.
  void markSessionExpired() {
    if (_status == AuthStatus.unauthenticated ||
        _status == AuthStatus.sessionExpired) return;
    _status = AuthStatus.sessionExpired;
    _currentPrincipal = null;
    _authResponse = null;
    _accessibleBusinesses = [];
    _selectedBusiness = null;
    _errorMessage = 'انتهت صلاحية الجلسة. سجّل الدخول مجددًا.';
    notifyListeners();
  }

  /// Refresh session
  Future<bool> refreshSession() async {
    try {
      final res = await authRepository.refreshSession();
      _authResponse = res;
      _currentPrincipal = res.principal;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        authRepository.apiClient.clearSession();
        markSessionExpired();
      } else {
        _errorMessage = 'تعذر تجديد الجلسة مؤقتًا. أعد المحاولة.';
        notifyListeners();
      }
      return false;
    } catch (_) {
      // A timeout is not evidence of refresh-token revocation.
      _errorMessage = 'تعذر الاتصال بالخادم لتجديد الجلسة.';
      notifyListeners();
      return false;
    }
  }

  /// Explicit logout: hide the private workspace immediately.
  Future<void> logout() async {
    _status = AuthStatus.unauthenticated;
    _currentPrincipal = null;
    _authResponse = null;
    _accessibleBusinesses = [];
    _selectedBusiness = null;
    _errorMessage = null;
    _lastRequestId = null;
    _isLoading = false;
    notifyListeners();
    try {
      await authRepository.logout();
    } catch (_) {
      // The repository clears credentials even if server revocation fails.
    }
  }

  /// Inspect an invitation token
  Future<TeamInvitation?> inspectInvitation(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final invitation = await authRepository.inspectInvitation(
        acceptanceToken: token,
      );
      _isLoading = false;
      notifyListeners();
      return invitation;
    } on ApiErrorEnvelope catch (e) {
      _errorMessage = invitationErrorMessage(e, resend: false);
      _lastRequestId = e.requestId;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'تعذر إكمال الدعوة. تحقق من الاتصال وحاول مرة أخرى.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Accept an invitation for a new account
  Future<bool> acceptNewAccountInvitation({
    required String token,
    required String displayName,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.acceptNewAccountInvitation(
        acceptanceToken: token,
        displayName: displayName,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _errorMessage = invitationErrorMessage(e, resend: false);
      _lastRequestId = e.requestId;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'تعذر إكمال الدعوة. تحقق من الاتصال وحاول مرة أخرى.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Accept an invitation for an existing account
  Future<bool> acceptTeamInvitation({required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.acceptTeamInvitation(acceptanceToken: token);
      await _loadBusinesses();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiErrorEnvelope catch (e) {
      _errorMessage = invitationErrorMessage(e, resend: false);
      _lastRequestId = e.requestId;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'تعذر إكمال الدعوة. تحقق من الاتصال وحاول مرة أخرى.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
