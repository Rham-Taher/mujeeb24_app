import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/transaction_models.dart';
import 'package:mujeeb24_app/core/widgets/common_ui_widgets.dart';
import 'package:mujeeb24_app/core/widgets/filter_widgets.dart';
import 'package:mujeeb24_app/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:mujeeb24_app/features/transactions/presentation/transaction_draft_form_screen.dart';
import 'package:mujeeb24_app/features/transactions/providers/transaction_provider.dart';

class TransactionsScreen extends StatefulWidget {
  final TransactionProvider transactionProvider;
  final String businessId;
  final String? initialStateFilter;

  const TransactionsScreen({
    super.key,
    required this.transactionProvider,
    required this.businessId,
    this.initialStateFilter,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialStateFilter != null &&
        widget.initialStateFilter!.isNotEmpty) {
      widget.transactionProvider.setStateFilter(widget.initialStateFilter!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await widget.transactionProvider.loadTransactions(
      widget.businessId,
      refresh: true,
    );
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'confirmed':
        return AppColors.statusSuccess;
      case 'review':
        return AppColors.statusWarning;
      case 'cancelled':
        return AppColors.statusError;
      case 'draft':
      default:
        return AppColors.primary;
    }
  }

  Color _getStateBgColor(String state) {
    switch (state.toLowerCase()) {
      case 'confirmed':
        return AppColors.statusSuccessContainer;
      case 'review':
        return AppColors.statusWarningContainer;
      case 'cancelled':
        return AppColors.statusErrorContainer;
      case 'draft':
      default:
        return AppColors.primaryContainer.withValues(alpha: 0.12);
    }
  }

  IconData _getStateIcon(String state) {
    switch (state.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'review':
        return Icons.pending_actions_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'draft':
      default:
        return Icons.edit_note_rounded;
    }
  }

  String _formatStateLabel(String state, String Function(String) strings) {
    switch (state.toLowerCase()) {
      case 'draft':
        return strings('tx_state_draft');
      case 'review':
        return strings('tx_state_review');
      case 'confirmed':
        return strings('tx_state_confirmed');
      case 'cancelled':
        return strings('tx_state_cancelled');
      default:
        return strings('tx_state_all');
    }
  }

  void _openDetail(CommercialTransaction tx) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(
          transactionProvider: widget.transactionProvider,
          businessId: widget.businessId,
          transactionId: tx.id,
        ),
      ),
    );
  }

  void _openCreateDraft() async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionDraftFormScreen(
          transactionProvider: widget.transactionProvider,
          businessId: widget.businessId,
        ),
      ),
    );
    if (created != null) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    ensureScreenUtilInitialized();
    String strings(String key) => AppStrings.get(key, context);
    final provider = widget.transactionProvider;

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final txList = provider.filteredTransactions;

        // Compute KPI Summary Metrics
        int draftsCount = 0;
        double draftsTotal = 0.0;
        int confirmedCount = 0;
        double confirmedTotal = 0.0;
        int reviewCount = 0;

        for (final tx in provider.transactions) {
          final s = tx.state.toLowerCase();
          final amount = tx.totalAmount ?? 0.0;
          if (s == 'draft') {
            draftsCount++;
            draftsTotal += amount;
          } else if (s == 'confirmed') {
            confirmedCount++;
            confirmedTotal += amount;
          } else if (s == 'review') {
            reviewCount++;
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceCanvas,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 16,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: AppColors.borderHairline,
                height: 1,
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    strings('transactions_title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Text(
                    '${txList.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.onSurfaceVariant),
                tooltip: strings('refresh'),
                onPressed: provider.isLoadingTransactions ? null : _loadData,
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateDraft,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              strings('create_draft_transaction'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 600;
                return RefreshIndicator(
                  onRefresh: _loadData,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // Quick Operational KPI Highlights Grid
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Drafts KPI
                      SizedBox(
                        width: 120,
                        child: _buildKpiCard(
                          icon: Icons.edit_document,
                          iconColor: AppColors.statusWarning,
                          badgeText: '$draftsCount معلقة',
                          badgeColor: AppColors.statusWarning,
                          badgeBg: AppColors.statusWarningContainer,
                          value: draftsTotal > 0
                              ? draftsTotal.toStringAsFixed(0)
                              : '$draftsCount',
                          unit: draftsTotal > 0 ? strings('currency_sar') : 'مسودة',
                          label: 'مسودات معلقة',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Confirmed KPI
                      SizedBox(
                        width: 120,
                        child: _buildKpiCard(
                          icon: Icons.verified_rounded,
                          iconColor: AppColors.statusSuccess,
                          badgeText: '$confirmedCount صفقة',
                          badgeColor: AppColors.statusSuccess,
                          badgeBg: AppColors.statusSuccessContainer,
                          value: confirmedTotal > 0
                              ? confirmedTotal.toStringAsFixed(0)
                              : '$confirmedCount',
                          unit: confirmedTotal > 0 ? strings('currency_sar') : 'صفقة',
                          label: 'مبيعات مؤكدة',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Review KPI
                      SizedBox(
                        width: 120,
                        child: _buildKpiCard(
                          icon: Icons.pending_actions_rounded,
                          iconColor: AppColors.primary,
                          badgeText: '$reviewCount مراجعة',
                          badgeColor: AppColors.primary,
                          badgeBg: AppColors.primaryContainer.withValues(alpha: 0.12),
                          value: '$reviewCount',
                          unit: 'معاملة',
                          label: 'بانتظار الاعتماد',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Modern Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderHairline),
                    boxShadow: AppShadows.card,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: strings('search_transactions'),
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceCanvas,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: (val) => provider.setSearchQuery(val),
                  ),
                ),
                const SizedBox(height: 12),

                // State Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStateFilterChip(
                        'all',
                        strings('tx_state_all'),
                        provider,
                        indicatorColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildStateFilterChip(
                        'review',
                        strings('tx_state_review'),
                        provider,
                        indicatorColor: AppColors.statusWarning,
                        badgeCount: reviewCount > 0 ? reviewCount : null,
                      ),
                      const SizedBox(width: 8),
                      _buildStateFilterChip(
                        'draft',
                        strings('tx_state_draft'),
                        provider,
                        indicatorColor: AppColors.primary,
                        badgeCount: draftsCount > 0 ? draftsCount : null,
                      ),
                      const SizedBox(width: 8),
                      _buildStateFilterChip(
                        'confirmed',
                        strings('tx_state_confirmed'),
                        provider,
                        indicatorColor: AppColors.statusSuccess,
                        badgeCount: confirmedCount > 0 ? confirmedCount : null,
                      ),
                      const SizedBox(width: 8),
                      _buildStateFilterChip(
                        'cancelled',
                        strings('tx_state_cancelled'),
                        provider,
                        indicatorColor: AppColors.statusError,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Type Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTypeFilterChip(
                        'all',
                        strings('tx_type_all'),
                        provider,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeFilterChip(
                        'order',
                        strings('tx_type_order'),
                        provider,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeFilterChip(
                        'quote',
                        strings('tx_type_quote'),
                        provider,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeFilterChip(
                        'invoice',
                        strings('tx_type_invoice'),
                        provider,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeFilterChip(
                        'sale',
                        strings('tx_type_sale'),
                        provider,
                      ),
                    ],
                  ),
                ),
                if (provider.activeFiltersCount > 0) ...[
                  const SizedBox(height: 10),
                  ActiveFiltersHeader(
                    activeCount: provider.activeFiltersCount,
                    onClear: () {
                      _searchController.clear();
                      provider.clearFilters(widget.businessId);
                    },
                  ),
                ],
                const SizedBox(height: 14),

                // Error Banner
                if (provider.transactionsError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.statusErrorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.statusError.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.statusError,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            provider.transactionsError!,
                            style: const TextStyle(
                              color: AppColors.statusError,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Transactions List
                if (provider.isLoadingTransactions && txList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else if (txList.isEmpty)
                  provider.activeFiltersCount > 0
                      ? FilterEmptyState(
                          title: strings('no_filtered_results'),
                          subtitle: strings('no_filtered_results_hint'),
                          onClearFilters: () {
                            _searchController.clear();
                            provider.clearFilters(widget.businessId);
                          },
                          clearButtonText: strings('reset_all_filters'),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 50,
                            horizontal: 24,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: provider.stateFilter == 'review'
                                        ? AppColors.statusWarningContainer
                                        : AppColors.surfaceContainerLow,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: provider.stateFilter == 'review'
                                          ? AppColors.statusWarning.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.primary.withValues(
                                              alpha: 0.15,
                                            ),
                                    ),
                                  ),
                                  child: Icon(
                                    provider.stateFilter == 'review'
                                        ? Icons.task_alt_rounded
                                        : Icons.receipt_long_rounded,
                                    size: 34,
                                    color: provider.stateFilter == 'review'
                                        ? AppColors.statusWarning
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  provider.stateFilter == 'review'
                                      ? strings(
                                          'no_transactions_needing_review',
                                        )
                                      : strings('no_transactions'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                else
                  ...txList.map((tx) {
                    final stateColor = _getStateColor(tx.state);
                    final stateBg = _getStateBgColor(tx.state);
                    final stateIcon = _getStateIcon(tx.state);
                    final parsedLines = tx.parsedLines;
                    final hasLines = parsedLines.isNotEmpty;
                    final firstLine = hasLines ? parsedLines.first : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCanvas,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderHairline),
                        boxShadow: AppShadows.card,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openDetail(tx),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Avatar/Customer, ID badge, and State Badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Customer avatar
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        tx.customerId.isNotEmpty
                                            ? tx.customerId.substring(0, 1).toUpperCase()
                                            : 'C',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Customer ID and Reference
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.customerId,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${tx.transactionType.toUpperCase()} • #${tx.id.length > 8 ? tx.id.substring(0, 8) : tx.id}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.4,
                                            color: AppColors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // State StatusBadge
                                  StatusBadge(
                                    label: _formatStateLabel(
                                      tx.state,
                                      strings,
                                    ),
                                    color: stateColor,
                                    backgroundColor: stateBg,
                                    icon: stateIcon,
                                    fontSize: 11,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Inner Item & Value Summary Box (matching design reference)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(color: AppColors.borderHairline),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceCanvas,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                        border: Border.all(color: AppColors.borderHairline),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            firstLine != null && firstLine.itemNameSnapshot.isNotEmpty
                                                ? firstLine.itemNameSnapshot
                                                : (firstLine?.catalogItemId ?? tx.transactionType.toUpperCase()),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5,
                                              color: AppColors.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            firstLine != null
                                                ? '${strings('quantity')}: ${firstLine.quantity.toInt()}${parsedLines.length > 1 ? ' (+${parsedLines.length - 1})' : ''}'
                                                : 'ID: ${tx.id.length > 12 ? '${tx.id.substring(0, 12)}...' : tx.id}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${tx.totalAmount?.toStringAsFixed(2) ?? '0.00'} ${tx.currency ?? ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Card Footer: Date & Details prompt
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tx.createdAt.length >= 10
                                            ? tx.createdAt.substring(0, 10)
                                            : tx.createdAt,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        strings('transaction_details'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 10,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                // Pagination Load More
                if (provider.hasMore) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: provider.isLoadingMore
                          ? null
                          : () => provider.loadMoreTransactions(
                              widget.businessId,
                            ),
                      child: provider.isLoadingMore
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : Text(
                              strings('load_more'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
                SizedBox(height: 60.h),
              ],
            ),
          );
        },
      ),
    ),
  );
      },
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStateFilterChip(
    String state,
    String label,
    TransactionProvider provider, {
    Color? indicatorColor,
    int? badgeCount,
  }) {
    final isSelected = provider.stateFilter == state;
    return FilterChip(
      avatar: indicatorColor != null && !isSelected
          ? Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            )
          : null,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (badgeCount != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        provider.setStateFilter(state);
        provider.loadTransactions(widget.businessId);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderHairline,
          width: isSelected ? 1.2 : 0.8,
        ),
      ),
      backgroundColor: AppColors.surfaceCanvas,
      selectedColor: AppColors.primaryContainer.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTypeFilterChip(
    String type,
    String label,
    TransactionProvider provider,
  ) {
    final isSelected = provider.transactionTypeFilter == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        provider.setTransactionTypeFilter(type);
        provider.loadTransactions(widget.businessId);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderHairline,
          width: isSelected ? 1.2 : 0.8,
        ),
      ),
      backgroundColor: AppColors.surfaceCanvas,
      selectedColor: AppColors.primaryContainer.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
    );
  }
}
