import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mujeeb24_app/core/services/deep_link_service.dart';
import 'package:mujeeb24_app/core/auth/refresh_cookie_store.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/auth/auth_repository.dart';
import 'package:mujeeb24_app/core/auth/workspace_repository.dart';
import 'package:mujeeb24_app/core/catalog/catalog_repository.dart';
import 'package:mujeeb24_app/core/channels/channel_automation_repository.dart';
import 'package:mujeeb24_app/core/crm/crm_repository.dart';
import 'package:mujeeb24_app/core/merchant/merchant_repository.dart';
import 'package:mujeeb24_app/core/platform/platform_repository.dart';
import 'package:mujeeb24_app/core/team/team_audit_repository.dart';
import 'package:mujeeb24_app/core/transactions/transaction_repository.dart';
import 'package:mujeeb24_app/features/auth/presentation/invitation_screen.dart';
import 'package:mujeeb24_app/features/auth/presentation/login_screen.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';
import 'package:mujeeb24_app/features/catalog/providers/catalog_provider.dart';
import 'package:mujeeb24_app/features/channels/providers/channel_automation_provider.dart';
import 'package:mujeeb24_app/features/crm/providers/crm_provider.dart';
import 'package:mujeeb24_app/features/merchant/presentation/merchant_home_screen.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';
import 'package:mujeeb24_app/features/platform/providers/platform_provider.dart';
import 'package:mujeeb24_app/features/team/providers/team_audit_provider.dart';
import 'package:mujeeb24_app/features/transactions/providers/transaction_provider.dart';
import 'package:mujeeb24_app/features/workspace/presentation/business_selection_screen.dart';

enum AppRoute { login, invitation, businessSelection, workspace }

class MujeebApp extends StatefulWidget {
  final ApiClient? apiClient;

  const MujeebApp({super.key, this.apiClient});

  @override
  State<MujeebApp> createState() => _MujeebAppState();
}

class _MujeebAppState extends State<MujeebApp> {
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final WorkspaceRepository _workspaceRepository;
  late final AuthProvider _authProvider;
  late final MerchantRepository _merchantRepository;
  late final MerchantProvider _merchantProvider;
  late final CrmRepository _crmRepository;
  late final CrmProvider _crmProvider;
  late final TransactionRepository _transactionRepository;
  late final TransactionProvider _transactionProvider;
  late final CatalogRepository _catalogRepository;
  late final CatalogProvider _catalogProvider;
  late final ChannelAutomationRepository _channelAutomationRepository;
  late final ChannelAutomationProvider _channelAutomationProvider;
  late final TeamAuditRepository _teamAuditRepository;
  late final TeamAuditProvider _teamAuditProvider;
  late final PlatformRepository _platformRepository;
  late final PlatformProvider _platformProvider;
  final AppLocaleProvider _localeProvider = AppLocaleProvider();

  final DeepLinkService _deepLinkService = DeepLinkService();
  String? _incomingInvitationToken;
  AppRoute _currentRoute = AppRoute.login;
  bool _restoringSavedSession = true;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient(
      cookieStore: SecureRefreshCookieStore(),
    );
    _authRepository = AuthRepository(apiClient: _apiClient);
    _workspaceRepository = WorkspaceRepository(apiClient: _apiClient);
    _merchantRepository = MerchantRepository(apiClient: _apiClient);
    _crmRepository = CrmRepository(apiClient: _apiClient);
    _transactionRepository = TransactionRepository(apiClient: _apiClient);
    _catalogRepository = CatalogRepository(apiClient: _apiClient);
    _channelAutomationRepository = ChannelAutomationRepository(apiClient: _apiClient);
    _teamAuditRepository = TeamAuditRepository(apiClient: _apiClient);
    _platformRepository = PlatformRepository(apiClient: _apiClient);
    _authProvider = AuthProvider(
      authRepository: _authRepository,
      workspaceRepository: _workspaceRepository,
    );
    _merchantProvider = MerchantProvider(
      merchantRepository: _merchantRepository,
    );
    _crmProvider = CrmProvider(crmRepository: _crmRepository);
    _transactionProvider = TransactionProvider(
      transactionRepository: _transactionRepository,
    );
    _catalogProvider = CatalogProvider(
      catalogRepository: _catalogRepository,
    );
    _channelAutomationProvider = ChannelAutomationProvider(
      repository: _channelAutomationRepository,
    );
    _teamAuditProvider = TeamAuditProvider(
      repository: _teamAuditRepository,
    );
    _platformProvider = PlatformProvider(
      repository: _platformRepository,
    );

    _apiClient.onSessionExpired = _authProvider.markSessionExpired;
    _authProvider.addListener(_handleAuthStateChange);
    unawaited(_restoreSessionAtStartup());
    _localeProvider.addListener(() => setState(() {}));
    unawaited(_deepLinkService.init(onInvitationReceived: (token) {
      if (!mounted) return;
      setState(() {
        _incomingInvitationToken = token;
        _currentRoute = AppRoute.invitation;
      });
    }));
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthStateChange);
    _authProvider.dispose();
    _merchantProvider.dispose();
    _crmProvider.dispose();
    _transactionProvider.dispose();
    _catalogProvider.dispose();
    _channelAutomationProvider.dispose();
    _teamAuditProvider.dispose();
    _platformProvider.dispose();
    _deepLinkService.dispose();
    _localeProvider.dispose();
    super.dispose();
  }

  Future<void> _restoreSessionAtStartup() async {
    try {
      await _apiClient.restoreRefreshCookie();
      if (_apiClient.refreshCookie?.isNotEmpty == true &&
          _apiClient.accessToken == null) {
        await _authProvider.initSession();
      }
    } catch (_) {
      // An unavailable Keystore/Keychain must never crash the login screen.
    } finally {
      if (mounted) setState(() => _restoringSavedSession = false);
    }
  }

  void _handleAuthStateChange() {
    if (!mounted) return;
    setState(() {
      if (_authProvider.isAuthenticated) {
        if (_authProvider.accessibleBusinesses.length > 1 &&
            _authProvider.selectedBusiness == null) {
          _currentRoute = AppRoute.businessSelection;
        } else if (_authProvider.selectedBusiness != null) {
          _currentRoute = AppRoute.workspace;
        } else {
          _currentRoute = AppRoute.businessSelection;
        }
      } else {
        if (_currentRoute != AppRoute.invitation) {
          _currentRoute = AppRoute.login;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_restoringSavedSession) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Semantics(
              label: 'جاري التحقق من جلسة الدخول',
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }
    return MaterialApp(
      title: 'Mujeeb 24',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _localeProvider.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentRoute) {
      case AppRoute.invitation:
        return InvitationScreen(
          key: ValueKey(_incomingInvitationToken),
          authProvider: _authProvider,
          initialToken: _incomingInvitationToken,
          onBackToLogin: () {
            setState(() => _currentRoute = AppRoute.login);
          },
        );

      case AppRoute.businessSelection:
        return BusinessSelectionScreen(
          authProvider: _authProvider,
          onBusinessSelected: () {
            setState(() => _currentRoute = AppRoute.workspace);
          },
          onLogout: () {
            // Changing route alone is NOT logout. Revoke and clear credentials.
            unawaited(_authProvider.logout());
          },
        );

      case AppRoute.workspace:
        return MerchantHomeScreen(
          authProvider: _authProvider,
          merchantProvider: _merchantProvider,
          crmProvider: _crmProvider,
          transactionProvider: _transactionProvider,
          catalogProvider: _catalogProvider,
          channelAutomationProvider: _channelAutomationProvider,
          teamAuditProvider: _teamAuditProvider,
          platformProvider: _platformProvider,
          localeProvider: _localeProvider,
          onSwitchBusiness: () {
            setState(() => _currentRoute = AppRoute.businessSelection);
          },
          onLogout: () {
            // Changing route alone is NOT logout. Revoke and clear credentials.
            unawaited(_authProvider.logout());
          },
        );

      case AppRoute.login:
        return LoginScreen(
          authProvider: _authProvider,
          onLoginSuccess: () {
            _handleAuthStateChange();
          },
          onNavigateToInvitation: () {
            setState(() {
              _incomingInvitationToken = null;
              _currentRoute = AppRoute.invitation;
            });
          },
        );
    }
  }
}
