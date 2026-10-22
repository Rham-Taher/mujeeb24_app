import 'package:flutter/material.dart';
import '../../../core/models/catalog_models.dart';

/// Contract labels remain the source of truth. UI only removes internal API
/// constraint notes (for example `amount + pricing_unit`) from customer copy.
String merchantCatalogOptionLabel(String label) {
  final readable = label.replaceAll(
    RegExp(r'\s*\([^)]*(?:amount|pricing_unit|attribute_schema_id)[^)]*\)'),
    '',
  ).trim();
  return readable.isEmpty ? label : readable;
}

/// Merchant item names from the frontend catalog-form-values contract.
String merchantItemTypeLabel(String type) {
  const names = <String, String>{
    'product': 'منتج',
    'physical_good': 'منتج',
    'service': 'خدمة',
    'consultation': 'استشارة',
    'booking': 'حجز',
    'real_estate': 'عقار',
    'course': 'دورة',
    'subscription': 'اشتراك',
  };
  return names[type] ?? type;
}

/// Contract-backed labels: never show opaque attribute keys to merchants.
String specificationName(String key, List<AttributeDefinition> definitions) {
  for (final definition in definitions) {
    if (definition.key == key) return definition.label;
  }
  return key.startsWith('attr_') ? 'معلومة محفوظة من قالب' : key;
}

String displaySpecification(dynamic value) {
  if (value == null || value == '') return 'غير محدد';
  if (value is bool) return value ? 'نعم' : 'لا';
  if (value is List) {
    return value.isEmpty
        ? 'لا توجد اختيارات'
        : value.map(displaySpecification).join('، ');
  }
  if (value is Map) {
    final parts = value.values.map(displaySpecification).toList();
    return parts.isEmpty ? 'تفاصيل محفوظة' : parts.join(' — ');
  }
  return value.toString();
}

bool missingSpecification(dynamic value) =>
    value == null ||
    (value is String && value.trim().isEmpty) ||
    (value is List && value.isEmpty);

String? validateSpecification(AttributeDefinition definition, dynamic value) {
  if (missingSpecification(value)) {
    return definition.required ? 'أدخل ${definition.label}' : null;
  }
  final type = definition.dataType;
  if ((type == 'number' || type == 'money') &&
      (value is! num || !value.isFinite)) {
    return 'أدخل رقمًا صحيحًا في ${definition.label}';
  }
  final options = definition.validationRules?['enum'];
  if (options is List && options.isNotEmpty) {
    final values = type == 'multi_select'
        ? (value is List ? value : [value])
        : [value];
    if (values.any((v) => !options.contains(v))) {
      return 'اختر ${definition.label} من الاختيارات الموجودة';
    }
  }
  final min = definition.validationRules?['min'];
  final max = definition.validationRules?['max'];
  if (value is num && min is num && value < min) {
    return 'أدخل رقمًا لا يقل عن ${min}';
  }
  if (value is num && max is num && value > max) {
    return 'أدخل رقمًا لا يزيد عن ${max}';
  }
  return null;
}

/// Matches the frontend SpecificationInput by preserving typed values.
class CatalogSpecificationInput extends StatefulWidget {
  final AttributeDefinition definition;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final bool enabled;
  const CatalogSpecificationInput({
    super.key,
    required this.definition,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<CatalogSpecificationInput> createState() => _CatalogSpecificationInputState();
}

class _CatalogSpecificationInputState extends State<CatalogSpecificationInput> {
  final _choiceText = TextEditingController();

  @override
  void dispose() {
    _choiceText.dispose();
    super.dispose();
  }

  Widget _field(Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final definition = widget.definition;
    final name = '${definition.label}${definition.required ? ' *' : ''}';
    final value = widget.value;
    final dataType = definition.dataType;
    final available = definition.validationRules?['enum'];
    final choices = available is List ? available : const <dynamic>[];

    if (dataType == 'boolean') {
      return _field(DropdownButtonFormField<bool>(
        key: ValueKey('managed-${definition.key}'),
        initialValue: value is bool ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: name),
        items: const [
          DropdownMenuItem<bool>(value: true, child: Text('نعم')),
          DropdownMenuItem<bool>(value: false, child: Text('لا')),
        ],
        onChanged: widget.enabled ? widget.onChanged : null,
      ));
    }

    if (dataType == 'select' && choices.isNotEmpty) {
      final selection = choices.indexOf(value);
      return _field(DropdownButtonFormField<int>(
        key: ValueKey('managed-${definition.key}'),
        initialValue: selection >= 0 ? selection : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: name),
        items: [
          for (var index = 0; index < choices.length; index++)
            DropdownMenuItem<int>(
              value: index,
              child: Text(displaySpecification(choices[index]),
                overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: widget.enabled
            ? (index) {
                if (index != null) widget.onChanged(choices[index]);
              }
            : null,
      ));
    }

    if (dataType == 'multi_select') {
      final selection = value is List ? value : <dynamic>[];
      return _field(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (choices.isNotEmpty)
            for (final choice in choices)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(displaySpecification(choice)),
                value: selection.contains(choice),
                onChanged: !widget.enabled
                    ? null : (selected) {
                        final next = List<dynamic>.from(selection);
                        if (selected == true && !next.contains(choice)) {
                          next.add(choice);
                        }
                        if (selected != true) next.remove(choice);
                        widget.onChanged(next);
                      },
              )
          else ...[
            Row(children: [
              Expanded(child: TextField(
                controller: _choiceText,
                enabled: widget.enabled,
                decoration: const InputDecoration(
                  labelText: 'أضف اختيارًا',
                ),
              )),
              const SizedBox(width: 8),
              TextButton(
                onPressed: !widget.enabled ? null : () {
                  final nextChoice = _choiceText.text.trim();
                  if (nextChoice.isEmpty || selection.contains(nextChoice)) return;
                  widget.onChanged([...selection, nextChoice]);
                  _choiceText.clear();
                },
                child: const Text('إضافة'),
              ),
            ]),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final choice in selection)
                InputChip(
                  label: Text(displaySpecification(choice)),
                  onDeleted: !widget.enabled ? null : () {
                    widget.onChanged(
                      List<dynamic>.from(selection)..remove(choice),
                    );
                  },
                ),
            ]),
          ],
        ],
      ));
    }

    if (value is Map || (value is List && dataType != 'multi_select')) {
      return _field(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Text('تفاصيل مركبة محفوظة؛ تعديل بقية المعلومات لن يغيّرها.'),
        ],
      ));
    }

    if (dataType == 'date' || dataType == 'datetime') {
      return _field(TextFormField(
        // Re-create read-only field after a picker selection so its text updates.
        key: ValueKey('managed-${definition.key}-${value ?? ''}'),
        initialValue: value?.toString() ?? '',
        enabled: widget.enabled,
        readOnly: true,
        decoration: InputDecoration(
          labelText: name, suffixIcon: const Icon(Icons.calendar_today_outlined)),
        onTap: () async {
          final initial = DateTime.tryParse(value?.toString() ?? '') ??
              DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked == null || !context.mounted) return;
          if (dataType == 'date') {
            widget.onChanged(picked.toIso8601String().substring(0, 10));
            return;
          }
          final time = await showTimePicker(
            context: context, initialTime: TimeOfDay.fromDateTime(initial));
          if (time == null) return;
          final dateTime = DateTime(picked.year, picked.month,
              picked.day, time.hour, time.minute);
          widget.onChanged(dateTime.toUtc().toIso8601String());
        },
      ));
    }

    final numeric = dataType == 'number' || dataType == 'money';
    return _field(TextFormField(
      key: ValueKey('managed-${definition.key}'),
      initialValue: value?.toString() ?? '',
      enabled: widget.enabled,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(labelText: name),
      onChanged: (raw) {
        if (raw.trim().isEmpty) {
          widget.onChanged(null);
        } else {
          widget.onChanged(numeric ? num.tryParse(raw.trim()) : raw.trim());
        }
      },
      validator: (_) => validateSpecification(definition, widget.value),
    ));
  }
}
