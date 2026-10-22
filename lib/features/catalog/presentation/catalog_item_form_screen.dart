import 'package:flutter/material.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/catalog_models.dart';
import '../providers/catalog_provider.dart';
import 'catalog_specification_input.dart';
import 'catalog_currency_select.dart';

/// Form screen for creating or editing a CatalogItem.
class CatalogItemFormScreen extends StatefulWidget {
  final CatalogProvider catalogProvider;
  final String businessId;
  final String catalogId;
  final String? businessCurrency;
  final CatalogItem? existingItem;

  const CatalogItemFormScreen({
    super.key,
    required this.catalogProvider,
    required this.businessId,
    required this.catalogId,
    this.businessCurrency,
    this.existingItem,
  });

  @override
  State<CatalogItemFormScreen> createState() => _CatalogItemFormScreenState();
}

class _AttributeEntryController {
  final TextEditingController keyController;
  final TextEditingController valueController;
  final String? originalKey;
  final dynamic originalValue;
  bool changed = false;

  _AttributeEntryController({String key = '', String value = '',
      this.originalKey, this.originalValue})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _CatalogItemFormScreenState extends State<CatalogItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _itemTypeController;
  late final TextEditingController _shortDescController;
  late final TextEditingController _longDescController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _unitController;
  String? _availabilityStatus;
  bool _saveInitialOffer = true;
  bool _skipPricingForDraft = false;
  int _step = 0;
  bool _customItemType = false;

  late String _selectedPricingMode;
  late String _selectedAvailabilityMode;
  late String _selectedFulfillmentMode;
  late String _selectedStatus;
  late bool _requiresConfirmation;
  String? _selectedAttributeSchemaId;

  final List<_AttributeEntryController> _attributeControllers = [];
  final Map<String, dynamic> _attributeValues = {};
  final Set<String> _removedKeys = {};
  AttributeSchema? _selectedSchema;
  bool _schemaLoading = false;
  String? _schemaError;
  String? _customError;
  bool _attributesDirty = false;
  bool _isSaving = false;
  bool _manualInitialized = false;

  bool get _isEditing => widget.existingItem != null;

  bool get _draftWithoutPricing =>
      !_isEditing && (_skipPricingForDraft || !_saveInitialOffer);

  // Backend catalog contract defaults for an item without an initial offer.
  // No price, availability or fulfillment promise is created.
  static const _draftPricingMode = 'quote_required';
  static const _draftAvailabilityMode = 'unknown';
  static const _draftFulfillmentMode = 'manual';

  void _contractChanged() {
    if (mounted) setState(() {});
  }

  void _continueAsDraft() {
    if (_isEditing) return;
    setState(() {
      _saveInitialOffer = false;
      _skipPricingForDraft = true;
      _step = 2;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.catalogProvider.addListener(_contractChanged);
    final item = widget.existingItem;

    _nameController = TextEditingController(text: item?.name ?? '');
    _itemTypeController =
        TextEditingController(text: item?.itemType ?? 'product');
    _shortDescController =
        TextEditingController(text: item?.shortDescription ?? '');
    _longDescController =
        TextEditingController(text: item?.longDescription ?? '');

    if (item != null) {
      const known = ['product', 'physical_good', 'service',
        'consultation', 'booking', 'real_estate', 'course', 'subscription'];
      _customItemType = !known.contains(item.itemType);
    }
    _selectedPricingMode = item?.pricingMode ?? 'fixed';
    _selectedAvailabilityMode = item?.availabilityMode ?? 'unknown';
    _selectedFulfillmentMode = item?.fulfillmentMode ?? 'manual';
    _selectedStatus = item?.status ?? 'draft';
    _requiresConfirmation = item?.requiresConfirmation ?? false;
    _selectedAttributeSchemaId = item?.attributeSchemaId;
    _amountController = TextEditingController();
    _currencyController = TextEditingController(text: widget.businessCurrency ?? '');
    _unitController = TextEditingController();

    if (item != null) _attributeValues.addAll(item.attributes);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.catalogProvider.fetchEntityContract(widget.businessId);
      if (!mounted) return;
      await widget.catalogProvider.fetchAttributeSchemas(widget.businessId);
      if (!mounted) return;
      await _selectSchema(_selectedAttributeSchemaId);
    });
  }

  @override
  void dispose() {
    widget.catalogProvider.removeListener(_contractChanged);
    _nameController.dispose();
    _itemTypeController.dispose();
    _shortDescController.dispose();
    _longDescController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _unitController.dispose();
    for (final c in _attributeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _selectSchema(String? schemaId) async {
    if (_selectedAttributeSchemaId != schemaId && !_isEditing) {
      _attributeValues.removeWhere((key, _) =>
        _selectedSchema?.definitions.any((d) => d.key == key) ?? false);
      _attributesDirty = true;
    }
    setState(() {
      _selectedAttributeSchemaId = schemaId;
      _selectedSchema = null;
      _schemaError = null;
      _schemaLoading = schemaId != null;
    });
    if (schemaId != null) {
      try {
        final schema = await widget.catalogProvider.catalogRepository.getAttributeSchema(
          businessId: widget.businessId, schemaId: schemaId);
        if (!mounted || schemaId != _selectedAttributeSchemaId) return;
        setState(() => _selectedSchema = schema);
      } catch (_) {
        if (!mounted || schemaId != _selectedAttributeSchemaId) return;
        setState(() => _schemaError =
          'تعذر تحميل أسئلة قالب المواصفات. أعد اختياره.');
      } finally {
        if (mounted && schemaId == _selectedAttributeSchemaId) {
          setState(() => _schemaLoading = false);
        }
      }
    }
    if (_isEditing && !_manualInitialized && mounted) {
      final managed = _selectedSchema?.definitions.map((d) => d.key).toSet() ??
          <String>{};
      for (final entry in widget.existingItem!.attributes.entries) {
        // An opaque server key is never presented as a merchant-editable label.
        if (managed.contains(entry.key) || entry.key.startsWith('attr_')) continue;
        _attributeControllers.add(_AttributeEntryController(
          key: entry.key,
          value: entry.value is String ? entry.value as String : '',
          originalKey: entry.key,
          originalValue: entry.value,
        ));
      }
      _manualInitialized = true;
      setState(() {});
    }
  }

  void _addAttribute() {
    setState(() => _attributeControllers.add(_AttributeEntryController()));
  }

  void _removeAttribute(int index) {
    setState(() {
      final removed = _attributeControllers.removeAt(index);
      if (removed.originalKey != null) _removedKeys.add(removed.originalKey!);
      _attributesDirty = true;
      removed.dispose();
    });
  }

  void _changeManagedAttribute(String key, dynamic value) {
    setState(() {
      if (value == null || (value is String && value.isEmpty)) {
        _attributeValues.remove(key);
      } else {
        _attributeValues[key] = value;
      }
      _attributesDirty = true;
    });
  }

  String? _validateAttributes() {
    if (_schemaLoading) return 'انتظر تحميل قالب المواصفات.';
    if (_selectedAttributeSchemaId != null && _selectedSchema == null) {
      return _schemaError ?? 'تعذر تحميل قالب المواصفات. أعد المحاولة.';
    }
    final definitions = _selectedSchema?.definitions ?? <AttributeDefinition>[];
    for (final definition in definitions) {
      final error = validateSpecification(definition, _attributeValues[definition.key]);
      if (error != null) return error;
    }
    final names = definitions.map((d) => d.label.trim()).toSet();
    final originalManagedKeys = definitions.map((d) => d.key).toSet();
    for (final row in _attributeControllers) {
      final key = row.keyController.text.trim();
      final value = row.valueController.text.trim();
      final isUntouchedSavedValue = row.originalKey != null && !row.changed;
      if (key.isEmpty && value.isEmpty && row.originalKey == null) continue;
      if (key.isEmpty || (!isUntouchedSavedValue && value.isEmpty)) {
        return 'اكتب اسم المعلومة وقيمتها، أو احذف السطر.';
      }
      if (key.startsWith('attr_') || key.length > 120 ||
          key.runes.any((r) => r < 32 || r == 127) ||
          originalManagedKeys.contains(key)) {
        return 'استخدم اسم معلومة طبيعيًا، مثل الضمان أو اللون.';
      }
      if (!names.add(key)) return 'هذه المعلومة موجودة بالفعل: $key';
    }
    return null;
  }

  Map<String, dynamic> _collectAttributes() {
    final map = Map<String, dynamic>.from(_attributeValues);
    for (final removed in _removedKeys) {
      map.remove(removed);
    }
    for (final row in _attributeControllers) {
      final name = row.keyController.text.trim();
      if (name.isEmpty) continue;
      if (row.originalKey != null && row.originalKey != name) {
        map.remove(row.originalKey);
      }
      if (row.originalKey != null && !row.changed &&
          row.originalKey == name) {
        map[name] = row.originalValue;
      } else {
        map[name] = row.valueController.text.trim();
      }
    }
    return map;
  }

  String _reviewPrice() {
    if (_selectedPricingMode == 'quote_required') return 'يحدد بعد معرفة الطلب';
    if (_amountController.text.trim().isEmpty) return 'سعر متغير يحتاج تأكدًا';
    return '${_amountController.text.trim()} ${_currencyController.text.trim().toUpperCase()}';
  }

  String _itemTypeName(String type) {
    const types = {
      'product': 'منتج', 'physical_good': 'منتج',
      'service': 'خدمة', 'consultation': 'استشارة',
      'booking': 'حجز', 'real_estate': 'عقار',
      'course': 'دورة', 'subscription': 'اشتراك',
    };
    return types[type] ?? type;
  }

  void _nextStep() {
    if (_step == 0 && !_formKey.currentState!.validate()) return;
    if (_step == 0 && _itemTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر نوع المنتج أو الخدمة')));
      return;
    }
    if (_step == 0) {
      final attributesError = _validateAttributes();
      if (attributesError != null) {
        setState(() => _customError = attributesError);
        return;
      }
      setState(() => _customError = null);
    }
    if (_step == 1 && !widget.catalogProvider.hasLoadedContract) {
      _continueAsDraft();
      return;
    }
    if (_step == 1 && _saveInitialOffer) {
      final amount = double.tryParse(_amountController.text.trim());
      final needsAmount = _selectedPricingMode != 'quote_required' &&
          _selectedPricingMode != 'dynamic';
      final needsUnit = _selectedPricingMode == 'per_unit';
      if (_availabilityStatus == null ||
          (needsAmount && (amount == null || amount < 0)) ||
          (_amountController.text.trim().isNotEmpty && amount == null) ||
          (needsUnit && _unitController.text.trim().isEmpty) ||
          ((needsAmount || (_selectedPricingMode == 'dynamic' && amount != null)) &&
              !RegExp(r'^[A-Za-z]{3}$').hasMatch(_currencyController.text.trim()))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('راجع السعر والعملة وحدد حالة التوفر قبل المتابعة')),
        );
        return;
      }
    }
    setState(() => _step++);
  }

  Future<void> _submit() async {
    if (!_isEditing && _step != 2) return;
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (!widget.catalogProvider.hasLoadedContract &&
        !(!_isEditing && _draftWithoutPricing)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حمّل اختيارات السعر أو احفظ المنتج مسودة دون سعر.')));
      return;
    }
    final attributesError = _validateAttributes();
    if ((_attributesDirty || !_isEditing) && attributesError != null) {
      setState(() => _customError = attributesError);
      if (!_isEditing) setState(() => _step = 0);
      return;
    }
    setState(() => _isSaving = true);

    String strings(String key) => AppStrings.get(key, context);
    final attributes = _collectAttributes();
    final parsedAmount = double.tryParse(_amountController.text.trim());
    final effectiveUnit = _unitController.text.trim().isNotEmpty
        ? _unitController.text.trim()
        : _selectedPricingMode == 'per_person'
            ? 'person'
            : _selectedPricingMode == 'per_day' ? 'day' : null;
    final unconfiguredDraft = _skipPricingForDraft ||
        !widget.catalogProvider.hasLoadedContract;


    CatalogItem? result;
    if (_isEditing) {
      final updateReq = UpdateCatalogItemRequest(
        name: _nameController.text.trim(),
        itemType: _itemTypeController.text.trim(),
        pricingMode: _selectedPricingMode,
        availabilityMode: _selectedAvailabilityMode,
        fulfillmentMode: _selectedFulfillmentMode,
        status: _selectedStatus,
        requiresConfirmation: _requiresConfirmation,
        shortDescription: _shortDescController.text.trim().isNotEmpty
            ? _shortDescController.text.trim()
            : null,
        longDescription: _longDescController.text.trim().isNotEmpty
            ? _longDescController.text.trim()
            : null,
        attributes: _attributesDirty ? attributes : null,
      );

      result = await widget.catalogProvider.updateCatalogItem(
        widget.businessId,
        widget.catalogId,
        widget.existingItem!.id,
        updateReq,
        ifMatch: widget.existingItem!.resourceVersion,
      );
    } else {
      final createReq = CreateCatalogItemRequest(
        name: _nameController.text.trim(),
        itemType: _itemTypeController.text.trim(),
        pricingMode: unconfiguredDraft ? _draftPricingMode : _selectedPricingMode,
        availabilityMode: unconfiguredDraft ? _draftAvailabilityMode : _selectedAvailabilityMode,
        fulfillmentMode: unconfiguredDraft ? _draftFulfillmentMode : _selectedFulfillmentMode,
        requiresConfirmation: _requiresConfirmation,
        shortDescription: _shortDescController.text.trim().isNotEmpty
            ? _shortDescController.text.trim()
            : null,
        longDescription: _longDescController.text.trim().isNotEmpty
            ? _longDescController.text.trim()
            : null,
        attributeSchemaId: _selectedAttributeSchemaId,
        attributes: attributes,
        initialOffer: !_draftWithoutPricing && !unconfiguredDraft ? CreateOfferRequest(
          name: 'السعر الأساسي',
          pricingMode: _selectedPricingMode,
          amount: _selectedPricingMode == 'quote_required' ? null : parsedAmount,
          currency: parsedAmount != null && _selectedPricingMode != 'quote_required'
              ? _currencyController.text.trim().toUpperCase() : null,
          pricingUnit: ['per_unit', 'per_person', 'per_day'].contains(_selectedPricingMode)
              ? effectiveUnit : null,
          availabilityMode: _selectedAvailabilityMode,
          availabilityStatus: _availabilityStatus!,
          fulfillmentMode: _selectedFulfillmentMode,
          status: 'active',
        ) : null,
      );

      result = await widget.catalogProvider.createCatalogItem(
        widget.businessId,
        widget.catalogId,
        createReq,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? strings('item_updated_success')
                  : strings('item_created_success'),
            ),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
        Navigator.of(context).pop(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.catalogProvider.actionError ?? strings('request_failed'),
            ),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final contract = widget.catalogProvider.entityContract;
    final isBusy = widget.catalogProvider.isPerformingAction || _isSaving;
    final schemas = widget.catalogProvider.attributeSchemas;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? strings('edit_item') : strings('create_item'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            if (!_isEditing) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  minHeight: 5,
                  backgroundColor: AppColors.borderHairline,
                ),
              ),
              const SizedBox(height: 12),
              Text('الخطوة ${_step + 1} من 3',
                style: const TextStyle(color: AppColors.primary,
                  fontWeight: FontWeight.bold)),
              Text(const [
                'ما الذي تقدمه؟', 'السعر والتوفر', 'راجع واحفظ',
              ][_step], style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 18),
            ],
            if (_isEditing || _step == 0) ...[
            // Item Name
            TextFormField(
              controller: _nameController,
              enabled: !isBusy,
              decoration: InputDecoration(
                labelText: '${strings('item_name')} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return strings('required_field');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Use the same merchant vocabulary in create and edit.
            DropdownButtonFormField<String>(
              key: ValueKey('item-type-' + (_customItemType ? 'custom' :
                _itemTypeController.text.trim())),
              initialValue: _customItemType ? 'custom' :
                _itemTypeController.text.trim(),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'ما الذي تقدمه؟',
                border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: 'product', child: Text('منتج')),
                if (_isEditing && widget.existingItem?.itemType == 'physical_good')
                  const DropdownMenuItem(value: 'physical_good', child: Text('منتج')),
                const DropdownMenuItem(value: 'service', child: Text('خدمة')),
                const DropdownMenuItem(value: 'consultation', child: Text('استشارة')),
                const DropdownMenuItem(value: 'booking', child: Text('حجز')),
                const DropdownMenuItem(value: 'real_estate', child: Text('عقار')),
                const DropdownMenuItem(value: 'course', child: Text('دورة')),
                const DropdownMenuItem(value: 'subscription', child: Text('اشتراك')),
                const DropdownMenuItem(value: 'custom', child: Text('نوع آخر')),
              ],
              onChanged: isBusy ? null : (type) {
                if (type == null) return;
                setState(() {
                  _customItemType = type == 'custom';
                  if (!_customItemType) _itemTypeController.text = type;
                  if (_customItemType && !_isEditing) _itemTypeController.clear();
                });
              },
            ),
            if (_customItemType) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _itemTypeController,
                enabled: !isBusy,
                decoration: const InputDecoration(
                  labelText: 'اسم النوع',
                  hintText: 'مثل: بطاقة حضور',
                  border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty
                  ? strings('required_field') : null,
              ),
            ],
            const SizedBox(height: 16),

            // Short Description
            TextFormField(
              controller: _shortDescController,
              enabled: !isBusy,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'وصف قصير يساعد العميل يفهم ما تقدمه',
                labelText: strings('short_description'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Long Description
            TextFormField(
              controller: _longDescController,
              enabled: !isBusy,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'أضف التفاصيل التي يحتاج العميل إلى معرفتها',
                labelText: strings('long_description'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Arabic merchant specifications: the server owns opaque schema keys.
            const SizedBox(height: 4),
            Text('المعلومات والمواصفات (اختياري)',
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('مثل اللون أو الضمان. خيارات المقاس واللون التي يختارها العميل تضاف بعد حفظ المنتج.'),
            const SizedBox(height: 12),
            if (!_isEditing && widget.catalogProvider.schemasError != null)
              Card(child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Text(widget.catalogProvider.schemasError!),
                  TextButton(
                    onPressed: () => widget.catalogProvider.fetchAttributeSchemas(widget.businessId),
                    child: const Text('إعادة تحميل القوالب')),
                ]),
              )),
            if (!_isEditing && schemas.isNotEmpty)
              DropdownButtonFormField<String>(
                key: ValueKey('schema-${_selectedAttributeSchemaId ?? 'none'}'),
                initialValue: _selectedAttributeSchemaId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'استخدام قالب مواصفات', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String>(
                    value: null, child: Text('سأضيف المعلومات بنفسي')),
                  for (final schema in schemas)
                    DropdownMenuItem<String>(
                      value: schema.id,
                      child: Text(schema.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: isBusy ? null : (value) => _selectSchema(value),
              ),
            if (_isEditing && _selectedAttributeSchemaId != null)
              Text(_selectedSchema == null
                ? 'جاري تحميل قالب المواصفات المحفوظ'
                : 'قالب المواصفات الحالي: ${_selectedSchema!.name}'),
            if (_schemaLoading) const LinearProgressIndicator(),
            if (_schemaError != null)
              Card(child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Text(_schemaError!, style: const TextStyle(color: AppColors.statusError)),
                  TextButton(onPressed: () => _selectSchema(_selectedAttributeSchemaId),
                    child: const Text('إعادة تحميل المواصفات')),
                ]),
              )),
            if (_selectedSchema != null) ...[
              const SizedBox(height: 14),
              for (final definition in (_selectedSchema!.definitions.toList()
                ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder))))
                CatalogSpecificationInput(
                  key: ValueKey('spec-${definition.key}'),
                  definition: definition,
                  value: _attributeValues[definition.key],
                  enabled: !isBusy,
                  onChanged: (value) => _changeManagedAttribute(definition.key, value),
                ),
            ],
            const SizedBox(height: 12),
            Text('معلومات أخرى', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (var index = 0; index < _attributeControllers.length; index++) ...[
              Builder(builder: (context) {
                final row = _attributeControllers[index];
                final isStructuredSaved = row.originalKey != null &&
                  row.originalValue is! String;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text('المعلومة ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600))),
                          IconButton(
                            tooltip: 'حذف المعلومة',
                            onPressed: isBusy ? null : () => _removeAttribute(index),
                            icon: const Icon(Icons.delete_outline_rounded)),
                        ]),
                        TextFormField(
                          controller: row.keyController,
                          enabled: !isBusy && row.originalKey == null,
                          textDirection: TextDirection.rtl,
                          decoration: const InputDecoration(
                            labelText: 'اسم المعلومة',
                            hintText: 'مثل: الضمان أو اللون',
                            border: OutlineInputBorder()),
                          onChanged: (_) { row.changed = true; _attributesDirty = true; },
                        ),
                        const SizedBox(height: 10),
                        if (isStructuredSaved) ...[
                          Text('القيمة: ${displaySpecification(row.originalValue)}'),
                          const Text('هذه القيمة محفوظة بنوعها الأصلي ولن تتحول إلى نص عند الحفظ.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ] else
                          TextFormField(
                            controller: row.valueController,
                            enabled: !isBusy,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              labelText: 'قيمة المعلومة',
                              hintText: 'اكتب القيمة بالعربية',
                              border: OutlineInputBorder()),
                            onChanged: (_) { row.changed = true; _attributesDirty = true; },
                          ),
                      ],
                    ),
                  )),
                );
              }),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded),
              onPressed: isBusy ? null : _addAttribute,
              label: const Text('إضافة معلومة'),
            ),
            if (_customError != null) ...[
              const SizedBox(height: 8),
              Text(_customError!, style: const TextStyle(color: AppColors.statusError)),
            ],
            if (_isEditing && _selectedSchema == null &&
                widget.existingItem!.attributes.keys.any((k) => k.startsWith('attr_')))
              const Text('المواصفات المحفوظة من القالب ستبقى كما هي حتى يكتمل تحميل القالب.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            ],
            if (_isEditing || _step == 1) ...[
            if (widget.catalogProvider.isLoadingContract)
              const LinearProgressIndicator(),
            if (!widget.catalogProvider.hasLoadedContract)
              Card(
                color: AppColors.surfaceCanvas,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.catalogProvider.isLoadingContract
                            ? 'جاري تحميل خيارات السعر والتوفر'
                            : 'تعذر تحميل خيارات السعر والتوفر',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'يمكنك حفظ المنتج كمسودة دون سعر أو تأكيد توفر، ثم إضافة السعر وخيارات المنتج بعد الحفظ.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        key: const Key('catalog_skip_pricing_draft'),
                        onPressed: isBusy ? null : _continueAsDraft,
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('متابعة كمسودة دون سعر'),
                      ),
                      if (!widget.catalogProvider.isLoadingContract)
                        TextButton(
                          onPressed: isBusy ? null : () =>
                              widget.catalogProvider.fetchEntityContract(widget.businessId),
                          child: const Text('إعادة تحميل اختيارات السعر'),
                        ),
                    ],
                  ),
                ),
              ),
            if (widget.catalogProvider.hasLoadedContract) ...[
            // Pricing Mode Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedPricingMode,
              decoration: InputDecoration(
                labelText: strings('pricing_mode'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.price_change_rounded),
              ),
              isExpanded: true,
              items: contract.pricingModes.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    merchantCatalogOptionLabel(e.value),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: isBusy ? null : (val) {
                if (val != null) setState(() => _selectedPricingMode = val);
              },
            ),
            const SizedBox(height: 16),

            // Availability Mode Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedAvailabilityMode,
              decoration: InputDecoration(
                labelText: strings('availability_mode'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.event_available_rounded),
              ),
              isExpanded: true,
              items: contract.availabilityModes.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    merchantCatalogOptionLabel(e.value),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: isBusy ? null : (val) {
                if (val != null) setState(() => _selectedAvailabilityMode = val);
              },
            ),
            const SizedBox(height: 16),

            // Fulfillment Mode Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedFulfillmentMode,
              decoration: InputDecoration(
                labelText: strings('fulfillment_mode'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.local_shipping_rounded),
              ),
              isExpanded: true,
              items: contract.fulfillmentModes.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    merchantCatalogOptionLabel(e.value),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: isBusy ? null : (val) {
                if (val != null) setState(() => _selectedFulfillmentMode = val);
              },
            ),
            const SizedBox(height: 16),

            // Status Dropdown (when editing)
            if (_isEditing) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: strings('customer_status'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.shield_outlined),
                ),
                isExpanded: true,
                items: contract.itemStatuses.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                onChanged: isBusy ? null : (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Requires Confirmation Switch
            SwitchListTile.adaptive(
              value: _requiresConfirmation,
              contentPadding: EdgeInsets.zero,
              title: Text(
                strings('requires_confirmation'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                strings('requires_confirmation_subtitle'),
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              onChanged: isBusy ? null : (val) {
                setState(() => _requiresConfirmation = val);
              },
            ),
            const SizedBox(height: 12),

            ],
            ],
            if (!_isEditing && _step == 1 && widget.catalogProvider.hasLoadedContract) ...[
              SwitchListTile.adaptive(
                title: const Text('حفظ السعر والتوفر الآن'),
                subtitle: const Text('يمكن تأجيل السعر وسيظل المنتج مسودة'),
                value: _saveInitialOffer,
                onChanged: isBusy ? null : (value) =>
                    setState(() => _saveInitialOffer = value),
              ),
              if (_saveInitialOffer) ...[
                if (_selectedPricingMode != 'quote_required') ...[
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _selectedPricingMode == 'dynamic'
                          ? 'مبلغ استرشادي (اختياري)' : 'المبلغ *',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_selectedPricingMode != 'quote_required')
                  CatalogCurrencySelect(
                    controller: _currencyController, enabled: !isBusy),

                if (['per_unit', 'per_person', 'per_day'].contains(_selectedPricingMode))
                  TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'السعر لكل ماذا؟ *', hintText: 'قطعة أو ساعة',
                    ),
                  ),
                DropdownButtonFormField<String>(
                  initialValue: _availabilityStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'هل هو متوفر؟ اختر حالته *',
                    border: OutlineInputBorder(),
                  ),
                  items: contract.availabilityStatuses.entries.map((e) =>
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis),
                    ),
                  ).toList(),
                  onChanged: isBusy ? null : (value) =>
                      setState(() => _availabilityStatus = value),
                ),
                const SizedBox(height: 16),
              ],
            ],
            if (!_isEditing && _step == 2) ...[
              Text('راجع جميع المعلومات قبل الحفظ',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nameController.text.trim(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 6),
                    Text('النوع: ${_itemTypeName(_itemTypeController.text.trim())}'),
                    if (_shortDescController.text.trim().isNotEmpty)
                      Text('الوصف المختصر: ${_shortDescController.text.trim()}'),
                    if (_longDescController.text.trim().isNotEmpty)
                      Text('الوصف التفصيلي: ${_longDescController.text.trim()}'),
                    if (_selectedSchema != null)
                      Text('قالب المواصفات: ${_selectedSchema!.name}'),
                    for (final entry in _collectAttributes().entries)
                      Padding(padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${specificationName(entry.key, _selectedSchema?.definitions ?? <AttributeDefinition>[])}: ${displaySpecification(entry.value)}')),
                    const Divider(),
                    Text(_skipPricingForDraft
                        ? 'التسعير: سيُحدد لاحقًا'
                        : 'طريقة التسعير: ${contract.labelPricingMode(_selectedPricingMode)}'),
                    if (_saveInitialOffer) ...[
                      Text('السعر: ${_reviewPrice()}'),
                      if (['per_unit', 'per_person', 'per_day']
                        .contains(_selectedPricingMode))
                        Text('وحدة التسعير: ${_unitController.text.trim().isEmpty ? (_selectedPricingMode == 'per_person' ? 'شخص' : 'يوم') : _unitController.text.trim()}'),
                      Text('التوفر الحالي: ${contract.labelAvailabilityStatus(_availabilityStatus ?? 'unknown')}'),
                    ] else
                      const Text('السعر والتوفر سيُضافان لاحقًا'),
                    if (!_skipPricingForDraft) ...[
                      Text('طريقة التأكد من التوفر: ${contract.labelAvailabilityMode(_selectedAvailabilityMode)}'),
                      Text('طريقة الحصول عليه: ${contract.labelFulfillmentMode(_selectedFulfillmentMode)}'),
                    ] else
                      const Text('التوفر والتسليم: يُحددان لاحقًا'),
                    Text('موافقة الموظف: ${_requiresConfirmation ? 'مطلوبة قبل التأكيد' : 'حسب سياسات النشاط'}'),
                  ],
                ),
              )),
              const SizedBox(height: 10),
              const Text('سيُحفظ المنتج كمسودة. الحفظ لا يفعّل الرد الآلي عليه تلقائيًا.',
                style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 6),
              const Text('يمكن إضافة المقاسات والألوان وخيارات المنتج بعد الحفظ.',
                style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: AppColors.surfaceCanvas,
            border: Border(top: BorderSide(color: AppColors.borderHairline)),
          ),
          child: Row(
            children: [
              if (!_isEditing && _step > 0) ...[
                OutlinedButton.icon(
                  onPressed: isBusy ? null : () => setState(() => _step--),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('السابق'),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: isBusy
                      ? null
                      : (_isEditing || _step == 2 ? _submit : _nextStep),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isBusy
                      ? const SizedBox(
                          width: 21, height: 21,
                          child: CircularProgressIndicator(strokeWidth: 2,
                            color: Colors.white))
                      : Text(_isEditing
                          ? strings('save_changes')
                          : _step == 2 ? 'حفظ المنتج'
                          : _step == 1 && !widget.catalogProvider.hasLoadedContract
                              ? 'متابعة كمسودة دون سعر'
                              : 'متابعة',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
