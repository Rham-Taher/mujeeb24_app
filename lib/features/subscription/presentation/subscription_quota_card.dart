import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/subscription_models.dart';

/// Professional Subscription and Quota Metering Card.
/// Can be rendered in Merchant Dashboard or Settings.
class SubscriptionQuotaCard extends StatelessWidget {
  final MerchantSubscriptionView? subscription;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onUpgradeOrRenew;

  const SubscriptionQuotaCard({
    super.key,
    required this.subscription,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onUpgradeOrRenew,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && subscription == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderHairline),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    if (error != null && subscription == null) {
      return Card(
        elevation: 0,
        color: AppColors.statusErrorContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.statusError.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.statusError,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error!,
                  style: const TextStyle(
                    color: AppColors.statusError,
                    fontSize: 13,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text('إعادة المحاولة'),
                ),
            ],
          ),
        ),
      );
    }

    final sub = subscription;
    final hasSub = sub != null && sub.hasSubscription;

    return Card(
      elevation: 0,
      color: AppColors.surfaceCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borderHairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Plan Name, Status Badge, and Upgrade/Renew button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              hasSub
                                  ? (sub.planName ??
                                        sub.planCode ??
                                        'الاشتراك التجاري')
                                  : 'لا يوجد اشتراك نشط',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hasSub) _buildStatusBadge(sub),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasSub
                            ? '${_formatPrice(sub.priceYerSnapshot ?? sub.amountDueYer ?? 0)} ر.ي / شهر'
                            : 'اشترك الآن للاستفادة من الرد الآلي وقنوات البيع',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onUpgradeOrRenew != null)
                  FilledButton.tonal(
                    onPressed: onUpgradeOrRenew,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      hasSub && sub.isActive ? 'ترقية الباقة' : 'تجديد / تفعيل',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            if (hasSub) ...[
              const Divider(height: 24),

              // Period & Days Remaining Details
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCanvas.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'نهاية الفترة: ${_formatDate(sub.periodEnd)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.timelapse_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${sub.daysRemaining ?? 0} يوم متبقٍ',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Section Title
              const Text(
                'استهلاك الموارد والحصص المخصصة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // AI Replies Meter
              _buildProgressMeter(
                title: 'ردود الذكاء الاصطناعي (AI Replies)',
                used: sub.aiRepliesUsed ?? 0,
                limit: sub.aiReplyLimit ?? 0,
                remaining: sub.aiRepliesRemaining,
                unit: 'رد',
                icon: Icons.smart_toy_outlined,
              ),

              const SizedBox(height: 14),

              // 3-columns Quota Tiles (Catalog Products, Channels, Team Seats)
              Row(
                children: [
                  Expanded(
                    child: _buildQuotaItem(
                      title: 'منتجات الكتالوج',
                      value: '${sub.aiCatalogLimit ?? 0}',
                      subtitle: 'منتج مدعوم بالـAI',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuotaItem(
                      title: 'القنوات المتصلة',
                      value:
                          '${sub.activeChannels} / ${sub.channelCeiling ?? sub.channelLimit ?? 1}',
                      subtitle: 'قناة نشطة (السقف)',
                      icon: Icons.hub_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuotaItem(
                      title: 'مقاعد الفريق',
                      value: '${sub.activeSeats} / ${sub.seatLimit ?? 1}',
                      subtitle: 'عضو نشط',
                      icon: Icons.group_outlined,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusWarningContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.statusWarning.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.statusWarning,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'لا يتوفر حالياً اشتراك نشط لهذا المتجر. يمكنك ترقية الباقة لربط القنوات وتفعيل الردود الآلية.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.statusWarning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MerchantSubscriptionView sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: sub.statusBadgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: sub.statusBadgeColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        sub.localizedStatus,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: sub.statusBadgeColor,
        ),
      ),
    );
  }

  Widget _buildProgressMeter({
    required String title,
    required int used,
    required int limit,
    int? remaining,
    required String unit,
    required IconData icon,
  }) {
    final ratio = limit > 0 ? (used / limit.toDouble()).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).toInt();
    final color = MerchantSubscriptionView.getQuotaColor(ratio);
    final isFull = ratio >= 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: AppColors.borderHairline,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$used / $limit $unit',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isFull
                    ? 'اكتملت الحصة 100%'
                    : '${remaining ?? (limit - used)} $unit متبقٍ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isFull ? FontWeight.bold : FontWeight.normal,
                  color: isFull ? AppColors.statusError : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaItem({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatPrice(int amount) {
    if (amount <= 0) return '0';
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
