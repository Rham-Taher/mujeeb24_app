import 'package:flutter/material.dart';
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
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: strings('catalog_description'),
                      border: const OutlineInputBorder(),
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop();
                final messenger = ScaffoldMessenger.of(context);

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
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(strings('catalog_created_success')),
                      backgroundColor: AppColors.statusSuccess,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.catalogProvider.actionError ??
                            strings('request_failed'),
                      ),
                      backgroundColor: AppColors.statusError,
                    ),
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
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: strings('catalog_description'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          labelText: strings('catalog_status'),
                          border: const OutlineInputBorder(),
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(ctx).pop();
                    final messenger = ScaffoldMessenger.of(context);

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
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(strings('catalog_updated_success')),
                          backgroundColor: AppColors.statusSuccess,
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.catalogProvider.actionError ??
                                strings('request_failed'),
                          ),
                          backgroundColor: AppColors.statusError,
                        ),
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
          appBar: AppBar(
            title: Text(
              strings('catalogs_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: strings('refresh'),
                onPressed: provider.isLoadingCatalogs ? null : _loadCatalogs,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: provider.isPerformingAction
                ? null
                : _showCreateCatalogDialog,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(strings('create_catalog')),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('قوالب المواصفات'),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('all', strings('all_catalogs'), currentFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('active', strings('status_active'), currentFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('draft', strings('status_draft'), currentFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('archived', strings('status_archived'), currentFilter),
                  ],
                ),
              ),

              if (provider.isPerformingAction)
                const LinearProgressIndicator(color: AppColors.primary),

              // Content Area
              Expanded(
                child: provider.isLoadingCatalogs && catalogs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : provider.catalogsError != null && catalogs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 48,
                                    color: AppColors.statusError,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    provider.catalogsError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadCatalogs,
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
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 56,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      strings('no_catalogs'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _showCreateCatalogDialog,
                                      icon: const Icon(Icons.add_rounded),
                                      label: Text(strings('create_catalog')),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadCatalogs,
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                                  itemCount: catalogs.length + (provider.catalogsHasMore ? 1 : 0),
                                  separatorBuilder: (_, index) => const SizedBox(height: 12),
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
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: AppColors.surfaceSubtle,
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

    return Card(
      elevation: 0,
      color: AppColors.surfaceCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderHairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
          padding: const EdgeInsets.all(16),
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
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catalog.name,
                          style: const TextStyle(
                            fontSize: 16,
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
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: strings('edit_catalog'),
                    onPressed: () => _showEditCatalogDialog(catalog),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
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
                        size: 12,
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
