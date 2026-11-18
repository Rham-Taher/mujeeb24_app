import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/channels/channel_presentation.dart';
import 'package:mujeeb24_app/core/models/crm_models.dart';
import 'package:mujeeb24_app/core/widgets/filter_widgets.dart';
import 'package:mujeeb24_app/features/crm/presentation/customer_detail_screen.dart';
import 'package:mujeeb24_app/features/crm/presentation/customer_form_screen.dart';
import 'package:mujeeb24_app/features/crm/providers/crm_provider.dart';

class CustomersTab extends StatefulWidget {
  final CrmProvider crmProvider;
  final String businessId;

  const CustomersTab({
    super.key,
    required this.crmProvider,
    required this.businessId,
  });

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.crmProvider.addListener(_onStateChange);
    _searchController.text = widget.crmProvider.customerSearchQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    widget.crmProvider.removeListener(_onStateChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) {
      if (_searchController.text != widget.crmProvider.customerSearchQuery &&
          !_searchController.selection.isValid) {
        _searchController.text = widget.crmProvider.customerSearchQuery;
      }
      setState(() {});
    }
  }

  void _loadData() {
    if (widget.businessId.isNotEmpty) {
      widget.crmProvider.loadCustomers(widget.businessId);
    }
  }

  void _openCustomerDetail(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(
          crmProvider: widget.crmProvider,
          businessId: widget.businessId,
          customerId: customer.id,
          initialCustomer: customer,
        ),
      ),
    );
  }

  void _openCreateCustomer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(
          crmProvider: widget.crmProvider,
          businessId: widget.businessId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ensureScreenUtilInitialized();
    String strings(String key) => AppStrings.get(key, context);
    final provider = widget.crmProvider;
    final customers = provider.filteredCustomers;

    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: Text(
          strings('create_customer'),
          style: AppTypography.buttonLabel.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        onPressed: _openCreateCustomer,
      ),
      body: SafeArea(
        child: Column(
          children: [
          // Search & Filter Header Container
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceCanvas,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderLightBlue,
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Title Row ("دليل العملاء") with Count Badge & Refresh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              strings('customers_title'),
                              style: AppTypography.pageTitle.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: AppColors.primaryBlue.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            '${customers.length} عميل',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.borderLightBlue),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 19,
                          color: AppColors.headingNavy,
                        ),
                        onPressed: _loadData,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: const EdgeInsets.all(8),
                        tooltip: strings('refresh'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Modern Search Field matching Mujeeb24 Design System
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderLightBlue),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTypography.body.copyWith(
                      color: AppColors.headingNavy,
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      hintText: strings('search_customers'),
                      hintStyle: AppTypography.caption.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.secondaryText,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              color: AppColors.secondaryText,
                              onPressed: () {
                                _searchController.clear();
                                provider.setCustomerSearchQuery('');
                                provider.loadCustomers(
                                  widget.businessId,
                                  search: '',
                                );
                              },
                            )
                          : null,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: (value) {
                      provider.setCustomerSearchQuery(value);
                    },
                    onSubmitted: (value) {
                      provider.setCustomerSearchQuery(value);
                      provider.loadCustomers(widget.businessId, search: value);
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // 1. Channel Filter Bar (WhatsApp, Facebook, Telegram, etc.)
                ChannelFilterBar(
                  selectedChannel: provider.customerChannelFilter,
                  onChannelSelected: (channel) {
                    provider.setCustomerChannelFilter(channel);
                  },
                ),
                const SizedBox(height: 10),

                // 2. Status Filter Chips (All, Active, Archived)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: strings('all_conversations'),
                        status: 'all',
                        current: provider.customerFilterStatus,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: strings('customer_active'),
                        status: 'active',
                        current: provider.customerFilterStatus,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: strings('customer_archived'),
                        status: 'archived',
                        current: provider.customerFilterStatus,
                      ),
                    ],
                  ),
                ),

                // 3. Active Filters Header & Clear action
                if (provider.activeCustomerFiltersCount > 0) ...[
                  const SizedBox(height: 8),
                  ActiveFiltersHeader(
                    activeCount: provider.activeCustomerFiltersCount,
                    onClear: () {
                      _searchController.clear();
                      provider.clearCustomerFilters(widget.businessId);
                    },
                  ),
                ],
              ],
            ),
          ),

          // Error banner if any
          if (provider.customersError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.customersError!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
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
              ),
            ),

          // Customer List View
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () async => _loadData(),
              child: provider.isLoadingCustomers && customers.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                        strokeWidth: 2.5,
                      ),
                    )
                  : customers.isEmpty
                      ? (provider.activeCustomerFiltersCount > 0
                          ? FilterEmptyState(
                              title: strings('no_filtered_results'),
                              subtitle: strings('no_filtered_results_hint'),
                              onClearFilters: () {
                                _searchController.clear();
                                provider.clearCustomerFilters(
                                  widget.businessId,
                                );
                              },
                              clearButtonText: strings('reset_all_filters'),
                            )
                          : _buildEmptyState(strings))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isTablet = constraints.maxWidth >= 600;
                            if (isTablet) {
                              return GridView.builder(
                                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 84.h),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: customers.length,
                                itemBuilder: (context, index) {
                                  final customer = customers[index];
                                  return _buildCustomerCard(
                                    customer: customer,
                                    strings: strings,
                                    onTap: () => _openCustomerDetail(customer),
                                  );
                                },
                              );
                            }
                            return ListView.separated(
                              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 84.h),
                              itemCount: customers.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: 10.h),
                              itemBuilder: (context, index) {
                                final customer = customers[index];
                                return _buildCustomerCard(
                                  customer: customer,
                                  strings: strings,
                                  onTap: () => _openCustomerDetail(customer),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String status,
    required String current,
  }) {
    final isSelected = current == status;
    return InkWell(
      onTap: () {
        widget.crmProvider.setCustomerFilterStatus(status);
        widget.crmProvider.loadCustomers(widget.businessId, status: status);
      },
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderLightBlue,
            width: isSelected ? 1 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.headingNavy,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard({
    required Customer customer,
    required String Function(String) strings,
    required VoidCallback onTap,
  }) {
    final name = customer.displayName?.isNotEmpty == true
        ? customer.displayName!
        : strings('customer');
    final phone = customer.primaryPhone;
    final email = customer.primaryEmail;
    final isActive = customer.status == 'active';
    final contactPoints = customer.contactPoints ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.borderLightBlue,
          width: 1,
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Customer Avatar with channel indicator dot
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isActive
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainerLow,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: TextStyle(
                          color: isActive
                              ? AppColors.primaryBlueDark
                              : AppColors.secondaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isActive)
                      Positioned(
                        bottom: -1,
                        left: -1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.successGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cardWhite,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Customer Info Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.headingNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.statusSuccessContainer
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.successGreen.withValues(alpha: 0.3)
                                    : AppColors.borderLightBlue,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isActive) ...[
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppColors.successGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  isActive
                                      ? strings('customer_active')
                                      : customer.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? AppColors.successGreen
                                        : AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Phone / Email / ID row
                      if (phone != null || email != null) ...[
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            if (phone != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.phone_rounded,
                                    size: 13,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      phone,
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.headingNavy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (email != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    size: 13,
                                    color: AppColors.secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      email,
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 11.5,
                                        color: AppColors.secondaryText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.fingerprint,
                              size: 13,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                'ID: ${customer.id}',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.secondaryText,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Display Channel badges for contact points if any
                      if (contactPoints.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: contactPoints.map((cp) {
                            final meta = ChannelPresentation.getMeta(cp.kind);
                            return ChannelBadge(channel: meta.key, size: 10);
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String Function(String) strings) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 38,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings('no_customers_found'),
              style: AppTypography.cardTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.headingNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              strings('create_customer_prompt'),
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
