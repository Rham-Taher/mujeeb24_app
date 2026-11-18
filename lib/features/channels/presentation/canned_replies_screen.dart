import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_ui_widgets.dart';
import '../../../core/models/channel_automation_models.dart';
import '../../../core/models/merchant_models.dart';
import '../providers/channel_automation_provider.dart';

/// Screen for managing Reusable Canned Replies.
class CannedRepliesScreen extends StatefulWidget {
  final ChannelAutomationProvider channelProvider;
  final String businessId;

  const CannedRepliesScreen({
    super.key,
    required this.channelProvider,
    required this.businessId,
  });

  @override
  State<CannedRepliesScreen> createState() => _CannedRepliesScreenState();
}

class _CannedRepliesScreenState extends State<CannedRepliesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await widget.channelProvider.fetchCannedReplies(
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
  // Dialog: Create Canned Reply
  // ===========================================================================
  void _showCreateReplyDialog() {
    final shortcutController = TextEditingController();
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        String strings(String key) => AppStrings.get(key, context);
        return AlertDialog(
          title: Text(strings('create_canned_reply')),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: shortcutController,
                    decoration: InputDecoration(
                      labelText: '${strings('reply_shortcut')} *',
                      hintText: 'e.g. /welcome or /pricing',
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
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: '${strings('reply_title')} *',
                      hintText: 'e.g. Welcome Greeting',
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
                    controller: bodyController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: '${strings('reply_body')} *',
                      hintText: 'Enter canned text response...',
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
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  final req = CreateCannedReplyRequest(
                    shortcut: shortcutController.text.trim(),
                    title: titleController.text.trim(),
                    body: bodyController.text.trim(),
                  );

                  final created = await widget.channelProvider.createReply(
                    widget.businessId,
                    req,
                  );
                  if (!mounted) return;
                  if (created != null) {
                    _showSuccessDialog(strings('reply_created_success'));
                  } else if (widget.channelProvider.actionError != null) {
                    _showErrorDialog(
                      widget.channelProvider.actionError!,
                      widget.channelProvider.lastRequestId,
                    );
                  }
                }
              },
              child: Text(strings('create_canned_reply')),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // Dialog: Edit Canned Reply
  // ===========================================================================
  void _showEditReplyDialog(CannedReply reply) {
    final shortcutController = TextEditingController(text: reply.shortcut);
    final titleController = TextEditingController(text: reply.title);
    final bodyController = TextEditingController(text: reply.body);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        String strings(String key) => AppStrings.get(key, context);
        return AlertDialog(
          title: Text(strings('edit_canned_reply')),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: shortcutController,
                    decoration: InputDecoration(
                      labelText: strings('reply_shortcut'),
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
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: strings('reply_title'),
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
                    controller: bodyController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: strings('reply_body'),
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
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  final req = UpdateCannedReplyRequest(
                    shortcut: shortcutController.text.trim(),
                    title: titleController.text.trim(),
                    body: bodyController.text.trim(),
                  );

                  final updated = await widget.channelProvider.updateReply(
                    widget.businessId,
                    reply.id,
                    req,
                    ifMatch: reply.resourceVersion,
                  );
                  if (!mounted) return;
                  if (updated != null) {
                    _showSuccessDialog(strings('reply_updated_success'));
                  } else if (widget.channelProvider.actionError != null) {
                    _showErrorDialog(
                      widget.channelProvider.actionError!,
                      widget.channelProvider.lastRequestId,
                    );
                  }
                }
              },
              child: Text(strings('edit_canned_reply')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings('canned_replies_title')),
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
          if (provider.isLoadingCannedReplies &&
              provider.cannedReplies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              if (provider.cannedRepliesError != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    provider.cannedRepliesError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),

              Expanded(
                child: provider.cannedReplies.isEmpty
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
                                Icons.reply_all,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              strings('no_canned_replies'),
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
                              onPressed: _showCreateReplyDialog,
                              icon: const Icon(Icons.add),
                              label: Text(strings('create_canned_reply')),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.cannedReplies.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final reply = provider.cannedReplies[index];

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
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.sm,
                                            ),
                                          ),
                                          child: Text(
                                            reply.shortcut,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            reply.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
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
                                              _showEditReplyDialog(reply),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      reply.body,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
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
        onPressed: _showCreateReplyDialog,
        icon: const Icon(Icons.add),
        label: Text(strings('create_canned_reply')),
      ),
    );
  }
}
