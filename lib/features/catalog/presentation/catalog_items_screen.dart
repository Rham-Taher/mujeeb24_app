import 'package:flutter/material.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/catalog_models.dart';
import '../providers/catalog_provider.dart';
import 'catalog_specification_input.dart';
import 'catalog_item_detail_screen.dart';
import 'catalog_item_form_screen.dart';

/// Screen displaying items within a specific Catalog.
class CatalogItemsScreen extends StatefulWidget {
  final CatalogProvider catalogProvider;
  final String businessId;
  final Catalog catalog;
  final String? businessCurrency;

  const CatalogItemsScreen({
    super.key,
    required this.catalogProvider,
    required this.businessId,
    required this.catalog,
    this.businessCurrency,
  });

  @override
  State<CatalogItemsScreen> createState() => _CatalogItemsScreenState();
}

class _CatalogItemsScreenState extends State<CatalogItemsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
      widget.catalogProvider.fetchAttributeSchemas(widget.businessId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    await widget.catalogProvider.fetchCatalogItems(
      widget.businessId,
      widget.catalog.id,
      refresh: true,
    );
  }

  Future<void> _openCreatedItemOptions(CatalogItem created) async {
    await _loadItems();
    if (!mounted) return;
    // Same lifecycle as the web frontend: save the item first.
    // Product options/variants are a separate, optional follow-up action.
    widget.catalogProvider.selectItem(created);
    final isPhysicalProduct = created.itemType == 'product' ||
        created.itemType == 'physical_good';
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => CatalogItemDetailScreen(
        catalogProvider: widget.catalogProvider,
        businessId: widget.businessId,
        catalogId: widget.catalog.id,
        itemId: created.id,
        businessCurrency: widget.businessCurrency,
        justCreated: true,
        initialTabIndex: isPhysicalProduct ? 1 : 0,
      ),
    ));
    if (mounted) await _loadItems();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.statusSuccess;
      case 'draft':
        return AppColors.statusWarning;
      case 'inactive':
        return AppColors.statusError;
      case 'archived':
      default:
        return AppColors.textMuted;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.statusSuccessContainer;
      case 'draft':
        return AppColors.statusWarningContainer;
      case 'inactive':
        return AppColors.statusErrorContainer;
      case 'archived':
      default:
        return AppColors.surfaceSubtle;
    }
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final provider = widget.catalogProvider;

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final items = provider.catalogItems;
        final currentFilter = provider.itemStatusFilter;

        ensureScreenUtilInitialized();
    return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceCanvas,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 16,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: AppColors.borderHairline,
                height: 1,
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.catalog.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        strings('catalog_items_title'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.onSurfaceVariant),
                tooltip: strings('refresh'),
                onPressed: provider.isLoadingItems ? null : _loadItems,
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final created = await Navigator.of(context).push<CatalogItem>(
                MaterialPageRoute(
                  builder: (_) => CatalogItemFormScreen(
                    catalogProvider: provider,
                    businessId: widget.businessId,
                    catalogId: widget.catalog.id,
                    businessCurrency: widget.businessCurrency,
                  ),
                ),
              );
              if (created != null) {
                await _openCreatedItemOptions(created);
              }
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              strings('create_item'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderHairline),
                    boxShadow: AppShadows.card,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: strings('search_items'),
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                provider.setItemSearchQuery('');
                                _loadItems();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceCanvas,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (query) {
                      provider.setItemSearchQuery(query.trim());
                      _loadItems();
                    },
                  ),
                ),
              ),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    _buildFilterChip('all', strings('all_transactions'), currentFilter),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('active', strings('status_active'), currentFilter),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('draft', strings('status_draft'), currentFilter),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('inactive', strings('status_inactive'), currentFilter),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('archived', strings('status_archived'), currentFilter),
                  ],
                ),
              ),

              if (provider.isPerformingAction)
                const LinearProgressIndicator(color: AppColors.primary, minHeight: 3),

              // Items List
              Expanded(
                child: provider.isLoadingItems && items.isEmpty
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                    : provider.itemsError != null && items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 48,
                                    color: AppColors.statusError,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    provider.itemsError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ElevatedButton(
                                    onPressed: _loadItems,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                    ),
                                    child: Text(strings('retry')),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : items.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      decoration: const BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.category_outlined,
                                        size: 48,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      strings('no_items'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final created =
                                            await Navigator.of(context).push<CatalogItem>(
                                          MaterialPageRoute(
                                            builder: (_) => CatalogItemFormScreen(
                                              catalogProvider: provider,
                                              businessId: widget.businessId,
                                              catalogId: widget.catalog.id,
                                              businessCurrency: widget.businessCurrency,
                                            ),
                                          ),
                                        );
                                        if (created != null) {
                                          await _openCreatedItemOptions(created);
                                        }
                                      },
                                      icon: const Icon(Icons.add_rounded),
                                      label: Text(strings('create_item')),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadItems,
                                color: AppColors.primary,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 88),
                                  itemCount: items.length + (provider.itemsHasMore ? 1 : 0),
                                  separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (context, index) {
                                    if (index == items.length) {
                                      return OutlinedButton(
                                        onPressed: provider.isLoadingItems ? null : () => provider.loadMoreCatalogItems(widget.businessId, widget.catalog.id),
                                        child: Text(provider.isLoadingItems ? 'جاري التحميل...' : 'عرض المزيد من المنتجات'),
                                      );
                                    }
                                    final item = items[index];
                                    return _buildItemCard(item, strings);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label, String current) {
    final isSelected = current == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        widget.catalogProvider.setItemStatusFilter(key);
        _loadItems();
      },
      selectedColor: AppColors.primaryContainer.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      backgroundColor: AppColors.surfaceCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderHairline,
          width: isSelected ? 1.2 : 0.8,
        ),
      ),
    );
  }

  Widget _buildItemCard(
    CatalogItem item,
    String Function(String) strings,
  ) {
    final statusColor = _getStatusColor(item.status);
    final statusBg = _getStatusBgColor(item.status);
    final statusLabel =
        widget.catalogProvider.entityContract.labelItemStatus(item.status);
    final pricingLabel =
        widget.catalogProvider.entityContract.labelPricingMode(item.pricingMode);
    final fulfillmentLabel = widget.catalogProvider.entityContract
        .labelFulfillmentMode(item.fulfillmentMode);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCanvas,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: AppShadows.card,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          widget.catalogProvider.selectItem(item);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CatalogItemDetailScreen(
                catalogProvider: widget.catalogProvider,
                businessId: widget.businessId,
                catalogId: widget.catalog.id,
                itemId: item.id,
                businessCurrency: widget.businessCurrency,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Thumbnail Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.borderHairline),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border:
                                    Border.all(color: AppColors.borderHairline),
                              ),
                              child: Text(
                                merchantItemTypeLabel(item.itemType),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (item.requiresConfirmation) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.statusWarningContainer,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  strings('requires_confirmation'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.statusWarning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.shortDescription != null &&
                            item.shortDescription!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.shortDescription!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 1,
                color: AppColors.borderHairline,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$pricingLabel • $fulfillmentLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
