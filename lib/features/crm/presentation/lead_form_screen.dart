import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/crm_models.dart';
import 'package:mujeeb24_app/features/crm/providers/crm_provider.dart';

class LeadFormScreen extends StatefulWidget {
  final CrmProvider crmProvider;
  final String businessId;
  final Lead? leadToEdit;
  final String? prefilledCustomerId;

  const LeadFormScreen({
    super.key,
    required this.crmProvider,
    required this.businessId,
    this.leadToEdit,
    this.prefilledCustomerId,
  });

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerIdController = TextEditingController();
  final _contextController = TextEditingController();
  bool _isSubmitting = false;

  bool get isEditing => widget.leadToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.leadToEdit != null) {
      _customerIdController.text = widget.leadToEdit!.customerId;
    } else if (widget.prefilledCustomerId != null) {
      _customerIdController.text = widget.prefilledCustomerId!;
    }
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final contextText = _contextController.text.trim();
    final qualContext = <String, dynamic>{};
    if (contextText.isNotEmpty) {
      qualContext['notes'] = contextText;
    }

    Lead? result;
    if (isEditing) {
      final req = UpdateLeadRequest(
        qualificationContext: qualContext.isNotEmpty ? qualContext : null,
      );
      result = await widget.crmProvider.updateLead(
        widget.businessId,
        widget.leadToEdit!.id,
        req,
        ifMatch: widget.leadToEdit!.resourceVersion,
      );
    } else {
      final req = CreateLeadRequest(
        customerId: _customerIdController.text.trim(),
        qualificationContext: qualContext.isNotEmpty ? qualContext : null,
      );
      result = await widget.crmProvider.createLead(widget.businessId, req);
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
          isEditing ? strings('lead_details') : strings('create_lead'),
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

              // Customer ID Field (read-only if editing)
              TextFormField(
                controller: _customerIdController,
                readOnly: isEditing,
                decoration: InputDecoration(
                  labelText: strings('customer_id'),
                  hintText: 'e.g. 123e4567-e89b-12d3-a456-426614174000',
                  prefixIcon: const Icon(Icons.person_pin_rounded),
                  filled: true,
                  fillColor: isEditing
                      ? AppColors.surfaceCanvas
                      : AppColors.surfaceCanvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? strings('required_field')
                    : null,
              ),
              const SizedBox(height: 16),

              // Qualification Context Notes Field
              TextFormField(
                controller: _contextController,
                decoration: InputDecoration(
                  labelText: strings('qualification_context'),
                  hintText:
                      'e.g. Interested in premium tier, budget confirmed...',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  filled: true,
                  fillColor: AppColors.surfaceCanvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 4,
              ),
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
                            : strings('create_lead'),
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
