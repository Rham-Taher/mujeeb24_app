import 'package:flutter/foundation.dart';
import 'package:mujeeb24_app/core/errors/api_error.dart';
import 'package:mujeeb24_app/core/models/platform_models.dart';
import 'package:mujeeb24_app/core/models/subscription_models.dart';
import 'package:mujeeb24_app/core/subscription/subscription_repository.dart';

/// State Management provider for Merchant Subscriptions, Quota projections,
/// Plans catalog, and Manual Payment submissions.
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionRepository repository;

  MerchantSubscriptionView? _subscription;
  List<PricingPlan> _plans = PricingPlan.canonicalPlans;
  List<PaymentView> _payments = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _lastRequestId;
  String? _submissionSuccessMessage;
  String? _lastRequestedId;

  SubscriptionProvider({required this.repository});

  MerchantSubscriptionView? get subscription => _subscription;
  List<PricingPlan> get plans => _plans;
  List<PaymentView> get payments => _payments;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get lastRequestId => _lastRequestId;
  String? get submissionSuccessMessage => _submissionSuccessMessage;
  String? get lastRequestedId => _lastRequestedId;

  /// Loads current business subscription.
  Future<void> loadSubscription(
    String businessId, {
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _subscription = await repository.getSubscription(businessId);
      _error = null;
      if (_subscription?.id != null && _subscription!.id!.isNotEmpty) {
        _loadPaymentsInternal(_subscription!.id!);
      }
    } on ApiErrorEnvelope catch (e) {
      _error = e.error.message;
      _lastRequestId = e.requestId;
    } on NetworkException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads available pricing plans.
  Future<void> loadPlans() async {
    try {
      final fetched = await repository.listPlans();
      if (fetched.isNotEmpty) {
        _plans = fetched;
        notifyListeners();
      }
    } catch (_) {
      // Retain canonical plans
    }
  }

  /// Submits a request to subscribe to or upgrade to a chosen plan.
  Future<bool> requestSubscription(
    String businessId,
    PricingPlan plan, {
    String? contactPhone,
    String? notes,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _error = null;
    _submissionSuccessMessage = null;
    notifyListeners();

    try {
      final requestId = await repository.createSubscriptionRequest(
        businessId,
        plan: plan,
        contactPhone: contactPhone,
        notes: notes,
      );

      _lastRequestedId = requestId;
      _submissionSuccessMessage =
          'تم تقديم طلب اشتراك باقة ${plan.nameAr} بنجاح. رقم الطلب: $requestId';

      // Reload subscription snapshot
      await loadSubscription(businessId, refresh: true);
      return true;
    } on ApiErrorEnvelope catch (e) {
      _error = e.error.message;
      _lastRequestId = e.requestId;
      return false;
    } on NetworkException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Sends manual payment verification reference to backend.
  Future<bool> submitManualPayment(
    String subscriptionId,
    ManualPaymentProofRequest request,
  ) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _error = null;
    _submissionSuccessMessage = null;
    notifyListeners();

    try {
      final payment = await repository.submitManualPayment(
        subscriptionId,
        request,
      );

      _payments.insert(0, payment);
      _submissionSuccessMessage =
          'تم إرسال إثبات الدفع بنجاح برقم مرجع: ${payment.reference}. الاشتراك قيد المراجعة لدى الإدارة.';

      // Reload current subscription from server to see if activated or pending
      await loadSubscription(request.businessId, refresh: true);
      return true;
    } on ApiErrorEnvelope catch (e) {
      _error = e.error.message;
      _lastRequestId = e.requestId;
      return false;
    } on NetworkException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> _loadPaymentsInternal(String subscriptionId) async {
    try {
      final list = await repository.listPayments(subscriptionId);
      _payments = list;
    } catch (_) {
      // Non-fatal
    }
  }

  void clearMessages() {
    _error = null;
    _submissionSuccessMessage = null;
    notifyListeners();
  }
}
