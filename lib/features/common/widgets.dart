import 'package:flutter/material.dart';

import 'package:sukoon/theme.dart';

/// Rounded dark card — the standard container of the Sukoon Gold system.
///
/// IMPORTANT: [Material] asserts when both `borderRadius` and `shape` are
/// set (this was the v0 crash that red-screened every tab). We ALWAYS use
/// `shape` only — never the `borderRadius` shortcut.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kRadius);
    return Material(
      color: color ?? SukoonColors.card,
      // shape ONLY — do not pass borderRadius alongside it.
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: borderColor ?? SukoonColors.stroke,
          width: borderColor == null ? 0.6 : 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Animated integer that counts up/down to [value].
class CountUpText extends StatelessWidget {
  const CountUpText(this.value, {super.key, this.style, this.duration});

  final int value;
  final TextStyle? style;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: duration ?? const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// Animated circular progress ring with center content.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 148,
    this.stroke = 12,
    this.color = SukoonColors.accent,
    this.child,
  });

  final double value; // 0..1
  final double size;
  final double stroke;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, kid) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, stroke, color),
          child: Center(child: kid),
        ),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.color);

  final double value;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inner = rect.deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = SukoonColors.cardRaised;
    canvas.drawArc(inner, 0, 6.283185, false, track);
    if (value > 0) {
      final fg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(inner, -1.570796, 6.283185 * value, false, fg);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

/// Small colored status dot (permission rows).
class StatusDot extends StatelessWidget {
  const StatusDot(this.ok, {super.key});

  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ok ? SukoonColors.lime : SukoonColors.danger,
      ),
    );
  }
}

/// Friendly empty/error state — optional brand illustration instead of an
/// icon, optional retry action. Never a bare spinner that can hang.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.imageAsset,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData? icon;
  final String? imageAsset;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageAsset != null)
              Image.asset(imageAsset!,
                  width: 120, height: 120, fit: BoxFit.contain)
            else
              Icon(icon ?? Icons.inbox_outlined,
                  size: 44, color: SukoonColors.textFaint),
            const SizedBox(height: 12),
            Text(title, style: t.titleMedium, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(
                body!,
                style:
                    t.bodyMedium?.copyWith(color: SukoonColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
