import 'package:flutter/material.dart';
import '../../../core/widgets/common_ui_widgets.dart';
import 'package:flutter/services.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/merchant_editor_dialog.dart';
import '../../../core/models/team_audit_models.dart';
import '../../../core/services/invitation_link_service.dart';
import '../../../core/team/team_invitation_presentation.dart';
import '../providers/team_audit_provider.dart';

class TeamScreen extends StatefulWidget {
  final TeamAuditProvider provider;
  final String businessId;

  const TeamScreen({
    super.key,
    required this.provider,
    required this.businessId,
  });

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    widget.provider.fetchMembers(widget.businessId, refresh: true);
    widget.provider.fetchInvitations(widget.businessId, refresh: true);
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case TeamRoles.owner:
        return const Color(0xFF6B21A8); // Deep purple
      case TeamRoles.admin:
        return AppColors.statusError;
      case TeamRoles.manager:
        return AppColors.primary;
      case TeamRoles.agent:
        return const Color(0xFF0D9488); // Teal
      case TeamRoles.analyst:
        return const Color(0xFF2563EB); // Blue
      case TeamRoles.viewer:
      default:
        return AppColors.textMuted;
    }
  }

  String _getRoleLabel(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case TeamRoles.owner:
        return AppStrings.get('role_owner', context);
      case TeamRoles.admin:
        return AppStrings.get('role_admin', context);
      case TeamRoles.manager:
        return AppStrings.get('role_manager', context);
      case TeamRoles.agent:
        return AppStrings.get('role_agent', context);
      case TeamRoles.analyst:
        return AppStrings.get('role_analyst', context);
      case TeamRoles.viewer:
        return AppStrings.get('role_viewer', context);
      default:
        return role;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'accepted':
        return AppColors.statusSuccess;
      case 'revoked':
      case 'expired':
        return AppColors.statusError;
      case 'pending':
        return AppColors.statusWarning;
      default:
        return AppColors.textMuted;
    }
  }

  String _getStatusLabel(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppStrings.get('status_active', context);
      case 'revoked':
        return AppStrings.get('status_revoked', context);
      case 'pending':
        return AppStrings.get('status_pending', context);
      case 'accepted':
        return AppStrings.get('status_accepted', context);
      case 'expired':
        return AppStrings.get('status_expired', context);
      default:
        return status;
    }
  }

  void _showTokenDialog(TeamInvitationCreated created) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.statusSuccess),
            const SizedBox(width: 8),
            Text(AppStrings.get('invitation_token_modal_title', ctx)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('invitation_token_modal_desc', ctx),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: SelectableText(
                InvitationLinkService.buildWebInvitationUrl(
                  created.acceptanceToken),
                style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(
              created.acceptanceToken,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppStrings.get('member_email', ctx)}: ${created.invitation.email}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            Text(
              '${AppStrings.get('member_role', ctx)}: ${_getRoleLabel(ctx, created.invitation.role)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            key: const Key('btn_share_invitation'),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('مشاركة الدعوة'),
            onPressed: () async {
              final shared = await InvitationLinkService.shareInvitation(
                token: created.acceptanceToken,
                businessName: created.invitation.businessName,
                role: _getRoleLabel(ctx, created.invitation.role),
                email: created.invitation.email,
              );
              if (!shared && mounted) {
                showAppAlertDialog(
                  context,
                  message: 'يمكنك نسخ الرابط ومشاركته يدويًا.',
                );
              }
            },
          ),
          TextButton.icon(
            key: const Key('btn_copy_invitation_url'),
            icon: const Icon(Icons.link_outlined, size: 18),
            label: const Text('نسخ رابط الدعوة'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                text: InvitationLinkService.buildWebInvitationUrl(
                  created.acceptanceToken)));
              if (!mounted) return;
              showAppAlertDialog(
                context,
                message: 'تم نسخ رابط الدعوة',
              );
            },
          ),
          TextButton.icon(
            key: const Key('btn_copy_token'),
            icon: const Icon(Icons.copy, size: 16),
            label: Text(AppStrings.get('copy_token', ctx)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: created.acceptanceToken));
              showAppAlertDialog(
                context,
                message: AppStrings.get('token_copied', ctx),
              );
            },
          ),
          ElevatedButton(
            key: const Key('btn_close_token_modal'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('close', ctx)),
          ),
        ],
      ),
    );
  }

  void _showInviteMemberDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final expiryController = TextEditingController(text: '72');
    String selectedRole = TeamRoles.agent;
    List<String> selectedPermissions =
        TeamRoles.defaultPermissionsForRole(TeamRoles.agent);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => MerchantEditorDialog(
          title: Text(AppStrings.get('invite_member_title', dialogCtx)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('input_invite_email'),
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('member_email', dialogCtx),
                      hintText: 'user@business.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('input_invite_name'),
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText:
                          AppStrings.get('member_display_name', dialogCtx),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('select_invite_role'),
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('member_role', dialogCtx),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    items: TeamRoles.assignableRoles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(_getRoleLabel(dialogCtx, r)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedRole = val;
                          selectedPermissions =
                              TeamRoles.defaultPermissionsForRole(val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('input_invite_expiry'),
                    controller: expiryController,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('expires_in_hours', dialogCtx),
                      prefixIcon: const Icon(Icons.timer_outlined),
                      helperText: 'من ساعة واحدة إلى 720 ساعة',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.get('member_permissions', dialogCtx),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            if (selectedPermissions.length ==
                                TeamPermissions.all.length) {
                              selectedPermissions.clear();
                            } else {
                              selectedPermissions =
                                  List.from(TeamPermissions.all);
                            }
                          });
                        },
                        child: Text(
                          selectedPermissions.length ==
                                  TeamPermissions.all.length
                              ? 'إلغاء تحديد الكل'
                              : 'تحديد الكل',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderHairline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: TeamPermissions.all.length,
                      itemBuilder: (context, idx) {
                        final perm = TeamPermissions.all[idx];
                        final isChecked = selectedPermissions.contains(perm);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(perm, style: const TextStyle(fontSize: 12)),
                          value: isChecked,
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedPermissions.add(perm);
                              } else {
                                selectedPermissions.remove(perm);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.get('cancel', dialogCtx)),
            ),
            ElevatedButton(
              key: const Key('btn_submit_invite'),
              onPressed: () async {
                final email = emailController.text.trim();
                final name = nameController.text.trim();
                final expiry = int.tryParse(expiryController.text.trim());

                if (email.isEmpty || name.isEmpty) {
                  showAppAlertDialog(
                    context,
                    message: AppStrings.get('required_field', dialogCtx),
                    isError: true,
                  );
                  return;
                }

                if (expiry == null || expiry < 1 || expiry > 720) {
                  showAppAlertDialog(
                    context,
                    message: 'مدة الدعوة يجب أن تكون بين 1 و720 ساعة.',
                    isError: true,
                  );
                  return;
                }
                if (selectedPermissions.isEmpty) {
                  showAppAlertDialog(
                    context,
                    message: 'At least one permission is required',
                    isError: true,
                  );
                  return;
                }

                Navigator.of(ctx).pop();

                final created = await widget.provider.createInvitation(
                  businessId: widget.businessId,
                  request: CreateTeamInvitationRequest(
                    email: email,
                    displayName: name,
                    role: selectedRole,
                    permissions: selectedPermissions,
                    expiresInHours: expiry,
                  ),
                );

                if (created != null && mounted) {
                  _showTokenDialog(created);
                } else if (mounted && widget.provider.actionError != null) {
                  showAppAlertDialog(
                    context,
                    message: widget.provider.actionError!,
                    isError: true,
                  );
                }
              },
              child: Text(AppStrings.get('send_invitation', dialogCtx)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAccessDialog(TeamMember member) {
    if (member.isOwner) {
      showAppAlertDialog(
        context,
        message: AppStrings.get('cannot_revoke_owner', context),
        isError: true,
      );
      return;
    }

    String selectedRole = member.role;
    if (!TeamRoles.assignableRoles.contains(selectedRole)) {
      selectedRole = TeamRoles.agent;
    }
    List<String> selectedPermissions = List.from(member.permissions);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(AppStrings.get('edit_member_access', dialogCtx)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${member.displayName} (${member.email})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('select_edit_role'),
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('member_role', dialogCtx),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    items: TeamRoles.assignableRoles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(_getRoleLabel(dialogCtx, r)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedRole = val;
                          selectedPermissions =
                              TeamRoles.defaultPermissionsForRole(val);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get('member_permissions', dialogCtx),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderHairline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: TeamPermissions.all.length,
                      itemBuilder: (context, idx) {
                        final perm = TeamPermissions.all[idx];
                        final isChecked = selectedPermissions.contains(perm);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(perm, style: const TextStyle(fontSize: 12)),
                          value: isChecked,
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedPermissions.add(perm);
                              } else {
                                selectedPermissions.remove(perm);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.get('cancel', dialogCtx)),
            ),
            ElevatedButton(
              key: const Key('btn_submit_edit_access'),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final ok = await widget.provider.updateMemberAccess(
                  businessId: widget.businessId,
                  principalId: member.principalId,
                  role: selectedRole,
                  permissions: selectedPermissions,
                );

                if (ok && mounted) {
                  showAppAlertDialog(
                    context,
                    message: AppStrings.get('update_access_success', context),
                  );
                } else if (mounted && widget.provider.actionError != null) {
                  showAppAlertDialog(
                    context,
                    message: widget.provider.actionError!,
                    isError: true,
                  );
                }
              },
              child: Text(AppStrings.get('save', dialogCtx)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevokeMemberDialog(TeamMember member) {
    if (member.isOwner) {
      showAppAlertDialog(
        context,
        message: AppStrings.get('cannot_revoke_owner', context),
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('revoke_member', ctx)),
        content: Text(
          '${AppStrings.get('revoke_member_confirm', ctx)}\n\n(${member.displayName} - ${member.email})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('cancel', ctx)),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_revoke_member'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await widget.provider.revokeMember(
                businessId: widget.businessId,
                principalId: member.principalId,
              );

              if (ok && mounted) {
                showAppAlertDialog(
                  context,
                  message: AppStrings.get('member_revoked_success', context),
                );
              } else if (mounted && widget.provider.actionError != null) {
                showAppAlertDialog(
                  context,
                  message: widget.provider.actionError!,
                  isError: true,
                );
              }
            },
            child: Text(AppStrings.get('revoke_member', ctx)),
          ),
        ],
      ),
    );
  }

  void _showResendInvitationDialog(TeamInvitationDetails invitation) {
    final expiryController = TextEditingController(text: '72');
    bool sending = false;
    String? error;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, updateDialog) => AlertDialog(
          scrollable: true,
          title: const Text('تجديد رابط الدعوة'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('سيصبح رابط الدعوة السابق غير صالح، وسيُنشأ رمز جديد. لن يُرسل بريد تلقائيًا؛ شارك الرابط الجديد مع الموظف بعد إنشائه.'),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('input_resend_expiry'),
                  controller: expiryController,
                  enabled: !sending,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'صلاحية الرابط الجديد بالساعات',
                    helperText: 'من ساعة واحدة إلى 720 ساعة',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: AppColors.statusError)),
                  if (widget.provider.lastRequestId?.isNotEmpty == true)
                    SelectableText(
                      'رقم الطلب للدعم: ${widget.provider.lastRequestId}',
                      style: const TextStyle(fontSize: 12,
                        color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              key: const Key('btn_confirm_resend_invitation'),
              onPressed: sending ? null : () async {
                final hours = int.tryParse(expiryController.text.trim());
                if (hours == null || hours < 1 || hours > 720) {
                  updateDialog(() => error = 'اختر مدة من ساعة إلى 720 ساعة.');
                  return;
                }
                updateDialog(() {
                  sending = true;
                  error = null;
                });
                final created = await widget.provider.resendInvitation(
                  businessId: widget.businessId,
                  invitationId: invitation.id,
                  expiresInHours: hours,
                );
                if (!ctx.mounted) return;
                if (created == null) {
                  updateDialog(() {
                    sending = false;
                    error = widget.provider.actionError ??
                      'تعذر تجديد الدعوة. أعد تحميل القائمة ثم حاول مجددًا.';
                  });
                  return;
                }
                Navigator.of(ctx).pop();
                if (mounted) _showTokenDialog(created);
              },
              child: sending
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2,
                      color: Colors.white))
                : const Text('إنشاء رابط جديد'),
            ),
          ],
        ),
      ),
    ).whenComplete(expiryController.dispose);
  }

  void _showRevokeInvitationDialog(TeamInvitationDetails invitation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('revoke_invitation', ctx)),
        content: Text(AppStrings.get('revoke_invitation_confirm', ctx)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('cancel', ctx)),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_revoke_invitation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await widget.provider.revokeInvitation(
                businessId: widget.businessId,
                invitationId: invitation.id,
              );

              if (ok && mounted) {
                showAppAlertDialog(
                  context,
                  message: AppStrings.get('invitation_revoked_success', context),
                );
              } else if (mounted && widget.provider.actionError != null) {
                showAppAlertDialog(
                  context,
                  message: widget.provider.actionError!,
                  isError: true,
                );
              }
            },
            child: Text(AppStrings.get('revoke_invitation', ctx)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ensureScreenUtilInitialized();
    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceCanvas,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              AppStrings.get('team_and_audit', context),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.headingNavy,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLightBlue),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelColor: AppColors.textSecondary,
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                  tabs: [
                    Tab(
                      key: const Key('tab_team_members'),
                      text: AppStrings.get('team_members_title', context),
                    ),
                    Tab(
                      key: const Key('tab_team_invitations'),
                      text: AppStrings.get('team_invitations_title', context),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                key: const Key('btn_refresh_team'),
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadData,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('fab_invite_member'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
            icon: const Icon(Icons.person_add_rounded),
            label: Text(
              AppStrings.get('invite_member', context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _showInviteMemberDialog,
          ),
          body: SafeArea(
            child: TabBarView(
              controller: _tabController,
            children: [
              _buildMembersTab(),
              _buildInvitationsTab(),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    if (widget.provider.isLoadingMembers &&
        widget.provider.rawMembers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.provider.membersError != null &&
        widget.provider.rawMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.statusError.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.statusError),
            ),
            const SizedBox(height: 12),
            Text(
              widget.provider.membersError!,
              style: const TextStyle(color: AppColors.statusError),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              onPressed: () => widget.provider
                  .fetchMembers(widget.businessId, refresh: true),
              child: Text(AppStrings.get('retry', context)),
            ),
          ],
        ),
      );
    }

    final members = widget.provider.members;

    return Column(
      children: [
        // Role & Status filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              FilterChip(
                key: const Key('chip_role_all'),
                label: Text(AppStrings.get('all_roles', context)),
                selected: widget.provider.memberRoleFilter == 'all',
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundColor: AppColors.surfaceCanvas,
                side: const BorderSide(color: AppColors.borderLightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                onSelected: (_) =>
                    widget.provider.setMemberFilters(role: 'all'),
              ),
              const SizedBox(width: 6),
              ...TeamRoles.allRoles.map((r) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      key: Key('chip_role_$r'),
                      label: Text(_getRoleLabel(context, r)),
                      selected: widget.provider.memberRoleFilter == r,
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundColor: AppColors.surfaceCanvas,
                      side: const BorderSide(color: AppColors.borderLightBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      onSelected: (_) =>
                          widget.provider.setMemberFilters(role: r),
                    ),
                  )),
              Container(
                height: 20,
                width: 1,
                color: AppColors.borderLightBlue,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              FilterChip(
                key: const Key('chip_status_all'),
                label: Text(AppStrings.get('all_statuses', context)),
                selected: widget.provider.memberStatusFilter == 'all',
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundColor: AppColors.surfaceCanvas,
                side: const BorderSide(color: AppColors.borderLightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                onSelected: (_) =>
                    widget.provider.setMemberFilters(status: 'all'),
              ),
              const SizedBox(width: 6),
              FilterChip(
                key: const Key('chip_status_active'),
                label: Text(AppStrings.get('status_active', context)),
                selected: widget.provider.memberStatusFilter == 'active',
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundColor: AppColors.surfaceCanvas,
                side: const BorderSide(color: AppColors.borderLightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                onSelected: (_) =>
                    widget.provider.setMemberFilters(status: 'active'),
              ),
              const SizedBox(width: 6),
              FilterChip(
                key: const Key('chip_status_revoked'),
                label: Text(AppStrings.get('status_revoked', context)),
                selected: widget.provider.memberStatusFilter == 'revoked',
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundColor: AppColors.surfaceCanvas,
                side: const BorderSide(color: AppColors.borderLightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                onSelected: (_) =>
                    widget.provider.setMemberFilters(status: 'revoked'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLightBlue),
        Expanded(
          child: members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.get('no_team_members', context),
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final member = members[idx];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCanvas,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderLightBlue),
                        boxShadow: AppShadows.card,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      _getRoleColor(member.role).withValues(alpha: 0.12),
                                  child: Icon(
                                    member.isOwner
                                        ? Icons.stars_rounded
                                        : Icons.person_outline_rounded,
                                    color: _getRoleColor(member.role),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.headingNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        member.email,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(member.role)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                    border: Border.all(
                                      color: _getRoleColor(member.role).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    _getRoleLabel(context, member.role),
                                    style: TextStyle(
                                      color: _getRoleColor(member.role),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(member.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                    border: Border.all(
                                      color: _getStatusColor(member.status).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    _getStatusLabel(context, member.status),
                                    style: TextStyle(
                                      color: _getStatusColor(member.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (!member.isOwner)
                                  PopupMenuButton<String>(
                                    key: Key('menu_member_${member.principalId}'),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _showEditAccessDialog(member);
                                      } else if (val == 'revoke') {
                                        _showRevokeMemberDialog(member);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.edit_outlined,
                                                size: 16),
                                            const SizedBox(width: 8),
                                            Text(AppStrings.get(
                                                'edit_member_access', context)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'revoke',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.person_off_outlined,
                                                size: 16,
                                                color: AppColors.statusError),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppStrings.get(
                                                  'revoke_member', context),
                                              style: const TextStyle(
                                                  color:
                                                      AppColors.statusError),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            if (member.permissions.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1, color: AppColors.borderLightBlue),
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: member.permissions
                                    .take(6)
                                    .map(
                                      (p) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceSubtle,
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                          border: Border.all(color: AppColors.borderLightBlue),
                                        ),
                                        child: Text(
                                          p,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList()
                                  ..addAll(
                                    member.permissions.length > 6
                                        ? [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                              ),
                                              child: Text(
                                                '+${member.permissions.length - 6}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ]
                                        : [],
                                  ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInvitationsTab() {
    if (widget.provider.isLoadingInvitations &&
        widget.provider.rawInvitations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.provider.invitationsError != null &&
        widget.provider.rawInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.statusError.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.statusError),
            ),
            const SizedBox(height: 12),
            Text(
              widget.provider.invitationsError!,
              style: const TextStyle(color: AppColors.statusError),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              onPressed: () => widget.provider
                  .fetchInvitations(widget.businessId, refresh: true),
              child: Text(AppStrings.get('retry', context)),
            ),
          ],
        ),
      );
    }

    final invitations = widget.provider.invitations;

    return Column(
      children: [
        // Status filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              FilterChip(
                key: const Key('chip_inv_all'),
                label: Text(AppStrings.get('all_statuses', context)),
                selected: widget.provider.invitationStatusFilter == 'all',
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundColor: AppColors.surfaceCanvas,
                side: const BorderSide(color: AppColors.borderLightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                onSelected: (_) =>
                    widget.provider.setInvitationStatusFilter('all'),
              ),
              const SizedBox(width: 6),
              FilterChip(
                key: const Key('chip_inv_pending'),
                label: Text(AppStrings.get('status_pending', context)),
                selected: widget.provider.invitationStatusFilter == 'pending',
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundColor: AppColors.surfaceCanvas,
                side: const BorderSide(color: AppColors.borderLightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                onSelected: (_) =>
                    widget.provider.setInvitationStatusFilter('pending'),
              ),
              const SizedBox(width: 6),
              FilterChip(
                key: const Key('chip_inv_accepted'),
                label: Text(AppStrings.get('status_accepted', context)),
                selected: widget.provider.invitationStatusFilter == 'accepted',
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundColor: AppColors.surfaceCanvas,
                side: const BorderSide(color: AppColors.borderLightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                onSelected: (_) =>
                    widget.provider.setInvitationStatusFilter('accepted'),
              ),
              const SizedBox(width: 6),
              FilterChip(
                key: const Key('chip_inv_revoked'),
                label: Text(AppStrings.get('status_revoked', context)),
                selected: widget.provider.invitationStatusFilter == 'revoked',
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundColor: AppColors.surfaceCanvas,
                side: const BorderSide(color: AppColors.borderLightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                onSelected: (_) =>
                    widget.provider.setInvitationStatusFilter('revoked'),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLightBlue),
        Expanded(
          child: invitations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.statusWarning.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mail_outline_rounded, size: 48, color: AppColors.statusWarning),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.get('no_team_invitations', context),
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: invitations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final inv = invitations[idx];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCanvas,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderLightBlue),
                        boxShadow: AppShadows.card,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      _getRoleColor(inv.role).withValues(alpha: 0.12),
                                  child: Icon(
                                    Icons.mail_outline_rounded,
                                    color: _getRoleColor(inv.role),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inv.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.headingNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        inv.email,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(inv.role)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                    border: Border.all(
                                      color: _getRoleColor(inv.role).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    _getRoleLabel(context, inv.role),
                                    style: TextStyle(
                                      color: _getRoleColor(inv.role),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(inv.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                    border: Border.all(
                                      color: _getStatusColor(inv.status).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    _getStatusLabel(context, inv.status),
                                    style: TextStyle(
                                      color: _getStatusColor(inv.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppStrings.get('expires_at', context)}: ${formatTeamInvitationDate(context, inv.expiresAt)}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (inv.isPending) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1, color: AppColors.borderLightBlue),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    key: Key('btn_resend_inv_${inv.id}'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.borderLightBlue),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                    ),
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: Text(AppStrings.get(
                                        'resend_invitation', context)),
                                    onPressed: () =>
                                        _showResendInvitationDialog(inv),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    key: Key('btn_revoke_inv_${inv.id}'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.statusError,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                    ),
                                    icon: const Icon(Icons.close_rounded,
                                        size: 16,
                                        color: AppColors.statusError),
                                    label: Text(
                                      AppStrings.get(
                                          'revoke_invitation', context),
                                      style: const TextStyle(
                                          color: AppColors.statusError),
                                    ),
                                    onPressed: () =>
                                        _showRevokeInvitationDialog(inv),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
