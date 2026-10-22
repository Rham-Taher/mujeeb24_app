import 'package:flutter/material.dart';

/// An editor is a focused task, not a dialog squeezed into a phone viewport.
///
/// Phone: real full-screen page with a pinned action area and keyboard-aware body.
/// Tablet / desktop: capped-width dialog. Retains the existing form and callbacks.
class MerchantEditorDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget> actions;

  const MerchantEditorDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 600) {
      return AlertDialog(
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        title: title,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: content,
        ),
        actions: actions,
      );
    }
    return Dialog.fullscreen(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            child: title,
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: content,
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.35))),
            ),
            child: Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: SizedBox(
                    height: 50,
                    child: actions[i],
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
