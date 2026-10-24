import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

class ConversationDetailScreen extends StatefulWidget {
  final MerchantProvider merchantProvider;
  final String businessId;
  final String conversationId;

  const ConversationDetailScreen({
    super.key,
    required this.merchantProvider,
    required this.businessId,
    required this.conversationId,
  });

  @override
  State<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isPrivateNoteMode = false;

  @override
  void initState() {
    super.initState();
    widget.merchantProvider.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadConversationAndMessages(),
    );
  }

  @override
  void dispose() {
    widget.merchantProvider.removeListener(_onStateChange);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _loadConversationAndMessages() {
    widget.merchantProvider.selectConversation(
      businessId: widget.businessId,
      conversationId: widget.conversationId,
    );
    widget.merchantProvider.loadCannedReplies(widget.businessId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.merchantProvider.isPerformingAction) return;

    bool success;
    if (_isPrivateNoteMode) {
      success = await widget.merchantProvider.addPrivateNote(
        businessId: widget.businessId,
        conversationId: widget.conversationId,
        text: text,
      );
    } else {
      success = await widget.merchantProvider.sendMessage(
        businessId: widget.businessId,
        conversationId: widget.conversationId,
        text: text,
      );
    }

    if (success) {
      _textController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final provider = widget.merchantProvider;
    final conv = provider.selectedConversation;
    final customerName =
        conv?.customer.displayName ?? conv?.customer.id ?? strings('customer');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryFixed,
              child: Text(
                customerName.isNotEmpty
                    ? customerName.characters.first.toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.presenceOnline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        conv?.state == 'waiting_human'
                            ? strings('waiting_filter')
                            : (conv?.state == 'closed'
                                  ? strings('closed_filter')
                                  : strings('open_filter')),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outline_rounded),
            tooltip: strings('labels'),
            onPressed: conv != null
                ? () => _showLabelsModal(context, conv, strings)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: strings('assign_agent'),
            onPressed: conv != null
                ? () => _showAssignDialog(context, conv, strings)
                : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'toggle_state' && conv != null) {
                final newState = conv.state == 'closed' ? 'open' : 'closed';
                await provider.updateConversation(
                  businessId: widget.businessId,
                  conversationId: conv.id,
                  state: newState,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_state',
                child: Row(
                  children: [
                    Icon(
                      conv?.state == 'closed'
                          ? Icons.replay_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      conv?.state == 'closed'
                          ? strings('reopen_conversation')
                          : strings('close_conversation'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Action / Error Alert Banner
            if (provider.actionError != null)
              _buildErrorAlert(
                provider.actionError!,
                provider.lastRequestId,
                strings,
              ),

            // Messages Timeline
            Expanded(
              child: provider.isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : provider.messages.isEmpty
                  ? Center(
                      child: Text(
                        strings('no_messages'),
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = provider.messages[index];
                        return _buildMessageItem(msg, strings);
                      },
                    ),
            ),

            // Composer Area
            _buildComposer(strings),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Message msg, String Function(String) strings) {
    // 1. Private Note Item
    if (msg.private) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.statusWarningContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.statusWarning.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: AppColors.statusWarning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      strings('private_note_badge'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.statusWarning,
                      ),
                    ),
                  ],
                ),
                Text(
                  msg.displayTime,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.text ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurface,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Outbound / Inbound Message Item
    final isOutbound =
        msg.direction == 'outbound' || msg.origin == 'human_agent';
    return Align(
      alignment: isOutbound ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOutbound ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOutbound ? 16 : 2),
            bottomRight: Radius.circular(isOutbound ? 2 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isOutbound
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text ?? '',
              style: TextStyle(
                fontSize: 14,
                color: isOutbound ? Colors.white : AppColors.onSurface,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.displayTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: isOutbound
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textMuted,
                  ),
                ),
                if (isOutbound) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.status == 'delivered'
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(String Function(String) strings) {
    final provider = widget.merchantProvider;
    final isActionLoading = provider.isPerformingAction;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        border: Border(top: BorderSide(color: AppColors.borderHairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode Toggle Strip & Canned Replies Trigger
          Row(
            children: [
              // Message Mode Chip
              FilterChip(
                selected: !_isPrivateNoteMode,
                label: Text(strings('public_message')),
                onSelected: (_) => setState(() => _isPrivateNoteMode = false),
                selectedColor: AppColors.primaryFixed,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: !_isPrivateNoteMode
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: !_isPrivateNoteMode
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide.none,
              ),
              const SizedBox(width: 6),

              // Private Note Mode Chip
              FilterChip(
                selected: _isPrivateNoteMode,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 12),
                    const SizedBox(width: 4),
                    Text(strings('private_note')),
                  ],
                ),
                onSelected: (_) => setState(() => _isPrivateNoteMode = true),
                selectedColor: AppColors.statusWarningContainer,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: _isPrivateNoteMode
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _isPrivateNoteMode
                      ? AppColors.statusWarning
                      : AppColors.textMuted,
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide.none,
              ),
              const Spacer(),

              // Canned Replies Button
              TextButton.icon(
                icon: const Icon(Icons.quickreply_rounded, size: 16),
                label: Text(
                  strings('canned_replies'),
                  style: const TextStyle(fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: () => _showCannedRepliesSheet(context, strings),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Input Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _isPrivateNoteMode
                        ? strings('type_private_note')
                        : strings('type_message'),
                    fillColor: _isPrivateNoteMode
                        ? AppColors.statusWarningContainer.withValues(
                            alpha: 0.3,
                          )
                        : AppColors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send Button with Double-tap Protection
              IconButton.filled(
                icon: isActionLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _isPrivateNoteMode
                            ? Icons.note_add_rounded
                            : Icons.send_rounded,
                      ),
                style: IconButton.styleFrom(
                  backgroundColor: _isPrivateNoteMode
                      ? AppColors.statusWarning
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(46, 46),
                ),
                onPressed: isActionLoading ? null : _handleSend,
                tooltip: strings('send'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCannedRepliesSheet(
    BuildContext context,
    String Function(String) strings,
  ) {
    final replies = widget.merchantProvider.cannedReplies;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings('canned_replies'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (replies.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      strings('canned_replies_empty'),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: replies.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = replies[index];
                      return ListTile(
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(64, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await widget.merchantProvider.sendCannedReply(
                              businessId: widget.businessId,
                              conversationId: widget.conversationId,
                              cannedReplyId: item.id,
                            );
                            _scrollToBottom();
                          },
                          child: Text(strings('send')),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAssignDialog(
    BuildContext context,
    Conversation conv,
    String Function(String) strings,
  ) {
    final assignController = TextEditingController(
      text: conv.assignment?['principal_id'] ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(strings('assign_agent')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: assignController,
                decoration: InputDecoration(
                  labelText: strings('assignee_principal_id'),
                  hintText: 'e.g. 018f3a2c-4b5d-7a6c-8e9f-0123456789ab',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
              onPressed: () async {
                final id = assignController.text.trim();
                if (id.isNotEmpty) {
                  Navigator.pop(ctx);
                  await widget.merchantProvider.assignConversation(
                    businessId: widget.businessId,
                    conversationId: widget.conversationId,
                    assigneePrincipalId: id,
                  );
                }
              },
              child: Text(strings('assign')),
            ),
          ],
        );
      },
    );
  }

  void _showLabelsModal(
    BuildContext context,
    Conversation conv,
    String Function(String) strings,
  ) {
    final newLabelController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentLabels =
                widget.merchantProvider.selectedConversation?.labels ??
                conv.labels;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings('labels'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Add label input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newLabelController,
                            decoration: InputDecoration(
                              hintText: strings('label_name'),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(80, 44),
                          ),
                          onPressed: () async {
                            final label = newLabelController.text.trim();
                            if (label.isNotEmpty) {
                              newLabelController.clear();
                              await widget.merchantProvider
                                  .updateConversationLabels(
                                    businessId: widget.businessId,
                                    conversationId: widget.conversationId,
                                    add: [label],
                                  );
                              setModalState(() {});
                            }
                          },
                          child: Text(strings('add_label')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Labels list
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentLabels.map((lbl) {
                        return Chip(
                          label: Text('#$lbl'),
                          deleteIcon: const Icon(
                            Icons.cancel_rounded,
                            size: 16,
                          ),
                          onDeleted: () async {
                            await widget.merchantProvider
                                .updateConversationLabels(
                                  businessId: widget.businessId,
                                  conversationId: widget.conversationId,
                                  remove: [lbl],
                                );
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorAlert(
    String error,
    String? requestId,
    String Function(String) strings,
  ) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.statusErrorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.statusError,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.statusError,
              ),
            ),
          ),
          if (requestId != null)
            Text(
              'req: ${requestId.length > 8 ? requestId.substring(0, 8) : requestId}',
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
