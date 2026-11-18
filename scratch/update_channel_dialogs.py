import re

channel_files = [
    'lib/features/channels/presentation/ai_decisions_screen.dart',
    'lib/features/channels/presentation/automation_rules_screen.dart',
    'lib/features/channels/presentation/canned_replies_screen.dart',
    'lib/features/channels/presentation/channels_screen.dart',
]

for p in channel_files:
    with open(p, 'r', encoding='utf-8') as f:
        code = f.read()

    # Ensure common_ui_widgets.dart is imported
    if "import '../../../core/widgets/common_ui_widgets.dart';" not in code:
        code = code.replace(
            "import '../../../app/theme/app_theme.dart';",
            "import '../../../app/theme/app_theme.dart';\nimport '../../../core/widgets/common_ui_widgets.dart';"
        )

    # Replace _showErrorSnackBar and _showSuccessSnackBar
    # In ai_decisions_screen.dart
    old_ai = """  void _showErrorSnackBar(String message, [String? requestId]) {
    final text = requestId != null ? '$message ($requestId)' : message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }"""

    new_dialog = """  void _showErrorSnackBar(String message, [String? requestId]) {
    showAppAlertDialog(
      context,
      message: message,
      isError: true,
      requestId: requestId,
    );
  }

  void _showSuccessSnackBar(String message) {
    showAppAlertDialog(
      context,
      message: message,
      isError: false,
    );
  }"""

    old_std = """  void _showErrorSnackBar(String message, [String? requestId]) {
    final text = requestId != null ? '$message ($requestId)' : message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }"""

    old_ch = """  void _showErrorSnackBar(String message, [String? requestId]) {
    final text = requestId != null ? '$message ($requestId)' : message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }"""

    code_norm = code.replace('\r\n', '\n')
    if old_ai.replace('\r\n', '\n') in code_norm:
        code_norm = code_norm.replace(old_ai.replace('\r\n', '\n'), new_dialog)
        print("Updated AI decisions", p)
    elif old_std.replace('\r\n', '\n') in code_norm:
        code_norm = code_norm.replace(old_std.replace('\r\n', '\n'), new_dialog)
        print("Updated std", p)
    elif old_ch.replace('\r\n', '\n') in code_norm:
        code_norm = code_norm.replace(old_ch.replace('\r\n', '\n'), new_dialog)
        print("Updated ch", p)
    else:
        print("Not matched in", p)

    with open(p, 'w', encoding='utf-8') as f:
        f.write(code_norm)

print("Channel files updated!")
