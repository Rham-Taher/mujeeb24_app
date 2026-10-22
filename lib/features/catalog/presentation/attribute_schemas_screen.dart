import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/catalog_models.dart';
import '../providers/catalog_provider.dart';

/// Same merchant contract as frontend schema-management-tab:
/// label + data type + required + optional choices, NO client-generated key.
class _DraftDefinition {
  final label = TextEditingController();
  final choices = TextEditingController();
  String dataType = 'text';
  bool required = false;

  void dispose() {
    label.dispose();
    choices.dispose();
  }
}

class AttributeSchemasScreen extends StatefulWidget {
  final CatalogProvider catalogProvider;
  final String businessId;
  const AttributeSchemasScreen({
    super.key,
    required this.catalogProvider,
    required this.businessId,
  });
  @override
  State<AttributeSchemasScreen> createState() => _AttributeSchemasScreenState();
}

class _AttributeSchemasScreenState extends State<AttributeSchemasScreen> {
  static const _typeLabels = <String, String>{
    'text': 'كتابة',
    'number': 'رقم',
    'boolean': 'نعم أو لا',
    'date': 'تاريخ',
    'datetime': 'تاريخ ووقت',
    'select': 'اختيار واحد',
    'multi_select': 'أكثر من اختيار',
    'location': 'موقع أو عنوان',
    'money': 'مبلغ مالي',
  };
  final _name = TextEditingController();
  final _draft = <_DraftDefinition>[];
  bool _creating = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.catalogProvider.fetchAttributeSchemas(widget.businessId);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    for (final draft in _draft) {
      draft.dispose();
    }
    super.dispose();
  }

  void _newSchema() {
    for (final draft in _draft) {
      draft.dispose();
    }
    _name.clear();
    setState(() {
      _draft.clear();
      _draft.add(_DraftDefinition());
      _error = null;
      _creating = true;
    });
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'اكتب اسم قالب المواصفات.';
    final chosen = _draft.where((d) => d.label.text.trim().isNotEmpty).toList();
    if (chosen.isEmpty) return 'أضف معلومة واحدة على الأقل.';
    final labels = <String>{};
    for (final draft in _draft) {
      final label = draft.label.text.trim();
      final options = draft.choices.text
          .split('\n').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
      if (label.isEmpty && (draft.required || options.isNotEmpty)) {
        return 'أدخل اسم المعلومة التي أضفت لها اختيارات أو احذفها.';
      }
      if (label.isEmpty) continue;
      if (!labels.add(label)) return 'اسم المعلومة مكرر: ${label}';
      if (label.startsWith('attr_') || label.length > 120) {
        return 'اختر اسم معلومة واضحًا مثل اللون أو الضمان.';
      }
      if (['select', 'multi_select'].contains(draft.dataType)) {
        if (options.isEmpty) return 'أضف اختيارات للمعلومة ${label}';
        if (options.toSet().length != options.length) {
          return 'لا تكرر الاختيارات في ${label}';
        }
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final definitions = <AttributeDefinitionInput>[];
    for (final draft in _draft) {
      final label = draft.label.text.trim();
      if (label.isEmpty) continue;
      final options = draft.choices.text
        .split('\n').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
      definitions.add(AttributeDefinitionInput(
        label: label,
        dataType: draft.dataType,
        required: draft.required,
        displayOrder: definitions.length + 1,
        validationRules: ['select', 'multi_select'].contains(draft.dataType)
            ? {'enum': options}
            : null,
      ));
    }
    final result = await widget.catalogProvider.createAttributeSchema(
      widget.businessId,
      CreateAttributeSchemaRequest(
        name: _name.text.trim(), definitions: definitions,
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = result == null
          ? (widget.catalogProvider.actionError ?? 'تعذر حفظ القالب.')
          : null;
      if (result != null) _creating = false;
    });
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ قالب المواصفات')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.catalogProvider;
    return Scaffold(
      appBar: AppBar(title: const Text('قوالب المواصفات')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: provider,
          builder: (context, _) => Column(children: [
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (!_creating) ...[
                  const Text('قوالب المواصفات',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                  const SizedBox(height: 8),
                  const Text('جهّز أسئلة واضحة مثل اللون وحجم الذاكرة. مجيب يحتفظ بالمفاتيح الداخلية بعيدًا عن التاجر.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _newSchema,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إنشاء قالب مواصفات'),
                  ),
                  if (provider.schemasError != null) ...[
                    const SizedBox(height: 8),
                    Text(provider.schemasError!,
                      style: const TextStyle(color: AppColors.statusError)),
                    TextButton(onPressed: () =>
                      provider.fetchAttributeSchemas(widget.businessId),
                      child: const Text('إعادة المحاولة')),
                  ],
                  const SizedBox(height: 16),
                  if (provider.attributeSchemas.isEmpty)
                    const Text('لا توجد قوالب محفوظة حاليًا'),
                  for (final schema in provider.attributeSchemas)
                    Card(child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(schema.name, style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          for (final definition in schema.definitions)
                            Padding(padding: const EdgeInsets.only(bottom: 5),
                              child: Text('${definition.label} — ${_typeLabels[definition.dataType] ?? 'تفاصيل محفوظة'}${definition.required ? ' (مطلوب)' : ''}')),
                        ],
                      ),
                    )),
                ] else ...[
                  const Text('إنشاء قالب مواصفات',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    enabled: !_saving,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'اسم قالب المواصفات *',
                      hintText: 'مثل: مواصفات أجهزة الجوال'),
                  ),
                  const SizedBox(height: 14),
                  for (var index = 0; index < _draft.length; index++) ...[
                    Builder(builder: (_) {
                      final draft = _draft[index];
                      return Card(child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(
                                'المعلومة ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold))),
                              IconButton(
                                tooltip: 'حذف المعلومة',
                                onPressed: _saving ? null : () {
                                  setState(() => _draft.removeAt(index));
                                  draft.dispose();
                                },
                                icon: const Icon(Icons.delete_outline_rounded)),
                            ]),
                            TextField(
                              controller: draft.label,
                              enabled: !_saving,
                              textDirection: TextDirection.rtl,
                              decoration: const InputDecoration(
                                labelText: 'اسم المعلومة *',
                                hintText: 'اللون، حجم الذاكرة، عدد الغرف'),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: draft.dataType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'كيف ستكون الإجابة؟'),
                              items: [
                                for (final option in _typeLabels.entries)
                                  DropdownMenuItem(
                                    value: option.key, child: Text(option.value)),
                              ],
                              onChanged: _saving ? null : (value) {
                                if (value == null) return;
                                setState(() {
                                  draft.dataType = value;
                                  if (!['select', 'multi_select'].contains(value)) {
                                    draft.choices.clear();
                                  }
                                });
                              },
                            ),
                            if (['select', 'multi_select']
                                .contains(draft.dataType)) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: draft.choices,
                                enabled: !_saving,
                                maxLines: 4,
                                textDirection: TextDirection.rtl,
                                decoration: const InputDecoration(
                                  labelText: 'الاختيارات المتاحة *',
                                  hintText: 'اكتب كل اختيار في سطر مستقل',
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('هذه المعلومة مطلوبة'),
                              value: draft.required,
                              onChanged: _saving ? null
                                : (value) => setState(() => draft.required = value),
                            ),
                          ],
                        ),
                      ));
                    }),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null : () => setState(() => _draft.add(_DraftDefinition())),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة معلومة'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(
                      color: AppColors.statusError)),
                  ],
                ],
              ],
            )),
            if (_creating) Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: _saving ? null : () => setState(() => _creating = false),
                  child: const Text('إلغاء'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'جاري الحفظ...' : 'حفظ القالب'))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
