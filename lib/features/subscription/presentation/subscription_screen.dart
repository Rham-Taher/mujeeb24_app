import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/subscription_models.dart';
import 'package:mujeeb24_app/features/subscription/presentation/manual_payment_dialog.dart';
import 'package:mujeeb24_app/features/subscription/presentation/subscription_plans_screen.dart';
import 'package:mujeeb24_app/features/subscription/presentation/subscription_quota_card.dart';
import 'package:mujeeb24_app/features/subscription/providers/subscription_provider.dart';

/// Full screen for Subscription Management and Quota monitoring.
class SubscriptionScreen extends StatefulWidget {
  final String businessId;
  final SubscriptionProvider provider;

  const SubscriptionScreen({
    super.key,
    required this.businessId,
    required this.provider,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    await widget.provider.loadSubscription(widget.businessId, refresh: true);
  }

  void _navigateToPlans() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubscriptionPlansScreen(
          businessId: widget.businessId,
          provider: widget.provider,
        ),
      ),
    );
  }

  void _showManualPaymentForPending(MerchantSubscriptionView sub) {
    final plan = widget.provider.plans.firstWhere(
      (p) => p.code.toLowerCase() == (sub.planCode ?? '').toLowerCase(),
      orElse: () => PricingPlan.canonicalPlans.first,
    );

    ManualPaymentDialog.show(
      context,
      plan: plan,
      subscriptionId: sub.id ?? '',
      businessId: widget.businessId,
      provider: widget.provider,
      onSuccess: () => _loadData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final sub = provider.subscription;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الاشتراك والحصص'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quota Card
            SubscriptionQuotaCard(
              subscription: sub,
              isLoading: provider.isLoading,
              error: provider.error,
              onRetry: _loadData,
              onUpgradeOrRenew: _navigateToPlans,
            ),
            const SizedBox(height: 16),

            // Pending Payment Alert Banner
            if (sub != null && sub.isPending) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusWarningContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.statusWarning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          color: AppColors.statusWarning,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'اشتراكك حالياً قيد المراجعة في انتظار تأكيد السداد',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.statusWarning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'إذا قمت بالتحويل، يرجى إرسال رقم الإشعار المرجعي لتقوم الإدارة بمطابقته وتفعيل الباقة فوراً.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.statusWarning,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: () => _showManualPaymentForPending(sub),
                      child: const Text('تسجيل إشعار الدفع'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Compare Plans Button Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.borderHairline),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.view_carousel_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'استعراض ومقارنة الباقات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'مقارنة أسعار ومزايا باقات بداية، متجر، نمو، احتراف، وأعمال',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: _navigateToPlans,
              ),
            ),
            const SizedBox(height: 20),

            // Payment Records Section
            const Text(
              'سجل المدفوعات والتحويلات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            if (provider.payments.isEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCanvas.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: const Center(
                  child: Text(
                    'لا توجد عمليات دفع مسجلة مسبقاً لهذا الاشتراك.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ),
            ] else ...[
              ...provider.payments.map(
                (p) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderHairline),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.statusSuccess,
                    ),
                    title: Text(
                      '${p.amountYer} ر.ي (${p.method})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'مرجع: ${p.reference} • ${p.paidAt.split("T").first}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccess.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'معتمد',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
