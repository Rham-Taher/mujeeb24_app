import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

/// Redesigned Conversation Detail Screen matching Mujeeb24 Master Visual Reference.
/// Retains 100% of business logic, message ordering, sending, canned replies, and assignment flows.
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

  bool _shouldShowDateDivider(int index, List<Message> messages) {
    if (index == 0) return true;
    final curr = _extractDate(messages[index]);
    final prev = _extractDate(messages[index - 1]);
    return curr != null && curr != prev;
  }

  String? _extractDate(Message msg) {
    final raw = msg.occurredAt ?? msg.createdAt;
    if (raw == null || raw.length < 10) return null;
    return raw.substring(0, 10);
  }

  Color _getChannelColor(String? channel) {
    switch (channel?.toLowerCase()) {
      case 'whatsapp':
        return AppColors.channelWhatsapp;
      case 'instagram':
        return AppColors.channelInstagram;
      case 'facebook':
        return AppColors.channelFacebook;
      case 'telegram':
        return AppColors.channelTelegram;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _getChannelIcon(String? channel) {
    switch (channel?.toLowerCase()) {
      case 'whatsapp':
        return Icons.chat_bubble_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'telegram':
        return Icons.send_rounded;
      default:
        return Icons.chat_rounded;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderLightBlue,
          ),
        ),
        title: Row(
          children: [
            // Customer Avatar with Channel Badge Pin
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.primaryFixed,
                  child: Text(
                    customerName.isNotEmpty
                        ? customerName.characters.first.toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primaryBlueDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  left: -2,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: _getChannelColor(null),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.cardWhite,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _getChannelIcon(null),
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headingNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: conv?.state == 'closed'
                              ? AppColors.textMuted
                              : AppColors.presenceOnline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        conv?.state == 'waiting_human'
                            ? strings('waiting_filter')
                            : (conv?.state == 'closed'
                                ? strings('closed_filter')
                                : strings('open_filter')),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: conv?.state == 'waiting_human'
                              ? AppColors.statusWarning
                              : AppColors.secondaryText,
                        ),
                      ),
                      if (conv?.assignment != null &&
                          conv!.assignment!['principal_id'] != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: AppColors.primaryBlue.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.shield_outlined,
                                size: 10,
                                color: AppColors.primaryBlue,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'معيّن',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: conv?.labels.isNotEmpty == true
                ? Badge(
                    label: Text('${conv!.labels.length}'),
                    backgroundColor: AppColors.primaryBlue,
                    child: const Icon(Icons.label_outline_rounded),
                  )
                : const Icon(Icons.label_outline_rounded),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                      color: AppColors.primaryBlue,
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

            // Customer Context Mini-Dashboard Banner (Matching _1/code.html)
            if (conv != null)
              _buildCustomerMiniDashboard(conv, strings),

            // Metadata Strip (Only when real labels exist)
            if (conv != null && conv.labels.isNotEmpty)
              _buildLabelsStrip(conv.labels),

            // Messages Timeline
            Expanded(
              child: provider.isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : provider.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: AppColors.textMuted.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings('no_messages'),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
                        final showDate = _shouldShowDateDivider(
                          index,
                          provider.messages,
                        );
                        final dateStr = _extractDate(msg);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showDate && dateStr != null)
                              _buildDateDivider(dateStr),
                            _buildMessageItem(msg, strings),
                          ],
                        );
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

  /// Mini-dashboard showing operational customer context matching reference _1/code.html
  Widget _buildCustomerMiniDashboard(
    Conversation conv,
    String Function(String) strings,
  ) {
    final customerId = conv.customer.id;
    final agentName = conv.assignment?['principal_name'] ??
        conv.assignment?['principal_id'] ??
        'غير معيّن';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLightBlue),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: conv.state == 'closed'
                      ? AppColors.surfaceMuted
                      : AppColors.statusSuccessContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: conv.state == 'closed'
                        ? AppColors.disabledBorder
                        : AppColors.successGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: conv.state == 'closed'
                            ? AppColors.textMuted
                            : AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      conv.state == 'closed' ? 'مغلقة' : 'محادثة نشطة',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: conv.state == 'closed'
                            ? AppColors.textMuted
                            : AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderLightBlue),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        size: 13,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          agentName,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.headingNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.fingerprint,
                size: 12,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 5),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  'ID: $customerId',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelsStrip(List<String> labels) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLightBlue, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: labels.map((lbl) {
            return Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.borderLightBlue,
                  width: 0.5,
                ),
              ),
              child: Text(
                '#$lbl',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateDivider(String dateStr) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderLightBlue,
            width: 0.8,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            dateStr,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(Message msg, String Function(String) strings) {
    // 1. Private Note Item
    if (msg.private) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.statusWarningContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warningAmber.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.warningAmber.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: AppColors.warningAmber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      strings('private_note_badge'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.warningAmber.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    'داخلي فقط',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warningAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg.text ?? '',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  msg.displayTime,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.secondaryText,
                  ),
                ),
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
          color: isOutbound ? AppColors.primaryBlue : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOutbound ? 16 : 4),
            bottomRight: Radius.circular(isOutbound ? 4 : 16),
          ),
          border: isOutbound
              ? null
              : Border.all(
                  color: AppColors.borderLightBlue,
                  width: 0.8,
                ),
          boxShadow: [
            BoxShadow(
              color: isOutbound
                  ? AppColors.primaryBlue.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
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
                color: isOutbound ? Colors.white : AppColors.headingNavy,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    msg.displayTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: isOutbound
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.secondaryText,
                    ),
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        border: Border(
          top: BorderSide(color: AppColors.borderLightBlue, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode Toggle Strip & Canned Replies Trigger
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Message Mode Chip
                FilterChip(
                  selected: !_isPrivateNoteMode,
                  label: Text(strings('public_message')),
                  onSelected: (_) => setState(() => _isPrivateNoteMode = false),
                  selectedColor: AppColors.surfaceContainerLow,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: !_isPrivateNoteMode
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: !_isPrivateNoteMode
                        ? AppColors.primaryBlue
                        : AppColors.secondaryText,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: !_isPrivateNoteMode
                        ? AppColors.primaryBlue.withValues(alpha: 0.3)
                        : AppColors.borderLightBlue,
                  ),
                ),
                const SizedBox(width: 8),

                // Private Note Mode Chip
                FilterChip(
                  selected: _isPrivateNoteMode,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: _isPrivateNoteMode
                            ? AppColors.warningAmber
                            : AppColors.secondaryText,
                      ),
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
                        ? AppColors.warningAmber
                        : AppColors.secondaryText,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: _isPrivateNoteMode
                        ? AppColors.warningAmber.withValues(alpha: 0.3)
                        : AppColors.borderLightBlue,
                  ),
                ),
                const SizedBox(width: 14),

                // Canned Replies Button
                TextButton.icon(
                  icon: const Icon(Icons.quickreply_rounded, size: 16),
                  label: Text(
                    strings('canned_replies'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () => _showCannedRepliesSheet(context, strings),
                ),
              ],
            ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.headingNavy,
                  ),
                  decoration: InputDecoration(
                    hintText: _isPrivateNoteMode
                        ? strings('type_private_note')
                        : strings('type_message'),
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                    fillColor: _isPrivateNoteMode
                        ? AppColors.statusWarningContainer.withValues(
                            alpha: 0.3,
                          )
                        : AppColors.surfaceContainerLow,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _isPrivateNoteMode
                            ? AppColors.warningAmber.withValues(alpha: 0.4)
                            : AppColors.borderLightBlue,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _isPrivateNoteMode
                            ? AppColors.warningAmber.withValues(alpha: 0.4)
                            : AppColors.borderLightBlue,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _isPrivateNoteMode
                            ? AppColors.warningAmber
                            : AppColors.primaryBlue,
                        width: 1.5,
                      ),
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
                    : Transform.flip(
                        flipX: !_isPrivateNoteMode && isRtl,
                        child: Icon(
                          _isPrivateNoteMode
                              ? Icons.note_add_rounded
                              : Icons.send_rounded,
                        ),
                      ),
                style: IconButton.styleFrom(
                  backgroundColor: _isPrivateNoteMode
                      ? AppColors.warningAmber
                      : AppColors.primaryBlue,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.headingNavy,
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
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      strings('no_canned_replies'),
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: replies.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = replies[i];
                      return ListTile(
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.secondaryText),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.shortcut,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryBlue,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _textController.text = item.body;
                        },
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

  void _showLabelsModal(
    BuildContext context,
    Conversation conv,
    String Function(String) strings,
  ) {
    final textEditController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final currentLabels = List<String>.from(conv.labels);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
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
                          color: AppColors.headingNavy,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: currentLabels.map((l) {
                      return Chip(
                        label: Text(l),
                        backgroundColor: AppColors.surfaceContainerLow,
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () async {
                          await widget.merchantProvider.updateConversationLabels(
                            businessId: widget.businessId,
                            conversationId: widget.conversationId,
                            remove: [l],
                          );
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textEditController,
                          decoration: InputDecoration(
                            hintText: strings('label_hint'),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final newTag = textEditController.text.trim();
                          if (newTag.isNotEmpty && !currentLabels.contains(newTag)) {
                            await widget.merchantProvider.updateConversationLabels(
                              businessId: widget.businessId,
                              conversationId: widget.conversationId,
                              add: [newTag],
                            );
                            textEditController.clear();
                            setModalState(() {});
                          }
                        },
                        child: Text(strings('add_label')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignDialog(
    BuildContext context,
    Conversation conv,
    String Function(String) strings,
  ) {
    final idController = TextEditingController(
      text: conv.assignment?['principal_id'] ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(strings('assign_agent')),
          content: TextField(
            controller: idController,
            decoration: InputDecoration(
              labelText: strings('agent_id_label'),
              hintText: 'user_123 or agent-email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(strings('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final val = idController.text.trim();
                await widget.merchantProvider.assignConversation(
                  businessId: widget.businessId,
                  conversationId: conv.id,
                  assigneePrincipalId: val,
                );
              },
              child: Text(strings('save')),
            ),
          ],
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
      width: double.infinity,
      color: AppColors.statusErrorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.errorRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (requestId != null && requestId.isNotEmpty)
            Text(
              requestId,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.secondaryText,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }
}
