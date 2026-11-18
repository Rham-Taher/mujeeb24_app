import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/auth/auth_repository.dart';
import 'package:mujeeb24_app/core/auth/workspace_repository.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/models/platform_models.dart';
import 'package:mujeeb24_app/core/platform/platform_repository.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';
import 'package:mujeeb24_app/features/platform/presentation/platform_hub_screen.dart';
import 'package:mujeeb24_app/features/platform/providers/platform_provider.dart';

class Phase9MockAuthRepo extends AuthRepository {
  Phase9MockAuthRepo() : super(apiClient: ApiClient());
}

class Phase9MockWorkspaceRepo extends WorkspaceRepository {
  Phase9MockWorkspaceRepo() : super(apiClient: ApiClient());
}

class Phase9MockAuthProvider extends AuthProvider {
  Phase9MockAuthProvider()
      : super(
          authRepository: Phase9MockAuthRepo(),
          workspaceRepository: Phase9MockWorkspaceRepo(),
        );

  @override
  bool get isPlatformAdmin => true;

  @override
  bool get isAuthenticated => true;
}

class Phase9MockPlatformRepo extends PlatformRepository {
  Phase9MockPlatformRepo() : super(apiClient: ApiClient());

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
          name: 'شركة الأفق للتجارة الذكية',
          slug: 'alufuq-corp',
          platformStatus: 'active',
          ownerIdentitySummary: 'admin@alufuq.com (عبدالله الأحمد)',
          subscriptionSummary: 'الباقة المتقدمة Pro • ينتهي: 31 ديسمبر 2026',
          createdAt: '2026-01-01T00:00:00Z',
          updatedAt: '2026-01-01T00:00:00Z',
        ),
        PlatformBusinessView(
          id: 'biz_sample_2',
          name: 'متجر زهور النرجس والورود',
          slug: 'al-narjis-flowers',
          platformStatus: 'active',
          ownerIdentitySummary: 'flowers@narjis.store (فاطمة الدوسري)',
          subscriptionSummary: 'الباقة الأساسية Starter • ينتهي: 15 نوفمبر 2026',
          createdAt: '2026-02-15T00:00:00Z',
          updatedAt: '2026-02-15T00:00:00Z',
        ),
        PlatformBusinessView(
          id: 'biz_sample_3',
          name: 'مؤسسة قمة التقنية للخدمات',
          slug: 'qimma-tech',
          platformStatus: 'suspended',
          ownerIdentitySummary: 'support@qimmatech.sa (صالح القرني)',
          subscriptionSummary: 'منتهي الصلاحية • تم الإيقاف للصيانة',
          createdAt: '2026-03-01T00:00:00Z',
          updatedAt: '2026-03-01T00:00:00Z',
        ),
      ],
      pagination: PaginationPage(hasMore: false),
      requestId: 'req_biz_render',
    );
  }

  @override
  Future<PlatformChannelPage> listChannels({int limit = 25, String? cursor}) async {
    return const PlatformChannelPage(
      items: [],
      pagination: PaginationPage(hasMore: false),
      requestId: 'req_chan_render',
    );
  }

  @override
  Future<PlatformPlanPage> listPlans({int limit = 25, String? cursor, String? status}) async {
    return const PlatformPlanPage(
      items: [
        PlanView(
          id: 'plan_starter',
          code: 'STARTER',
          displayName: 'الباقة الأساسية Starter',
          priceYer: 15000,
          billingInterval: 'monthly',
          status: 'active',
          aiReplyLimit: 500,
          aiCatalogLimit: 100,
          channelLimit: 1,
          createdAt: '2026-01-01T00:00:00Z',
          updatedAt: '2026-01-01T00:00:00Z',
        ),
        PlanView(
          id: 'plan_pro',
          code: 'PRO',
          displayName: 'باقة المحترفين Pro',
          priceYer: 35000,
          billingInterval: 'monthly',
          status: 'active',
          aiReplyLimit: 2500,
          aiCatalogLimit: 500,
          channelLimit: 3,
          createdAt: '2026-01-01T00:00:00Z',
          updatedAt: '2026-01-01T00:00:00Z',
        ),
      ],
      pagination: PaginationPage(hasMore: false),
      requestId: 'req_plan_render',
    );
  }

  @override
  Future<PlatformSubscriptionPage> listSubscriptions({
    int limit = 25,
    String? cursor,
    String? businessId,
    String? status,
  }) async {
    return const PlatformSubscriptionPage(
      items: [],
      pagination: PaginationPage(hasMore: false),
      requestId: 'req_sub_render',
    );
  }
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

Widget buildTestApp(Widget child, GlobalKey repaintKey) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.lightTheme,
    home: RepaintBoundary(
      key: repaintKey,
      child: child,
    ),
  );
}

void main() {
  testWidgets('Phase 9 Render Test: Platform Hub Businesses', (tester) async {
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeAuth = Phase9MockAuthProvider();
    final fakeRepo = Phase9MockPlatformRepo();
    final provider = PlatformProvider(repository: fakeRepo);
    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      buildTestApp(
        PlatformHubScreen(
          provider: provider,
          authProvider: fakeAuth,
          onBackToWorkspace: () {},
        ),
        repaintKey,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('شركة الأفق للتجارة الذكية'), findsOneWidget);
    expect(find.text('متجر زهور النرجس والورود'), findsOneWidget);

    await captureWidgetScreenshot(
      tester,
      repaintKey,
      'docs/renders/phase9_platform_businesses.png',
    );
  });

  testWidgets('Phase 9 Render Test: Platform Hub Plans', (tester) async {
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeAuth = Phase9MockAuthProvider();
    final fakeRepo = Phase9MockPlatformRepo();
    final provider = PlatformProvider(repository: fakeRepo);
    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      buildTestApp(
        PlatformHubScreen(
          provider: provider,
          authProvider: fakeAuth,
          onBackToWorkspace: () {},
        ),
        repaintKey,
      ),
    );

    await tester.pumpAndSettle();

    // Switch to Plans tab
    await tester.ensureVisible(find.byKey(const Key('tab_plat_plans')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_plat_plans')));
    await tester.pumpAndSettle();

    expect(find.textContaining('الباقة الأساسية Starter'), findsOneWidget);

    await captureWidgetScreenshot(
      tester,
      repaintKey,
      'docs/renders/phase9_platform_plans.png',
    );
  });
}
