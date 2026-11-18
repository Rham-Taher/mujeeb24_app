import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_ui_widgets.dart';
import '../../../core/models/channel_automation_models.dart';
import '../providers/channel_automation_provider.dart';

/// Screen for managing Inbound Automation Rules.
class AutomationRulesScreen extends StatefulWidget {
  final ChannelAutomationProvider channelProvider;
  final String businessId;

  const AutomationRulesScreen({
    super.key,
    required this.channelProvider,
    required this.businessId,
  });

  @override
  State<AutomationRulesScreen> createState() => _AutomationRulesScreenState();
}

class _AutomationRulesScreenState extends State<AutomationRulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await widget.channelProvider.fetchAutomationRules(
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
  // Dialog: Create Automation Rule
  // ===========================================================================
  void _showCreateRuleDialog() {
    final nameController = TextEditingController();
    final keywordController = TextEditingController();
    final actionParamController = TextEditingController();
    String selectedAction = 'add_label';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String strings(String key) => AppStrings.get(key, context);
            return AlertDialog(
              title: Text(strings('create_rule')),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: '${strings('rule_name')} *',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return strings('required_field');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: keywordController,
                        decoration: const InputDecoration(
                          labelText: 'Condition: Keyword filter (optional)',
                          hintText: 'e.g. refund, urgent, pricing',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedAction,
                        decoration: InputDecoration(
                          labelText: strings('rule_action'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'add_label',
                            child: Text(strings('action_add_label')),
                          ),
                          DropdownMenuItem(
                            value: 'set_priority',
                            child: Text(strings('action_set_priority')),
                          ),
                          DropdownMenuItem(
                            value: 'assign_human',
                            child: Text(strings('action_assign_human')),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedAction = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: actionParamController,
                        decoration: InputDecoration(
                          labelText: selectedAction == 'add_label'
                              ? 'Label Name (e.g. VIP, Urgent)'
                              : selectedAction == 'set_priority'
                              ? 'Priority (e.g. 1, 2, high)'
                              : 'Assignee User ID',
                          border: const OutlineInputBorder(),
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
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(ctx);
                      final conditions = <String, dynamic>{};
                      if (keywordController.text.trim().isNotEmpty) {
                        conditions['keyword'] = keywordController.text.trim();
                      }

                      final req = CreateAutomationRuleRequest(
                        name: nameController.text.trim(),
                        conditions: conditions,
                        actionKind: selectedAction,
                        actionPayload: {
                          if (selectedAction == 'add_label')
                            'label': actionParamController.text.trim(),
                          if (selectedAction == 'set_priority')
                            'priority': actionParamController.text.trim(),
                          if (selectedAction == 'assign_human')
                            'user_id': actionParamController.text.trim(),
                        },
                      );

                      final created = await widget.channelProvider.createRule(
                        widget.businessId,
                        req,
                      );
                      if (!mounted) return;
                      if (created != null) {
                        _showSuccessDialog(strings('rule_created_success'));
                      } else if (widget.channelProvider.actionError != null) {
                        _showErrorDialog(
                          widget.channelProvider.actionError!,
                          widget.channelProvider.lastRequestId,
                        );
                      }
                    }
                  },
                  child: Text(strings('create_rule')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // Dialog: Edit Automation Rule
  // ===========================================================================
  void _showEditRuleDialog(AutomationRule rule) {
    final nameController = TextEditingController(text: rule.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        String strings(String key) => AppStrings.get(key, context);
        return AlertDialog(
          title: Text(strings('edit_rule')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: strings('rule_name'),
                    border: const OutlineInputBorder(),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  final updated = await widget.channelProvider.updateRule(
                    widget.businessId,
                    rule.id,
                    UpdateAutomationRuleRequest(
                      name: nameController.text.trim(),
                    ),
                    ifMatch: rule.resourceVersion,
                  );
                  if (!mounted) return;
                  if (updated != null) {
                    _showSuccessDialog(strings('rule_updated_success'));
                  } else if (widget.channelProvider.actionError != null) {
                    _showErrorDialog(
                      widget.channelProvider.actionError!,
                      widget.channelProvider.lastRequestId,
                    );
                  }
                }
              },
              child: Text(strings('edit_rule')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleRuleStatus(AutomationRule rule) async {
    final newStatus = rule.status == 'active' ? 'disabled' : 'active';
    String strings(String key) => AppStrings.get(key, context);

    final updated = await widget.channelProvider.updateRule(
      widget.businessId,
      rule.id,
      UpdateAutomationRuleRequest(status: newStatus),
      ifMatch: rule.resourceVersion,
    );

    if (!mounted) return;
    if (updated != null) {
      _showSuccessDialog(strings('rule_updated_success'));
    } else if (widget.channelProvider.actionError != null) {
      _showErrorDialog(
        widget.channelProvider.actionError!,
        widget.channelProvider.lastRequestId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings('automation_rules_title')),
        backgroundColor: AppColors.surfaceCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: strings('refresh'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.channelProvider,
        builder: (context, _) {
          final provider = widget.channelProvider;
          if (provider.isLoadingRules && provider.automationRules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(strings('all_conversations')),
                      selected: provider.ruleStatusFilter == 'all',
                      onSelected: (_) {
                        provider.setRuleStatusFilter('all');
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(strings('rule_active')),
                      selected: provider.ruleStatusFilter == 'active',
                      onSelected: (_) {
                        provider.setRuleStatusFilter('active');
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(strings('rule_disabled')),
                      selected: provider.ruleStatusFilter == 'disabled',
                      onSelected: (_) {
                        provider.setRuleStatusFilter('disabled');
                        _loadData();
                      },
                    ),
                  ],
                ),
              ),

              if (provider.rulesError != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    provider.rulesError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),

              Expanded(
                child: provider.automationRules.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.alt_route,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              strings('no_automation_rules'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              onPressed: _showCreateRuleDialog,
                              icon: const Icon(Icons.add),
                              label: Text(strings('create_rule')),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.automationRules.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final rule = provider.automationRules[index];
                            final isActive = rule.status == 'active';

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCanvas,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.primary.withValues(alpha: 0.35)
                                      : AppColors.borderLightBlue,
                                  width: isActive ? 1.5 : 1.0,
                                ),
                                boxShadow: AppShadows.card,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            rule.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                            color: AppColors.textSecondary,
                                          ),
                                          onPressed: () =>
                                              _showEditRuleDialog(rule),
                                        ),
                                        Switch(
                                          value: isActive,
                                          activeTrackColor: AppColors.primary,
                                          onChanged: (_) =>
                                              _toggleRuleStatus(rule),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Trigger: ${rule.triggerKind.isNotEmpty ? rule.triggerKind : 'inbound_message'}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (rule.conditions.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Conditions: ${rule.conditions}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(AppRadius.full),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Text(
                                        '${rule.actionKind}: ${rule.actionPayload}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showCreateRuleDialog,
        icon: const Icon(Icons.add),
        label: Text(strings('create_rule')),
      ),
    );
  }
}
