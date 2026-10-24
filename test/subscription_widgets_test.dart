import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/models/platform_models.dart';
import 'package:mujeeb24_app/core/models/subscription_models.dart';
import 'package:mujeeb24_app/core/subscription/subscription_repository.dart';
import 'package:mujeeb24_app/features/subscription/presentation/manual_payment_dialog.dart';
import 'package:mujeeb24_app/features/subscription/presentation/subscription_plans_screen.dart';
import 'package:mujeeb24_app/features/subscription/presentation/subscription_quota_card.dart';
import 'package:mujeeb24_app/features/subscription/presentation/subscription_screen.dart';
import 'package:mujeeb24_app/features/subscription/providers/subscription_provider.dart';

class FakeSubscriptionRepository extends SubscriptionRepository {
  MerchantSubscriptionView? mockSubscription;
  List<PricingPlan>? mockPlans;
  List<PaymentView> mockPayments = [];
  bool shouldThrowError = false;
  String? lastCreatedSubscriptionId;
  ManualPaymentProofRequest? lastPaymentRequest;

  FakeSubscriptionRepository({this.mockSubscription, this.mockPlans})
    : super(
        apiClient: ApiClient(
          baseUrl: 'https://mock.mujeeb24.com',
          client: MockClient(
            (_) async => http.Response(jsonEncode({'data': {}}), 200),
          ),
        ),
      );

  @override
  Future<MerchantSubscriptionView> getSubscription(String businessId) async {
    if (shouldThrowError) throw Exception('Network timeout');
    return mockSubscription ??
        MerchantSubscriptionView(
          hasSubscription: true,
          id: 'sub-growth-1',
          businessId: businessId,
          planId: 'plan-growth-uuid',
          planCode: 'growth',
          planName: 'نمو (Growth)',
          status: 'ACTIVE',
          priceYerSnapshot: 10000,
          aiReplyLimit: 500,
          aiRepliesUsed: 150,
          aiRepliesRemaining: 350,
          aiCatalogLimit: 200,
          channelLimit: 1,
          channelCeiling: 2,
          seatLimit: 3,
          activeChannels: 1,
          activeSeats: 2,
          daysRemaining: 15,
        );
  }

  @override
  Future<List<PricingPlan>> listPlans() async {
    if (shouldThrowError) throw Exception('Failed to load plans');
    return mockPlans ?? PricingPlan.canonicalPlans;
  }

  @override
  Future<String> createSubscriptionRequest(
    String businessId, {
    required PricingPlan plan,
    String? contactPhone,
    String? notes,
    String? idempotencyKey,
  }) async {
    if (shouldThrowError) throw Exception('Failed to create subscription');
    lastCreatedSubscriptionId = 'sub-new-req-${plan.code}';
    return lastCreatedSubscriptionId!;
  }

  @override
  Future<PaymentView> submitManualPayment(
    String subscriptionId,
    ManualPaymentProofRequest request, {
    String? idempotencyKey,
  }) async {
    if (shouldThrowError) throw Exception('Failed to record payment');
    lastPaymentRequest = request;
    final payment = PaymentView(
      id: 'pay-confirmed-1',
      subscriptionId: subscriptionId,
      businessId: request.businessId,
      amountYer: request.amountYer,
      method: request.method,
      reference: request.reference,
      paidAt: request.paidAt,
      recordedBy: 'user-prn',
      createdAt: DateTime.now().toIso8601String(),
    );
    mockPayments.add(payment);
    return payment;
  }

  @override
  Future<List<PaymentView>> listPayments(String subscriptionId) async {
    return mockPayments;
  }
}

Widget createTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ar'), Locale('en')],
    locale: const Locale('ar'),
    home: child,
  );
}

void main() {
  const testBusinessId = 'biz-alufuq-1';

  final activeGrowthSubscription = const MerchantSubscriptionView(
    hasSubscription: true,
    id: 'sub-active-123',
    businessId: testBusinessId,
    planCode: 'growth',
    planName: 'نمو (Growth)',
    status: 'ACTIVE',
    priceYerSnapshot: 10000,
    aiReplyLimit: 500,
    aiRepliesUsed: 150,
    aiRepliesRemaining: 350,
    aiCatalogLimit: 200,
    channelLimit: 1,
    channelCeiling: 2,
    seatLimit: 3,
    activeChannels: 1,
    activeSeats: 2,
    daysRemaining: 15,
  );

  group('SubscriptionQuotaCard Widget Tests', () {
    testWidgets(
      'renders active subscription details and 4 quota meters correctly',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            Scaffold(
              body: SubscriptionQuotaCard(
                subscription: activeGrowthSubscription,
                onUpgradeOrRenew: () {},
              ),
            ),
          ),
        );

        // Verify Header
        expect(find.text('نمو (Growth)'), findsOneWidget);
        expect(find.text('نشط'), findsOneWidget);
        expect(find.text('15 يوم متبقٍ'), findsOneWidget);
        expect(find.text('10,000 ر.ي / شهر'), findsOneWidget);

        // Verify AI Replies meter
        expect(find.text('ردود الذكاء الاصطناعي (AI Replies)'), findsOneWidget);
        expect(find.text('150 / 500 رد'), findsOneWidget);
        expect(find.text('30%'), findsOneWidget);

        // Verify Catalog Items meter
        expect(find.text('منتجات الكتالوج'), findsOneWidget);
        expect(find.text('200'), findsOneWidget);

        // Verify Connected Channels meter
        expect(find.text('القنوات المتصلة'), findsOneWidget);
        expect(find.text('1 / 2'), findsOneWidget);

        // Verify Team Seats meter
        expect(find.text('مقاعد الفريق'), findsOneWidget);
        expect(find.text('2 / 3'), findsOneWidget);

        // Verify upgrade button
        expect(find.text('ترقية الباقة'), findsOneWidget);
      },
    );

    testWidgets(
      'renders empty state when merchant has no active subscription',
      (tester) async {
        bool upgradeClicked = false;
        const noSub = MerchantSubscriptionView(
          hasSubscription: false,
          businessId: testBusinessId,
        );

        await tester.pumpWidget(
          createTestApp(
            Scaffold(
              body: SubscriptionQuotaCard(
                subscription: noSub,
                onUpgradeOrRenew: () {
                  upgradeClicked = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('لا يوجد اشتراك نشط'), findsOneWidget);
        expect(find.text('تجديد / تفعيل'), findsOneWidget);

        await tester.tap(find.text('تجديد / تفعيل'));
        await tester.pump();
        expect(upgradeClicked, isTrue);
      },
    );

    testWidgets('renders loading state when isLoading is true', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: SubscriptionQuotaCard(subscription: null, isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state and retries on button press', (
      tester,
    ) async {
      bool retried = false;
      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: SubscriptionQuotaCard(
              subscription: null,
              error: 'تعذر الاتصال بالخادم',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('SubscriptionPlansScreen Widget Tests', () {
    testWidgets('renders all commercial tiers with prices and badges', (
      tester,
    ) async {
      final fakeRepo = FakeSubscriptionRepository(
        mockSubscription: activeGrowthSubscription,
      );
      final provider = SubscriptionProvider(repository: fakeRepo);
      await provider.loadPlans();
      await provider.loadSubscription(testBusinessId);

      await tester.pumpWidget(
        createTestApp(
          SubscriptionPlansScreen(
            businessId: testBusinessId,
            provider: provider,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Title
      expect(find.text('باقات واشتراكات مجيب'), findsOneWidget);

      // Check canonical tier names from Mujeeb_24_Pricing_Contract_v2.0.md
      expect(find.text('بداية'), findsOneWidget);
      expect(find.text('متجر'), findsOneWidget);

      // Scroll to and verify Growth
      await tester.dragUntilVisible(
        find.text('نمو'),
        find.byType(ListView),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      expect(find.text('نمو'), findsOneWidget);

      // Check "باقتك الحالية" badge on Growth
      expect(find.text('باقتك الحالية'), findsWidgets);

      // Scroll to and verify Pro
      await tester.dragUntilVisible(
        find.text('احتراف'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(find.text('احتراف'), findsOneWidget);

      // Scroll to and verify Business
      await tester.dragUntilVisible(
        find.text('أعمال'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(find.text('أعمال'), findsOneWidget);

      // Scroll to and verify Enterprise
      await tester.dragUntilVisible(
        find.text('مؤسسات / وكالات'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(find.text('مؤسسات / وكالات'), findsOneWidget);
    });

    testWidgets(
      'tapping Enterprise contact button opens sales contact dialog',
      (tester) async {
        final fakeRepo = FakeSubscriptionRepository(
          mockSubscription: activeGrowthSubscription,
        );
        final provider = SubscriptionProvider(repository: fakeRepo);
        await provider.loadPlans();
        await provider.loadSubscription(testBusinessId);

        await tester.pumpWidget(
          createTestApp(
            SubscriptionPlansScreen(
              businessId: testBusinessId,
              provider: provider,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final enterpriseBtn = find.widgetWithText(
          FilledButton,
          'تواصل مع المبيعات',
        );
        await tester.dragUntilVisible(
          enterpriseBtn,
          find.byType(ListView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        await tester.tap(enterpriseBtn);
        await tester.pumpAndSettle();

        // Verify contact dialog appears
        expect(find.text('باقة المؤسسات والوكالات'), findsOneWidget);
        expect(find.text('حسناً'), findsOneWidget);
      },
    );

    testWidgets('selecting a plan triggers confirmation sheet', (tester) async {
      final fakeRepo = FakeSubscriptionRepository(
        mockSubscription: activeGrowthSubscription,
      );
      final provider = SubscriptionProvider(repository: fakeRepo);
      await provider.loadPlans();
      await provider.loadSubscription(testBusinessId);

      await tester.pumpWidget(
        createTestApp(
          SubscriptionPlansScreen(
            businessId: testBusinessId,
            provider: provider,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final proBtn = find.byKey(const ValueKey('plan_button_pro'));
      await tester.dragUntilVisible(
        proBtn,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      await tester.tap(proBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('طلب باقة احتراف'), findsOneWidget);
      expect(find.text('تأكيد واختيار الباقة'), findsOneWidget);
    });
  });

  group('ManualPaymentDialog Widget Tests', () {
    testWidgets(
      'renders payment methods, validates empty reference, and accepts input',
      (tester) async {
        final fakeRepo = FakeSubscriptionRepository();
        final provider = SubscriptionProvider(repository: fakeRepo);
        final targetPlan = PricingPlan.canonicalPlans.firstWhere(
          (p) => p.code == 'growth',
        );

        await tester.pumpWidget(
          createTestApp(
            Scaffold(
              body: ManualPaymentDialog(
                plan: targetPlan,
                subscriptionId: 'sub-test-123',
                businessId: testBusinessId,
                provider: provider,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check UI elements
        expect(find.text('تسجيل بيانات الدفع اليدوي'), findsOneWidget);
        expect(find.text('10000 ر.ي شهرياً'), findsOneWidget);
        expect(find.text('طريقة الدفع المعتمدة *'), findsOneWidget);

        // Check payment methods are rendered
        expect(find.text('تحويل بنكي'), findsOneWidget);
        expect(find.text('محفظة إلكترونية'), findsOneWidget);
        expect(find.text('نقداً'), findsOneWidget);

        // Scroll to submit button and tap with empty reference
        final submitButton = find.text('إرسال إثبات الدفع');
        await tester.dragUntilVisible(
          submitButton,
          find.byType(SingleChildScrollView),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(find.text('يرجى إدخال رقم مرجع التحويل'), findsOneWidget);

        // Enter reference number
        final referenceField = find.byType(TextFormField).first;
        await tester.enterText(referenceField, 'REF-TEST-998877');
        await tester.pumpAndSettle();

        // Submit again
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Verify repository received the call
        expect(fakeRepo.lastPaymentRequest, isNotNull);
        expect(
          fakeRepo.lastPaymentRequest!.reference,
          equals('REF-TEST-998877'),
        );
        expect(fakeRepo.lastPaymentRequest!.amountYer, equals(10000));
        expect(
          fakeRepo.lastPaymentRequest!.subscriptionId,
          equals('sub-test-123'),
        );
      },
    );
  });

  group('SubscriptionScreen Widget Tests', () {
    testWidgets('renders quota card, action buttons, and handles navigation', (
      tester,
    ) async {
      final fakeRepo = FakeSubscriptionRepository(
        mockSubscription: activeGrowthSubscription,
      );
      final provider = SubscriptionProvider(repository: fakeRepo);
      await provider.loadSubscription(testBusinessId);

      await tester.pumpWidget(
        createTestApp(
          SubscriptionScreen(businessId: testBusinessId, provider: provider),
        ),
      );

      await tester.pumpAndSettle();

      // Check AppBar title
      expect(find.text('إدارة الاشتراك والحصص'), findsOneWidget);

      // Check SubscriptionQuotaCard is embedded
      expect(find.text('نمو (Growth)'), findsOneWidget);

      // Check Compare Plans tile
      expect(find.text('استعراض ومقارنة الباقات'), findsOneWidget);

      // Tap 'استعراض ومقارنة الباقات'
      await tester.tap(find.text('استعراض ومقارنة الباقات'));
      await tester.pumpAndSettle();

      // Verify navigated to SubscriptionPlansScreen
      expect(find.text('باقات واشتراكات مجيب'), findsOneWidget);
    });

    testWidgets(
      'renders pending payment banner when subscription status is PENDING',
      (tester) async {
        const pendingSub = MerchantSubscriptionView(
          hasSubscription: true,
          id: 'sub-pending-456',
          businessId: testBusinessId,
          planCode: 'basic',
          planName: 'متجر (Basic)',
          status: 'PENDING',
          priceYerSnapshot: 6500,
          amountDueYer: 6500,
          aiReplyLimit: 200,
          aiRepliesUsed: 0,
          aiRepliesRemaining: 200,
        );

        final fakeRepo = FakeSubscriptionRepository(
          mockSubscription: pendingSub,
        );
        final provider = SubscriptionProvider(repository: fakeRepo);
        await provider.loadSubscription(testBusinessId);

        await tester.pumpWidget(
          createTestApp(
            SubscriptionScreen(businessId: testBusinessId, provider: provider),
          ),
        );

        await tester.pumpAndSettle();

        // Verify pending status and notice banner
        expect(find.text('قيد المراجعة'), findsWidgets);
        expect(
          find.text('اشتراكك حالياً قيد المراجعة في انتظار تأكيد السداد'),
          findsOneWidget,
        );
        expect(find.text('تسجيل إشعار الدفع'), findsOneWidget);
      },
    );
  });
}
