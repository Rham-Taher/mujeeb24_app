import 'package:mujeeb24_app/core/api/api_client.dart';
import 'package:mujeeb24_app/core/models/platform_models.dart';
import 'package:mujeeb24_app/core/models/subscription_models.dart';

/// Subscription Repository handling:
/// - Merchant subscription projection (GET /businesses/{business_id}/subscription)
/// - Pricing plans catalog matching Mujeeb_24_Pricing_Contract_v2.0.md
/// - Subscription creation request (POST /platform/businesses/{business_id}/subscriptions)
/// - Manual payment recording (POST /platform/subscriptions/{subscription_id}/payments)
/// - Payment history (GET /platform/subscriptions/{subscription_id}/payments)
class SubscriptionRepository {
  final ApiClient apiClient;

  SubscriptionRepository({required this.apiClient});

  /// `GET /businesses/{business_id}/subscription`
  /// Retrieves active subscription details and quota projections.
  Future<MerchantSubscriptionView> getSubscription(String businessId) async {
    final response = await apiClient.get(
      '/businesses/$businessId/subscription',
      requiresAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    return MerchantSubscriptionView.fromJson(data);
  }

  /// Retrieves list of plans.
  /// Queries backend `/platform/plans` when available, falling back safely to canonical plans.
  Future<List<PricingPlan>> listPlans() async {
    try {
      final response = await apiClient.get(
        '/platform/plans',
        queryParameters: {'status': 'ACTIVE', 'limit': '20'},
        requiresAuth: true,
      );
      if (response is Map<String, dynamic> && response['data'] is List) {
        final rawList = response['data'] as List;
        if (rawList.isNotEmpty) {
          final fetched = rawList
              .map((e) => PricingPlan.fromJson(e as Map<String, dynamic>))
              .toList();

          // Ensure Enterprise option is included at the end
          if (!fetched.any((p) => p.isCustom)) {
            fetched.add(PricingPlan.canonicalPlans.last);
          }
          return fetched;
        }
      }
    } catch (_) {
      // Gracefully fall back to the canonical plans contract if /platform/plans is restricted or unreachable
    }
    return PricingPlan.canonicalPlans;
  }

  /// Creates a subscription request in `PENDING` state on the backend.
  /// Uses `POST /platform/businesses/{business_id}/subscriptions` or support billing ticket.
  Future<String> createSubscriptionRequest(
    String businessId, {
    required PricingPlan plan,
    String? contactPhone,
    String? notes,
    String? idempotencyKey,
  }) async {
    final key =
        idempotencyKey ??
        'sub_req_${DateTime.now().millisecondsSinceEpoch}_${businessId.hashCode}';

    // 1. Attempt direct platform subscription creation if plan has a UUID ID
    if (plan.id.length >= 30) {
      try {
        final response = await apiClient.post(
          '/platform/businesses/$businessId/subscriptions',
          body: {'plan_id': plan.id},
          headers: {'Idempotency-Key': key},
          requiresAuth: true,
        );
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null && data['id'] != null) {
          return data['id'] as String;
        }
      } catch (_) {
        // Fall back to billing ticket creation if platform admin is not authorized
      }
    }

    // 2. Create support billing ticket
    try {
      final ticketRes = await apiClient.post(
        '/platform/businesses/$businessId/support/tickets',
        body: {
          'subject': '[طلب اشتراك] باقة ${plan.nameAr} (${plan.nameEn})',
          'priority': 'HIGH',
          'category': 'BILLING',
        },
        headers: {'Idempotency-Key': key},
        requiresAuth: true,
      );
      final ticketData = ticketRes['data'] as Map<String, dynamic>?;
      final ticketId =
          ticketData?['id'] as String? ??
          'req_${DateTime.now().millisecondsSinceEpoch}';

      // Append detailed message
      final msgLines = [
        'طلب اشتراك جديد:',
        'الباقة المطلوبة: ${plan.nameAr} (${plan.code})',
        'السعر: ${plan.priceYer} ر.ي / شهر',
        if (contactPhone != null && contactPhone.isNotEmpty)
          'رقم التواصل: $contactPhone',
        if (notes != null && notes.isNotEmpty) 'ملاحظات: $notes',
      ];

      await apiClient.post(
        '/platform/support/tickets/$ticketId/messages',
        body: {'body': msgLines.join('\n')},
        requiresAuth: true,
      );

      return ticketId;
    } catch (e) {
      // Re-throw meaningful error
      rethrow;
    }
  }

  /// `POST /platform/subscriptions/{subscription_id}/payments`
  /// Records a manual payment and sends it to the backend for verification/activation.
  Future<PaymentView> submitManualPayment(
    String subscriptionId,
    ManualPaymentProofRequest request, {
    String? idempotencyKey,
  }) async {
    final key =
        idempotencyKey ??
        'pay_${DateTime.now().millisecondsSinceEpoch}_${subscriptionId.hashCode}';

    final response = await apiClient.post(
      '/platform/subscriptions/$subscriptionId/payments',
      body: request.toJson(),
      headers: {'Idempotency-Key': key},
      requiresAuth: true,
    );

    final data = response['data'] as Map<String, dynamic>;
    return PaymentView.fromJson(data);
  }

  /// `GET /platform/subscriptions/{subscription_id}/payments`
  /// Lists payment records for a subscription.
  Future<List<PaymentView>> listPayments(String subscriptionId) async {
    try {
      final response = await apiClient.get(
        '/platform/subscriptions/$subscriptionId/payments',
        requiresAuth: true,
      );
      if (response is Map<String, dynamic> && response['data'] is List) {
        final list = response['data'] as List;
        return list
            .map((e) => PaymentView.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Return empty if not accessible
    }
    return [];
  }
}
