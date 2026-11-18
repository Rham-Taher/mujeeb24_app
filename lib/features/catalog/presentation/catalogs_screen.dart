import 'package:flutter/material.dart';
import '../../../core/widgets/common_ui_widgets.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/catalog_models.dart';
import '../providers/catalog_provider.dart';
import 'catalog_items_screen.dart';
import 'attribute_schemas_screen.dart';

/// Screen displaying all Catalogs for the current business.
class CatalogsScreen extends StatefulWidget {
  final CatalogProvider catalogProvider;
  final String businessId;
  final String? businessCurrency;

  const CatalogsScreen({
    super.key,
    required this.catalogProvider,
    required this.businessId,
    this.businessCurrency,
  });

  @override
  State<CatalogsScreen> createState() => _CatalogsScreenState();
}

class _CatalogsScreenState extends State<CatalogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCatalogs();
      widget.catalogProvider.fetchEntityContract(widget.businessId);
    });
  }

  Future<void> _loadCatalogs() async {
    await widget.catalogProvider.fetchCatalogs(
      widget.businessId,
      refresh: true,
    );
  }

  void _showCreateCatalogDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        String strings(String key) => AppStrings.get(key, context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Text(strings('create_catalog')),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '${strings('catalog_name')} *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.borderHairline),
                      ),
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
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: strings('catalog_description'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.borderHairline),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(strings('cancel_action')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop();

                final created = await widget.catalogProvider.createCatalog(
                  widget.businessId,
                  CreateCatalogRequest(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isNotEmpty
                        ? descriptionController.text.trim()
                        : null,
                  ),
                );

                if (!mounted) return;
                if (created != null) {
                  showAppAlertDialog(
                    context,
                    message: strings('catalog_created_success'),
                  );
                } else {
                  showAppAlertDialog(
                    context,
                    message: widget.catalogProvider.actionError ??
                        strings('request_failed'),
                    isError: true,
                  );
                }
              },
              child: Text(strings('create_catalog')),
            ),
          ],
        );
      },
    );
  }

  void _showEditCatalogDialog(Catalog catalog) {
    final nameController = TextEditingController(text: catalog.name);
    final descriptionController =
        TextEditingController(text: catalog.description ?? '');
    String selectedStatus = catalog.status;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        String strings(String key) => AppStrings.get(key, context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
              title: Text(strings('edit_catalog')),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: '${strings('catalog_name')} *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.borderHairline),
                          ),
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
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: strings('catalog_description'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.borderHairline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          labelText: strings('catalog_status'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.borderHairline),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text(strings('status_draft')),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text(strings('status_active')),
                          ),
                          DropdownMenuItem(
                            value: 'archived',
                            child: Text(strings('status_archived')),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedStatus = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(strings('cancel_action')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(ctx).pop();

                    final updated = await widget.catalogProvider.updateCatalog(
                      widget.businessId,
                      catalog.id,
                      UpdateCatalogRequest(
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim().isNotEmpty
                            ? descriptionController.text.trim()
                            : null,
                        status: selectedStatus,
                      ),
                      ifMatch: catalog.resourceVersion,
                    );

                    if (!mounted) return;
                    if (updated != null) {
                      showAppAlertDialog(
                        context,
                        message: strings('catalog_updated_success'),
                      );
                    } else {
                      showAppAlertDialog(
                        context,
                        message: widget.catalogProvider.actionError ??
                            strings('request_failed'),
                        isError: true,
                      );
                    }
                  },
                  child: Text(strings('save_changes')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.statusSuccess;
      case 'draft':
        return AppColors.statusWarning;
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
        final catalogs = provider.catalogs;
        final currentFilter = provider.catalogStatusFilter;

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
                  child: Text(
                    strings('catalogs_title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                    '${catalogs.length}',
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
                onPressed: provider.isLoadingCatalogs ? null : _loadCatalogs,
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: provider.isPerformingAction
                ? null
                : _showCreateCatalogDialog,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              strings('create_catalog'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('قوالب المواصفات'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.borderHairline),
                      backgroundColor: AppColors.surfaceCanvas,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AttributeSchemasScreen(
                        catalogProvider: widget.catalogProvider,
                        businessId: widget.businessId,
                      )),
                    ),
                  ),
                ),
              ),

              // Status Filters Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    _buildFilterChip('all', strings('all_catalogs'), currentFilter),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('active', strings('status_active'), currentFilter),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('draft', strings('status_draft'), currentFilter),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('archived', strings('status_archived'), currentFilter),
                  ],
                ),
              ),

              if (provider.isPerformingAction)
                const LinearProgressIndicator(color: AppColors.primary, minHeight: 3),

              // Content Area
              Expanded(
                child: provider.isLoadingCatalogs && catalogs.isEmpty
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                    : provider.catalogsError != null && catalogs.isEmpty
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
                                    provider.catalogsError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ElevatedButton(
                                    onPressed: _loadCatalogs,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(strings('retry')),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : catalogs.isEmpty
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
                                        Icons.inventory_2_outlined,
                                        size: 48,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      strings('no_catalogs'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    ElevatedButton.icon(
                                      onPressed: _showCreateCatalogDialog,
                                      icon: const Icon(Icons.add_rounded),
                                      label: Text(strings('create_catalog')),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadCatalogs,
                                color: AppColors.primary,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 88),
                                  itemCount: catalogs.length + (provider.catalogsHasMore ? 1 : 0),
                                  separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (context, index) {
                                    if (index == catalogs.length) {
                                      return OutlinedButton(
                                        onPressed: provider.isLoadingCatalogs ? null : () => provider.loadMoreCatalogs(widget.businessId),
                                        child: Text(provider.isLoadingCatalogs ? 'جاري التحميل...' : 'عرض المزيد من الكتالوجات'),
                                      );
                                    }
                                    final catalog = catalogs[index];
                                    return _buildCatalogCard(catalog, strings);
                                  },
                                ),
                              ),
              ),
            ],
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
        widget.catalogProvider.setCatalogStatusFilter(key);
        _loadCatalogs();
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

  Widget _buildCatalogCard(
    Catalog catalog,
    String Function(String) strings,
  ) {
    final statusColor = _getStatusColor(catalog.status);
    final statusBg = _getStatusBgColor(catalog.status);
    final statusLabel =
        widget.catalogProvider.entityContract.labelCatalogStatus(catalog.status);

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
          widget.catalogProvider.selectCatalog(catalog);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CatalogItemsScreen(
                catalogProvider: widget.catalogProvider,
                businessId: widget.businessId,
                catalog: catalog,
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catalog.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (catalog.description != null &&
                            catalog.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            catalog.description!,
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
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.onSurfaceVariant),
                    tooltip: strings('edit_catalog'),
                    onPressed: () => _showEditCatalogDialog(catalog),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: AppColors.borderHairline),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        strings('catalog_items_title'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: AppColors.primary,
                      ),
                    ],
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
