with open('lib/core/widgets/common_ui_widgets.dart', 'r', encoding='utf-8') as f:
    code = f.read()

helper = """

/// Standard AlertDialog helper replacing SnackBar notifications across Mujeeb24 UI.
Future<void> showAppAlertDialog(
  BuildContext context, {
  required String message,
  String? title,
  bool isError = false,
  String? requestId,
  VoidCallback? onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: isError ? AppColors.statusError : AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title ?? (isError ? 'تنبيه' : 'إشعار'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isError ? AppColors.statusError : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurface,
            ),
          ),
          if (requestId != null && requestId.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              'معرف الطلب: $requestId',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm?.call();
          },
          child: const Text('حسناً'),
        ),
      ],
    ),
  );
}
"""

if 'showAppAlertDialog' not in code:
    code = code.rstrip() + helper
    with open('lib/core/widgets/common_ui_widgets.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added showAppAlertDialog to common_ui_widgets.dart")
else:
    print("Already exists")
