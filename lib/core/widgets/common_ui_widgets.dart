import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Reusable Elevated Card matching Mujeeb24 Design System.
class MujeebCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const MujeebCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.onTap,
    this.backgroundColor = AppColors.surfaceCanvas,
    this.borderColor,
    this.borderRadius = AppRadius.xl,
    this.boxShadow = AppShadows.card,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.borderHairline,
          width: 0.8,
        ),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}

/// Capsule Status Badge for orders, conversations, leads, and customer states.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);
    final border = color.withValues(alpha: 0.25);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Metric Stat Pill Card matching the 5-metric grid in the reference board.
class MetricStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final IconData? icon;

  const MetricStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderHairline),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Standardized Search Input Field matching Mujeeb24 UI Board.
class MujeebSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  const MujeebSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  color: AppColors.textMuted,
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                )
              : null,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

/// Standardized Filter Chip Pill with smooth animated selection.
class MujeebFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;
  final int? count;

  const MujeebFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surfaceCanvas,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderHairline,
            width: isSelected ? 1 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.onSurface,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : activeColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Header row displaying screen/section title, count pill, and optional action button.
class MujeebSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? trailing;

  const MujeebSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Button variants supported by Mujeeb24 Design System.
enum MujeebButtonVariant { primary, secondary, danger, outline }

/// Standardized action button matching Mujeeb24 brand aesthetics.
class MujeebButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final MujeebButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double height;
  final double fontSize;

  const MujeebButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = MujeebButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.height = 44,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case MujeebButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case MujeebButtonVariant.secondary:
        bg = AppColors.cardWhite;
        fg = AppColors.primaryBlue;
        border = const BorderSide(color: AppColors.primaryBlue, width: 1.2);
        break;
      case MujeebButtonVariant.danger:
        bg = AppColors.statusError;
        fg = Colors.white;
        break;
      case MujeebButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.onSurface;
        border = const BorderSide(color: AppColors.borderHairline, width: 1);
        break;
    }

    final isEnabled = onPressed != null && !isLoading;

    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 4, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: bg.withValues(alpha: 0.5),
      disabledForegroundColor: fg.withValues(alpha: 0.5),
      elevation: 0,
      side: border,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      minimumSize: Size(fullWidth ? double.infinity : 0, height),
    );

    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: buttonStyle,
      child: child,
    );
  }
}

/// Standardized Form Input Field for Mujeeb24.
class MujeebTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool isPassword;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool enabled;

  const MujeebTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
        ],
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.primary)
                : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: enabled ? AppColors.surfaceCanvas : AppColors.surfaceSubtle,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.borderHairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.borderHairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.statusError),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.statusError, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Standardized List Tile item with consistent padding and typography.
class MujeebListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const MujeebListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm + 2,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Standardized Empty State Component for tabs and lists.
class MujeebEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;

  const MujeebEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              MujeebButton(
                text: actionText!,
                onPressed: onAction,
                variant: MujeebButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standardized Loading Indicator matching Mujeeb24 theme.
class MujeebLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const MujeebLoadingIndicator({
    super.key,
    this.message,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standardized App Header (AppBar) matching Mujeeb24 Design System.
class MujeebAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final double elevation;
  final Color backgroundColor;

  const MujeebAppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = false,
    this.elevation = 0,
    this.backgroundColor = AppColors.surfaceCanvas,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (subtitle != null ? 14.0 : 0.0) + (bottom?.preferredSize.height ?? 0.0),
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: subtitle == null
          ? Text(title, style: AppTypography.pageTitle)
          : Column(
              crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTypography.pageTitle),
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTypography.caption),
              ],
            ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: AppColors.headingNavy,
      elevation: elevation,
      leading: leading,
      actions: actions,
      bottom: bottom ??
          const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderHairline,
            ),
          ),
    );
  }
}

/// Navigation item definition for MujeebBottomNavigation.
class MujeebBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int? badgeCount;

  const MujeebBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

/// Standardized Bottom Navigation Bar matching Mujeeb24 Design System.
class MujeebBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MujeebBottomNavItem> items;

  const MujeebBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCanvas,
        border: Border(
          top: BorderSide(color: AppColors.borderHairline, width: 1),
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;
              final color = isSelected ? AppColors.primaryBlue : AppColors.secondaryText;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                            color: color,
                            size: 24,
                          ),
                          if (item.badgeCount != null && item.badgeCount! > 0)
                            Positioned(
                              top: -4,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.errorRed,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  item.badgeCount! > 99 ? '99+' : item.badgeCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Supported channel badge types for MujeebAvatar.
enum MujeebChannelType { whatsapp, instagram, facebook, telegram, none }

/// Standardized Avatar matching Mujeeb24 Design System with optional channel and presence indicators.
class MujeebAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double size;
  final MujeebChannelType channel;
  final bool? isOnline;
  final Color? backgroundColor;

  const MujeebAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 44,
    this.channel = MujeebChannelType.none,
    this.isOnline,
    this.backgroundColor,
  });

  String get _initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return parts[0][0] + parts[1][0];
    }
    return parts[0][0];
  }

  Color get _channelColor {
    switch (channel) {
      case MujeebChannelType.whatsapp:
        return AppColors.channelWhatsapp;
      case MujeebChannelType.instagram:
        return AppColors.channelInstagram;
      case MujeebChannelType.facebook:
        return AppColors.channelFacebook;
      case MujeebChannelType.telegram:
        return AppColors.channelTelegram;
      case MujeebChannelType.none:
        return Colors.transparent;
    }
  }

  IconData get _channelIcon {
    switch (channel) {
      case MujeebChannelType.whatsapp:
        return Icons.chat_bubble_rounded;
      case MujeebChannelType.instagram:
        return Icons.camera_alt_rounded;
      case MujeebChannelType.facebook:
        return Icons.facebook_rounded;
      case MujeebChannelType.telegram:
        return Icons.send_rounded;
      case MujeebChannelType.none:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surfaceContainer;
    final badgeSize = size * 0.38;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar Circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLightBlue, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: TextStyle(
                color: AppColors.primaryBlueDark,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Channel Badge
          if (channel != MujeebChannelType.none)
            Positioned(
              bottom: -2,
              left: -2,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: _channelColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardWhite, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _channelIcon,
                  size: badgeSize * 0.6,
                  color: Colors.white,
                ),
              ),
            ),
          // Presence Dot
          if (isOnline != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: size * 0.24,
                height: size * 0.24,
                decoration: BoxDecoration(
                  color: isOnline! ? AppColors.presenceOnline : AppColors.presenceOffline,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardWhite, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standardized Error State Component with retry callback.
class MujeebErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? retryText;
  final VoidCallback? onRetry;
  final IconData icon;

  const MujeebErrorState({
    super.key,
    required this.title,
    required this.message,
    this.retryText,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.statusErrorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.errorRed),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.secondaryText,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              MujeebButton(
                text: retryText ?? 'إعادة المحاولة',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                variant: MujeebButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader card for loading states without external dependencies.
class MujeebSkeletonCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const MujeebSkeletonCard({
    super.key,
    this.height = 72,
    this.width,
    this.borderRadius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.borderLightBlue),
      ),
    );
  }
}

/// Helper group for horizontal scrolling filter chips.
class FilterChipGroup extends StatelessWidget {
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onSelected;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: options.map((opt) {
          final isSel = opt == selectedOption;
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: MujeebFilterChip(
              label: opt,
              isSelected: isSel,
              onSelected: () => onSelected(opt),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Aliases for backward and design document compatibility
typedef SummaryStatCard = MetricStatCard;
typedef QuickActionButton = MujeebButton;
typedef UnifiedEmptyState = MujeebEmptyState;

/// Platform Brand Icon that renders the authentic brand colors and iconography
/// for WhatsApp, Telegram, Instagram, Messenger/Facebook, SMS, and Webhooks.
class PlatformBrandIcon extends StatelessWidget {
  final String platform;
  final double size;
  final double borderRadius;

  const PlatformBrandIcon({
    super.key,
    required this.platform,
    this.size = 48,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final p = platform.toLowerCase();

    Gradient gradient;
    Widget icon;

    if (p.contains('whatsapp')) {
      gradient = const LinearGradient(
        colors: [Color(0xFF25D366), Color(0xFF128C7E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      icon = const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24);
    } else if (p.contains('telegram')) {
      gradient = const LinearGradient(
        colors: [Color(0xFF2AABEE), Color(0xFF229ED9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      icon = const Icon(Icons.send_rounded, color: Colors.white, size: 22);
    } else if (p.contains('instagram')) {
      gradient = const LinearGradient(
        colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF77737)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );
      icon = const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24);
    } else if (p.contains('facebook') || p.contains('messenger')) {
      gradient = const LinearGradient(
        colors: [Color(0xFF00C6FF), Color(0xFF0078FF)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );
      icon = const Icon(Icons.forum_rounded, color: Colors.white, size: 24);
    } else if (p.contains('sms') || p.contains('twilio')) {
      gradient = const LinearGradient(
        colors: [Color(0xFFF22F46), Color(0xFFD61F35)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      icon = const Icon(Icons.textsms_rounded, color: Colors.white, size: 24);
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      icon = const Icon(Icons.hub_rounded, color: Colors.white, size: 24);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: icon),
    );
  }
}

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
