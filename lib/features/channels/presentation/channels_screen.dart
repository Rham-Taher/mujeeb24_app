import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/widgets/merchant_editor_dialog.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/channel_automation_models.dart';
import '../providers/channel_automation_provider.dart';
import 'ai_decisions_screen.dart';
import 'automation_rules_screen.dart';
import 'canned_replies_screen.dart';

/// Screen for managing Channel Connections, capabilities, reconnect/disconnect, and history purge.
class ChannelsScreen extends StatefulWidget {
  final ChannelAutomationProvider channelProvider;
  final String businessId;

  const ChannelsScreen({
    super.key,
    required this.channelProvider,
    required this.businessId,
  });

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await widget.channelProvider.fetchConnections(
      widget.businessId,
      refresh: true,
    );
  }

  void _showErrorSnackBar(String message, [String? requestId]) {
    final text = requestId != null ? '$message ($requestId)' : message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // ===========================================================================
  /// Open only provider-issued HTTPS authorization URLs in an external browser.
  Future<void> _openChannelAuthorization(String? rawUrl) async {
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _showErrorSnackBar('رابط الربط غير صالح. أعد محاولة الربط.');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!opened) _showErrorSnackBar('تعذر فتح الرابط. انسخه وافتحه من المتصفح.');
    } catch (_) {
      if (mounted) _showErrorSnackBar('تعذر فتح الرابط. يمكنك نسخه يدويًا.');
    }
  }

  // Dialog: Begin New Channel Connection
  // ===========================================================================
  void _showConnectDialog() {
    String selectedProvider = 'meta';
    String selectedChannel = 'whatsapp';
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String strings(String key) => AppStrings.get(key, context);
            return MerchantEditorDialog(
              title: Text(strings('connect_channel')),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedProvider,
                        decoration: InputDecoration(
                          labelText: strings('channel_provider'),
                          border: const OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'meta', child: Text('ميتا — واتساب وإنستغرام')),
                          DropdownMenuItem(value: 'telegram', child: Text('تليجرام')),
                          DropdownMenuItem(value: 'twilio', child: Text('Twilio — رسائل نصية')),
                          DropdownMenuItem(value: 'custom', child: Text('تكامل مخصص')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedProvider = val;
                              if (val == 'meta') selectedChannel = 'whatsapp';
                              if (val == 'telegram') selectedChannel = 'telegram';
                              if (val == 'twilio') selectedChannel = 'sms';
                              if (val == 'custom') selectedChannel = 'webhook';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedChannel,
                        decoration: InputDecoration(
                          labelText: strings('channel_type'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          if (selectedProvider == 'meta') ...const [
                            DropdownMenuItem(value: 'whatsapp', child: Text('واتساب للأعمال')),
                            DropdownMenuItem(value: 'instagram', child: Text('إنستغرام')),
                          ],
                          if (selectedProvider == 'telegram') ...const [
                            DropdownMenuItem(value: 'telegram', child: Text('تليجرام بوت')),
                          ],
                          if (selectedProvider == 'twilio') ...const [
                            DropdownMenuItem(value: 'sms', child: Text('الرسائل النصية')),
                          ],
                          if (selectedProvider == 'custom') ...const [
                            DropdownMenuItem(value: 'webhook', child: Text('تكامل مخصص')),
                          ],
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedChannel = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: strings('channel_display_name'),
                          hintText: 'مثال: واتساب خدمة العملاء',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
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
                      final req = BeginChannelConnectionRequest(
                        provider: selectedProvider,
                        channel: selectedChannel,
                        displayName: nameController.text.trim().isEmpty
                            ? null
                            : nameController.text.trim(),
                      );
                      final provisioning = await widget.channelProvider.beginConnection(
                        widget.businessId,
                        req,
                      );
                      if (!mounted) return;
                      if (provisioning != null) {
                        _showProvisioningResultDialog(provisioning);
                      } else if (widget.channelProvider.actionError != null) {
                        _showErrorSnackBar(
                          widget.channelProvider.actionError!,
                          widget.channelProvider.lastRequestId,
                        );
                      }
                    }
                  },
                  child: Text(strings('connect_channel')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProvisioningResultDialog(ChannelProvisioning provisioning) {
    showDialog(
      context: context,
      builder: (ctx) {
        String strings(String key) => AppStrings.get(key, context);
        return AlertDialog(
          scrollable: true,
          title: Text(strings('provisioning_started')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${provisioning.provisioningId}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('الحالة: ${_channelStatusLabel(provisioning.status)}'),
              if (provisioning.authorizationUrl != null) ...[
                const SizedBox(height: 12),
                Text(strings('open_authorization_url')),
                const SizedBox(height: 8),
                SelectableText(
                  provisioning.authorizationUrl!,
                  style: const TextStyle(color: AppColors.primary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const Key('btn_open_channel_authorization'),
                      onPressed: () => _openChannelAuthorization(
                        provisioning.authorizationUrl),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('فتح رابط الربط'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('btn_copy_channel_authorization'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(
                          text: provisioning.authorizationUrl!));
                        if (mounted) _showSuccessSnackBar('تم نسخ رابط الربط');
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('نسخ الرابط'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // Dialog: Reconnect Channel
  // ===========================================================================
  void _showReconnectDialog(ChannelConnection connection) {
    final reasonController = TextEditingController(text: 'إعادة توثيق اتصال القناة');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        String strings(String key) => AppStrings.get(key, context);
        return AlertDialog(
          title: Text(strings('channel_reconnect')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${strings('channel_display_name')}: ${connection.displayName ?? connection.channel}'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'سبب الإجراء',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return strings('required_field');
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
                  final res = await widget.channelProvider.reconnectConnection(
                    widget.businessId,
                    connection.id,
                    reasonController.text.trim(),
                    ifMatch: connection.resourceVersion,
                  );
                  if (!mounted) return;
                  if (res != null) {
                    _showSuccessSnackBar(strings('reconnect_success'));
                  } else if (widget.channelProvider.actionError != null) {
                    _showErrorSnackBar(
                      widget.channelProvider.actionError!,
                      widget.channelProvider.lastRequestId,
                    );
                  }
                }
              },
              child: Text(strings('channel_reconnect')),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // Dialog: Disconnect Channel
  // ===========================================================================
  void _showDisconnectDialog(ChannelConnection connection) {
    final reasonController = TextEditingController(text: 'فصل القناة مؤقتًا للصيانة');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        String strings(String key) => AppStrings.get(key, context);
        return AlertDialog(
          title: Text(strings('channel_disconnect')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${strings('channel_display_name')}: ${connection.displayName ?? connection.channel}'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'سبب الإجراء',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return strings('required_field');
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  final res = await widget.channelProvider.disconnectConnection(
                    widget.businessId,
                    connection.id,
                    reasonController.text.trim(),
                    ifMatch: connection.resourceVersion,
                  );
                  if (!mounted) return;
                  if (res != null) {
                    _showSuccessSnackBar(strings('disconnect_success'));
                  } else if (widget.channelProvider.actionError != null) {
                    _showErrorSnackBar(
                      widget.channelProvider.actionError!,
                      widget.channelProvider.lastRequestId,
                    );
                  }
                }
              },
              child: Text(strings('channel_disconnect')),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // Purge History: Preview & Irreversible Confirmation Flow
  // ===========================================================================
  Future<void> _startPurgeHistoryFlow(ChannelConnection connection) async {
    String strings(String key) => AppStrings.get(key, context);

    // Step 1: Fetch preview
    final preview = await widget.channelProvider.previewPurge(
      widget.businessId,
      connection.id,
    );

    if (!mounted) return;

    if (preview == null) {
      _showErrorSnackBar(
        widget.channelProvider.actionError ?? strings('request_failed'),
        widget.channelProvider.lastRequestId,
      );
      return;
    }

    // Step 2: Show irreversible warning preview dialog
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(child: Text(strings('purge_preview_title'))),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      strings('purge_history_warning'),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${strings('conversations_to_delete')}: ${preview.conversationsCount}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('${strings('messages_to_delete')}: ${preview.messagesCount}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Text(
                    strings('purge_confirmation_prompt'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: confirmController,
                    decoration: const InputDecoration(
                      hintText: 'DELETE_ALL_CHANNEL_HISTORY',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val != 'DELETE_ALL_CHANNEL_HISTORY') {
                        return strings('purge_confirmation_error');
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
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  final purged = await widget.channelProvider.executePurge(
                    widget.businessId,
                    connection.id,
                    expectedVersion: connection.resourceVersion,
                    confirmation: confirmController.text.trim(),
                  );
                  if (!mounted) return;
                  if (purged != null) {
                    _showSuccessSnackBar(strings('purge_success'));
                    _loadData();
                  } else if (widget.channelProvider.actionError != null) {
                    _showErrorSnackBar(
                      widget.channelProvider.actionError!,
                      widget.channelProvider.lastRequestId,
                    );
                  }
                }
              },
              child: Text(strings('channel_purge_history')),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // Dialog: Show Capabilities
  // ===========================================================================
  Future<void> _showCapabilitiesDialog(ChannelConnection connection) async {
    await widget.channelProvider.fetchConnectionDetail(
      widget.businessId,
      connection.id,
    );
    if (!mounted) return;

    final capabilities = widget.channelProvider.connectionCapabilities;
    String strings(String key) => AppStrings.get(key, context);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(strings('channel_capabilities')),
          content: capabilities.isEmpty
              ? const Text('No capabilities reported.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: capabilities.length,
                    itemBuilder: (context, i) {
                      final cap = capabilities[i];
                      return ListTile(
                        leading: Icon(
                          cap.supported ? Icons.check_circle : Icons.cancel,
                          color: cap.supported ? AppColors.success : AppColors.textSecondary,
                        ),
                        title: Text(cap.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: cap.description != null ? Text(cap.description!) : null,
                      );
                    },
                  ),
                ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'pending_provisioning':
      case 'degraded':
        return AppColors.warning;
      case 'disconnected':
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _channelStatusLabel(String status) => switch (status.toLowerCase()) {
    'active' => 'متصل ونشط',
    'degraded' => 'الاتصال يحتاج مراجعة',
    'disconnected' => 'غير متصل',
    'failed' => 'فشل الربط',
    'pending' => 'جارٍ الربط',
    'connecting' => 'جارٍ الاتصال',
    _ => 'حالة غير معروفة',
  };

  String _channelName(String channel) => switch (channel.toLowerCase()) {
    'whatsapp' => 'واتساب للأعمال',
    'instagram' => 'إنستغرام',
    'facebook' => 'فيسبوك مسنجر',
    'messenger' => 'فيسبوك مسنجر',
    'telegram' => 'تليجرام',
    'sms' => 'الرسائل النصية',
    'webhook' => 'تكامل مخصص',
    _ => 'قناة تواصل',
  };

  IconData _getChannelIcon(String channel) {
    final ch = channel.toLowerCase();
    if (ch.contains('whatsapp')) return Icons.chat;
    if (ch.contains('instagram')) return Icons.camera_alt;
    if (ch.contains('telegram')) return Icons.send;
    if (ch.contains('sms')) return Icons.sms;
    return Icons.cloud_queue;
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings('channels_title')),
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
          if (provider.isLoadingConnections && provider.connections.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Navigation Quick Bar to Automation, AI Decisions, Canned Replies
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.smart_toy_outlined, size: 18),
                        label: Text(strings('ai_decisions_title')),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AIDecisionsScreen(
                                channelProvider: widget.channelProvider,
                                businessId: widget.businessId,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.alt_route, size: 18),
                        label: Text(strings('automation_rules_title')),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AutomationRulesScreen(
                                channelProvider: widget.channelProvider,
                                businessId: widget.businessId,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.reply_all, size: 18),
                        label: Text(strings('canned_replies_title')),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CannedRepliesScreen(
                                channelProvider: widget.channelProvider,
                                businessId: widget.businessId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(strings('all_conversations')),
                        selected: provider.connectionStatusFilter == 'all',
                        onSelected: (_) {
                          provider.setConnectionStatusFilter('all');
                          _loadData();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(strings('status_active')),
                        selected: provider.connectionStatusFilter == 'active',
                        onSelected: (_) {
                          provider.setConnectionStatusFilter('active');
                          _loadData();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('يحتاج مراجعة'),
                        selected: provider.connectionStatusFilter == 'degraded',
                        onSelected: (_) {
                          provider.setConnectionStatusFilter('degraded');
                          _loadData();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('غير متصل'),
                        selected: provider.connectionStatusFilter == 'disconnected',
                        onSelected: (_) {
                          provider.setConnectionStatusFilter('disconnected');
                          _loadData();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (provider.connectionsError != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    provider.connectionsError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),

              Expanded(
                child: provider.connections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(provider.connectionsError != null
                              ? Icons.wifi_off_outlined : Icons.cable,
                              size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            Text(provider.connectionsError == null
                              ? strings('no_channels')
                              : 'تعذر تحميل حالة القنوات',
                              style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: provider.connectionsError != null
                                ? _loadData : _showConnectDialog,
                              icon: Icon(provider.connectionsError != null
                                ? Icons.refresh_rounded : Icons.add_link),
                              label: Text(provider.connectionsError != null
                                ? 'إعادة المحاولة' : strings('connect_channel')),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.connections.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final conn = provider.connections[index];
                            final statusColor = _getStatusColor(conn.status);

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: statusColor.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: statusColor.withValues(alpha: 0.15),
                                          child: Icon(_getChannelIcon(conn.channel), color: statusColor),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                conn.displayName?.trim().isNotEmpty == true
                                                    ? conn.displayName! : _channelName(conn.channel),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              Text(
                                                'القناة: ${_channelName(conn.channel)}',
                                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _channelStatusLabel(conn.status),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        ActionChip(
                                          avatar: const Icon(Icons.settings_outlined, size: 16),
                                          label: Text(strings('channel_capabilities')),
                                          onPressed: () => _showCapabilitiesDialog(conn),
                                        ),
                                        if (conn.status == 'disconnected' || conn.status == 'failed')
                                          ActionChip(
                                            avatar: const Icon(Icons.sync, size: 16, color: AppColors.primary),
                                            label: Text(strings('channel_reconnect')),
                                            onPressed: () => _showReconnectDialog(conn),
                                          ),
                                        if (conn.status == 'active' || conn.status == 'degraded')
                                          ActionChip(
                                            avatar: const Icon(Icons.link_off, size: 16, color: AppColors.error),
                                            label: Text(strings('channel_disconnect')),
                                            onPressed: () => _showDisconnectDialog(conn),
                                          ),
                                        ActionChip(
                                          avatar: const Icon(Icons.delete_forever, size: 16, color: AppColors.error),
                                          label: Text(strings('channel_purge_history')),
                                          onPressed: () => _startPurgeHistoryFlow(conn),
                                        ),
                                      ],
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
        onPressed: _showConnectDialog,
        icon: const Icon(Icons.add_link),
        label: Text(strings('connect_channel')),
      ),
    );
  }
}
