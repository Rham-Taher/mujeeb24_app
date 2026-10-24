import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

class BusinessSettingsTab extends StatefulWidget {
  final MerchantProvider merchantProvider;
  final Business? currentBusiness;
  final VoidCallback onSwitchBusiness;
  final VoidCallback onLogout;
  final VoidCallback onToggleLanguage;
  final VoidCallback? onNavigateToTeam;
  final VoidCallback? onNavigateToAuditLogs;
  final VoidCallback? onNavigateToPlatform;
  final VoidCallback? onNavigateToSubscription;
  final VoidCallback? onNavigateToPlans;

  const BusinessSettingsTab({
    super.key,
    required this.merchantProvider,
    required this.currentBusiness,
    required this.onSwitchBusiness,
    required this.onLogout,
    required this.onToggleLanguage,
    this.onNavigateToTeam,
    this.onNavigateToAuditLogs,
    this.onNavigateToPlatform,
    this.onNavigateToSubscription,
    this.onNavigateToPlans,
  });

  @override
  State<BusinessSettingsTab> createState() => _BusinessSettingsTabState();
}

class _BusinessSettingsTabState extends State<BusinessSettingsTab> {
  // Business Profile controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _localeController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();

  // Policy state
  String _aiMode = 'suggest';
  bool _defaultHumanReview = false;
  bool _allowAutoReply = false;
  bool _allowAutoLeadCreation = false;
  bool _allowAutoTransactionDraft = false;
  bool _allowAutoConfirmation = false;

  @override
  void initState() {
    super.initState();
    widget.merchantProvider.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    widget.merchantProvider.removeListener(_onStateChange);
    _nameController.dispose();
    _currencyController.dispose();
    _localeController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAll() async {
    final businessId = widget.currentBusiness?.id;
    if (businessId != null && businessId.isNotEmpty) {
      await Future.wait([
        widget.merchantProvider.loadBusinessProfile(businessId),
        widget.merchantProvider.loadBusinessPolicy(businessId),
      ]);

      if (mounted) {
        _syncControllers();
      }
    }
  }

  void _syncControllers() {
    final profile =
        widget.merchantProvider.businessProfile ?? widget.currentBusiness;
    final policy = widget.merchantProvider.businessPolicy;

    if (profile != null) {
      _nameController.text = profile.name;
      _currencyController.text = profile.defaultCurrency ?? '';
      _localeController.text = profile.locale ?? '';
      _timezoneController.text = profile.timezone ?? '';
    }

    if (policy != null) {
      _aiMode = policy.aiMode;
      _defaultHumanReview = policy.defaultHumanReview;
      _allowAutoReply = policy.allowAutoReply;
      _allowAutoLeadCreation = policy.allowAutoLeadCreation;
      _allowAutoTransactionDraft = policy.allowAutoTransactionDraft;
      _allowAutoConfirmation = policy.allowAutoConfirmation;
    }

    setState(() {});
  }

  Future<void> _saveProfile(String Function(String) strings) async {
    final businessId = widget.currentBusiness?.id;
    if (businessId == null) return;

    final success = await widget.merchantProvider.updateBusinessProfile(
      businessId: businessId,
      name: _nameController.text.trim(),
      defaultCurrency: _currencyController.text.trim(),
      locale: _localeController.text.trim(),
      timezone: _timezoneController.text.trim(),
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings('profile_updated')),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
    }
  }

  Future<void> _savePolicy(String Function(String) strings) async {
    final businessId = widget.currentBusiness?.id;
    if (businessId == null) return;

    final success = await widget.merchantProvider.updateBusinessPolicy(
      businessId: businessId,
      aiMode: _aiMode,
      defaultHumanReview: _defaultHumanReview,
      allowAutoReply: _allowAutoReply,
      allowAutoLeadCreation: _allowAutoLeadCreation,
      allowAutoTransactionDraft: _allowAutoTransactionDraft,
      allowAutoConfirmation: _allowAutoConfirmation,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings('policy_updated')),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final provider = widget.merchantProvider;
    final isActionLoading = provider.isPerformingAction;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error Display
          if (provider.businessError != null || provider.policyError != null)
            _buildErrorCard(
              provider.businessError ?? provider.policyError!,
              provider.lastRequestId,
              strings,
            ),

          // Business Profile Section
          _buildSectionHeader(strings('business_profile'), Icons.store_rounded),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: strings('business_name'),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _currencyController,
                          decoration: InputDecoration(
                            labelText: strings('default_currency'),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _localeController,
                          decoration: InputDecoration(
                            labelText: strings('locale'),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _timezoneController,
                    decoration: InputDecoration(
                      labelText: strings('timezone'),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isActionLoading
                        ? null
                        : () => _saveProfile(strings),
                    child: isActionLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(strings('save_changes')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // AI Policy Section
          _buildSectionHeader(
            strings('ai_policy_title'),
            Icons.smart_toy_outlined,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AI Mode selector
                  DropdownButtonFormField<String>(
                    initialValue: ['auto', 'suggest', 'off'].contains(_aiMode)
                        ? _aiMode
                        : 'suggest',
                    decoration: InputDecoration(
                      labelText: strings('ai_mode'),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'auto',
                        child: Text('تلقائي كامل (auto)'),
                      ),
                      DropdownMenuItem(
                        value: 'suggest',
                        child: Text('اقتراح للموظف (suggest)'),
                      ),
                      DropdownMenuItem(value: 'off', child: Text('معطل (off)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _aiMode = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Policy Switches
                  SwitchListTile(
                    title: Text(
                      strings('default_human_review'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: _defaultHumanReview,
                    onChanged: (val) =>
                        setState(() => _defaultHumanReview = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      strings('allow_auto_reply'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: _allowAutoReply,
                    onChanged: (val) => setState(() => _allowAutoReply = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      strings('allow_auto_lead'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: _allowAutoLeadCreation,
                    onChanged: (val) =>
                        setState(() => _allowAutoLeadCreation = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      strings('allow_auto_tx_draft'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: _allowAutoTransactionDraft,
                    onChanged: (val) =>
                        setState(() => _allowAutoTransactionDraft = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      strings('allow_auto_confirm'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: _allowAutoConfirmation,
                    onChanged: (val) =>
                        setState(() => _allowAutoConfirmation = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isActionLoading
                        ? null
                        : () => _savePolicy(strings),
                    child: isActionLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(strings('save_changes')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Team & Audit Section
          if (widget.onNavigateToTeam != null ||
              widget.onNavigateToAuditLogs != null) ...[
            _buildSectionHeader(
              strings('team_and_audit'),
              Icons.groups_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  if (widget.onNavigateToTeam != null)
                    ListTile(
                      key: const Key('tile_team_management'),
                      leading: const Icon(
                        Icons.people_alt_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(strings('team_members_title')),
                      subtitle: Text(strings('team_members_subtitle')),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: widget.onNavigateToTeam,
                    ),
                  if (widget.onNavigateToTeam != null &&
                      widget.onNavigateToAuditLogs != null)
                    const Divider(height: 1),
                  if (widget.onNavigateToAuditLogs != null)
                    ListTile(
                      key: const Key('tile_audit_logs'),
                      leading: const Icon(
                        Icons.history_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(strings('audit_logs_title')),
                      subtitle: Text(strings('audit_logs_subtitle')),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: widget.onNavigateToAuditLogs,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Platform Administration Section (Visible to Platform Admins)
          if (widget.onNavigateToPlatform != null) ...[
            _buildSectionHeader(
              strings('platform_title'),
              Icons.admin_panel_settings_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                key: const Key('tile_platform_administration'),
                leading: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primary,
                ),
                title: Text(strings('platform_title')),
                subtitle: Text(strings('platform_subtitle')),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: widget.onNavigateToPlatform,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Subscription & Billing Section
          if (widget.onNavigateToSubscription != null ||
              widget.onNavigateToPlans != null) ...[
            _buildSectionHeader(
              'الاشتراك والفوترة',
              Icons.workspace_premium_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  if (widget.onNavigateToSubscription != null)
                    ListTile(
                      key: const Key('tile_subscription_management'),
                      leading: const Icon(
                        Icons.donut_large_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text('الاشتراك الحالي ومتابعة الحصص'),
                      subtitle: const Text(
                        'عرض باقة المتجر واستهلاك ردود الذكاء الاصطناعي والقنوات',
                      ),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: widget.onNavigateToSubscription,
                    ),
                  if (widget.onNavigateToPlans != null) ...[
                    if (widget.onNavigateToSubscription != null)
                      const Divider(height: 1),
                    ListTile(
                      key: const Key('tile_subscription_plans'),
                      leading: const Icon(
                        Icons.view_carousel_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text('ترقية الباقة ومقارنة الأسعار'),
                      subtitle: const Text(
                        'مقارنة باقات بداية، متجر، نمو، احتراف، وأعمال',
                      ),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: widget.onNavigateToPlans,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Workspace & Account Actions
          _buildSectionHeader(
            'الحساب ومساحة العمل',
            Icons.manage_accounts_rounded,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.language_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(strings('switch_language')),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: widget.onToggleLanguage,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(strings('select_business')),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: widget.onSwitchBusiness,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.statusError,
                  ),
                  title: Text(
                    strings('logout'),
                    style: const TextStyle(
                      color: AppColors.statusError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: widget.onLogout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
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
      margin: const EdgeInsets.only(bottom: 16),
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
              TextButton(onPressed: _loadAll, child: Text(strings('retry'))),
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
