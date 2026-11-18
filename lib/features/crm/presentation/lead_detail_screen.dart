import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/crm_models.dart';
import 'package:mujeeb24_app/features/crm/presentation/customer_detail_screen.dart';
import 'package:mujeeb24_app/features/crm/presentation/lead_form_screen.dart';
import 'package:mujeeb24_app/features/crm/providers/crm_provider.dart';

class LeadDetailScreen extends StatefulWidget {
  final CrmProvider crmProvider;
  final String businessId;
  final String leadId;
  final Lead? initialLead;

  const LeadDetailScreen({
    super.key,
    required this.crmProvider,
    required this.businessId,
    required this.leadId,
    this.initialLead,
  });

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.crmProvider.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    widget.crmProvider.removeListener(_onStateChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _loadData() {
    widget.crmProvider.loadLeadDetail(widget.businessId, widget.leadId);
    widget.crmProvider.loadLeadScores(widget.businessId, widget.leadId);
    widget.crmProvider.loadLeadAttributions(widget.businessId, widget.leadId);
  }

  void _showQualifyDialog(Lead lead) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _QualifyLeadDialog(
        crmProvider: widget.crmProvider,
        businessId: widget.businessId,
        lead: lead,
      ),
    );
  }

  void _showMarkLostDialog(Lead lead) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _MarkLostDialog(
        crmProvider: widget.crmProvider,
        businessId: widget.businessId,
        lead: lead,
      ),
    );
  }

  void _openEditLead(Lead lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeadFormScreen(
          crmProvider: widget.crmProvider,
          businessId: widget.businessId,
          leadToEdit: lead,
        ),
      ),
    );
  }

  void _openCustomerProfile(String customerId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(
          crmProvider: widget.crmProvider,
          businessId: widget.businessId,
          customerId: customerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final provider = widget.crmProvider;
    final lead = provider.selectedLead ?? widget.initialLead;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          lead != null
              ? 'Lead: ${lead.id.length > 8 ? lead.id.substring(0, 8) : lead.id}'
              : strings('lead_details'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (lead != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: strings('edit_customer'),
              onPressed: () => _openEditLead(lead),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: strings('refresh'),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: strings('tab_overview')),
            Tab(
              text: '${strings('tab_scores')} (${provider.leadScores.length})',
            ),
            Tab(
              text:
                  '${strings('tab_attributions')} (${provider.leadAttributions.length})',
            ),
          ],
        ),
      ),
      body: lead == null && provider.isLoadingLeadDetail
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(lead, strings),
                _buildScoresTab(provider, strings),
                _buildAttributionsTab(provider, strings),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(Lead? lead, String Function(String) strings) {
    if (lead == null) {
      return Center(
        child: Text(
          strings('no_leads_found'),
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final isQualified = lead.status == 'qualified';
    final isLost = lead.status == 'lost';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lead Main Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings('lead_status'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isQualified
                            ? AppColors.statusSuccessContainer
                            : isLost
                            ? AppColors.statusErrorContainer
                            : AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lead.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isQualified
                              ? AppColors.statusSuccess
                              : isLost
                              ? AppColors.statusError
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (lead.scoreBand != null || lead.currentScore != null)
                  Row(
                    children: [
                      if (lead.scoreBand != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCanvas,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderHairline),
                          ),
                          child: Text(
                            'BAND: ${lead.scoreBand!.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (lead.currentScore != null)
                        Text(
                          'Score: ${lead.currentScore!.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                const Divider(height: 24),
                // Quick Action Buttons (Qualify & Mark Lost)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.verified_rounded,
                          color: AppColors.statusSuccess,
                          size: 18,
                        ),
                        label: Text(
                          strings('qualify_lead'),
                          style: const TextStyle(
                            color: AppColors.statusSuccess,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.statusSuccess,
                          ),
                        ),
                        onPressed: () => _showQualifyDialog(lead),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.statusError,
                          size: 18,
                        ),
                        label: Text(
                          strings('mark_lead_lost'),
                          style: const TextStyle(
                            color: AppColors.statusError,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.statusError),
                        ),
                        onPressed: () => _showMarkLostDialog(lead),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Associated Customer Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_pin_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings('customer'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        lead.customerId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _openCustomerProfile(lead.customerId),
                  child: Text(strings('view_customer')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Technical Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetaRow('Lead ID', lead.id),
                const Divider(height: 16),
                _buildMetaRow('Created By', lead.createdBy),
                const Divider(height: 16),
                _buildMetaRow('Version', lead.resourceVersion),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        Text(
          value.length > 20 ? '${value.substring(0, 18)}...' : value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildScoresTab(
    CrmProvider provider,
    String Function(String) strings,
  ) {
    if (provider.isLoadingLeadScores) {
      return const Center(child: CircularProgressIndicator());
    }

    final scores = provider.leadScores;
    if (scores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                strings('no_scores'),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: scores.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sc = scores[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCanvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: ${sc.value.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'BAND: ${sc.band.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Calculated: ${sc.calculatedAt}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              if (sc.factors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Factors: ${sc.factors.toString()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttributionsTab(
    CrmProvider provider,
    String Function(String) strings,
  ) {
    if (provider.isLoadingLeadAttributions) {
      return const Center(child: CircularProgressIndicator());
    }

    final attributions = provider.leadAttributions;
    if (attributions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hub_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                strings('no_attributions'),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: attributions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final attr = attributions[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCanvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    attr.sourceChannel != null
                        ? 'Channel: ${attr.sourceChannel!.toUpperCase()}'
                        : 'Channel: Direct',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    attr.capturedAt,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (attr.sourceConversationId != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Source Conv: ${attr.sourceConversationId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              if (attr.catalogItemId != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Catalog Item: ${attr.catalogItemId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _QualifyLeadDialog extends StatefulWidget {
  final CrmProvider crmProvider;
  final String businessId;
  final Lead lead;

  const _QualifyLeadDialog({
    required this.crmProvider,
    required this.businessId,
    required this.lead,
  });

  @override
  State<_QualifyLeadDialog> createState() => _QualifyLeadDialogState();
}

class _QualifyLeadDialogState extends State<_QualifyLeadDialog> {
  final _reasonController = TextEditingController();
  final _evidenceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    List<String>? evidence;
    if (_evidenceController.text.trim().isNotEmpty) {
      evidence = _evidenceController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final result = await widget.crmProvider.qualifyLead(
      widget.businessId,
      widget.lead.id,
      reason: _reasonController.text.trim().isNotEmpty
          ? _reasonController.text.trim()
          : null,
      evidenceReferences: evidence,
      ifMatch: widget.lead.resourceVersion,
    );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);

    return AlertDialog(
      title: Text(strings('qualify_lead')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: strings('qualification_reason'),
                hintText: 'e.g. Budget confirmed, decision maker agreed',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _evidenceController,
              decoration: InputDecoration(
                labelText: strings('evidence_references'),
                hintText: 'e.g. conv-123, call-456',
                border: const OutlineInputBorder(),
              ),
            ),
            if (widget.crmProvider.actionError != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.crmProvider.actionError!,
                style: const TextStyle(
                  color: AppColors.statusError,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusSuccess,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(strings('qualify_lead')),
        ),
      ],
    );
  }
}

class _MarkLostDialog extends StatefulWidget {
  final CrmProvider crmProvider;
  final String businessId;
  final Lead lead;

  const _MarkLostDialog({
    required this.crmProvider,
    required this.businessId,
    required this.lead,
  });

  @override
  State<_MarkLostDialog> createState() => _MarkLostDialogState();
}

class _MarkLostDialogState extends State<_MarkLostDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await widget.crmProvider.markLeadLost(
      widget.businessId,
      widget.lead.id,
      _reasonController.text.trim(),
      ifMatch: widget.lead.resourceVersion,
    );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);

    return AlertDialog(
      title: Text(strings('mark_lead_lost')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: strings('lost_reason'),
                  hintText: 'e.g. Budget constraints, chose competitor',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => v == null || v.trim().isEmpty
                    ? strings('required_field')
                    : null,
              ),
              if (widget.crmProvider.actionError != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.crmProvider.actionError!,
                  style: const TextStyle(
                    color: AppColors.statusError,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusError,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(strings('mark_lead_lost')),
        ),
      ],
    );
  }
}
