import 'package:flutter/material.dart';

class FloatingAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final double toolbarHeight;

  const FloatingAppBar({
    super.key,
    this.title,
    this.actions,
    this.toolbarHeight = 56,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        height: toolbarHeight,
        padding: const EdgeInsets.only(left: 4, right: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/logo.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (title != null) Expanded(child: title!),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}
