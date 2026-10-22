import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/channels/channel_presentation.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

class DashboardTab extends StatefulWidget {
  final MerchantProvider merchantProvider;
  final Business? currentBusiness;
  final VoidCallback onNavigateToInbox;
  final VoidCallback? onNavigateToCustomers;
  final VoidCallback? onNavigateToLeads;
  final VoidCallback? onNavigateToTransactions;
  final VoidCallback? onNavigateToReviews;
  final VoidCallback? onNavigateToCatalogs;
  final VoidCallback? onNavigateToChannels;
  final VoidCallback? onNavigateToTeam;
  final VoidCallback? onNavigateToAuditLogs;
  final VoidCallback? onSessionExpired;

  const DashboardTab({
    super.key,
    required this.merchantProvider,
    required this.currentBusiness,
    required this.onNavigateToInbox,
    this.onNavigateToCustomers,
    this.onNavigateToLeads,
    this.onNavigateToTransactions,
    this.onNavigateToReviews,
    this.onNavigateToCatalogs,
    this.onNavigateToChannels,
    this.onNavigateToTeam,
    this.onNavigateToAuditLogs,
    this.onSessionExpired,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    widget.merchantProvider.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    widget.merchantProvider.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _loadData() {
    final businessId = widget.currentBusiness?.id;
    if (businessId != null && businessId.isNotEmpty) {
      widget.merchantProvider.loadDashboardOverview(businessId);
    }
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final provider = widget.merchantProvider;
    final overview = provider.dashboardOverview;
    final business = widget.currentBusiness;

    if (overview == null) {
      return RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeBanner(business, strings),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: AppColors.surfaceCanvas,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.borderHairline),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 28),
                child: Column(
                  children: [
                    Icon(
                      provider.dashboardRequiresLogin
                          ? Icons.lock_outline_rounded
                          : provider.isLoadingDashboard
                              ? Icons.sync_rounded
                              : Icons.cloud_off_outlined,
                      size: 40,
                      color: provider.dashboardRequiresLogin
                          ? AppColors.statusWarning : AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.dashboardRequiresLogin
                          ? 'يلزم تسجيل الدخول'
                          : provider.isLoadingDashboard
                              ? 'جاري تحميل بيانات نشاطك'
                              : 'تعذر تحديث لوحة النشاط',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.dashboardError ??
                          'سيتم عرض مؤشرات الأداء بعد استلام البيانات من الخادم.',
                      style: const TextStyle(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    if (provider.isLoadingDashboard) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ] else ...[
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: provider.dashboardRequiresLogin
                            ? widget.onSessionExpired
                            : _loadData,
                        icon: Icon(provider.dashboardRequiresLogin
                            ? Icons.login_rounded : Icons.refresh_rounded),
                        label: Text(provider.dashboardRequiresLogin
                            ? 'تسجيل الدخول من جديد'
                            : 'إعادة المحاولة'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Business Welcome Banner
            _buildWelcomeBanner(business, strings),
            const SizedBox(height: 12),

            // Error display if any
            if (provider.dashboardError != null) ...[
              _buildErrorCard(
                provider.dashboardError!,
                provider.lastRequestId,
                strings,
              ),
              const SizedBox(height: 12),
            ],

            // Channel Connectivity Banner
            _buildConnectivityBanner(overview.connections, strings),
            const SizedBox(height: 16),

            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings('stats_period_today'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                if (provider.isLoadingDashboard)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 2x2 Metric Cards Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: strings('open_conversations'),
                    value: overview.openConversations.toString(),
                    icon: Icons.forum_rounded,
                    color: AppColors.primary,
                    bgColor: AppColors.primaryFixed,
                    onTap: widget.onNavigateToInbox,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: strings('waiting_human'),
                    value: overview.waitingHuman.toString(),
                    icon: Icons.support_agent_rounded,
                    color: AppColors.statusWarning,
                    bgColor: AppColors.statusWarningContainer,
                    onTap: widget.onNavigateToInbox,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: strings('new_customers'),
                    value: overview.newCustomers.toString(),
                    icon: Icons.people_alt_rounded,
                    color: AppColors.secondary,
                    bgColor: AppColors.secondaryFixed,
                    onTap: widget.onNavigateToCustomers,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: strings('new_leads'),
                    value: overview.newLeads.toString(),
                    icon: Icons.trending_up_rounded,
                    color: AppColors.statusSuccess,
                    bgColor: AppColors.statusSuccessContainer,
                    onTap: widget.onNavigateToLeads,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transactions Review Banner Card
            _buildReviewCard(
              title: strings('transactions_review'),
              count: overview.transactionsNeedingReview,
              onTap: widget.onNavigateToReviews ?? widget.onNavigateToTransactions,
            ),
            if (widget.onNavigateToCatalogs != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: widget.onNavigateToCatalogs,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings('catalogs_title'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.onNavigateToTeam != null) ...[
              const SizedBox(height: 12),
              InkWell(
                key: const Key('quick_link_team'),
                onTap: widget.onNavigateToTeam,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B21A8).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFF6B21A8),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings('team_and_audit'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.onNavigateToChannels != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: widget.onNavigateToChannels,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.cable_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings('channels_and_automation'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Channel List Section
            _buildChannelsSection(overview.connections, strings),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(
    Business? business,
    String Function(String) strings,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business?.name ?? strings('app_name'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${business?.slug ?? business?.id ?? ''} • ${business?.defaultCurrency ?? 'SAR'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusSuccessContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.presenceOnline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  strings('active_badge'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.statusSuccess,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityBanner(
    Map<String, int> connections,
    String Function(String) strings,
  ) {
    final activeCount = connections.values.fold<int>(
      0,
      (prev, curr) => prev + curr,
    );
    final channelCount = connections.keys.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.hub_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channelCount > 0
                      ? '$channelCount ${strings('connected_channels')}'
                      : strings('no_connected_channels'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  activeCount > 0
                      ? '$activeCount اتصال نشط'
                      : 'بانتظار وصول محادثات جديدة',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            channelCount > 0
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            size: 20,
            color: channelCount > 0
                ? AppColors.presenceOnline
                : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderHairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required int count,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: count > 0
              ? AppColors.statusWarningContainer
              : AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                count > 0 ? AppColors.statusWarning : AppColors.borderHairline,
          ),
        ),
        child: Row(
          children: [
          Icon(
            count > 0
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            color: count > 0
                ? AppColors.statusWarning
                : AppColors.statusSuccess,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: count > 0
                    ? AppColors.statusWarning
                    : AppColors.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0
                  ? AppColors.statusWarning
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: count > 0 ? Colors.white : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildChannelsSection(
    Map<String, int> connections,
    String Function(String) strings,
  ) {
    if (connections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings('connected_channels'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCanvas,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: connections.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final key = connections.keys.elementAt(index);
              final count = connections[key] ?? 0;
              final meta = ChannelPresentation.getMeta(key);

              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: meta.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    meta.icon,
                    color: meta.brandColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  meta.key == 'other' ? key : meta.localizedName(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                trailing: Text(
                  '$count محادثة',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(
    String error,
    String? requestId,
    String Function(String) strings,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusErrorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.statusError,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(
                    color: AppColors.statusError,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(onPressed: _loadData, child: Text(strings('retry'))),
            ],
          ),
          if (requestId != null && requestId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${strings('request_id')}: $requestId',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
