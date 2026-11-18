import 'package:flutter/material.dart';
import 'package:mujeeb24_app/core/widgets/common_ui_widgets.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/subscription_models.dart';
import 'package:mujeeb24_app/features/subscription/presentation/manual_payment_dialog.dart';
import 'package:mujeeb24_app/features/subscription/providers/subscription_provider.dart';

/// Full screen comparing all commercial subscription tiers.
class SubscriptionPlansScreen extends StatefulWidget {
  final String businessId;
  final SubscriptionProvider provider;

  const SubscriptionPlansScreen({
    super.key,
    required this.businessId,
    required this.provider,
  });

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.provider.loadPlans();
      widget.provider.loadSubscription(widget.businessId);
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

  void _onSelectPlan(PricingPlan plan) async {
    if (plan.isCustom) {
      _showEnterpriseContactDialog();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('طلب باقة ${plan.nameAr}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أنت على وشك طلب الاشتراك في باقة ${plan.nameAr} (${plan.nameEn}).',
            ),
            const SizedBox(height: 10),
            Text(
              'السعر: ${_formatPrice(plan.priceYer)} ر.ي شهرياً',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'بعد تأكيد الطلب، يمكنك إرسال رقم مرجع الحوالة لمراجعتها واعتماد تفعيل الباقة.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تأكيد واختيار الباقة'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Send subscription creation intent to backend
    final success = await widget.provider.requestSubscription(
      widget.businessId,
      plan,
    );

    if (!mounted) return;

    if (success) {
      final subId =
          widget.provider.subscription?.id ??
          widget.provider.lastRequestedId ??
          '';

      // Open Manual Payment dialog so merchant can submit transfer reference
      ManualPaymentDialog.show(
        context,
        plan: plan,
        subscriptionId: subId,
        businessId: widget.businessId,
        provider: widget.provider,
        onSuccess: () {
          widget.provider.loadSubscription(widget.businessId, refresh: true);
        },
      );
    } else {
      showAppAlertDialog(
        context,
        message: widget.provider.error ?? 'تعذر تقديم طلب الاشتراك',
        isError: true,
      );
    }
  }

  void _showEnterpriseContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('باقة المؤسسات والوكالات'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'باقة المؤسسات مصممة للشركات ذات السعة العالية وحجم المحادثات الكبير مع دعم فني مخصص.',
            ),
            SizedBox(height: 12),
            Text(
              'يرجى التواصل مع فريق المبيعات والحلول المؤسسية لتحديد السعة والتسعير المخصص وفق احتياجكم.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final currentSub = provider.subscription;
    final currentCode = currentSub?.planCode?.toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('باقات واشتراكات مجيب'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            provider.loadPlans(),
            provider.loadSubscription(widget.businessId, refresh: true),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Informative Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر الباقة المناسبة لحجم نشاطك التجاري',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'جميع الأسعار معتمدة بالريال اليمني شهرياً وتشمل الردود الذكية وتكامل القنوات.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (provider.error != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusErrorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.statusError,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error!,
                        style: const TextStyle(
                          color: AppColors.statusError,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // List of Plan Cards
            ...provider.plans.map((plan) {
              final isCurrent = currentCode == plan.code.toLowerCase();
              return _buildPlanCard(plan, isCurrent);
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(PricingPlan plan, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: plan.isPopular
              ? AppColors.primary
              : isCurrent
              ? AppColors.statusSuccess
              : AppColors.borderHairline,
          width: plan.isPopular || isCurrent ? 2.0 : 1.0,
        ),
        boxShadow: plan.isPopular ? AppShadows.elevated : AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badges row
          if (plan.isPopular || isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.statusSuccess : AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCurrent ? Icons.check_circle_rounded : Icons.star_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCurrent ? 'باقتك الحالية' : 'الباقة الأكثر طلباً',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Plan Name and Price Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.nameAr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          plan.nameEn,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.isCustom
                              ? 'عرض مخصص'
                              : '${_formatPrice(plan.priceYer)} ر.ي',
                          style: TextStyle(
                            fontSize: plan.isCustom ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (!plan.isCustom)
                          const Text(
                            '/ شهرياً',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  plan.descriptionAr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const Divider(height: 24),

                // Features & Entitlements
                if (!plan.isCustom) ...[
                  _buildFeatureRow(
                    Icons.smart_toy_rounded,
                    '${_formatPrice(plan.aiReplyLimit)} رد ذكاء اصطناعي نهائي',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureRow(
                    Icons.inventory_2_rounded,
                    'حتى ${_formatPrice(plan.aiCatalogLimit)} منتج نشط مدعوم بالـAI',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureRow(
                    Icons.hub_rounded,
                    '${plan.includedChannels} قناة مشمولة (سقف الباقة: ${plan.channelCeiling} قنوات)',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureRow(
                    Icons.group_rounded,
                    '${plan.seatLimit} ${plan.seatLimit == 1 ? "مقعد موظف" : "مقاعد فريق"}',
                  ),
                ] else ...[
                  _buildFeatureRow(
                    Icons.all_inclusive_rounded,
                    'ردود ومنتجات غير محدودة وفق العقد',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureRow(
                    Icons.hub_rounded,
                    'قنوات متعددة وسعة مخصصة',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureRow(
                    Icons.support_agent_rounded,
                    'مدير حساب ودعم فني على مدار الساعة',
                  ),
                ],

                const SizedBox(height: 18),

                // Action Button
                FilledButton(
                  key: ValueKey('plan_button_${plan.code}'),
                  onPressed: widget.provider.isSubmitting
                      ? null
                      : () => _onSelectPlan(plan),
                  style: FilledButton.styleFrom(
                    backgroundColor: isCurrent
                        ? AppColors.surfaceCanvas
                        : plan.isPopular
                        ? AppColors.primary
                        : null,
                    foregroundColor: isCurrent ? AppColors.onSurface : null,
                    side: isCurrent
                        ? const BorderSide(color: AppColors.borderHairline)
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isCurrent
                        ? 'باقتك الحالية'
                        : plan.isCustom
                        ? 'تواصل مع المبيعات'
                        : 'اختيار الباقة',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
          ),
        ),
      ],
    );
  }

  String _formatPrice(int amount) {
    if (amount <= 0) return '0';
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
