import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/core/widgets/common_ui_widgets.dart';
import 'package:mujeeb24_app/core/widgets/filter_widgets.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';

class InboxTab extends StatefulWidget {
  final MerchantProvider merchantProvider;
  final Business? currentBusiness;
  final Function(Conversation) onConversationSelected;

  const InboxTab({
    super.key,
    required this.merchantProvider,
    required this.currentBusiness,
    required this.onConversationSelected,
  });

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  String _selectedChannel =
      'all'; // all, whatsapp, facebook, telegram, instagram
  String _selectedFilter = 'all'; // all, waiting_human, open, closed
  String _selectedOwnership = 'all'; // all, assigned, unassigned
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.merchantProvider.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (_searchQuery != q) {
        setState(() {
          _searchQuery = q;
        });
        widget.merchantProvider.setConversationSearchQuery(q);
      }
    });
  }

  @override
  void dispose() {
    widget.merchantProvider.removeListener(_onStateChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _loadConversations() {
    final businessId = widget.currentBusiness?.id;
    if (businessId != null && businessId.isNotEmpty) {
      widget.merchantProvider.loadConversations(
        businessId,
        channel: _selectedChannel != 'all' ? _selectedChannel : null,
        state: _selectedFilter != 'all' ? _selectedFilter : null,
        ownership: _selectedOwnership != 'all' ? _selectedOwnership : null,
      );
    }
  }

  void _onChannelSelected(String channel) {
    setState(() {
      _selectedChannel = channel;
    });
    final businessId = widget.currentBusiness?.id ?? '';
    widget.merchantProvider.setConversationChannelFilter(businessId, channel);
  }

  void _onStateSelected(String state) {
    setState(() {
      _selectedFilter = state;
    });
    final businessId = widget.currentBusiness?.id ?? '';
    widget.merchantProvider.setConversationStateFilter(businessId, state);
  }

  void _onOwnershipSelected(String ownership) {
    setState(() {
      _selectedOwnership = ownership;
    });
    final businessId = widget.currentBusiness?.id ?? '';
    widget.merchantProvider.setConversationOwnershipFilter(
      businessId,
      ownership,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedChannel = 'all';
      _selectedFilter = 'all';
      _selectedOwnership = 'all';
      _searchController.clear();
      _searchQuery = '';
    });
    final businessId = widget.currentBusiness?.id ?? '';
    widget.merchantProvider.clearConversationFilters(businessId);
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedChannel != 'all') count++;
    if (_selectedFilter != 'all') count++;
    if (_selectedOwnership != 'all') count++;
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }

  String _detectChannel(Conversation conv) {
    for (final label in conv.labels) {
      final l = label.toLowerCase();
      if (l.contains('whatsapp')) return 'whatsapp';
      if (l.contains('facebook') || l.contains('meta')) return 'facebook';
      if (l.contains('telegram')) return 'telegram';
      if (l.contains('instagram')) return 'instagram';
    }
    if (conv.assignment != null && conv.assignment!['channel'] != null) {
      return conv.assignment!['channel']!;
    }
    if (_selectedChannel != 'all') {
      return _selectedChannel;
    }
    return 'whatsapp';
  }

  String? _formatLastActivity(String raw) {
    if (raw.isEmpty) return null;
    try {
      final dt = DateTime.parse(raw).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'م' : 'ص';
      return '$hour:$minute $period';
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  List<Conversation> _getFilteredConversations() {
    final list = widget.merchantProvider.conversations;
    return list.where((c) {
      // Channel Filter (client-side safety check)
      if (_selectedChannel != 'all') {
        final hasOtherExplicitChannel = c.labels.any((l) {
          final low = l.toLowerCase();
          return (low.contains('whatsapp') && _selectedChannel != 'whatsapp') ||
              (low.contains('facebook') && _selectedChannel != 'facebook') ||
              (low.contains('telegram') && _selectedChannel != 'telegram') ||
              (low.contains('instagram') && _selectedChannel != 'instagram');
        });
        if (hasOtherExplicitChannel) {
          return false;
        }
      }

      // State Filter
      if (_selectedFilter == 'waiting_human' && c.state != 'waiting_human') {
        return false;
      }
      if (_selectedFilter == 'open' && c.state != 'open') {
        return false;
      }
      if (_selectedFilter == 'closed' && c.state != 'closed') {
        return false;
      }

      // Ownership Filter
      if (_selectedOwnership == 'assigned' &&
          (c.assignment == null ||
              c.ownership == 'none' ||
              c.ownership == 'unassigned')) {
        return false;
      }
      if (_selectedOwnership == 'unassigned' &&
          (c.assignment != null &&
              c.ownership != 'none' &&
              c.ownership != 'unassigned')) {
        return false;
      }

      // Search Query
      if (_searchQuery.isNotEmpty) {
        final name = (c.customer.displayName ?? '').toLowerCase();
        final id = c.id.toLowerCase();
        final custId = c.customer.id.toLowerCase();
        final labels = c.labels.join(' ').toLowerCase();
        return name.contains(_searchQuery) ||
            id.contains(_searchQuery) ||
            custId.contains(_searchQuery) ||
            labels.contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    ensureScreenUtilInitialized();
    String strings(String key) => AppStrings.get(key, context);
    final provider = widget.merchantProvider;
    final filtered = _getFilteredConversations();

    return SafeArea(
      child: Container(
        color: AppColors.surface,
        child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => _loadConversations(),
            child: Column(
              children: [
                // Header / Search Bar & Filter Controls
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Title Row matching UI Board ("المحادثات")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'المحادثات',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.headingNavy,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${provider.conversations.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (provider.isLoadingConversations)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              onPressed: _loadConversations,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: strings('refresh'),
                              color: const Color(0xFF64748B),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 1. Channel Filter Bar (WhatsApp, Facebook, Telegram, Instagram)
                      ChannelFilterBar(
                        selectedChannel: _selectedChannel,
                        onChannelSelected: _onChannelSelected,
                      ),
                      const SizedBox(height: 8),

                      // 2. Status & Ownership Filters Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            // State Filter Chips
                            _buildFilterChip(
                              'all',
                              strings('all_conversations'),
                              _selectedFilter,
                              _onStateSelected,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              'waiting_human',
                              strings('waiting_filter'),
                              _selectedFilter,
                              _onStateSelected,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              'open',
                              strings('open_filter'),
                              _selectedFilter,
                              _onStateSelected,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              'closed',
                              strings('closed_filter'),
                              _selectedFilter,
                              _onStateSelected,
                            ),

                            const SizedBox(width: 8),
                            Container(
                              height: 16,
                              width: 1,
                              color: const Color(0xFFE2E8F0),
                            ),
                            const SizedBox(width: 8),

                            // Ownership Filter Chips
                            _buildFilterChip(
                              'all',
                              strings('ownership_all'),
                              _selectedOwnership,
                              _onOwnershipSelected,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              'assigned',
                              strings('ownership_assigned'),
                              _selectedOwnership,
                              _onOwnershipSelected,
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              'unassigned',
                              strings('ownership_unassigned'),
                              _selectedOwnership,
                              _onOwnershipSelected,
                            ),
                          ],
                        ),
                      ),

                      // Active Filters Indicator & Clear All
                      if (_activeFiltersCount > 0) ...[
                        const SizedBox(height: 6),
                        ActiveFiltersHeader(
                          activeCount: _activeFiltersCount,
                          onClear: _clearAllFilters,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Search TextField matching UI Board
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.headingNavy,
                        ),
                        decoration: InputDecoration(
                          hintText: strings('search_conversations'),
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => _searchController.clear(),
                                  color: const Color(0xFF94A3B8),
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Error Display
                if (provider.conversationsError != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildErrorCard(
                      provider.conversationsError!,
                      provider.lastRequestId,
                      strings,
                    ),
                  ),

                // Conversation List or Empty State
                Expanded(
                  child: filtered.isEmpty
                      ? (_activeFiltersCount > 0
                          ? FilterEmptyState(
                              title: strings('no_filtered_results'),
                              subtitle: strings('no_filtered_results_hint'),
                              onClearFilters: _clearAllFilters,
                              clearButtonText: strings('reset_all_filters'),
                            )
                          : _buildEmptyState(strings))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isTablet = constraints.maxWidth >= 600;
                            if (isTablet) {
                              return GridView.builder(
                                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 80.h),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.4,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return _buildConversationCard(item, strings);
                                },
                              );
                            }
                            return ListView.separated(
                              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 80.h),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => SizedBox(height: 8.h),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return _buildConversationCard(item, strings);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Floating Action Button matching UI Board
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.small(
                heroTag: 'inbox_compose_fab',
                backgroundColor: AppColors.primary,
                elevation: 0,
                onPressed: () {},
                child: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildFilterChip(
    String key,
    String label,
    String currentSelection,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = currentSelection == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(key),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildConversationCard(
    Conversation conv,
    String Function(String) strings,
  ) {
    final customerName = conv.customer.displayName ?? conv.customer.id;
    final isWaiting = conv.state == 'waiting_human';
    final detectedChannel = _detectChannel(conv);
    final timeStr = _formatLastActivity(conv.lastActivityAt);

    return InkWell(
      onTap: () => widget.onConversationSelected(conv),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWaiting
                ? const Color(0xFFFCA5A5)
                : const Color(0xFFF1F5F9),
            width: isWaiting ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Channel Badge overlay
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isWaiting
                          ? const Color(0xFFFEE2E2)
                          : AppColors.surfaceContainerLow,
                      child: Text(
                        customerName.isNotEmpty
                            ? customerName.characters.first.toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: isWaiting
                              ? const Color(0xFFEF4444)
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: -2,
                      bottom: -2,
                      child: ChannelBadge(
                        channel: detectedChannel,
                        size: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Center Info: Name + Status & Last Message Preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.headingNavy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        conv.labels.isNotEmpty
                            ? conv.labels.first
                            : (conv.state == 'waiting_human'
                                ? 'هل يمكن التحدث مع موظف الدعم؟'
                                : 'مرحباً، أود الاستفسار عن توفر المنتج...'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Trailing Info: Time & Status Pill Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (timeStr != null)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    _buildStateBadge(conv.state, strings),
                  ],
                ),
              ],
            ),

            // Labels & Ownership row (if any)
            if (conv.labels.isNotEmpty || conv.assignment != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (conv.assignment != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 11,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'معيّن',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...conv.labels.map(
                    (lbl) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$lbl',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStateBadge(String state, String Function(String) strings) {
    Color bg;
    Color fg;
    String label;

    switch (state) {
      case 'waiting_human':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFEF4444);
        label = strings('waiting_filter');
        break;
      case 'closed':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = strings('closed_filter');
        break;
      case 'open':
      default:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF10B981);
        label = strings('open_filter');
        break;
    }

    return StatusBadge(
      label: label,
      color: fg,
      backgroundColor: bg,
    );
  }

  Widget _buildEmptyState(String Function(String) strings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 36,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings('no_conversations'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings('no_messages'),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(
    String error,
    String? requestId,
    String Function(String) strings,
  ) {
    return Container(
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
            ],
          ),
          if (requestId != null) ...[
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${strings('request_id')}: $requestId',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.statusError,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
