import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/models/subscription_models.dart';
import 'package:mujeeb24_app/core/subscription/subscription_repository.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';

void main() {
  group('Subscription Models & Quotas Unit Tests', () {
    test('MerchantSubscriptionView parses active subscription with full quota fields', () {
      final json = {
        'has_subscription': true,
        'id': 'sub-uuid-1234',
        'business_id': 'biz-uuid-5678',
        'plan_id': 'plan-growth-uuid',
        'plan_code': 'growth',
        'plan_name': 'نمو (Growth)',
        'plan_version': 2,
        'status': 'ACTIVE',
        'period_start': '2026-10-01T00:00:00Z',
        'period_end': '2026-11-01T00:00:00Z',
        'price_yer_snapshot': 10000,
        'amount_due_yer': 10000,
        'ai_reply_limit': 500,
        'ai_replies_used': 150,
        'ai_replies_remaining': 350,
        'ai_catalog_limit': 200,
        'channel_limit': 1,
        'channel_ceiling': 2,
        'seat_limit': 3,
        'active_channels': 1,
        'active_seats': 2,
        'days_remaining': 10,
        'activated_at': '2026-10-01T00:00:00Z',
        'created_at': '2026-09-30T12:00:00Z',
      };

      final sub = MerchantSubscriptionView.fromJson(json);

      expect(sub.hasSubscription, isTrue);
      expect(sub.id, equals('sub-uuid-1234'));
      expect(sub.businessId, equals('biz-uuid-5678'));
      expect(sub.planCode, equals('growth'));
      expect(sub.planName, equals('نمو (Growth)'));
      expect(sub.status, equals('ACTIVE'));
      expect(sub.isActive, isTrue);
      expect(sub.isPending, isFalse);
      expect(sub.priceYerSnapshot, equals(10000));
      expect(sub.aiReplyLimit, equals(500));
      expect(sub.aiRepliesUsed, equals(150));
      expect(sub.aiRepliesRemaining, equals(350));
      expect(sub.aiCatalogLimit, equals(200));
      expect(sub.channelCeiling, equals(2));
      expect(sub.seatLimit, equals(3));
      expect(sub.activeChannels, equals(1));
      expect(sub.activeSeats, equals(2));
      expect(sub.daysRemaining, equals(10));
      expect(sub.localizedStatus, equals('نشط'));

      // Progress calculation: 150 / 500 = 0.30 (30%)
      expect(sub.aiRepliesProgress, closeTo(0.30, 0.001));
      // Color transition: < 70% should be green (statusSuccess)
      final color = MerchantSubscriptionView.getQuotaColor(
        sub.aiRepliesProgress,
      );
      expect(color, equals(AppColors.statusSuccess));
    });

    test('MerchantSubscriptionView correctly transitions quota colors at 70% and 90%', () {
      // < 70%: Green
      expect(
        MerchantSubscriptionView.getQuotaColor(0.50),
        equals(AppColors.statusSuccess),
      );
      expect(
        MerchantSubscriptionView.getQuotaColor(0.69),
        equals(AppColors.statusSuccess),
      );

      // 70% to < 90%: Orange
      expect(
        MerchantSubscriptionView.getQuotaColor(0.70),
        equals(AppColors.statusWarning),
      );
      expect(
        MerchantSubscriptionView.getQuotaColor(0.89),
        equals(AppColors.statusWarning),
      );

      // >= 90%: Red
      expect(
        MerchantSubscriptionView.getQuotaColor(0.90),
        equals(AppColors.statusError),
      );
      expect(
        MerchantSubscriptionView.getQuotaColor(1.00),
        equals(AppColors.statusError),
      );
    });

    test(
      'MerchantSubscriptionView handles zero and null limits without errors',
      () {
        const sub = MerchantSubscriptionView(
          hasSubscription: true,
          businessId: 'biz-1',
          aiReplyLimit: 0,
          aiRepliesUsed: 0,
          channelLimit: null,
          seatLimit: 0,
        );

        expect(sub.aiRepliesProgress, equals(0.0));
        expect(sub.channelProgress, equals(0.0));
        expect(sub.seatProgress, equals(0.0));
      },
    );

    test('PricingPlan canonical tiers match Mujeeb_24_Pricing_Contract_v2.0.md exactly', () {
      final plans = PricingPlan.canonicalPlans;
      expect(plans.length, equals(6));

      // Starter
      final starter = plans[0];
      expect(starter.code, equals('starter'));
      expect(starter.nameAr, equals('بداية'));
      expect(starter.priceYer, equals(4000));
      expect(starter.aiReplyLimit, equals(50));
      expect(starter.aiCatalogLimit, equals(20));
      expect(starter.includedChannels, equals(1));
      expect(starter.channelCeiling, equals(1));
      expect(starter.seatLimit, equals(1));
      expect(starter.internalAiCostBudgetYer, equals(500));

      // Basic
      final basic = plans[1];
      expect(basic.code, equals('basic'));
      expect(basic.nameAr, equals('متجر'));
      expect(basic.priceYer, equals(6500));
      expect(basic.aiReplyLimit, equals(200));
      expect(basic.aiCatalogLimit, equals(60));
      expect(basic.seatLimit, equals(2));

      // Growth (Popular)
      final growth = plans[2];
      expect(growth.code, equals('growth'));
      expect(growth.nameAr, equals('نمو'));
      expect(growth.priceYer, equals(10000));
      expect(growth.aiReplyLimit, equals(500));
      expect(growth.aiCatalogLimit, equals(200));
      expect(growth.channelCeiling, equals(2));
      expect(growth.seatLimit, equals(3));
      expect(growth.isPopular, isTrue);

      // Pro
      final pro = plans[3];
      expect(pro.code, equals('pro'));
      expect(pro.nameAr, equals('احتراف'));
      expect(pro.priceYer, equals(16000));
      expect(pro.aiReplyLimit, equals(1200));
      expect(pro.aiCatalogLimit, equals(600));
      expect(pro.channelCeiling, equals(3));
      expect(pro.seatLimit, equals(5));

      // Business
      final business = plans[4];
      expect(business.code, equals('business'));
      expect(business.nameAr, equals('أعمال'));
      expect(business.priceYer, equals(25000));
      expect(business.aiReplyLimit, equals(3000));
      expect(business.aiCatalogLimit, equals(1500));
      expect(business.channelCeiling, equals(5));
      expect(business.seatLimit, equals(10));

      // Enterprise
      final enterprise = plans[5];
      expect(enterprise.code, equals('enterprise'));
      expect(enterprise.isCustom, isTrue);
    });

    test('ManualPaymentMethod contains supported backend enum methods', () {
      final methods = ManualPaymentMethod.supportedMethods;
      final codes = methods.map((m) => m.code).toList();

      expect(codes, contains('BANK_TRANSFER'));
      expect(codes, contains('MOBILE_MONEY'));
      expect(codes, contains('CASH'));
      expect(codes, contains('OTHER'));
    });
  });

  group('SubscriptionRepository Integration with MockClient', () {
    test('getSubscription calls GET /businesses/{business_id}/subscription and parses projection', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(
          request.url.path,
          equals('/api/v1/businesses/biz-test-1/subscription'),
        );
        expect(request.headers['Authorization'], equals('Bearer test_token'));

        final body = {
          'data': {
            'has_subscription': true,
            'id': 'sub-999',
            'business_id': 'biz-test-1',
            'plan_id': 'plan-1',
            'plan_code': 'basic',
            'plan_name': 'متجر',
            'status': 'ACTIVE',
            'price_yer_snapshot': 6500,
            'amount_due_yer': 6500,
            'ai_reply_limit': 200,
            'ai_replies_used': 45,
            'ai_replies_remaining': 155,
            'ai_catalog_limit': 60,
            'channel_limit': 1,
            'channel_ceiling': 1,
            'seat_limit': 2,
            'active_channels': 1,
            'active_seats': 1,
            'days_remaining': 20,
          },
        };

        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.mujeeb24.com/api/v1',
        client: mockClient,
      );
      apiClient.setAccessToken('test_token');

      final repo = SubscriptionRepository(apiClient: apiClient);
      final sub = await repo.getSubscription('biz-test-1');

      expect(sub.hasSubscription, isTrue);
      expect(sub.id, equals('sub-999'));
      expect(sub.planCode, equals('basic'));
      expect(sub.aiReplyLimit, equals(200));
      expect(sub.aiRepliesUsed, equals(45));
      expect(sub.aiRepliesRemaining, equals(155));
    });

    test('getSubscription returns hasSubscription=false when store has no subscription', () async {
      final mockClient = MockClient((request) async {
        final body = {
          'data': {
            'has_subscription': false,
            'business_id': 'biz-new',
            'active_channels': 0,
            'active_seats': 1,
          },
        };
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.mujeeb24.com/api/v1',
        client: mockClient,
      );
      final repo = SubscriptionRepository(apiClient: apiClient);
      final sub = await repo.getSubscription('biz-new');

      expect(sub.hasSubscription, isFalse);
      expect(sub.isActive, isFalse);
    });

    test('submitManualPayment calls POST /platform/subscriptions/{id}/payments with Idempotency-Key', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(
          request.url.path,
          equals('/api/v1/platform/subscriptions/sub-123/payments'),
        );
        expect(request.headers.containsKey('Idempotency-Key'), isTrue);

        final reqBody = jsonDecode(request.body) as Map<String, dynamic>;
        expect(reqBody['amount_yer'], equals(10000));
        expect(reqBody['method'], equals('BANK_TRANSFER'));
        expect(reqBody['reference'], equals('REF-987654321'));

        final responseBody = {
          'data': {
            'id': 'pay-555',
            'subscription_id': 'sub-123',
            'business_id': 'biz-1',
            'amount_yer': 10000,
            'method': 'BANK_TRANSFER',
            'reference': 'REF-987654321',
            'paid_at': '2026-10-24T12:00:00Z',
            'recorded_by': 'admin-1',
            'created_at': '2026-10-24T12:00:00Z',
          },
        };

        return http.Response(
          jsonEncode(responseBody),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'https://api.mujeeb24.com/api/v1',
        client: mockClient,
      );
      final repo = SubscriptionRepository(apiClient: apiClient);

      final payment = await repo.submitManualPayment(
        'sub-123',
        const ManualPaymentProofRequest(
          subscriptionId: 'sub-123',
          businessId: 'biz-1',
          amountYer: 10000,
          method: 'BANK_TRANSFER',
          reference: 'REF-987654321',
          paidAt: '2026-10-24T12:00:00Z',
        ),
      );

      expect(payment.id, equals('pay-555'));
      expect(payment.subscriptionId, equals('sub-123'));
      expect(payment.amountYer, equals(10000));
      expect(payment.reference, equals('REF-987654321'));
    });
  });
}
