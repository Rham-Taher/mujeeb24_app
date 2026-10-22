import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/auth/auth_repository.dart';
import 'package:mujeeb24_app/core/auth/workspace_repository.dart';
import 'package:mujeeb24_app/core/merchant/merchant_repository.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/core/models/platform_models.dart';
import 'package:mujeeb24_app/core/platform/platform_repository.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';
import 'package:mujeeb24_app/features/merchant/presentation/business_settings_tab.dart';
import 'package:mujeeb24_app/features/merchant/presentation/merchant_home_screen.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';
import 'package:mujeeb24_app/features/platform/presentation/platform_hub_screen.dart';
import 'package:mujeeb24_app/features/platform/providers/platform_provider.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(apiClient: ApiClient());
}

class FakeWorkspaceRepository extends WorkspaceRepository {
  FakeWorkspaceRepository() : super(apiClient: ApiClient());
}

class FakeAuthProvider extends AuthProvider {
  final bool _isAdmin;
  final BusinessMembership? selectedBiz;

  FakeAuthProvider({
    bool isPlatformAdmin = false,
    this.selectedBiz,
  })  : _isAdmin = isPlatformAdmin,
        super(
          authRepository: FakeAuthRepository(),
          workspaceRepository: FakeWorkspaceRepository(),
        );

  @override
  bool get isPlatformAdmin => _isAdmin;

  @override
  bool get isAuthenticated => true;

  @override
  BusinessMembership? get selectedBusiness => selectedBiz;

  @override
  List<BusinessMembership> get accessibleBusinesses {
    final biz = selectedBiz;
    return biz != null ? [biz] : [];
  }
}

class FakePlatformRepository extends PlatformRepository {
  bool killSwitchActive = false;
  bool healthCheckTriggered = false;

  FakePlatformRepository() : super(apiClient: ApiClient());

  @override
  Future<PlatformBusinessPage> listBusinesses({
    int limit = 25,
    String? cursor,
    String? platformStatus,
  }) async {
    return const PlatformBusinessPage(
      items: [
        PlatformBusinessView(
          id: 'biz_sample_1',
          name: 'شركة الأفق للتجارة',
          slug: 'alufuq-corp',
          platformStatus: 'active',
          ownerIdentitySummary: 'admin@alufuq.com',
          subscriptionSummary: 'Pro Plan (Active)',
          createdAt: '2026-01-01T00:00:00Z',
          updatedAt: '2026-01-01T00:00:00Z',
        ),
      ],
      pagination: PaginationPage(hasMore: false),
      requestId: 'req_biz_test',
    );
  }

  @override
  Future<PlatformChannelPage> listChannels({
    int limit = 25,
    String? cursor,
  }) async {
    return const PlatformChannelPage(
      items: [
        PlatformChannelView(
          businessId: 'biz_sample_1',
          connectionId: 'conn_meta_1',
          channel: 'whatsapp',
          provider: 'meta',
          status: 'active',
          health: 'healthy',
          providerAccountRef: 'waba_999',
        ),
      ],
      pagination: PaginationPage(hasMore: false),
      requestId: 'req_chan_test',
    );
  }

  @override
  Future<PlatformAIOverviewView> getAIOverview() async {
    return PlatformAIOverviewView(
      runtime: PlatformAIRuntime(
        status: killSwitchActive ? 'disabled' : 'enabled',
        health: killSwitchActive ? 'unhealthy' : 'healthy',
      ),
      provider: const PlatformAIProviderInfo(
        provider: 'openrouter',
        model: 'anthropic/claude-3.5-sonnet',
        enabled: true,
        health: 'healthy',
      ),
    );
  }

  @override
  Future<PlatformAIOverviewView> disableAI({
    String? reason,
    String? idempotencyKey,
  }) async {
    killSwitchActive = true;
    return getAIOverview();
  }

  @override
  Future<PlatformAIOverviewView> enableAI({String? idempotencyKey}) async {
    killSwitchActive = false;
    return getAIOverview();
  }

  @override
  Future<PlatformAIHealthCheckResult> runAIHealthCheck({
    String? idempotencyKey,
  }) async {
    healthCheckTriggered = true;
    return const PlatformAIHealthCheckResult(
      provider: 'openrouter',
      model: 'anthropic/claude-3.5-sonnet',
      result: 'success',
      latencyMs: 110,
      checkedAt: '2026-01-20T12:00:00Z',
    );
  }

  @override
  Future<PlatformAIUsageOverviewView> getAIUsage() async {
    return const PlatformAIUsageOverviewView(
      totalInvocations: 12500,
      totalTokens: 3500000,
      estimatedCostYer: 175000,
    );
  }

  @override
  Future<PlatformPlanPage> listPlans({
    int limit = 25,
    String? cursor,
    String? status,
  }) async {
    return const PlatformPlanPage(
      items: [
        PlanView(
          id: 'plan_starter',
          code: 'STARTER',
          displayName: 'الباقة الأساسية',
          priceYer: 30000,
          billingInterval: 'monthly',
          status: 'active',
          aiReplyLimit: 1000,
          aiCatalogLimit: 200,
          channelLimit: 1,
          createdAt: '2026-01-01T00:00:00Z',
          updatedAt: '2026-01-01T00:00:00Z',
        ),
      ],
      pagination: PaginationPage(hasMore: false),
      requestId: 'req_plans_test',
    );
  }

  @override
  Future<PlatformSubscriptionPage> listSubscriptions({
    int limit = 25,
    String? cursor,
    String? status,
  }) async {
    return const PlatformSubscriptionPage(
      items: [
        SubscriptionView(
          id: 'sub_001',
          businessId: 'biz_sample_1',
          planId: 'plan_starter',
          planCode: 'STARTER',
          planVersion: 1,
          periodStart: '2026-01-01T00:00:00Z',
          periodEnd: '2026-02-01T00:00:00Z',
          status: 'active',
          aiReplyLimit: 1000,
          aiCatalogLimit: 200,
          channelLimit: 1,
          createdAt: '2026-01-01T00:00:00Z',
        ),
      ],
      pagination: PaginationPage(hasMore: false),
      requestId: 'req_subs_test',
    );
  }

  @override
  Future<PlatformTicketPage> listTickets({
    int limit = 25,
    String? cursor,
    String? status,
  }) async {
    return const PlatformTicketPage(
      items: [
        SupportTicketView(
          id: 'tkt_99',
          businessId: 'biz_sample_1',
          subject: 'مشكلة في ربط الواتساب',
          status: 'open',
          priority: 'urgent',
          category: 'technical',
          createdBy: 'user_1',
          createdByType: 'merchant',
          createdAt: '2026-01-20T10:00:00Z',
        ),
      ],
      pagination: PaginationPage(hasMore: false),
      requestId: 'req_ticket_test',
    );
  }

  @override
  Future<PlatformAuditPage> listAuditEvents({
    int limit = 25,
    String? cursor,
    String? action,
    String? targetType,
  }) async {
    return const PlatformAuditPage(
      items: [
        PlatformAuditEventView(
          id: 'aud_1',
          action: 'ai.runtime.kill_switch_toggled',
          targetType: 'ai_runtime',
          result: 'success',
          metadata: {},
          occurredAt: '2026-01-20T12:00:00Z',
        ),
      ],
      pagination: PaginationPage(hasMore: false),
      requestId: 'req_audit_test',
    );
  }
}

Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void _setDesktopSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('Phase 8 Widget Tests: Access Guard & PlatformHubScreen', () {
    testWidgets('unauthorized user gets Access Denied view and back button', (
      tester,
    ) async {
      _setDesktopSize(tester);
      final fakeAuth = FakeAuthProvider(isPlatformAdmin: false);
      final fakeRepo = FakePlatformRepository();
      final platformProvider = PlatformProvider(repository: fakeRepo);

      bool backCalled = false;

      await tester.pumpWidget(
        _wrapWithApp(
          PlatformHubScreen(
            provider: platformProvider,
            authProvider: fakeAuth,
            onBackToWorkspace: () => backCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Access Denied screen
      expect(find.byKey(const Key('btn_back_to_workspace_denied')), findsOneWidget);
      expect(find.text('غير مصرح بالدخول'), findsNWidgets(2)); // AppBar + Body Header

      // Tap back button
      await tester.tap(find.byKey(const Key('btn_back_to_workspace_denied')));
      await tester.pumpAndSettle();
      expect(backCalled, true);
    });

    testWidgets('platform admin accesses dashboard with all 6 tabs and cards', (
      tester,
    ) async {
      _setDesktopSize(tester);
      final fakeAuth = FakeAuthProvider(isPlatformAdmin: true);
      final fakeRepo = FakePlatformRepository();
      final platformProvider = PlatformProvider(repository: fakeRepo);

      await tester.pumpWidget(
        _wrapWithApp(
          PlatformHubScreen(
            provider: platformProvider,
            authProvider: fakeAuth,
            onBackToWorkspace: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen title
      expect(find.text('إدارة المنصة المركزية'), findsOneWidget);

      // Verify all 6 tabs exist
      expect(find.byKey(const Key('tab_plat_businesses')), findsOneWidget);
      expect(find.byKey(const Key('tab_plat_channels')), findsOneWidget);
      expect(find.byKey(const Key('tab_plat_ai')), findsOneWidget);
      expect(find.byKey(const Key('tab_plat_plans')), findsOneWidget);
      expect(find.byKey(const Key('tab_plat_support')), findsOneWidget);
      expect(find.byKey(const Key('tab_plat_audit')), findsOneWidget);

      // Verify business item is rendered
      expect(find.text('شركة الأفق للتجارة'), findsOneWidget);
      expect(find.textContaining('alufuq-corp'), findsOneWidget);
    });

    testWidgets('switching tabs loads AI overview, kill switch, and health check', (
      tester,
    ) async {
      _setDesktopSize(tester);
      final fakeAuth = FakeAuthProvider(isPlatformAdmin: true);
      final fakeRepo = FakePlatformRepository();
      final platformProvider = PlatformProvider(repository: fakeRepo);

      await tester.pumpWidget(
        _wrapWithApp(
          PlatformHubScreen(
            provider: platformProvider,
            authProvider: fakeAuth,
            onBackToWorkspace: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap AI Tab
      await tester.tap(find.byKey(const Key('tab_plat_ai')));
      await tester.pumpAndSettle();

      // Verify AI Kill Switch card is displayed
      expect(find.byKey(const Key('btn_ai_kill_switch_disable')), findsOneWidget);
      expect(find.byKey(const Key('btn_run_ai_health')), findsOneWidget);

      // Tap Run AI Health Check button
      await tester.tap(find.byKey(const Key('btn_run_ai_health')));
      await tester.pumpAndSettle();

      expect(fakeRepo.healthCheckTriggered, true);
    });

    testWidgets('switching to Plans tab renders plan list and status', (
      tester,
    ) async {
      _setDesktopSize(tester);
      final fakeAuth = FakeAuthProvider(isPlatformAdmin: true);
      final fakeRepo = FakePlatformRepository();
      final platformProvider = PlatformProvider(repository: fakeRepo);

      await tester.pumpWidget(
        _wrapWithApp(
          PlatformHubScreen(
            provider: platformProvider,
            authProvider: fakeAuth,
            onBackToWorkspace: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Plans Tab
      await tester.tap(find.byKey(const Key('tab_plat_plans')));
      await tester.pumpAndSettle();

      expect(find.textContaining('الباقة الأساسية'), findsOneWidget);
      expect(find.textContaining('STARTER'), findsOneWidget);
    });

    testWidgets('switching to Support tab renders support tickets', (
      tester,
    ) async {
      _setDesktopSize(tester);
      final fakeAuth = FakeAuthProvider(isPlatformAdmin: true);
      final fakeRepo = FakePlatformRepository();
      final platformProvider = PlatformProvider(repository: fakeRepo);

      await tester.pumpWidget(
        _wrapWithApp(
          PlatformHubScreen(
            provider: platformProvider,
            authProvider: fakeAuth,
            onBackToWorkspace: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Support Tab
      await tester.tap(find.byKey(const Key('tab_plat_support')));
      await tester.pumpAndSettle();

      expect(find.text('مشكلة في ربط الواتساب'), findsOneWidget);
    });
  });

  group('Phase 8 Widget Tests: Navigation from Settings & Home', () {
    testWidgets('BusinessSettingsTab renders Platform tile only when onNavigateToPlatform is provided', (
      tester,
    ) async {
      _setDesktopSize(tester);
      bool navCalled = false;
      final merchantProvider = MerchantProvider(
        merchantRepository: FakeMerchantRepository(),
      );

      // 1. Without callback (regular merchant): tile should NOT appear
      await tester.pumpWidget(
        _wrapWithApp(
          Scaffold(
            body: BusinessSettingsTab(
              merchantProvider: merchantProvider,
              currentBusiness: null,
              onSwitchBusiness: () {},
              onLogout: () {},
              onToggleLanguage: () {},
              onNavigateToPlatform: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tile_platform_administration')), findsNothing);

      // 2. With callback (platform admin): tile should appear and trigger callback on tap
      await tester.pumpWidget(
        _wrapWithApp(
          Scaffold(
            body: BusinessSettingsTab(
              merchantProvider: merchantProvider,
              currentBusiness: null,
              onSwitchBusiness: () {},
              onLogout: () {},
              onToggleLanguage: () {},
              onNavigateToPlatform: () => navCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tileFinder = find.byKey(const Key('tile_platform_administration'));
      expect(tileFinder, findsOneWidget);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      expect(navCalled, true);
    });

    testWidgets('MerchantHomeScreen shows Platform admin icon in AppBar only for admins', (
      tester,
    ) async {
      _setDesktopSize(tester);
      final fakeAdminAuth = FakeAuthProvider(
        isPlatformAdmin: true,
        selectedBiz: const BusinessMembership(
          business: Business(
            id: 'biz_1',
            name: 'Al-Ufuq Store',
            slug: 'alufuq',
            defaultCurrency: 'SAR',
            locale: 'ar',
            timezone: 'Asia/Riyadh',
          ),
          permissions: ['*'],
        ),
      );
      final fakeUserAuth = FakeAuthProvider(
        isPlatformAdmin: false,
        selectedBiz: const BusinessMembership(
          business: Business(
            id: 'biz_1',
            name: 'Al-Ufuq Store',
            slug: 'alufuq',
            defaultCurrency: 'SAR',
            locale: 'ar',
            timezone: 'Asia/Riyadh',
          ),
          permissions: ['*'],
        ),
      );

      final merchantProvider = MerchantProvider(
        merchantRepository: FakeMerchantRepository(),
      );
      final platformProvider = PlatformProvider(
        repository: FakePlatformRepository(),
      );

      // 1. For regular user: no platform icon in AppBar
      await tester.pumpWidget(
        _wrapWithApp(
          MerchantHomeScreen(
            authProvider: fakeUserAuth,
            merchantProvider: merchantProvider,
            platformProvider: platformProvider,
            localeProvider: AppLocaleProvider(),
            onSwitchBusiness: () {},
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('merchant_more_actions')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('btn_appbar_platform')), findsNothing);
      // Close the first popup route before switching the mocked user.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // 2. For platform admin: platform item is available only to admins
      await tester.pumpWidget(
        _wrapWithApp(
          MerchantHomeScreen(
            authProvider: fakeAdminAuth,
            merchantProvider: merchantProvider,
            platformProvider: platformProvider,
            localeProvider: AppLocaleProvider(),
            onSwitchBusiness: () {},
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('merchant_more_actions')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('btn_appbar_platform')), findsOneWidget);
    });
  });
}

class FakeMerchantRepository extends MerchantRepository {
  FakeMerchantRepository() : super(apiClient: ApiClient());

  @override
  Future<DashboardOverview> getDashboardOverview(String businessId) async {
    return const DashboardOverview(
      openConversations: 0,
      waitingHuman: 0,
      newCustomers: 0,
      newLeads: 0,
      transactionsNeedingReview: 0,
      connections: {},
    );
  }

  @override
  Future<Business> getBusinessProfile(String businessId) async {
    return const Business(
      id: 'biz_1',
      name: 'Al-Ufuq Store',
      slug: 'alufuq',
      defaultCurrency: 'SAR',
      locale: 'ar',
      timezone: 'Asia/Riyadh',
    );
  }

  @override
  Future<BusinessPolicy> getBusinessPolicy(String businessId) async {
    return const BusinessPolicy(
      businessId: 'biz_1',
      aiMode: 'suggest',
      defaultHumanReview: false,
      allowAutoReply: false,
      allowAutoLeadCreation: false,
      allowAutoTransactionDraft: false,
      allowAutoConfirmation: false,
      resourceVersion: 'v1',
    );
  }
}
