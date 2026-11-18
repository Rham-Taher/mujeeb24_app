import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/core/widgets/common_ui_widgets.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';
import 'package:mujeeb24_app/features/subscription/providers/subscription_provider.dart';

class DashboardTab extends StatefulWidget {
  final MerchantProvider merchantProvider;
  final SubscriptionProvider? subscriptionProvider;
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
  final VoidCallback? onNavigateToSubscription;
  final VoidCallback? onNavigateToPlans;
  final VoidCallback? onSessionExpired;

  const DashboardTab({
    super.key,
    required this.merchantProvider,
    this.subscriptionProvider,
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
    this.onNavigateToSubscription,
    this.onNavigateToPlans,
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
    widget.subscriptionProvider?.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    widget.merchantProvider.removeListener(_onStateChange);
    widget.subscriptionProvider?.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _loadData() {
    final businessId = widget.currentBusiness?.id;
    if (businessId != null && businessId.isNotEmpty) {
      widget.merchantProvider.loadDashboardOverview(businessId);
      widget.subscriptionProvider?.loadSubscription(businessId);
    }
  }

  @override
  Widget build(BuildContext context) {
    ensureScreenUtilInitialized();
    String strings(String key) => AppStrings.get(key, context);
    final provider = widget.merchantProvider;
    final overview = provider.dashboardOverview;
    final business = widget.currentBusiness;

    if (overview == null) {
      return SafeArea(
        child: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            _buildWelcomeBanner(business, strings),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderHairline),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: provider.dashboardRequiresLogin
                          ? AppColors.statusWarningContainer
                          : provider.isLoadingDashboard
                              ? AppColors.primaryContainer
                              : AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      provider.dashboardRequiresLogin
                          ? Icons.lock_outline_rounded
                          : provider.isLoadingDashboard
                              ? Icons.sync_rounded
                              : Icons.cloud_off_outlined,
                      size: 32,
                      color: provider.dashboardRequiresLogin
                          ? AppColors.statusWarning
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    provider.dashboardRequiresLogin
                        ? 'يلزم تسجيل الدخول'
                        : provider.isLoadingDashboard
                            ? 'جاري تحميل بيانات نشاطك'
                            : 'تعذر تحديث لوحة النشاط',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.dashboardError ??
                        'سيتم عرض مؤشرات الأداء بعد استلام البيانات من الخادم.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (provider.isLoadingDashboard) ...[
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: provider.dashboardRequiresLogin
                          ? widget.onSessionExpired
                          : _loadData,
                      icon: Icon(
                        provider.dashboardRequiresLogin
                            ? Icons.login_rounded
                            : Icons.refresh_rounded,
                        size: 18,
                      ),
                      label: Text(
                        provider.dashboardRequiresLogin
                            ? 'تسجيل الدخول من جديد'
                            : 'إعادة المحاولة',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ));
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24.w.clamp(16.0, 32.0) : 16.w,
                vertical: 16.h,
              ),
              child: isTablet
                  ? _buildTabletDashboard(business, overview, provider, strings)
                  : _buildMobileDashboard(business, overview, provider, strings),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileDashboard(
    Business? business,
    DashboardOverview overview,
    MerchantProvider provider,
    String Function(String) strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopHeaderBar(business, strings),
        SizedBox(height: 16.h),
        if (provider.dashboardError != null) ...[
          _buildErrorCard(
            provider.dashboardError!,
            provider.lastRequestId,
            strings,
          ),
          SizedBox(height: 14.h),
        ],
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Text(
            strings('stats_period_today'),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ),
        _buildMetricsBoard(overview, strings),
        SizedBox(height: 16.h),
        _buildChannelsStatusCard(overview.connections, strings),
        SizedBox(height: 16.h),
        _buildSubscriptionPackageCard(overview, strings),
        SizedBox(height: 16.h),
        if (widget.onNavigateToCatalogs != null) ...[
          _buildQuickActionLink(
            icon: Icons.inventory_2_rounded,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.primaryContainer,
            title: strings('catalogs_title'),
            onTap: widget.onNavigateToCatalogs!,
          ),
          SizedBox(height: 10.h),
        ],
        if (widget.onNavigateToTeam != null) ...[
          _buildQuickActionLink(
            key: const Key('quick_link_team'),
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFF6B21A8),
            iconBgColor: const Color(0xFF6B21A8).withValues(alpha: 0.12),
            title: strings('team_and_audit'),
            onTap: widget.onNavigateToTeam!,
          ),
          SizedBox(height: 10.h),
        ],
        if (widget.onNavigateToChannels != null) ...[
          _buildQuickActionLink(
            icon: Icons.cable_rounded,
            iconColor: AppColors.secondary,
            iconBgColor: AppColors.secondaryContainer,
            title: strings('channels_and_automation'),
            onTap: widget.onNavigateToChannels!,
          ),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }

  Widget _buildTabletDashboard(
    Business? business,
    DashboardOverview overview,
    MerchantProvider provider,
    String Function(String) strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopHeaderBar(business, strings),
        SizedBox(height: 16.h),
        if (provider.dashboardError != null) ...[
          _buildErrorCard(
            provider.dashboardError!,
            provider.lastRequestId,
            strings,
          ),
          SizedBox(height: 14.h),
        ],
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Text(
            strings('stats_period_today'),
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildMetricPillCard(
                value: overview.openConversations.toString(),
                label: strings('open_conversations'),
                color: AppColors.primary,
                onTap: widget.onNavigateToInbox,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildMetricPillCard(
                value: overview.waitingHuman.toString(),
                label: strings('waiting_human'),
                color: AppColors.errorRed,
                onTap: widget.onNavigateToInbox,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildMetricPillCard(
                value: overview.transactionsNeedingReview.toString(),
                label: strings('transactions_review'),
                color: AppColors.successGreen,
                onTap: widget.onNavigateToReviews ?? widget.onNavigateToTransactions,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildMetricPillCard(
                value: overview.newCustomers.toString(),
                label: strings('new_customers'),
                color: AppColors.primary,
                onTap: widget.onNavigateToCustomers,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildMetricPillCard(
                value: overview.newLeads.toString(),
                label: strings('new_leads'),
                color: AppColors.successGreen,
                onTap: widget.onNavigateToLeads,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildChannelsStatusCard(overview.connections, strings),
                  SizedBox(height: 16.h),
                  if (widget.onNavigateToCatalogs != null) ...[
                    _buildQuickActionLink(
                      icon: Icons.inventory_2_rounded,
                      iconColor: AppColors.primary,
                      iconBgColor: AppColors.primaryContainer,
                      title: strings('catalogs_title'),
                      onTap: widget.onNavigateToCatalogs!,
                    ),
                    SizedBox(height: 10.h),
                  ],
                  if (widget.onNavigateToTeam != null) ...[
                    _buildQuickActionLink(
                      key: const Key('quick_link_team'),
                      icon: Icons.groups_rounded,
                      iconColor: const Color(0xFF6B21A8),
                      iconBgColor: const Color(0xFF6B21A8).withValues(alpha: 0.12),
                      title: strings('team_and_audit'),
                      onTap: widget.onNavigateToTeam!,
                    ),
                    SizedBox(height: 10.h),
                  ],
                  if (widget.onNavigateToChannels != null) ...[
                    _buildQuickActionLink(
                      icon: Icons.cable_rounded,
                      iconColor: AppColors.secondary,
                      iconBgColor: AppColors.secondaryContainer,
                      title: strings('channels_and_automation'),
                      onTap: widget.onNavigateToChannels!,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSubscriptionPackageCard(overview, strings),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner(
    Business? business,
    String Function(String) strings,
  ) {
    return _buildTopHeaderBar(business, strings);
  }

  Widget _buildQuickActionLink({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
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
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
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
    );
  }

  /// Top Header Bar: Store Switcher on right, Mujeeb24 Brand & Notifications on left
  Widget _buildTopHeaderBar(
    Business? business,
    String Function(String) strings,
  ) {
    final businessName = business?.name ?? strings('app_name');
    return MujeebCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: AppRadius.xl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Store Selector (Right in RTL)
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primaryFixed,
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 19,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${business?.slug ?? 'متجر نشط'} • ${business?.defaultCurrency ?? 'SAR'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Mujeeb24 Brand Logo & Notification Bell (Left in RTL)
          Row(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 22,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.errorRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'مجيب 24',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 5 Key Performance Metrics Cards matching UI Board:
  /// Row 1: 3 cards (Open Conversations: 12, Waiting Human: 3, Reviews: 8)
  /// Row 2: 2 cards (New Customers: 25, New Leads: 42)
  Widget _buildMetricsBoard(
    DashboardOverview overview,
    String Function(String) strings,
  ) {
    return Column(
      children: [
        // Row 1: 3 Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricPillCard(
                value: overview.openConversations.toString(),
                label: strings('open_conversations'),
                color: AppColors.primary,
                onTap: widget.onNavigateToInbox,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricPillCard(
                value: overview.waitingHuman.toString(),
                label: strings('waiting_human'),
                color: AppColors.errorRed,
                onTap: widget.onNavigateToInbox,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricPillCard(
                value: overview.transactionsNeedingReview.toString(),
                label: strings('transactions_review'),
                color: AppColors.successGreen,
                onTap: widget.onNavigateToReviews ??
                    widget.onNavigateToTransactions,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: 2 Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricPillCard(
                value: overview.newCustomers.toString(),
                label: strings('new_customers'),
                color: AppColors.primary,
                onTap: widget.onNavigateToCustomers,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricPillCard(
                value: overview.newLeads.toString(),
                label: strings('new_leads'),
                color: AppColors.successGreen,
                onTap: widget.onNavigateToLeads,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Single Metric Card with prominent large number and clean label
  Widget _buildMetricPillCard({
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderHairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Channels Status Card ("حالة قنوات التواصل") matching UI Board
  Widget _buildChannelsStatusCard(
    Map<String, int> connections,
    String Function(String) strings,
  ) {
    return MujeebCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'حالة قنوات التواصل',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              if (widget.onNavigateToChannels != null)
                InkWell(
                  onTap: widget.onNavigateToChannels,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(
                      Icons.settings_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal 4-channel row matching UI board
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChannelStatusItem(
                name: 'واتساب',
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF25D366),
                bgColor: const Color(0xFFE8F8F0),
                isConnected: true,
                count: connections['واتساب'] ?? connections['WhatsApp'],
              ),
              _buildChannelStatusItem(
                name: 'تيليجرام',
                icon: Icons.send_rounded,
                iconColor: const Color(0xFF0088CC),
                bgColor: const Color(0xFFE5F4FC),
                isConnected: true,
                count: connections['تيليجرام'] ?? connections['Telegram'],
              ),
              _buildChannelStatusItem(
                name: 'فيسبوك',
                icon: Icons.facebook_rounded,
                iconColor: const Color(0xFF1877F2),
                bgColor: const Color(0xFFE7F0FD),
                isConnected: true,
                count: connections['فيسبوك'] ?? connections['Facebook'],
              ),
              _buildChannelStatusItem(
                name: 'إنستغرام',
                icon: Icons.camera_alt_rounded,
                iconColor: const Color(0xFFE1306C),
                bgColor: const Color(0xFFFDF0F5),
                isConnected: (connections['إنستغرام'] ?? connections['Instagram'] ?? 0) > 0,
                count: connections['إنستغرام'] ?? connections['Instagram'],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Single channel status column in Channels card
  Widget _buildChannelStatusItem({
    required String name,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required bool isConnected,
    int? count,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          if (count != null && count > 0)
            Text(
              '$count محادثة',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isConnected ? 'متصل' : 'معطل',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isConnected
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Subscription Package Card ("باقة الاشتراك") matching UI Board
  Widget _buildSubscriptionPackageCard(
    DashboardOverview overview,
    String Function(String) strings,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Text info on right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'باقة الاشتراك',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'الباقة الاحترافية',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'تنتهي في 2025-12-31',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Outlined white Action button on left
          OutlinedButton(
            onPressed: widget.onNavigateToPlans ??
                widget.onNavigateToSubscription ??
                () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFFD8E8FE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 34),
            ),
            child: const Text(
              'إدارة الباقة',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildErrorCard(
    String error,
    String? requestId,
    String Function(String) strings,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusErrorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.statusError.withValues(alpha: 0.25)),
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(
                    color: AppColors.statusError,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.statusError,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _loadData,
                child: Text(
                  strings('retry'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (requestId != null && requestId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 30),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '${strings('request_id')}: $requestId',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
