import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
      openConversations: 18,
      waitingHuman: 3,
      newCustomers: 142,
      newLeads: 24,
      transactionsNeedingReview: 7,
      connections: {'WhatsApp': 3, 'Instagram': 2, 'Facebook': 1},
    );
  }

  @override
  Future<Business> getBusinessProfile(String businessId) async {
    return const Business(
      id: 'biz_01',
      name: 'مؤسسة الأفق للتجارة',
      slug: 'alufuq-corp',
      defaultCurrency: 'SAR',
      locale: 'ar',
      timezone: 'Asia/Riyadh',
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
        lastActivityAt: '2026-11-05T10:42:00Z',
        resourceVersion: 'v1',
        labels: ['whatsapp', 'vip'],
      ),
      Conversation(
        id: 'c2',
        businessId: 'biz_01',
        customer: CustomerSummary(
          id: 'cust_02',
          displayName: 'عبدالرحمن الشهري',
        ),
        state: 'open',
        ownership: 'assigned',
        aiMode: 'auto',
        priority: 'medium',
        lastActivityAt: '2026-11-05T09:15:00Z',
        resourceVersion: 'v1',
        labels: ['instagram'],
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

Future<void> captureWidgetScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String filePath,
) async {
  await tester.runAsync(() async {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is RenderRepaintBoundary) {
      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        final file = File(filePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(buffer);
      }
    }
  });
}

void main() {
  const testBusiness = Business(
    id: 'biz_01',
    name: 'مؤسسة الأفق للتجارة',
    slug: 'alufuq-corp',
    defaultCurrency: 'SAR',
    locale: 'ar',
    timezone: 'Asia/Riyadh',
  );

  testWidgets('Phase 3 Visual Capture Tests: Home Dashboard & Inbox',
      (tester) async {
    tester.view.physicalSize = const Size(780, 1688); // 390x844 @ 2x
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repaintKey = GlobalKey();
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

    await merchantProvider.loadDashboardOverview('biz_01');
    await merchantProvider.loadConversations('biz_01');

    await tester.pumpWidget(
      RepaintBoundary(
        key: repaintKey,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MerchantHomeScreen(
            authProvider: authProvider,
            merchantProvider: merchantProvider,
            localeProvider: localeProvider,
            onSwitchBusiness: () {},
            onLogout: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Capture Home Dashboard
    await captureWidgetScreenshot(
      tester,
      repaintKey,
      'docs/renders/phase3_home_dashboard.png',
    );

    // 2. Switch to Inbox
    await tester.tap(find.text('المحادثات'));
    await tester.pumpAndSettle();

    // 3. Capture Inbox
    await captureWidgetScreenshot(
      tester,
      repaintKey,
      'docs/renders/phase3_inbox.png',
    );
  });
}
