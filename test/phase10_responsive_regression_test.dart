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
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';
import 'package:mujeeb24_app/features/merchant/presentation/merchant_home_screen.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

class _FakeMerchantRepo extends MerchantRepository {
  _FakeMerchantRepo() : super(apiClient: ApiClient());

  @override
  Future<DashboardOverview> getDashboardOverview(String businessId) async {
    return const DashboardOverview(
      openConversations: 15,
      waitingHuman: 3,
      newCustomers: 8,
      newLeads: 4,
      transactionsNeedingReview: 2,
      connections: {'WhatsApp': 2, 'Telegram': 1},
    );
  }

  @override
  Future<Business> getBusinessProfile(String businessId) async {
    return const Business(
      id: 'biz_01',
      name: 'متجر مجيب النموذجي',
      slug: 'mujeeb-store',
      defaultCurrency: 'YER',
      locale: 'ar',
      timezone: 'Asia/Aden',
    );
  }

  @override
  Future<List<Conversation>> listConversations({
    required String businessId,
    int limit = 25,
    String? cursor,
    String? state,
    String? ownership,
    String? channel,
    String? customerId,
  }) async {
    return const [
      Conversation(
        id: 'c1',
        businessId: 'biz_01',
        customer: CustomerSummary(
          id: 'cust_01',
          displayName: 'سارة أحمد',
        ),
        state: 'waiting_human',
        ownership: 'unassigned',
        aiMode: 'off',
        priority: 'high',
        lastActivityAt: '2026-10-15T10:00:00Z',
        resourceVersion: 'v1',
      ),
    ];
  }
}

class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo() : super(apiClient: ApiClient());
}

class _FakeWorkspaceRepo extends WorkspaceRepository {
  _FakeWorkspaceRepo() : super(apiClient: ApiClient());
}

Widget buildTestApp({required Widget child}) {
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

void main() {
  const testBusiness = Business(
    id: 'biz_01',
    name: 'متجر مجيب النموذجي',
    slug: 'mujeeb-store',
    defaultCurrency: 'YER',
    locale: 'ar',
    timezone: 'Asia/Aden',
  );

  const testViewports = [
    Size(360, 640), // Small mobile
    Size(390, 844), // Standard mobile (iPhone 12/13/14)
    Size(428, 926), // Large mobile (iPhone Pro Max / Plus)
    Size(768, 1024), // Tablet portrait (iPad / Android Tablet >= 600px breakpoint)
    Size(1024, 768), // Tablet landscape (>= 600px breakpoint)
  ];

  for (final viewport in testViewports) {
    testWidgets(
      'Phase 10 Responsive Audit: MerchantHomeScreen on viewport ${viewport.width}x${viewport.height}',
      (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = _FakeMerchantRepo();
        final merchantProvider = MerchantProvider(merchantRepository: fakeRepo);
        final authProvider = AuthProvider(
          authRepository: _FakeAuthRepo(),
          workspaceRepository: _FakeWorkspaceRepo(),
        );
        authProvider.selectBusiness(
          const BusinessMembership(business: testBusiness, permissions: ['*']),
        );
        final localeProvider = AppLocaleProvider();

        await tester.pumpWidget(
          buildTestApp(
            child: MerchantHomeScreen(
              authProvider: authProvider,
              merchantProvider: merchantProvider,
              localeProvider: localeProvider,
              onSwitchBusiness: () {},
              onLogout: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Check no RenderFlex overflow or layout exceptions
        expect(tester.takeException(), isNull);

        // 2. Check BottomNavigationBar exists and is visible
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // 3. Check navigation between tabs on all screen sizes
        await tester.tap(find.text('المحادثات'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('الرئيسية'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
