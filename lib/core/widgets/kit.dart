import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Small uppercase mono label ("eyebrow" / "tagline" in the prototype).
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = Tokens.muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: Fonts.labelStyle(color: color));
}

/// Flat white card with a hairline border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Tokens.line),
      ),
      child: child,
    );
    return onTap == null
        ? box
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: box,
          );
  }
}

enum AppButtonVariant { primary, soft, ghost, outline, danger }

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.full = false,
    this.small = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool full;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (Tokens.ink, Colors.white, null),
      AppButtonVariant.soft => (Tokens.paper2, Tokens.ink, null),
      AppButtonVariant.ghost => (Colors.transparent, Tokens.ink, null),
      AppButtonVariant.outline => (Tokens.surface, Tokens.ink, Tokens.line),
      AppButtonVariant.danger => (Tokens.danger, Colors.white, null),
    };
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        child: Container(
          height: small ? 36 : 48,
          width: full ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: small ? 16 : 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(small ? 12 : 16),
            border: border == null ? null : Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: small ? 17 : 20, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: Fonts.bodyStyle(
                  size: small ? 14.5 : 16,
                  bold: true,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable filter chip.
class AppChip extends StatelessWidget {
  const AppChip(this.label, {super.key, this.selected = false, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Tokens.ink : Tokens.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? Tokens.ink : Tokens.line),
      ),
      child: Text(
        label,
        style: Fonts.bodyStyle(
          size: 14,
          bold: true,
          color: selected ? Colors.white : Tokens.ink,
        ),
      ),
    ),
  );
}

/// Muted status pill (amber / danger / neutral).
class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.tone = PillTone.neutral});
  final String text;
  final PillTone tone;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.neutral => (Tokens.paper2, Tokens.ink),
      PillTone.amber => (Tokens.amberSoft, Tokens.amber),
      PillTone.danger => (Tokens.dangerSoft, Tokens.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: Fonts.labelStyle(size: 10.5, color: fg),
      ),
    );
  }
}

enum PillTone { neutral, amber, danger }

/// Screen title row used at the top of tab roots.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.eyebrow, this.trailing});
  final String title;
  final String? eyebrow;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Tokens.gutter, 12, Tokens.gutter, 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Eyebrow(eyebrow!),
                const SizedBox(height: 6),
              ],
              Text(title, style: Fonts.displayStyle(size: 32)),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Modal bottom sheet in the app's style. Use instead of calling showModalBottomSheet directly.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool scrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: builder(ctx),
    ),
  );
}

/// Transient toast shown at the bottom of the screen, with an optional action.
void showToast(
  BuildContext context,
  String text, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Tokens.ink,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(milliseconds: 3600),
      content: Text(
        text,
        style: Fonts.bodyStyle(size: 15, bold: true, color: Colors.white),
      ),
      action: actionLabel == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            ),
    ),
  );
}
