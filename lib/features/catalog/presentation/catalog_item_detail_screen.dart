import 'package:flutter/material.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/catalog_models.dart';
import '../providers/catalog_provider.dart';
import 'catalog_item_form_screen.dart';
import 'catalog_specification_input.dart';
import 'merchant_editor_dialog.dart';
import 'catalog_currency_select.dart';

class _VariantAttributeRow {
  final TextEditingController name;
  final TextEditingController text;
  final String? originalKey;
  final dynamic originalValue;
  bool changed = false;

  _VariantAttributeRow({
    String name = '',
    String text = '',
    this.originalKey,
    this.originalValue,
  }) : name = TextEditingController(text: name),
       text = TextEditingController(text: text);

  void dispose() {
    name.dispose();
    text.dispose();
  }
}

/// Screen displaying complete details for a CatalogItem, its Variants, and Offers.
class CatalogItemDetailScreen extends StatefulWidget {
  final CatalogProvider catalogProvider;
  final String businessId;
  final String catalogId;
  final String itemId;
  final String? businessCurrency;
  final bool justCreated;
  final int initialTabIndex;

  const CatalogItemDetailScreen({
    super.key,
    required this.catalogProvider,
    required this.businessId,
    required this.catalogId,
    required this.itemId,
    this.businessCurrency,
    this.justCreated = false,
    this.initialTabIndex = 0,
  });

  @override
  State<CatalogItemDetailScreen> createState() =>
      _CatalogItemDetailScreenState();
}

class _CatalogItemDetailScreenState extends State<CatalogItemDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  AttributeSchema? _schema;
  bool _schemaLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, initialIndex: widget.initialTabIndex, vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    await widget.catalogProvider.fetchItemDetail(
      widget.businessId,
      widget.catalogId,
      widget.itemId,
    );
    final item = widget.catalogProvider.selectedItem;
    if (!mounted || item?.attributeSchemaId == null) {
      if (mounted) setState(() => _schema = null);
      return;
    }
    setState(() => _schemaLoading = true);
    try {
      final schema = await widget.catalogProvider.catalogRepository.getAttributeSchema(
        businessId: widget.businessId, schemaId: item!.attributeSchemaId!);
      if (mounted) setState(() => _schema = schema);
    } catch (_) {
      if (mounted) setState(() => _schema = null);
    } finally {
      if (mounted) setState(() => _schemaLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.statusSuccess;
      case 'draft':
        return AppColors.statusWarning;
      case 'inactive':
      case 'expired':
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
      case 'expired':
        return AppColors.statusErrorContainer;
      case 'archived':
      default:
        return AppColors.surfaceSubtle;
    }
  }

  Color _getAvailabilityColor(String status) {
    switch (status) {
      case 'available':
        return AppColors.statusSuccess;
      case 'unavailable':
        return AppColors.statusError;
      case 'requires_check':
      case 'unknown':
      case 'stale':
      default:
        return AppColors.statusWarning;
    }
  }

  Color _getPriceVerificationColor(String status) {
    switch (status) {
      case 'verified':
        return AppColors.statusSuccess;
      case 'unverified':
      case 'stale':
        return AppColors.statusWarning;
      case 'rejected':
      default:
        return AppColors.statusError;
    }
  }

  // ==========================================
  // Variant Dialogs
  // ==========================================

  void _showAddVariantDialog() => _showVariantDialog();

  void _showEditVariantDialog(Variant variant) =>
      _showVariantDialog(existing: variant);

  Future<void> _showVariantDialog({Variant? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name ?? '');
    final initialValues = Map<String, dynamic>.from(existing?.attributes ?? {});
    final values = Map<String, dynamic>.from(initialValues);
    final removed = <String>{};
    final rows = <_VariantAttributeRow>[];
    final managedDefinitions = _schema?.definitions ?? <AttributeDefinition>[];
    final managedKeys = managedDefinitions.map((d) => d.key).toSet();
    for (final entry in initialValues.entries) {
      if (managedKeys.contains(entry.key) || entry.key.startsWith('attr_')) continue;
      rows.add(_VariantAttributeRow(
        name: entry.key, originalKey: entry.key,
        text: entry.value is String ? entry.value as String : '',
        originalValue: entry.value,
      ));
    }
    String selectedStatus = existing?.status ?? 'active';
    bool busy = false;
    String? error;
    bool attributesDirty = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final contract = widget.catalogProvider.entityContract;
        return StatefulBuilder(builder: (dialogContext, setDialogState) {
          final chosen = values.keys.toSet();
          final notChosen = managedDefinitions
              .where((definition) => !chosen.contains(definition.key)).toList();
          return MerchantEditorDialog(
            title: Text(existing == null ? 'إضافة خيار للمنتج' : 'تعديل خيار المنتج'),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: 'اسم الخيار *',
                          hintText: 'مثل: كبير - أزرق',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                          val == null || val.trim().isEmpty ? 'اكتب اسم الخيار' : null,
                      ),
                      if (existing != null) ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'حالة الخيار'),
                          items: [
                            for (final item in contract.variantStatuses.entries)
                              DropdownMenuItem<String>(
                                value: item.key,
                                child: Text(item.value,
                                  overflow: TextOverflow.ellipsis)),
                            if (!contract.variantStatuses.containsKey(selectedStatus))
                              DropdownMenuItem(value: selectedStatus,
                                child: const Text('حالة محفوظة')),
                          ],
                          onChanged: busy ? null : (val) {
                            if (val != null) setDialogState(() => selectedStatus = val);
                          },
                        ),
                      ],
                      if (_schema != null) ...[
                        const SizedBox(height: 16),
                        const Text('معلومات من قالب المواصفات',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                        for (final def in managedDefinitions)
                          if (values.containsKey(def.key))
                            CatalogSpecificationInput(
                              key: ValueKey('variant-'+def.key),
                              definition: def,
                              value: values[def.key],
                              enabled: !busy,
                              onChanged: (value) => setDialogState(() {
                                if (value == null) {
                                  values.remove(def.key);
                                } else {
                                  values[def.key] = value;
                                }
                                attributesDirty = true;
                              }),
                            ),
                        if (notChosen.isNotEmpty)
                          DropdownButtonFormField<String>(
                            key: ValueKey('variant-add-'+notChosen.length.toString()),
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'إضافة معلومة من القالب'),
                            items: [
                              for (final definition in notChosen)
                                DropdownMenuItem(
                                  value: definition.key,
                                  child: Text(definition.label,
                                    overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: busy ? null : (key) {
                              if (key == null) return;
                              setDialogState(() {
                                // Null marks a selected but not answered attribute.
                                values[key] = null;
                                attributesDirty = true;
                              });
                            },
                          ),
                      ],
                      const SizedBox(height: 16),
                      const Text('معلومات إضافية', style: TextStyle(
                        fontWeight: FontWeight.w600)),
                      for (var index = 0; index < rows.length; index++) ...[
                        Builder(builder: (_) {
                          final row = rows[index];
                          final complex = row.originalKey != null &&
                            row.originalValue is! String;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(children: [
                              Row(children: [
                                Expanded(child: TextFormField(
                                  controller: row.name,
                                  enabled: !busy && row.originalKey == null,
                                  textDirection: TextDirection.rtl,
                                  decoration: const InputDecoration(
                                    labelText: 'اسم المعلومة',
                                    hintText: 'مثل: اللون أو المقاس',
                                  ),
                                )),
                                IconButton(
                                  tooltip: 'حذف المعلومة',
                                  onPressed: busy ? null : () => setDialogState(() {
                                    if (row.originalKey != null) {
                                      removed.add(row.originalKey!);
                                    }
                                    rows.removeAt(index);
                                    attributesDirty = true;
                                    row.dispose();
                                  }),
                                  icon: const Icon(Icons.delete_outline_rounded)),
                              ]),
                              const SizedBox(height: 8),
                              if (complex)
                                Text('القيمة المحفوظة: ${displaySpecification(row.originalValue)} (ستبقى كما هي)')
                              else
                                TextFormField(
                                  controller: row.text,
                                  enabled: !busy,
                                  textDirection: TextDirection.rtl,
                                  decoration: const InputDecoration(
                                    labelText: 'قيمة المعلومة',
                                    hintText: 'اكتب القيمة بالعربية'),
                                  onChanged: (_) { row.changed = true; attributesDirty = true; },
                                ),
                            ]),
                          );
                        }),
                      ],
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => setDialogState(() {
                          rows.add(_VariantAttributeRow());
                        }),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة معلومة'),
                      ),
                      if (_schema == null && initialValues.keys
                          .any((key) => key.startsWith('attr_')))
                        const Text('المواصفات المحفوظة من القالب ستبقى كما هي.',
                          style: TextStyle(fontSize: 12)),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        Text(error!, style: const TextStyle(
                          color: AppColors.statusError)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: busy ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  final next = Map<String, dynamic>.from(values);
                  for (final key in removed) { next.remove(key); }
                  final labels = managedDefinitions.map((d) => d.label.trim()).toSet();
                  for (final row in rows) {
                    final name = row.name.text.trim();
                    final value = row.text.text.trim();
                    final untouched = row.originalKey != null && !row.changed;
                    if (name.isEmpty || (!untouched && value.isEmpty)) {
                      setDialogState(() => error = 'أدخل اسم المعلومة وقيمتها.');
                      return;
                    }
                    if (name.startsWith('attr_') || labels.contains(name) ||
                        next.containsKey(name) && row.originalKey != name) {
                      setDialogState(() => error = 'استخدم اسم معلومة واضحًا وغير مكرر.');
                      return;
                    }
                    if (row.originalKey != null) next.remove(row.originalKey);
                    next[name] = untouched ? row.originalValue : value;
                    labels.add(name);
                  }
                  for (final def in managedDefinitions) {
                    if (!next.containsKey(def.key)) continue;
                    final message = validateSpecification(def, next[def.key]);
                    if (message != null) {
                      setDialogState(() => error = message);
                      return;
                    }
                  }
                  setDialogState(() { busy = true; error = null; });
                  final success = existing == null
                    ? await widget.catalogProvider.createVariant(
                        widget.businessId, widget.itemId,
                        CreateVariantRequest(
                          name: nameController.text.trim(),
                          attributes: next..removeWhere((_, v) => v == null),
                        ))
                    : await widget.catalogProvider.updateVariant(
                        widget.businessId, existing.id,
                        UpdateVariantRequest(
                          name: nameController.text.trim(),
                          status: selectedStatus,
                          attributes: attributesDirty ? (next..removeWhere((_, v) => v == null)) : null,
                        ),
                        ifMatch: existing.resourceVersion,
                      );
                  if (!dialogContext.mounted) return;
                  if (success != null) {
                    Navigator.of(dialogContext).pop(true);
                  } else {
                    setDialogState(() {
                      busy = false;
                      error = widget.catalogProvider.actionError ??
                        'تعذر حفظ الخيار. تحقق من الاتصال.';
                    });
                  }
                },
                child: Text(busy ? 'جاري الحفظ...' : 'حفظ'),
              ),
            ],
          );
        });
      },
    );
    for (final row in rows) { row.dispose(); }
    nameController.dispose();
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ خيار المنتج')));
    }
  }

  // ==========================================
  // Offer Dialogs
  // ==========================================

  void _showAddOfferDialog() => _showOfferDialog();
  void _showEditOfferDialog(Offer offer) => _showOfferDialog(existing: offer);

  void _showOfferDialog({Offer? existing}) {
    final nameController = TextEditingController(
      text: existing?.name ?? 'السعر الأساسي');
    final amountController = TextEditingController(
      text: existing?.amount?.toString() ?? '');
    final currencyController = TextEditingController(
      text: existing?.currency ?? widget.businessCurrency ?? '');
    final pricingUnitController = TextEditingController(
      text: existing?.pricingUnit ?? '');
    final validityFromController = TextEditingController(
      text: existing?.validityFrom ?? '');
    final validityUntilController = TextEditingController(
      text: existing?.validityUntil ?? '');
    final formKey = GlobalKey<FormState>();

    String pricingMode = existing?.pricingMode ?? widget.catalogProvider.selectedItem?.pricingMode ?? 'fixed';
    String availabilityMode =
        existing?.availabilityMode ?? widget.catalogProvider.selectedItem?.availabilityMode ?? 'unknown';
    String? availabilityStatus = existing?.availabilityStatus;
    String fulfillmentMode =
        existing?.fulfillmentMode ?? widget.catalogProvider.selectedItem?.fulfillmentMode ?? 'manual';
    String? selectedVariantId = existing?.variantId;
    String status = existing?.status ?? 'active';
    String? offerError;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        String strings(String key) => AppStrings.get(key, context);
        final contract = widget.catalogProvider.entityContract;
        final variants = widget.catalogProvider.variants;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return MerchantEditorDialog(
              title: Text(existing == null ? strings('add_offer') : strings('edit_offer')),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: '${strings('offer_name')} *',
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
                      DropdownButtonFormField<String>(
                        initialValue: pricingMode,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'طريقة التسعير'),
                        items: [
                          for (final option in contract.pricingModes.entries)
                            DropdownMenuItem(value: option.key,
                              child: Text(merchantCatalogOptionLabel(option.value),
                                overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: isSaving ? null : (value) {
                          if (value != null) setDialogState(() => pricingMode = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (pricingMode != 'quote_required') ...[
                        TextFormField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: pricingMode == 'dynamic'
                              ? 'مبلغ استرشادي (اختياري)' : 'المبلغ',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CatalogCurrencySelect(
                          controller: currencyController, enabled: !isSaving),

                        const SizedBox(height: 12),
                      ] else
                        const Text('لن يُسجل مبلغ. يحدد السعر بعد معرفة الطلب.'),
                      if (['per_unit', 'per_person', 'per_day']
                        .contains(pricingMode))
                        TextFormField(
                          controller: pricingUnitController,
                          decoration: const InputDecoration(
                            labelText: 'السعر لكل ماذا؟',
                            hintText: 'مثل: قطعة أو ساعة',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (variants.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue: selectedVariantId,
                          decoration: InputDecoration(
                            labelText: strings('linked_variant'),
                            border: const OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: const Text('سعر عام لكافة الخيارات'),
                            ),
                            ...variants.map((v) {
                              return DropdownMenuItem<String>(
                                value: v.id,
                                child: Text(v.name),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setDialogState(() => selectedVariantId = val);
                          },
                        ),
                        if (widget.catalogProvider.variantsHasMore)
                          TextButton(
                            onPressed: isSaving ? null : () async {
                              await widget.catalogProvider.loadMoreVariants(
                                widget.businessId, widget.itemId);
                              setDialogState(() {});
                            },
                            child: const Text('عرض المزيد من الخيارات'),
                          ),
                        const SizedBox(height: 12),
                      ],
                      DropdownButtonFormField<String>(
                        initialValue: availabilityMode,
                        decoration: const InputDecoration(
                          labelText: 'كيف تتأكد من التوفر؟',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: [
                          for (final option in contract.availabilityModes.entries)
                            DropdownMenuItem(value: option.key,
                              child: Text(merchantCatalogOptionLabel(option.value),
                                overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: isSaving ? null : (value) {
                          if (value != null) setDialogState(() => availabilityMode = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: availabilityStatus,
                        decoration: InputDecoration(
                          labelText: strings('availability_status'),
                          border: const OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: contract.availabilityStatuses.entries.map((e) {
                          return DropdownMenuItem(
                            value: e.key,
                            child: Text(merchantCatalogOptionLabel(e.value), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => availabilityStatus = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: fulfillmentMode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'طريقة الحصول على المنتج أو الخدمة',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final option in contract.fulfillmentModes.entries)
                            DropdownMenuItem(value: option.key,
                              child: Text(merchantCatalogOptionLabel(option.value),
                                overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: isSaving ? null : (value) {
                          if (value != null) setDialogState(() => fulfillmentMode = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'حالة السعر',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final option in contract.offerStatuses.entries)
                            DropdownMenuItem(value: option.key,
                              child: Text(merchantCatalogOptionLabel(option.value),
                                overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: isSaving ? null : (value) {
                          if (value != null) setDialogState(() => status = value);
                        },
                      ),
                      if (existing != null) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: validityFromController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'بداية صلاحية السعر (اختياري)',
                            suffixIcon: Icon(Icons.event_outlined)),
                          onTap: () async {
                            final initial = DateTime.tryParse(validityFromController.text)
                              ?? DateTime.now();
                            final date = await showDatePicker(
                              context: context, initialDate: initial,
                              firstDate: DateTime(1900), lastDate: DateTime(2100));
                            if (date == null || !context.mounted) return;
                            final time = await showTimePicker(
                              context: context, initialTime: TimeOfDay.fromDateTime(initial));
                            if (time == null) return;
                            final selected = DateTime(date.year, date.month,
                              date.day, time.hour, time.minute);
                            setDialogState(() => validityFromController.text =
                              selected.toUtc().toIso8601String());
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: validityUntilController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'نهاية صلاحية السعر (اختياري)',
                            suffixIcon: Icon(Icons.event_outlined)),
                          onTap: () async {
                            final initial = DateTime.tryParse(validityUntilController.text)
                              ?? DateTime.now();
                            final date = await showDatePicker(
                              context: context, initialDate: initial,
                              firstDate: DateTime(1900), lastDate: DateTime(2100));
                            if (date == null || !context.mounted) return;
                            final time = await showTimePicker(
                              context: context, initialTime: TimeOfDay.fromDateTime(initial));
                            if (time == null) return;
                            final selected = DateTime(date.year, date.month,
                              date.day, time.hour, time.minute);
                            setDialogState(() => validityUntilController.text =
                              selected.toUtc().toIso8601String());
                          },
                        ),
                      ],
                      if (offerError != null)
                        Padding(padding: const EdgeInsets.only(top: 8),
                          child: Text(offerError!,
                            style: const TextStyle(color: AppColors.statusError))),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    if (!widget.catalogProvider.hasLoadedContract) {
                      setDialogState(() => offerError = 'أعد تحميل اختيارات الكتالوج أولًا.');
                      return;
                    }
                    final amount = double.tryParse(amountController.text.trim());
                    final requiresAmount = pricingMode != 'quote_required' &&
                        pricingMode != 'dynamic';
                    final hasAmount = amountController.text.trim().isNotEmpty;
                    final validFrom = DateTime.tryParse(validityFromController.text);
                    final validUntil = DateTime.tryParse(validityUntilController.text);
                    if (existing != null && validFrom != null && validUntil != null &&
                        validFrom.isAfter(validUntil)) {
                      setDialogState(() => offerError =
                        'تاريخ بداية السعر لا يمكن أن يكون بعد نهايته.');
                      return;
                    }
                    if (availabilityStatus == null ||
                        (requiresAmount && (amount == null || amount < 0)) ||
                        (hasAmount && amount == null) ||
                        (hasAmount && !RegExp(r'^[A-Za-z]{3}$')
                          .hasMatch(currencyController.text.trim())) ||
                        (pricingMode == 'per_unit' && pricingUnitController.text.trim().isEmpty)) {
                      setDialogState(() => offerError = 'راجع المبلغ والعملة والتوفر قبل الحفظ.');
                      return;
                    }
                    setDialogState(() { isSaving = true; offerError = null; });
                    final messenger = ScaffoldMessenger.of(context);
                    final result = existing == null
                        ? await widget.catalogProvider.createOffer(
                      widget.businessId,
                      widget.itemId,
                      CreateOfferRequest(
                        name: nameController.text.trim(),
                        pricingMode: pricingMode,
                        amount: amount,
                        currency: amount != null && pricingMode != 'quote_required'
                            ? currencyController.text.trim().toUpperCase() : null,
                        pricingUnit: pricingUnitController.text.trim().isNotEmpty
                            ? pricingUnitController.text.trim()
                            : pricingMode == 'per_person' ? 'person'
                            : pricingMode == 'per_day' ? 'day' : null,
                        availabilityMode: availabilityMode,
                        availabilityStatus: availabilityStatus!,
                        fulfillmentMode: fulfillmentMode,
                        variantId: selectedVariantId,
                        status: status,
                      ),
                    )
                        : await widget.catalogProvider.updateOffer(
                          widget.businessId,
                          existing.id,
                          UpdateOfferRequest(
                            name: nameController.text.trim(),
                            pricingMode: pricingMode,
                            amount: pricingMode == 'quote_required' ? null : amount,
                            currency: amount != null && pricingMode != 'quote_required'
                              ? currencyController.text.trim().toUpperCase() : null,
                            pricingUnit: pricingUnitController.text.trim().isNotEmpty
                              ? pricingUnitController.text.trim()
                              : pricingMode == 'per_person' ? 'person'
                              : pricingMode == 'per_day' ? 'day' : null,
                            availabilityMode: availabilityMode,
                            availabilityStatus: availabilityStatus!,
                            fulfillmentMode: fulfillmentMode,
                            variantId: selectedVariantId,
                            status: status,
                            validityFrom: validityFromController.text.trim().isEmpty
                              ? null : validityFromController.text.trim(),
                            validityUntil: validityUntilController.text.trim().isEmpty
                              ? null : validityUntilController.text.trim(),
                            sendNullableFields: true,
                          ),
                          ifMatch: existing.resourceVersion,
                        );

                    if (!mounted || !ctx.mounted) return;
                    if (result != null) {
                      Navigator.of(ctx).pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(existing == null
                            ? strings('offer_created_success')
                            : strings('offer_updated_success')),
                          backgroundColor: AppColors.statusSuccess,
                        ),
                      );
                    } else {
                      setDialogState(() {
                        isSaving = false;
                        offerError = widget.catalogProvider.actionError ??
                            strings('request_failed');
                      });
                    }
                  },
                  child: Text(isSaving ? 'جاري الحفظ...' :
                    (existing == null ? strings('add_offer') : strings('save_changes'))),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      amountController.dispose();
      currencyController.dispose();
      pricingUnitController.dispose();
      validityFromController.dispose();
      validityUntilController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final provider = widget.catalogProvider;

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final item = provider.selectedItem;
        final variants = provider.variants;
        final offers = provider.offers;
        final contract = provider.entityContract;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              item?.name ?? strings('catalog_items_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            actions: [
              if (item != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: strings('edit_item'),
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<CatalogItem>(
                      MaterialPageRoute(
                        builder: (_) => CatalogItemFormScreen(
                          catalogProvider: provider,
                          businessId: widget.businessId,
                          catalogId: widget.catalogId,
                          existingItem: item,
                          businessCurrency: widget.businessCurrency,
                        ),
                      ),
                    );
                    if (updated != null) {
                      _loadDetails();
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: strings('refresh'),
                onPressed: provider.isLoadingItemDetail ? null : _loadDetails,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: strings('overview_tab')),
                Tab(text: '${strings('variants_tab')} (${variants.length})'),
                Tab(text: '${strings('offers_tab')} (${offers.length})'),
              ],
            ),
          ),
          body: provider.isLoadingItemDetail && item == null
              ? const Center(child: CircularProgressIndicator())
              : provider.itemDetailError != null && item == null
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
                              provider.itemDetailError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDetails,
                              child: Text(strings('retry')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : item == null
                      ? Center(child: Text(strings('no_items')))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(item, contract, strings),
                            _buildVariantsTab(variants, contract, strings),
                            _buildOffersTab(offers, contract, strings),
                          ],
                        ),
        );
      },
    );
  }

  // ==========================================
  // Tab 1: Overview
  // ==========================================

  Widget _buildOverviewTab(
    CatalogItem item,
    CatalogEntityContract contract,
    String Function(String) strings,
  ) {
    final statusColor = _getStatusColor(item.status);
    final statusBg = _getStatusBgColor(item.status);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main Info Card
        Card(
          elevation: 0,
          color: AppColors.surfaceCanvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderHairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        contract.labelItemStatus(item.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${strings('item_type')}: ${merchantItemTypeLabel(item.itemType)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (item.shortDescription != null &&
                    item.shortDescription!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.shortDescription!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (item.longDescription != null &&
                    item.longDescription!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    item.longDescription!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Modes Card
        Card(
          elevation: 0,
          color: AppColors.surfaceCanvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderHairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  strings('pricing_mode'),
                  merchantCatalogOptionLabel(contract.labelPricingMode(item.pricingMode)),
                  Icons.price_change_rounded,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  strings('availability_mode'),
                  merchantCatalogOptionLabel(contract.labelAvailabilityMode(item.availabilityMode)),
                  Icons.event_available_rounded,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  strings('fulfillment_mode'),
                  merchantCatalogOptionLabel(contract.labelFulfillmentMode(item.fulfillmentMode)),
                  Icons.local_shipping_rounded,
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  strings('requires_confirmation'),
                  item.requiresConfirmation
                      ? strings('status_pending')
                      : strings('status_approved'),
                  Icons.verified_user_rounded,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_schemaLoading) const LinearProgressIndicator(),
        // Custom Attributes Card
        Card(
          elevation: 0,
          color: AppColors.surfaceCanvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderHairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings('attributes'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (item.attributes.isEmpty)
                  Text(
                    'لم تضف معلومات أو مواصفات بعد',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  )
                else
                  ...item.attributes.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              specificationName(e.key,
                                _schema?.definitions ?? <AttributeDefinition>[]),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displaySpecification(e.value),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Tab 2: Variants
  // ==========================================

  Widget _postCreateBanner() => Card(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    color: AppColors.surfaceCanvas,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.check_circle_outline_rounded,
              color: AppColors.statusSuccess),
            SizedBox(width: 10),
            Expanded(child: Text('تم حفظ المنتج كمسودة',
              style: TextStyle(fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 8),
          const Text(
            'هذه الخطوة اختيارية. إذا كان للمنتج مقاسات أو ألوان أو خيارات مختلفة، أضفها الآن. يمكنك تجاوزها والعودة إليها لاحقًا.',
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إنهاء الآن'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildVariantsTab(
    List<Variant> variants,
    CatalogEntityContract contract,
    String Function(String) strings,
  ) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVariantDialog,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(strings('add_variant')),
      ),
      body: Column(children: [
        if (widget.justCreated) _postCreateBanner(),
        Expanded(child: widget.catalogProvider.isLoadingVariants &&
                variants.isEmpty
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text('جاري تحميل متغيرات المنتج'),
              ],
            ))
          : widget.catalogProvider.variantsError != null &&
                variants.isEmpty
          ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                    color: AppColors.textMuted, size: 40),
                  const SizedBox(height: 12),
                  Text(widget.catalogProvider.variantsError!,
                    textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => widget.catalogProvider.refreshVariants(
                      widget.businessId, widget.itemId),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة تحميل المتغيرات'),
                  ),
                  const SizedBox(height: 12),
                  const Text('تم حفظ المنتج، ويمكنك العودة لإضافة متغيراته لاحقًا.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ))
          : variants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.style_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings('no_variants'),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddVariantDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(strings('add_variant')),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: variants.length + (widget.catalogProvider.variantsHasMore ? 1 : 0),
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == variants.length) {
                  return OutlinedButton(
                    onPressed: widget.catalogProvider.loadingMoreVariants ? null
                      : () => widget.catalogProvider.loadMoreVariants(
                        widget.businessId, widget.itemId),
                    child: Text(widget.catalogProvider.loadingMoreVariants
                      ? 'جاري التحميل...' : 'عرض المزيد من الخيارات'),
                  );
                }
                final v = variants[index];
                final statusColor = _getStatusColor(v.status);
                final statusBg = _getStatusBgColor(v.status);
                final statusLabel = contract.labelVariantStatus(v.status);

                return Card(
                  elevation: 0,
                  color: AppColors.surfaceCanvas,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderHairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(
                              v.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(maxWidth: 115),
                                  child: Text(
                                    statusLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 18),
                                  tooltip: strings('edit_variant'),
                                  onPressed: () => _showEditVariantDialog(v),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (v.attributes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: v.attributes.entries.map((attr) {
                              return Chip(
                                label: Text(
                                  '${specificationName(attr.key, _schema?.definitions ?? <AttributeDefinition>[])}: ${displaySpecification(attr.value)}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ),
      ]),
    );
  }


  // ==========================================
  // Tab 3: Offers
  // ==========================================

  Widget _buildOffersTab(
    List<Offer> offers,
    CatalogEntityContract contract,
    String Function(String) strings,
  ) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOfferDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(strings('add_offer')),
      ),
      body: widget.catalogProvider.isLoadingOffers && offers.isEmpty
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text('جاري تحميل عروض المنتج'),
              ],
            ))
          : widget.catalogProvider.offersError != null && offers.isEmpty
          ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                    color: AppColors.textMuted, size: 40),
                  const SizedBox(height: 12),
                  Text(widget.catalogProvider.offersError!,
                    textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => widget.catalogProvider.refreshOffers(
                      widget.businessId, widget.itemId),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة تحميل الأسعار'),
                  ),
                ],
              ),
            ))
          : offers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings('no_offers'),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddOfferDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(strings('add_offer')),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: offers.length + (widget.catalogProvider.offersHasMore ? 1 : 0),
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == offers.length) {
                  return OutlinedButton(
                    onPressed: widget.catalogProvider.loadingMoreOffers ? null
                      : () => widget.catalogProvider.loadMoreOffers(
                        widget.businessId, widget.itemId),
                    child: Text(widget.catalogProvider.loadingMoreOffers
                      ? 'جاري التحميل...' : 'عرض المزيد من الأسعار'),
                  );
                }
                final offer = offers[index];
                final statusColor = _getStatusColor(offer.status);
                final statusBg = _getStatusBgColor(offer.status);
                final statusLabel = contract.labelOfferStatus(offer.status);

                final availColor =
                    _getAvailabilityColor(offer.availabilityStatus);
                final availLabel = contract
                    .labelAvailabilityStatus(offer.availabilityStatus);

                final priceVerifColor =
                    _getPriceVerificationColor(offer.priceVerificationStatus);
                final priceVerifLabel = contract
                    .labelPriceVerification(offer.priceVerificationStatus);

                return Card(
                  elevation: 0,
                  color: AppColors.surfaceCanvas,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderHairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                offer.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(10),
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
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 18),
                                  tooltip: strings('edit_offer'),
                                  onPressed: () => _showEditOfferDialog(offer),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              offer.amount != null
                                  ? '${offer.amount!.toStringAsFixed(2)} ${offer.currency ?? ''}'
                                  : strings('pricing_mode'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (offer.pricingUnit != null &&
                                offer.pricingUnit!.isNotEmpty) ...[
                              Text(
                                ' / ${offer.pricingUnit!}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: availColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${strings('availability_status')}: $availLabel',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: availColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priceVerifColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${strings('price_verification')}: $priceVerifLabel',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: priceVerifColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
