import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/transaction_models.dart';
import 'package:mujeeb24_app/core/widgets/common_ui_widgets.dart';
import 'package:mujeeb24_app/features/transactions/presentation/transaction_draft_form_screen.dart';
import 'package:mujeeb24_app/features/transactions/providers/transaction_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionProvider transactionProvider;
  final String businessId;
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionProvider,
    required this.businessId,
    required this.transactionId,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  Future<void> _loadDetails() async {
    await widget.transactionProvider.loadTransactionDetail(
      widget.businessId,
      widget.transactionId,
    );
    final tx = widget.transactionProvider.selectedTransaction;
    if (tx != null && (tx.state == 'review' || tx.state == 'confirmed')) {
      await widget.transactionProvider.loadTransactionReview(
        widget.businessId,
        widget.transactionId,
      );
    }
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
        return state;
    }
  }

  String _strings(String key) => AppStrings.get(key, context);

  // ==========================================
  // ACTION DIALOGS
  // ==========================================

  void _showSubmitReviewDialog(CommercialTransaction tx) {
    final reasonController = TextEditingController(
      text: 'high_value, manual_review',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_strings('submit_for_review')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings('confirm_action_prompt'),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: '${_strings('reason_codes')} *',
                hintText: _strings('reason_codes_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_strings('cancel_action')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final rawCodes = reasonController.text.trim();
              final codes = rawCodes
                  .split(',')
                  .map((c) => c.trim())
                  .where((c) => c.isNotEmpty)
                  .toList();

              final result = await widget.transactionProvider.submitForReview(
                widget.businessId,
                tx.id,
                codes,
                ifMatch: tx.resourceVersion,
              );

              if (mounted) {
                if (result != null) {
                  showAppAlertDialog(
                    context,
                    message: _strings('review_submitted_success'),
                  );
                  _loadDetails();
                } else {
                  showAppAlertDialog(
                    context,
                    message: widget.transactionProvider.actionError ??
                        _strings('request_failed'),
                    isError: true,
                  );
                }
              }
            },
            child: Text(_strings('submit_for_review')),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(CommercialTransaction tx) {
    final reviewerController = TextEditingController(text: 'manager_reviewer');
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_strings('approve_review')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings('confirm_action_prompt'),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewerController,
              decoration: InputDecoration(
                labelText: '${_strings('reviewer_reference')} *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: _strings('review_reason'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_strings('cancel_action')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusSuccess,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await widget.transactionProvider.approveReview(
                widget.businessId,
                tx.id,
                reviewerController.text.trim(),
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : null,
                ifMatch: tx.resourceVersion,
              );

              if (mounted) {
                if (result != null) {
                  showAppAlertDialog(
                    context,
                    message: _strings('review_approved_success'),
                  );
                  _loadDetails();
                } else {
                  showAppAlertDialog(
                    context,
                    message: widget.transactionProvider.actionError ??
                        _strings('request_failed'),
                    isError: true,
                  );
                }
              }
            },
            child: Text(_strings('approve_review')),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(CommercialTransaction tx) {
    final reviewerController = TextEditingController(text: 'manager_reviewer');
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_strings('reject_review')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings('confirm_action_prompt'),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewerController,
              decoration: InputDecoration(
                labelText: '${_strings('reviewer_reference')} *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: _strings('review_reason'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_strings('cancel_action')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await widget.transactionProvider.rejectReview(
                widget.businessId,
                tx.id,
                reviewerController.text.trim(),
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : null,
                ifMatch: tx.resourceVersion,
              );

              if (mounted) {
                if (result != null) {
                  showAppAlertDialog(
                    context,
                    message: _strings('review_rejected_success'),
                  );
                  _loadDetails();
                } else {
                  showAppAlertDialog(
                    context,
                    message: widget.transactionProvider.actionError ??
                        _strings('request_failed'),
                    isError: true,
                  );
                }
              }
            },
            child: Text(_strings('reject_review')),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(CommercialTransaction tx) {
    final evidenceController = TextEditingController(
      text: 'manual_receipt_ref',
    );
    final policyVersionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_strings('confirm_transaction')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings('confirm_action_prompt'),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: evidenceController,
              decoration: InputDecoration(
                labelText: '${_strings('evidence_reference')} *',
                hintText: 'e.g. receipt_12345',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: policyVersionController,
              decoration: InputDecoration(
                labelText: _strings('policy_version'),
                hintText: 'Optional',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_strings('cancel_action')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusSuccess,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await widget.transactionProvider
                  .confirmTransaction(
                    widget.businessId,
                    tx.id,
                    evidenceController.text.trim(),
                    policyVersion:
                        policyVersionController.text.trim().isNotEmpty
                        ? policyVersionController.text.trim()
                        : null,
                    ifMatch: tx.resourceVersion,
                  );

              if (mounted) {
                if (result != null) {
                  showAppAlertDialog(
                    context,
                    message: _strings('transaction_confirmed_success'),
                  );
                  _loadDetails();
                } else {
                  showAppAlertDialog(
                    context,
                    message: widget.transactionProvider.actionError ??
                        _strings('request_failed'),
                    isError: true,
                  );
                }
              }
            },
            child: Text(_strings('confirm_transaction')),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(CommercialTransaction tx) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_strings('cancel_transaction')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings('confirm_action_prompt'),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: '${_strings('cancel_reason')} *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_strings('cancel_action')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.of(ctx).pop();
              final result = await widget.transactionProvider.cancelTransaction(
                widget.businessId,
                tx.id,
                reasonController.text.trim(),
                ifMatch: tx.resourceVersion,
              );

              if (mounted) {
                if (result != null) {
                  showAppAlertDialog(
                    context,
                    message: _strings('transaction_cancelled_success'),
                  );
                  _loadDetails();
                } else {
                  showAppAlertDialog(
                    context,
                    message: widget.transactionProvider.actionError ??
                        _strings('request_failed'),
                    isError: true,
                  );
                }
              }
            },
            child: Text(_strings('cancel_transaction')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => _strings(key);
    final provider = widget.transactionProvider;
    final tx = provider.selectedTransaction;

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final currentTx = provider.selectedTransaction ?? tx;
        final isBusy = provider.isPerformingAction;

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
            title: Text(
              strings('transaction_details'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.onSurfaceVariant),
                tooltip: strings('refresh'),
                onPressed: provider.isLoadingTransactionDetail
                    ? null
                    : _loadDetails,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: provider.isLoadingTransactionDetail && currentTx == null
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
              : currentTx == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 32,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.transactionDetailError ??
                            strings('no_transactions'),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: _loadDetails,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(strings('retry')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDetails,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    children: [
                      if (isBusy) ...[
                        const ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
                          child: LinearProgressIndicator(
                            color: AppColors.primary,
                            minHeight: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Header / Overview Card
                      _buildHeaderCard(currentTx, strings),
                      const SizedBox(height: 14),

                      // Lines Section
                      _buildLinesSection(currentTx, strings),
                      const SizedBox(height: 14),

                      // Review Details Card (if in review or has review info)
                      if (currentTx.state == 'review' ||
                          provider.selectedReview != null) ...[
                        _buildReviewCard(provider.selectedReview, strings),
                        const SizedBox(height: 14),
                      ],

                      // Action Buttons
                      _buildActionButtons(currentTx, strings, isBusy),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    CommercialTransaction tx,
    String Function(String) strings,
  ) {
    final stateColor = _getStateColor(tx.state);
    final stateBg = _getStateBgColor(tx.state);
    final stateIcon = _getStateIcon(tx.state);

    return MujeebCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: _formatStateLabel(tx.state, strings),
                color: stateColor,
                backgroundColor: stateBg,
                icon: stateIcon,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Text(
                  tx.transactionType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Amount Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                strings('total_amount'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${tx.totalAmount?.toStringAsFixed(2) ?? '0.00'} ${tx.currency ?? ''}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: AppColors.borderHairline,
          ),
          const SizedBox(height: 14),

          // Meta Info List
          _buildInfoRow(
            icon: Icons.tag_rounded,
            label: strings('transaction_id'),
            value: tx.id,
            onCopy: () {
              Clipboard.setData(ClipboardData(text: tx.id));
              showAppAlertDialog(
                context,
                message: 'ID copied',
              );
            },
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: strings('customer_id'),
            value: tx.customerId,
          ),
          if (tx.leadId != null && tx.leadId!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.trending_up_rounded,
              label: strings('lead_id_optional'),
              value: tx.leadId!,
            ),
          ],
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.history_rounded,
            label: strings('resource_version'),
            value: tx.resourceVersion,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: strings('created_at'),
            value: tx.createdAt,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    IconData? icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value.length > 24 ? '${value.substring(0, 24)}...' : value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinesSection(
    CommercialTransaction tx,
    String Function(String) strings,
  ) {
    final lines = tx.parsedLines;

    return MujeebCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings('transaction_lines'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Text(
                  '${lines.length} items',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  strings('no_customer_transactions'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ...lines.map((line) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCanvas,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.borderHairline),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.itemNameSnapshot.isNotEmpty
                                ? line.itemNameSnapshot
                                : line.catalogItemId,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${strings('quantity')}: ${line.quantity} × ${line.unitPriceSnapshot?.toStringAsFixed(2) ?? '0.00'} ${line.currency ?? tx.currency ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${((line.unitPriceSnapshot ?? 0.0) * line.quantity).toStringAsFixed(2)} ${line.currency ?? tx.currency ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),

          // Financial Summary Breakdown Box
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        strings('total_amount'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tx.totalAmount?.toStringAsFixed(2) ?? '0.00'} ${tx.currency ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    TransactionReview? review,
    String Function(String) strings,
  ) {
    if (review == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.statusWarningContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.statusWarning.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.statusWarning,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings('transactions_review'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusWarning,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return MujeebCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings('review_details'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: review.status.toUpperCase(),
                color: review.isApproved
                    ? AppColors.statusSuccess
                    : review.isRejected
                    ? AppColors.statusError
                    : AppColors.statusWarning,
                backgroundColor: review.isApproved
                    ? AppColors.statusSuccessContainer
                    : review.isRejected
                    ? AppColors.statusErrorContainer
                    : AppColors.statusWarningContainer,
                fontSize: 11,
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (review.reviewerReference != null) ...[
            _buildInfoRow(
              icon: Icons.verified_user_outlined,
              label: strings('reviewer_reference'),
              value: review.reviewerReference!,
            ),
            const SizedBox(height: 10),
          ],
          if (review.reasonCodes != null &&
              review.reasonCodes!.isNotEmpty) ...[
            Text(
              strings('reason_codes'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: review.reasonCodes!.map((code) {
                return Chip(
                  label: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: AppColors.surfaceContainerLow,
                  side: const BorderSide(color: AppColors.borderHairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    CommercialTransaction tx,
    String Function(String) strings,
    bool isBusy,
  ) {
    final state = tx.state.toLowerCase();

    if (state == 'draft') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                      side: const BorderSide(color: AppColors.borderHairline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isBusy
                        ? null
                        : () async {
                            final updated = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    TransactionDraftFormScreen(
                                      transactionProvider:
                                          widget.transactionProvider,
                                      businessId: widget.businessId,
                                      existingTransaction: tx,
                                    ),
                              ),
                            );
                            if (updated != null) {
                              _loadDetails();
                            }
                          },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(
                      strings('edit_draft'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isBusy
                        ? null
                        : () => _showSubmitReviewDialog(tx),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      strings('submit_for_review'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.statusError,
              ),
              onPressed: isBusy ? null : () => _showCancelDialog(tx),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(
                strings('cancel_transaction'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    if (state == 'review') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusSuccess,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isBusy ? null : () => _showApproveDialog(tx),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      strings('approve_review'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusError,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isBusy ? null : () => _showRejectDialog(tx),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(
                      strings('reject_review'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statusSuccess,
                side: const BorderSide(color: AppColors.statusSuccess),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isBusy ? null : () => _showConfirmDialog(tx),
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: Text(
                strings('confirm_transaction'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.statusError,
              ),
              onPressed: isBusy ? null : () => _showCancelDialog(tx),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(
                strings('cancel_transaction'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    if (state == 'confirmed') {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: AppColors.statusError),
          onPressed: isBusy ? null : () => _showCancelDialog(tx),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: Text(
            strings('cancel_transaction'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
