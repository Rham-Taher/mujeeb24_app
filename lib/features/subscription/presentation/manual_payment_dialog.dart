import 'package:flutter/material.dart';
import 'package:mujeeb24_app/core/widgets/common_ui_widgets.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/subscription_models.dart';
import 'package:mujeeb24_app/features/subscription/providers/subscription_provider.dart';

/// Manual payment dialog/bottom sheet to submit transfer reference proof.
class ManualPaymentDialog extends StatefulWidget {
  final PricingPlan plan;
  final String subscriptionId;
  final String businessId;
  final SubscriptionProvider provider;
  final VoidCallback? onSuccess;

  const ManualPaymentDialog({
    super.key,
    required this.plan,
    required this.subscriptionId,
    required this.businessId,
    required this.provider,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required PricingPlan plan,
    required String subscriptionId,
    required String businessId,
    required SubscriptionProvider provider,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCanvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ManualPaymentDialog(
          plan: plan,
          subscriptionId: subscriptionId,
          businessId: businessId,
          provider: provider,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  State<ManualPaymentDialog> createState() => _ManualPaymentDialogState();
}

class _ManualPaymentDialogState extends State<ManualPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedMethod = 'BANK_TRANSFER';
  bool _isSubmitting = false;
  String? _localError;

  @override
  void dispose() {
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    final req = ManualPaymentProofRequest(
      subscriptionId: widget.subscriptionId,
      businessId: widget.businessId,
      amountYer: widget.plan.priceYer,
      method: _selectedMethod,
      reference: _referenceController.text.trim(),
      notes: _notesController.text.trim(),
      paidAt: DateTime.now().toUtc().toIso8601String(),
    );

    final success = await widget.provider.submitManualPayment(
      widget.subscriptionId,
      req,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
        showAppAlertDialog(
          context,
          message: widget.provider.submissionSuccessMessage ?? 'تم إرسال إثبات الدفع بنجاح. سيتم تفعيل الباقة بعد مراجعة الإدارة.',
        );
      } else {
        setState(() {
          _localError = widget.provider.error ?? 'تعذر إرسال إثبات الدفع';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderHairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تسجيل بيانات الدفع اليدوي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order Summary Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCanvas.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الباقة المطلوبة:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${widget.plan.nameAr} (${widget.plan.nameEn})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'المبلغ المستحق:',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${widget.plan.priceYer} ر.ي شهرياً',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.subscriptionId.isNotEmpty) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'معرّف الطلب:',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          widget.subscriptionId.length > 12
                              ? '#${widget.subscriptionId.substring(0, 8)}...'
                              : '#${widget.subscriptionId}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Methods Selector
            const Text(
              'طريقة الدفع المعتمدة *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: ManualPaymentMethod.supportedMethods.map((m) {
                final isSelected = _selectedMethod == m.code;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMethod = m.code),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surfaceCanvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderHairline,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            m.icon,
                            size: 20,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.nameAr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  m.noteAr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.borderHairline,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Reference Number Field
            const Text(
              'رقم الحوالة / الإشعار المرجعي *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                hintText: 'مثال: REF-987654321 أو رقم الحوالة من السند',
                prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'يرجى إدخال رقم مرجع التحويل';
                }
                if (val.trim().length < 3) {
                  return 'رقم المرجع يجب أن يتكون من 3 خانات على الأقل';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Notes Field
            const Text(
              'ملاحظات إضافية (اختياري)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'أي تفاصيل عن اسم المودع أو الفرع المحول منه...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 14),

            // Audit & Legal Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusWarningContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusWarning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: AppColors.statusWarning,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تنبيه: سيظل الاشتراك في حالة قيد المراجعة (PENDING) حتى يتم التحقق من وصول الحوالة واعتمادها رسمياً من إدارة المنصة، ولن يتم تفعيل الباقة محلياً دون تأكيد الخادم.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.statusWarning,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_localError != null) ...[
              const SizedBox(height: 12),
              Text(
                _localError!,
                style: const TextStyle(
                  color: AppColors.statusError,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Submit Button
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isSubmitting ? 'جاري الإرسال...' : 'إرسال إثبات الدفع',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
