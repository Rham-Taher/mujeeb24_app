import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/transaction_models.dart';
import 'package:mujeeb24_app/features/transactions/providers/transaction_provider.dart';

class _LineFormController {
  final TextEditingController catalogItemIdController;
  final TextEditingController quantityController;
  final TextEditingController offerIdController;
  final TextEditingController variantIdController;

  _LineFormController({
    String catalogItemId = '',
    String quantity = '1.0',
    String offerId = '',
    String variantId = '',
  }) : catalogItemIdController = TextEditingController(text: catalogItemId),
       quantityController = TextEditingController(text: quantity),
       offerIdController = TextEditingController(text: offerId),
       variantIdController = TextEditingController(text: variantId);

  void dispose() {
    catalogItemIdController.dispose();
    quantityController.dispose();
    offerIdController.dispose();
    variantIdController.dispose();
  }

  TransactionLineInput toLineInput() {
    return TransactionLineInput(
      catalogItemId: catalogItemIdController.text.trim(),
      quantity: double.tryParse(quantityController.text.trim()) ?? 1.0,
      offerId: offerIdController.text.trim().isNotEmpty
          ? offerIdController.text.trim()
          : null,
      variantId: variantIdController.text.trim().isNotEmpty
          ? variantIdController.text.trim()
          : null,
    );
  }
}

class TransactionDraftFormScreen extends StatefulWidget {
  final TransactionProvider transactionProvider;
  final String businessId;
  final CommercialTransaction? existingTransaction;
  final String? initialCustomerId;
  final String? initialLeadId;

  const TransactionDraftFormScreen({
    super.key,
    required this.transactionProvider,
    required this.businessId,
    this.existingTransaction,
    this.initialCustomerId,
    this.initialLeadId,
  });

  @override
  State<TransactionDraftFormScreen> createState() =>
      _TransactionDraftFormScreenState();
}

class _TransactionDraftFormScreenState
    extends State<TransactionDraftFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _customerIdController;
  late final TextEditingController _leadIdController;
  late final TextEditingController _currencyController;
  String _selectedTransactionType = 'order';

  final List<_LineFormController> _lineControllers = [];

  bool get _isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;

    _customerIdController = TextEditingController(
      text: tx?.customerId ?? widget.initialCustomerId ?? '',
    );
    _leadIdController = TextEditingController(
      text: tx?.leadId ?? widget.initialLeadId ?? '',
    );
    _currencyController = TextEditingController(
      text: tx?.currency ?? 'SAR',
    );

    if (tx != null && tx.transactionType.isNotEmpty) {
      _selectedTransactionType = tx.transactionType;
    }

    if (tx != null && tx.parsedLines.isNotEmpty) {
      for (final line in tx.parsedLines) {
        _lineControllers.add(
          _LineFormController(
            catalogItemId: line.catalogItemId,
            quantity: line.quantity.toString(),
            offerId: line.offerId ?? '',
            variantId: line.variantId ?? '',
          ),
        );
      }
    } else {
      _lineControllers.add(_LineFormController());
    }
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _leadIdController.dispose();
    _currencyController.dispose();
    for (final controller in _lineControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    setState(() {
      _lineControllers.add(_LineFormController());
    });
  }

  void _removeLine(int index) {
    if (_lineControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.get('at_least_one_line_required', context),
          ),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }
    setState(() {
      final removed = _lineControllers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String strings(String key) => AppStrings.get(key, context);
    final lines = _lineControllers.map((c) => c.toLineInput()).toList();

    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings('at_least_one_line_required')),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    CommercialTransaction? result;

    if (_isEditing) {
      final updateReq = UpdateTransactionDraftRequest(
        lines: lines,
        currency: _currencyController.text.trim().isNotEmpty
            ? _currencyController.text.trim()
            : null,
      );

      result = await widget.transactionProvider.updateDraft(
        widget.businessId,
        widget.existingTransaction!.id,
        updateReq,
        ifMatch: widget.existingTransaction!.resourceVersion,
      );
    } else {
      final createReq = CreateTransactionDraftRequest(
        customerId: _customerIdController.text.trim(),
        transactionType: _selectedTransactionType,
        lines: lines,
        currency: _currencyController.text.trim().isNotEmpty
            ? _currencyController.text.trim()
            : null,
        leadId: _leadIdController.text.trim().isNotEmpty
            ? _leadIdController.text.trim()
            : null,
      );

      result = await widget.transactionProvider.createDraft(
        widget.businessId,
        createReq,
      );
    }

    if (!mounted) {
      return;
    }

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? strings('draft_updated_success')
                : strings('draft_created_success'),
          ),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
      Navigator.of(context).pop(result);
    } else {
      final err = widget.transactionProvider.actionError ??
          strings('request_failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final isBusy = widget.transactionProvider.isPerformingAction;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? strings('edit_draft') : strings('create_draft_transaction'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isEditing) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${strings('transaction_id')}: ${widget.existingTransaction!.id}\n${strings('resource_version')}: ${widget.existingTransaction!.resourceVersion}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Customer ID field
            TextFormField(
              controller: _customerIdController,
              enabled: !_isEditing && !isBusy,
              decoration: InputDecoration(
                labelText: '${strings('customer_id')} *',
                hintText: 'e.g. 550e8400-e29b-41d4-a716-446655440000',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return strings('required_field');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Transaction Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedTransactionType,
              decoration: InputDecoration(
                labelText: strings('transaction_details'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category_rounded),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'order',
                  child: Text(strings('tx_type_order')),
                ),
                DropdownMenuItem(
                  value: 'quote',
                  child: Text(strings('tx_type_quote')),
                ),
                const DropdownMenuItem(
                  value: 'booking',
                  child: Text('حجز'),
                ),
                const DropdownMenuItem(
                  value: 'appointment',
                  child: Text('موعد'),
                ),
                const DropdownMenuItem(
                  value: 'service_request',
                  child: Text('طلب خدمة'),
                ),
                const DropdownMenuItem(
                  value: 'reservation',
                  child: Text('حجز مورد'),
                ),
                const DropdownMenuItem(
                  value: 'subscription',
                  child: Text('اشتراك'),
                ),
              ],
              onChanged: _isEditing || isBusy
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() => _selectedTransactionType = val);
                      }
                    },
            ),
            const SizedBox(height: 16),

            // Currency & Lead ID
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _currencyController,
                    enabled: !isBusy,
                    decoration: InputDecoration(
                      labelText: strings('currency'),
                      hintText: 'SAR',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.monetization_on_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _leadIdController,
                    enabled: !_isEditing && !isBusy,
                    decoration: InputDecoration(
                      labelText: strings('lead_id_optional'),
                      hintText: 'lead_...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.trending_up_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section Header: Lines
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings('transaction_lines'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: isBusy ? null : _addLine,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(strings('add_line')),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Line items list
            ..._lineControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Card(
                elevation: 0,
                color: AppColors.surfaceSubtle,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderHairline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${strings('item_name')} #${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (_lineControllers.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: AppColors.statusError,
                              ),
                              tooltip: strings('remove_line'),
                              onPressed: isBusy ? null : () => _removeLine(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.catalogItemIdController,
                        enabled: !isBusy,
                        decoration: InputDecoration(
                          labelText: '${strings('catalog_item_id')} *',
                          hintText: 'e.g. item_uuid_123',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return strings('required_field');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.quantityController,
                              enabled: !isBusy,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: '${strings('quantity')} *',
                                hintText: '1.0',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return strings('required_field');
                                }
                                final numVal = double.tryParse(val.trim());
                                if (numVal == null || numVal <= 0) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: controller.offerIdController,
                              enabled: !isBusy,
                              decoration: const InputDecoration(
                                labelText: 'Offer ID',
                                hintText: 'Optional',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: controller.variantIdController,
                              enabled: !isBusy,
                              decoration: const InputDecoration(
                                labelText: 'Variant ID',
                                hintText: 'Optional',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isBusy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? strings('edit_draft') : strings('create_draft_transaction'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
