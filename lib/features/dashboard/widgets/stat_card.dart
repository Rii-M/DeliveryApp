import 'package:flutter/material.dart';

enum StatCardVariant { large, compact }

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback? onTap;
  final int badgeCount;
  final StatCardVariant variant;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.onTap,
    this.badgeCount = 0,
    this.variant = StatCardVariant.large,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = variant == StatCardVariant.compact;

    final iconContainerSize = isCompact ? 28.0 : 36.0;
    final iconRadius = isCompact ? 8.0 : 10.0;
    final iconSize = isCompact ? 17.0 : 21.0;
    final padding =
        isCompact ? const EdgeInsets.all(10) : const EdgeInsets.all(13);
    final numberSize = isCompact ? 18.0 : 22.0;
    final labelSize = isCompact ? 12.0 : 13.0;
    final iconNumberGap = isCompact ? 6.0 : 8.0;
    final labelTopGap = isCompact ? 2.0 : 3.0;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(iconRadius),
                    ),
                    child: Icon(icon, size: iconSize, color: iconColor),
                  ),
                  const Spacer(),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: iconNumberGap),
              Text(
                value,
                style: TextStyle(
                  fontSize: numberSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: labelTopGap),
              Text(
                title,
                style: TextStyle(
                  fontSize: labelSize,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}