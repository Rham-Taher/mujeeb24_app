import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/crm_models.dart';
import 'package:mujeeb24_app/core/widgets/filter_widgets.dart';
import 'package:mujeeb24_app/features/crm/presentation/lead_detail_screen.dart';
import 'package:mujeeb24_app/features/crm/presentation/lead_form_screen.dart';
import 'package:mujeeb24_app/features/crm/providers/crm_provider.dart';

class LeadsTab extends StatefulWidget {
  final CrmProvider crmProvider;
  final String businessId;

  const LeadsTab({
    super.key,
    required this.crmProvider,
    required this.businessId,
  });

  @override
  State<LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<LeadsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.crmProvider.addListener(_onStateChange);
    _searchController.text = widget.crmProvider.leadSearchQuery;
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
      if (_searchController.text != widget.crmProvider.leadSearchQuery &&
          !_searchController.selection.isValid) {
        _searchController.text = widget.crmProvider.leadSearchQuery;
      }
      setState(() {});
    }
  }

  void _loadData() {
    if (widget.businessId.isNotEmpty) {
      widget.crmProvider.loadLeads(widget.businessId);
    }
  }

  void _openLeadDetail(Lead lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeadDetailScreen(
          crmProvider: widget.crmProvider,
          businessId: widget.businessId,
          leadId: lead.id,
          initialLead: lead,
        ),
      ),
    );
  }

  void _openCreateLead() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeadFormScreen(
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
    final leads = provider.filteredLeads;

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
        icon: const Icon(Icons.add_chart_rounded, size: 20),
        label: Text(
          strings('create_lead'),
          style: AppTypography.buttonLabel.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        onPressed: _openCreateLead,
      ),
      body: SafeArea(
        child: Column(
          children: [
          // Filter Chips & Search Header
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
                // Top Title Row ("العملاء المحتملين") with Count Badge & Refresh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'العملاء المحتملين',
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
                              '${leads.length} فرصة',
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

                // Modern Search Field
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
                                provider.setLeadSearchQuery('');
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
                      provider.setLeadSearchQuery(value);
                    },
                    onSubmitted: (value) {
                      provider.setLeadSearchQuery(value);
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // 1. Social Channels Filter Bar
                ChannelFilterBar(
                  selectedChannel: provider.leadChannelFilter,
                  onChannelSelected: (val) {
                    provider.setLeadChannelFilter(val);
                  },
                ),
                const SizedBox(height: 10),

                // 2. Status Filter Row (All, New, Contacted, Qualified, Lost)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: strings('all_conversations'),
                        value: 'all',
                        current: provider.leadFilterStatus,
                        onSelected: (val) {
                          provider.setLeadFilterStatus(val);
                          provider.loadLeads(widget.businessId, status: val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: strings('lead_status_new'),
                        value: 'new',
                        current: provider.leadFilterStatus,
                        onSelected: (val) {
                          provider.setLeadFilterStatus(val);
                          provider.loadLeads(widget.businessId, status: val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: strings('lead_status_contacted'),
                        value: 'contacted',
                        current: provider.leadFilterStatus,
                        onSelected: (val) {
                          provider.setLeadFilterStatus(val);
                          provider.loadLeads(widget.businessId, status: val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: strings('lead_status_qualified'),
                        value: 'qualified',
                        current: provider.leadFilterStatus,
                        onSelected: (val) {
                          provider.setLeadFilterStatus(val);
                          provider.loadLeads(widget.businessId, status: val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: strings('lead_status_lost'),
                        value: 'lost',
                        current: provider.leadFilterStatus,
                        onSelected: (val) {
                          provider.setLeadFilterStatus(val);
                          provider.loadLeads(widget.businessId, status: val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Score Band Filter Row (All, HIGH, MEDIUM, LOW)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: strings('lead_score_band'),
                        value: 'all',
                        current: provider.leadFilterScoreBand,
                        onSelected: (val) {
                          provider.setLeadFilterScoreBand(val);
                          provider.loadLeads(widget.businessId, scoreBand: val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'HIGH',
                        value: 'high',
                        current: provider.leadFilterScoreBand,
                        color: AppColors.statusSuccess,
                        onSelected: (val) {
                          provider.setLeadFilterScoreBand(val);
                          provider.loadLeads(widget.businessId, scoreBand: val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'MEDIUM',
                        value: 'medium',
                        current: provider.leadFilterScoreBand,
                        color: AppColors.statusWarning,
                        onSelected: (val) {
                          provider.setLeadFilterScoreBand(val);
                          provider.loadLeads(widget.businessId, scoreBand: val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'LOW',
                        value: 'low',
                        current: provider.leadFilterScoreBand,
                        color: AppColors.secondaryText,
                        onSelected: (val) {
                          provider.setLeadFilterScoreBand(val);
                          provider.loadLeads(widget.businessId, scoreBand: val);
                        },
                      ),
                    ],
                  ),
                ),

                // 4. Active Filters Header & Clear action
                if (provider.activeLeadFiltersCount > 0) ...[
                  const SizedBox(height: 8),
                  ActiveFiltersHeader(
                    activeCount: provider.activeLeadFiltersCount,
                    onClear: () {
                      _searchController.clear();
                      provider.clearLeadFilters(widget.businessId);
                    },
                  ),
                ],
              ],
            ),
          ),

          // Error banner if any
          if (provider.leadsError != null)
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
                        provider.leadsError!,
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

          // Leads List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () async => _loadData(),
              child: provider.isLoadingLeads && leads.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                        strokeWidth: 2.5,
                      ),
                    )
                  : leads.isEmpty
                      ? (provider.activeLeadFiltersCount > 0
                          ? FilterEmptyState(
                              title: strings('no_filtered_results'),
                              subtitle: strings('no_filtered_results_hint'),
                              onClearFilters: () {
                                _searchController.clear();
                                provider.clearLeadFilters(
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
                                itemCount: leads.length,
                                itemBuilder: (context, index) {
                                  final lead = leads[index];
                                  return _buildLeadCard(
                                    lead: lead,
                                    strings: strings,
                                    onTap: () => _openLeadDetail(lead),
                                  );
                                },
                              );
                            }
                            return ListView.separated(
                              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 84.h),
                              itemCount: leads.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: 10.h),
                              itemBuilder: (context, index) {
                                final lead = leads[index];
                                return _buildLeadCard(
                                  lead: lead,
                                  strings: strings,
                                  onTap: () => _openLeadDetail(lead),
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
    required String value,
    required String current,
    required ValueChanged<String> onSelected,
    Color? color,
  }) {
    final isSelected = current == value;
    final primaryColor = color ?? AppColors.primaryBlue;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? primaryColor : AppColors.borderLightBlue,
            width: isSelected ? 1 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
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

  Widget _buildLeadCard({
    required Lead lead,
    required String Function(String) strings,
    required VoidCallback onTap,
  }) {
    final statusColor = _getStatusColor(lead.status);
    final statusIcon = _getStatusIcon(lead.status);
    final score = lead.currentScore != null
        ? lead.currentScore!.toStringAsFixed(1)
        : '-';
    final band = lead.scoreBand?.toUpperCase() ?? 'NONE';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status Squircle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // Lead and Customer identifiers
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lead: ${lead.id}',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.headingNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Cust: ${lead.customerId}',
                            style: AppTypography.caption.copyWith(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Status Capsule Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        lead.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.borderLightBlue),
                const SizedBox(height: 10),

                // Score and Score Band Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.speed_rounded,
                              size: 15,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Score: $score',
                              style: AppTypography.caption.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.headingNavy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: AppColors.primaryBlue.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'BAND: $band',
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'qualified':
        return AppColors.statusSuccess;
      case 'lost':
        return AppColors.statusError;
      case 'contacted':
        return AppColors.statusWarning;
      case 'new':
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'qualified':
        return Icons.verified_rounded;
      case 'lost':
        return Icons.cancel_outlined;
      case 'contacted':
        return Icons.phone_in_talk_rounded;
      case 'new':
      default:
        return Icons.fiber_new_rounded;
    }
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
              child: Icon(
                Icons.trending_up_rounded,
                size: 38,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings('no_leads_found'),
              style: AppTypography.cardTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.headingNavy,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
