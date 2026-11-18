import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_ui_widgets.dart';
import '../../../core/models/channel_automation_models.dart';
import '../providers/channel_automation_provider.dart';

/// Screen for viewing AI Decisions, inspecting extracted intents/entities, and requesting human review.
class AIDecisionsScreen extends StatefulWidget {
  final ChannelAutomationProvider channelProvider;
  final String businessId;

  const AIDecisionsScreen({
    super.key,
    required this.channelProvider,
    required this.businessId,
  });

  @override
  State<AIDecisionsScreen> createState() => _AIDecisionsScreenState();
}

class _AIDecisionsScreenState extends State<AIDecisionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await widget.channelProvider.fetchAIDecisions(
      widget.businessId,
      refresh: true,
    );
  }

  void _showErrorDialog(String message, [String? requestId]) {
    showAppAlertDialog(
      context,
      message: message,
      isError: true,
      requestId: requestId,
    );
  }

  void _showSuccessDialog(String message) {
    showAppAlertDialog(
      context,
      message: message,
      isError: false,
    );
  }

  // ===========================================================================
  // Dialog: Request Human Review
  // ===========================================================================
  void _showRequestHumanDialog(AIDecision decision) {
    final reasonController = TextEditingController(
      text: 'Customer requested human supervisor',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        String strings(String key) => AppStrings.get(key, context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          backgroundColor: AppColors.surfaceCanvas,
          surfaceTintColor: Colors.transparent,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.person_pin_outlined,
                  color: AppColors.warningAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings('request_human_review'),
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.headingNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.borderLightBlue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Decision ID: ',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  decision.id,
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.headingNavy,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Intent: ',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                decision.intentBase,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    style: AppTypography.body,
                    decoration: InputDecoration(
                      labelText: strings('human_review_reason'),
                      labelStyle: AppTypography.caption.copyWith(
                        color: AppColors.secondaryText,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.borderLightBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.borderLightBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return strings('required_field');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryText,
              ),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warningAmber,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  final updated = await widget.channelProvider.requestHuman(
                    widget.businessId,
                    decision.id,
                    reasonController.text.trim(),
                  );
                  if (!mounted) return;
                  if (updated != null) {
                    _showSuccessDialog(
                      strings('human_review_requested_success'),
                    );
                  } else if (widget.channelProvider.actionError != null) {
                    _showErrorDialog(
                      widget.channelProvider.actionError!,
                      widget.channelProvider.lastRequestId,
                    );
                  }
                }
              },
              child: Text(
                strings('request_human_review'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDecisionDetailDialog(AIDecision decision) {
    String strings(String key) => AppStrings.get(key, context);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          backgroundColor: AppColors.surfaceCanvas,
          surfaceTintColor: Colors.transparent,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings('ai_decision_detail'),
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.headingNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('ID', decision.id, isLtr: true),
                _buildDetailRow(
                  'Conversation ID',
                  decision.conversationId ?? 'N/A',
                  isLtr: true,
                ),
                _buildDetailRow(
                  strings('lifecycle'),
                  decision.lifecycle ?? 'suggested',
                ),
                _buildDetailRow(strings('intent'), decision.intentBase),
                if (decision.requestedAction != null)
                  _buildDetailRow('Action', decision.requestedAction!),
                if (decision.effectiveCapability != null)
                  _buildDetailRow('Capability', decision.effectiveCapability!),
                _buildDetailRow(
                  strings('requires_human'),
                  decision.requiresHuman ? 'YES' : 'NO',
                  color: decision.requiresHuman
                      ? AppColors.errorRed
                      : AppColors.successGreen,
                ),
                if (decision.entities.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text(
                    strings('entities'),
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.headingNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: decision.entities.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.borderLightBlue),
                        ),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.headingNavy,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (decision.evidenceReferences.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text(
                    'Evidence References:',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.headingNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...decision.evidenceReferences.map(
                    (ref) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $ref',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ],
                if (decision.missingInformation.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text(
                    'Missing Information:',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warningAmber,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...decision.missingInformation.map(
                    (info) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $info',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warningAmber,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warningAmber,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(Icons.person_add, size: 18),
              label: Text(strings('request_human_review')),
              onPressed: () {
                Navigator.pop(ctx);
                _showRequestHumanDialog(decision);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryText,
              ),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? color,
    bool isLtr = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Directionality(
              textDirection: isLtr ? TextDirection.ltr : Directionality.of(context),
              child: Text(
                value,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color ?? AppColors.headingNavy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);

    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings('ai_decisions_title'),
              style: AppTypography.pageTitle.copyWith(fontSize: 18),
            ),
            Text(
              strings('ai_decisions_subtitle'),
              style: AppTypography.caption.copyWith(
                color: AppColors.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.borderLightBlue,
            height: 1,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderLightBlue),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.headingNavy,
                ),
                onPressed: _loadData,
                tooltip: strings('refresh'),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.channelProvider,
        builder: (context, _) {
          final provider = widget.channelProvider;
          if (provider.isLoadingDecisions && provider.aiDecisions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          final totalCount = provider.aiDecisions.length;
          final requiresHumanCount = provider.aiDecisions.where((d) => d.requiresHuman).length;
          final automatedCount = totalCount - requiresHumanCount;

          return Column(
            children: [
              // Summary Stat Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCanvas,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderLightBlue),
                  boxShadow: AppShadows.subtle,
                ),
                child: Row(
                  children: [
                    _buildStatPill(
                      label: 'الكل',
                      count: totalCount,
                      color: AppColors.primaryBlue,
                      icon: Icons.psychology_outlined,
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 28, color: AppColors.borderLightBlue),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      label: 'آلي',
                      count: automatedCount,
                      color: AppColors.successGreen,
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 28, color: AppColors.borderLightBlue),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      label: 'مراجعة',
                      count: requiresHumanCount,
                      color: AppColors.warningAmber,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
              ),

              // Filter Chips: All vs Requires Human
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                    ChoiceChip(
                      label: Text(strings('all_conversations')),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: provider.requiresHumanFilter == null
                            ? Colors.white
                            : AppColors.headingNavy,
                      ),
                      selected: provider.requiresHumanFilter == null,
                      selectedColor: AppColors.primaryBlue,
                      backgroundColor: AppColors.surfaceCanvas,
                      side: BorderSide(
                        color: provider.requiresHumanFilter == null
                            ? AppColors.primaryBlue
                            : AppColors.borderLightBlue,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      onSelected: (_) {
                        provider.setRequiresHumanFilter(null);
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: Icon(
                        Icons.person_pin,
                        size: 16,
                        color: provider.requiresHumanFilter == true
                            ? Colors.white
                            : AppColors.warningAmber,
                      ),
                      label: Text(strings('filter_requires_human')),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: provider.requiresHumanFilter == true
                            ? Colors.white
                            : AppColors.warningAmber,
                      ),
                      selected: provider.requiresHumanFilter == true,
                      selectedColor: AppColors.warningAmber,
                      backgroundColor: AppColors.surfaceCanvas,
                      side: BorderSide(
                        color: provider.requiresHumanFilter == true
                            ? AppColors.warningAmber
                            : AppColors.borderLightBlue,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      onSelected: (_) {
                        provider.setRequiresHumanFilter(true);
                        _loadData();
                      },
                    ),
                  ],
                ),
              ),
            ),

              if (provider.decisionsError != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.decisionsError!,
                          style: AppTypography.caption.copyWith(color: AppColors.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: provider.aiDecisions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.smart_toy_outlined,
                                size: 52,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              strings('no_ai_decisions'),
                              style: AppTypography.cardTitle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.headingNavy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strings('ai_decisions_subtitle'),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primaryBlue,
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          itemCount: provider.aiDecisions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final decision = provider.aiDecisions[index];
                            final lifecycleStr = decision.lifecycle ?? 'suggested';

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCanvas,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: decision.requiresHuman
                                      ? AppColors.warningAmber.withValues(alpha: 0.5)
                                      : AppColors.borderLightBlue,
                                  width: decision.requiresHuman ? 1.5 : 1.0,
                                ),
                                boxShadow: AppShadows.subtle,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                child: InkWell(
                                  onTap: () => _showDecisionDetailDialog(decision),
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row: Bot icon, Intent name, Lifecycle Pill
                                        Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: decision.requiresHuman
                                                    ? AppColors.warningAmber.withValues(alpha: 0.12)
                                                    : AppColors.primaryContainer,
                                                borderRadius: BorderRadius.circular(AppRadius.md),
                                              ),
                                              child: Icon(
                                                decision.requiresHuman
                                                    ? Icons.warning_amber_rounded
                                                    : Icons.psychology_outlined,
                                                size: 20,
                                                color: decision.requiresHuman
                                                    ? AppColors.warningAmber
                                                    : AppColors.primaryBlue,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    decision.intentBase.isNotEmpty
                                                        ? decision.intentBase
                                                        : 'Decision #${decision.id.substring(0, 8)}',
                                                    style: AppTypography.cardTitle.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.headingNavy,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  if (decision.conversationId != null)
                                                    Directionality(
                                                      textDirection: TextDirection.ltr,
                                                      child: Text(
                                                        'Conv: ${decision.conversationId}',
                                                        style: AppTypography.caption.copyWith(
                                                          color: AppColors.secondaryText,
                                                          fontSize: 11,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceContainerLow,
                                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                                border: Border.all(color: AppColors.borderLightBlue),
                                              ),
                                              child: Text(
                                                lifecycleStr.toUpperCase(),
                                                style: AppTypography.caption.copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.secondaryText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Extracted Entities Chips
                                        if (decision.entities.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: decision.entities.entries.map((ent) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceContainerLow,
                                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                                  border: Border.all(color: AppColors.borderLightBlue),
                                                ),
                                                child: Text(
                                                  '${ent.key}: ${ent.value}',
                                                  style: AppTypography.caption.copyWith(
                                                    fontSize: 11,
                                                    color: AppColors.headingNavy,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],

                                        // Action / Capability row if present
                                        if (decision.requestedAction != null || decision.effectiveCapability != null) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              if (decision.requestedAction != null) ...[
                                                const Icon(
                                                  Icons.bolt,
                                                  size: 14,
                                                  color: AppColors.primaryBlue,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  decision.requestedAction!,
                                                  style: AppTypography.caption.copyWith(
                                                    color: AppColors.primaryBlue,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                              ],
                                              if (decision.effectiveCapability != null) ...[
                                                const Icon(
                                                  Icons.tune,
                                                  size: 14,
                                                  color: AppColors.secondaryText,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  decision.effectiveCapability!,
                                                  style: AppTypography.caption.copyWith(
                                                    color: AppColors.secondaryText,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],

                                        const SizedBox(height: 12),
                                        const Divider(height: 1, color: AppColors.borderLightBlue),
                                        const SizedBox(height: 10),

                                        // Footer Row: Requires human badge & Request Human Review button
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            if (decision.requiresHuman)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.warningAmber.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                                  border: Border.all(
                                                    color: AppColors.warningAmber.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.warning_amber_rounded,
                                                      size: 14,
                                                      color: AppColors.warningAmber,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      strings('requires_human'),
                                                      style: AppTypography.caption.copyWith(
                                                        color: AppColors.warningAmber,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.successGreen.withValues(alpha: 0.10),
                                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                                  border: Border.all(
                                                    color: AppColors.successGreen.withValues(alpha: 0.25),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle_outline,
                                                      size: 14,
                                                      color: AppColors.successGreen,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'آلي معتمد',
                                                      style: AppTypography.caption.copyWith(
                                                        color: AppColors.successGreen,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            TextButton.icon(
                                              icon: const Icon(
                                                Icons.person_add,
                                                size: 16,
                                              ),
                                              label: Text(
                                                strings('request_human_review'),
                                              ),
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors.primaryBlue,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                              onPressed: () => _showRequestHumanDialog(decision),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.headingNavy,
                ),
              ),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
