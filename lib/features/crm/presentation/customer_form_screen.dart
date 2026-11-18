import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/crm_models.dart';
import 'package:mujeeb24_app/features/crm/providers/crm_provider.dart';

class CustomerFormScreen extends StatefulWidget {
  final CrmProvider crmProvider;
  final String businessId;
  final Customer? customerToEdit;

  const CustomerFormScreen({
    super.key,
    required this.crmProvider,
    required this.businessId,
    this.customerToEdit,
  });

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _localePreference = 'ar';
  final List<_ContactPointEntry> _contactPoints = [];
  bool _isSubmitting = false;

  bool get isEditing => widget.customerToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.customerToEdit != null) {
      final customer = widget.customerToEdit!;
      _nameController.text = customer.displayName ?? '';
      if (customer.contactPoints != null &&
          customer.contactPoints!.isNotEmpty) {
        for (final cp in customer.contactPoints!) {
          _contactPoints.add(
            _ContactPointEntry(
              kind: cp.kind,
              controller: TextEditingController(text: cp.valueNormalized),
            ),
          );
        }
      }
    }

    if (_contactPoints.isEmpty) {
      // Add initial phone and email rows for quick entry
      _contactPoints.add(
        _ContactPointEntry(kind: 'phone', controller: TextEditingController()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final entry in _contactPoints) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  void _addContactPoint() {
    setState(() {
      _contactPoints.add(
        _ContactPointEntry(kind: 'phone', controller: TextEditingController()),
      );
    });
  }

  void _removeContactPoint(int index) {
    setState(() {
      final removed = _contactPoints.removeAt(index);
      removed.controller.dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final validInputs = <ContactPointInput>[];
    for (final entry in _contactPoints) {
      final val = entry.controller.text.trim();
      if (val.isNotEmpty) {
        validInputs.add(ContactPointInput(kind: entry.kind, value: val));
      }
    }

    final name = _nameController.text.trim();
    final profile = <String, dynamic>{};
    if (name.isNotEmpty) {
      profile['name'] = name;
    }

    Customer? result;
    if (isEditing) {
      final req = UpdateCustomerRequest(
        contactPoints: validInputs.isNotEmpty ? validInputs : null,
        localePreference: _localePreference,
        profile: profile.isNotEmpty ? profile : null,
      );
      result = await widget.crmProvider.updateCustomer(
        widget.businessId,
        widget.customerToEdit!.id,
        req,
        ifMatch: widget.customerToEdit!.resourceVersion,
      );
    } else {
      final req = CreateCustomerRequest(
        contactPoints: validInputs.isNotEmpty ? validInputs : null,
        localePreference: _localePreference,
        profile: profile.isNotEmpty ? profile : null,
      );
      result = await widget.crmProvider.createCustomer(widget.businessId, req);
    }

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? strings('edit_customer') : strings('create_customer'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner if any
              if (widget.crmProvider.actionError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusErrorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.statusError.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    widget.crmProvider.actionError!,
                    style: const TextStyle(
                      color: AppColors.statusError,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Customer Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: strings('display_name'),
                  hintText: 'e.g. محمد العتيبي / Sarah Jenkins',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: AppColors.surfaceCanvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Locale preference
              DropdownButtonFormField<String>(
                initialValue: _localePreference,
                decoration: InputDecoration(
                  labelText: strings('locale'),
                  prefixIcon: const Icon(Icons.language_rounded),
                  filled: true,
                  fillColor: AppColors.surfaceCanvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'ar', child: Text('العربية (ar)')),
                  DropdownMenuItem(value: 'en', child: Text('English (en)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _localePreference = val);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Contact Points Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings('contact_points'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addContactPoint,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(strings('add_contact_point')),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ..._contactPoints.asMap().entries.map((entry) {
                final idx = entry.key;
                final point = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 125,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: point.kind,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceCanvas,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'phone',
                              child: Text(strings('contact_phone')),
                            ),
                            DropdownMenuItem(
                              value: 'email',
                              child: Text(strings('contact_email')),
                            ),
                            DropdownMenuItem(
                              value: 'whatsapp',
                              child: Text(strings('contact_whatsapp')),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => point.kind = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: point.controller,
                          decoration: InputDecoration(
                            hintText: point.kind == 'email'
                                ? 'name@example.com'
                                : '+966500000000',
                            filled: true,
                            fillColor: AppColors.surfaceCanvas,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      if (_contactPoints.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.statusError,
                          ),
                          onPressed: () => _removeContactPoint(idx),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing
                            ? strings('save_changes')
                            : strings('create_customer'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactPointEntry {
  String kind;
  TextEditingController controller;

  _ContactPointEntry({required this.kind, required this.controller});
}
