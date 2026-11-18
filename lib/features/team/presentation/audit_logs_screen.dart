import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/team_audit_models.dart';
import '../providers/team_audit_provider.dart';

class AuditLogsScreen extends StatefulWidget {
  final TeamAuditProvider provider;
  final String businessId;

  const AuditLogsScreen({
    super.key,
    required this.provider,
    required this.businessId,
  });

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.provider.fetchAuditEvents(widget.businessId, refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getActionColor(String action) {
    if (action.contains('create') || action.contains('accept')) {
      return AppColors.statusSuccess;
    } else if (action.contains('delete') ||
        action.contains('revoke') ||
        action.contains('purge')) {
      return AppColors.statusError;
    } else if (action.contains('update') ||
        action.contains('patch') ||
        action.contains('resend')) {
      return AppColors.primary;
    }
    return AppColors.statusWarning;
  }

  void _showEventDetailSheet(AuditEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getActionColor(event.action)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.action,
                      style: TextStyle(
                        color: _getActionColor(event.action),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailTile(
                icon: Icons.access_time,
                title: AppStrings.get('occurred_at', ctx),
                value: event.occurredAt,
              ),
              _buildDetailTile(
                icon: Icons.person_outline,
                title: AppStrings.get('actor_type', ctx),
                value:
                    '${event.actorType}${event.actorReference != null ? ' (${event.actorReference})' : ''}',
              ),
              _buildDetailTile(
                icon: Icons.category_outlined,
                title: AppStrings.get('resource_type', ctx),
                value:
                    '${event.resourceType}${event.resourceId != null ? ' [ID: ${event.resourceId}]' : ''}',
              ),
              _buildDetailTile(
                icon: Icons.fingerprint,
                title: 'Event ID',
                value: event.id,
              ),
              _buildDetailTile(
                icon: Icons.business_outlined,
                title: 'Business ID',
                value: event.businessId,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.get('audit_metadata', ctx),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLightBlue),
                ),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(event.metadata),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceCanvas,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(AppStrings.get('audit_logs_title', context),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            actions: [
              IconButton(
                key: const Key('btn_refresh_audit'),
                icon: const Icon(Icons.refresh),
                onPressed: () => widget.provider.fetchAuditEvents(
                  widget.businessId,
                  refresh: true,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  key: const Key('input_search_audit_action'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppStrings.get('filter_by_action', context),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.provider.setAuditFilters(action: 'all');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    widget.provider.setAuditFilters(
                      action: val.trim().isEmpty ? 'all' : val.trim(),
                    );
                    widget.provider.fetchAuditEvents(
                      widget.businessId,
                      refresh: true,
                    );
                  },
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    FilterChip(
                      key: const Key('chip_actor_all'),
                      label: const Text('All Actors'),
                      selected: widget.provider.actorTypeFilter == 'all',
                      onSelected: (_) {
                        widget.provider.setAuditFilters(actorType: 'all');
                        widget.provider.fetchAuditEvents(
                          widget.businessId,
                          refresh: true,
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      key: const Key('chip_actor_principal'),
                      label: const Text('Principal'),
                      selected: widget.provider.actorTypeFilter == 'principal',
                      onSelected: (_) {
                        widget.provider.setAuditFilters(actorType: 'principal');
                        widget.provider.fetchAuditEvents(
                          widget.businessId,
                          refresh: true,
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      key: const Key('chip_actor_system'),
                      label: const Text('System'),
                      selected: widget.provider.actorTypeFilter == 'system',
                      onSelected: (_) {
                        widget.provider.setAuditFilters(actorType: 'system');
                        widget.provider.fetchAuditEvents(
                          widget.businessId,
                          refresh: true,
                        );
                      },
                    ),
                    const VerticalDivider(),
                    FilterChip(
                      key: const Key('chip_res_all'),
                      label: const Text('All Resources'),
                      selected: widget.provider.resourceTypeFilter == 'all',
                      onSelected: (_) {
                        widget.provider.setAuditFilters(resourceType: 'all');
                        widget.provider.fetchAuditEvents(
                          widget.businessId,
                          refresh: true,
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      key: const Key('chip_res_team'),
                      label: const Text('Team / Member'),
                      selected:
                          widget.provider.resourceTypeFilter == 'team_member',
                      onSelected: (_) {
                        widget.provider.setAuditFilters(
                          resourceType: 'team_member',
                        );
                        widget.provider.fetchAuditEvents(
                          widget.businessId,
                          refresh: true,
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      key: const Key('chip_res_catalog'),
                      label: const Text('Catalog'),
                      selected:
                          widget.provider.resourceTypeFilter == 'catalog_item',
                      onSelected: (_) {
                        widget.provider.setAuditFilters(
                          resourceType: 'catalog_item',
                        );
                        widget.provider.fetchAuditEvents(
                          widget.businessId,
                          refresh: true,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildAuditList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuditList() {
    if (widget.provider.isLoadingAuditEvents &&
        widget.provider.auditEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.provider.auditEventsError != null &&
        widget.provider.auditEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.statusError,
            ),
            const SizedBox(height: 12),
            Text(
              widget.provider.auditEventsError!,
              style: const TextStyle(color: AppColors.statusError),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => widget.provider.fetchAuditEvents(
                widget.businessId,
                refresh: true,
              ),
              child: Text(AppStrings.get('retry', context)),
            ),
          ],
        ),
      );
    }

    final events = widget.provider.auditEvents;

    if (events.isEmpty) {
      return Center(
        child: Text(
          AppStrings.get('no_audit_events', context),
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final ev = events[idx];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCanvas,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLightBlue),
            boxShadow: AppShadows.card,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => _showEventDetailSheet(ev),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getActionColor(ev.action)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ev.action,
                          style: TextStyle(
                            color: _getActionColor(ev.action),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        ev.occurredAt,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ev.actorType}${ev.actorReference != null ? ' (${ev.actorReference})' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ev.resourceType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
