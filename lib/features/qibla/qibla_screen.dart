import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/qibla/compass_service.dart';
import 'package:sukoon/qibla/qibla_math.dart';
import 'package:sukoon/theme.dart';

/// Qibla compass — Islam-360-style live dial: the rose rotates as the phone
/// turns, a drawn Kaaba marker sits at the qibla bearing, and the dial
/// glows + pulses gold→sage with a haptic when aligned (±3°).
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<double>? _sub;

  /// Continuous (unwrapped) heading for buttery rotation — never spins
  /// backwards across the 359°→0° seam.
  double? _heading;
  bool _noSensor = false;
  bool _wasAligned = false;
  final List<double> _recent = [];

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sub = CompassService().headingStream().listen(
      (h) {
        _recent.add(h);
        if (_recent.length > 40) _recent.removeAt(0);

        final qibla = qiblaBearing(Prefs.lat, Prefs.lng);
        final aligned = angleDelta(h, qibla).abs() <= 3.0;
        if (aligned && !_wasAligned) {
          HapticFeedback.mediumImpact();
          _pulse.repeat(reverse: true);
        } else if (!aligned && _wasAligned) {
          _pulse.stop();
          _pulse.value = 0;
        }
        _wasAligned = aligned;

        if (!mounted) return;
        setState(() {
          // Follow the shortest rotation path (continuous heading).
          _heading =
              _heading == null ? h : _heading! + angleDelta(_heading!, h);
        });
      },
      onError: (Object _) {
        if (mounted) setState(() => _noSensor = true);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final qibla = qiblaBearing(Prefs.lat, Prefs.lng);

    return SafeArea(
      child: ListView(
        padding: kScreenPad,
        children: [
          Text(l10n.tabQibla, style: t.titleLarge),
          const SizedBox(height: 16),
          if (_noSensor)
            _StaticFallback(qibla: qibla)
          else if (_heading == null)
            const Padding(
              padding: EdgeInsets.only(top: 96),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _Dial(heading: _heading!, qibla: qibla, pulse: _pulse),
            const SizedBox(height: 20),
            _Readout(heading: _heading!, qibla: qibla),
            const SizedBox(height: 16),
            if (CompassService.isNoisy(_recent))
              SectionCard(
                borderColor: SukoonColors.warning,
                child: Row(
                  children: [
                    const Icon(Icons.gesture, color: SukoonColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l10n.qiblaCalibrate,
                          style: t.bodyMedium?.copyWith(
                              color: SukoonColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: Text(l10n.qiblaStaticInfo(qibla.round()),
                  style: t.labelSmall
                      ?.copyWith(color: SukoonColors.textFaint)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial({required this.heading, required this.qibla, required this.pulse});

  final double heading;
  final double qibla;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final aligned = angleDelta(heading, qibla).abs() <= 3.0;
    return Center(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final glow = aligned ? 0.25 + 0.25 * pulse.value : 0.0;
          return Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SukoonColors.surface,
              border: Border.all(
                color: aligned ? SukoonColors.lime : SukoonColors.stroke,
                width: aligned ? 2.4 : 1.2,
              ),
              boxShadow: aligned
                  ? [
                      BoxShadow(
                        color: SukoonColors.lime.withValues(alpha: glow),
                        blurRadius: 44,
                        spreadRadius: 6,
                      ),
                    ]
                  : const [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The rose rotates opposite the heading; top = phone's
                // current facing direction.
                Transform.rotate(
                  angle: -heading * math.pi / 180.0,
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter: _RosePainter(qibla: qibla, aligned: aligned),
                  ),
                ),
                // Fixed pointer at the top (what you're facing).
                const Positioned(
                  top: 6,
                  child: Icon(Icons.arrow_drop_down,
                      size: 30, color: SukoonColors.accent),
                ),
                // Center needle pointing up.
                Icon(
                  Icons.navigation,
                  size: 52,
                  color: aligned ? SukoonColors.lime : SukoonColors.accent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.heading, required this.qibla});

  final double heading;
  final double qibla;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final shown = normalizeDegrees(heading);
    final diff = angleDelta(shown, qibla);
    final aligned = diff.abs() <= 3.0;

    return Column(
      children: [
        Text('${shown.round()}°',
            style: t.displayMedium?.copyWith(
                color: aligned ? SukoonColors.lime : SukoonColors.text)),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: aligned
              ? Row(
                  key: const ValueKey('ok'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 18, color: SukoonColors.lime),
                    const SizedBox(width: 6),
                    Text(l10n.qiblaFacing,
                        style: t.titleMedium
                            ?.copyWith(color: SukoonColors.lime)),
                  ],
                )
              : Row(
                  key: const ValueKey('off'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      diff > 0
                          ? Icons.rotate_right
                          : Icons.rotate_left,
                      size: 18,
                      color: SukoonColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.qiblaDegrees(diff.abs().round()),
                      style: t.titleMedium
                          ?.copyWith(color: SukoonColors.textSecondary),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StaticFallback extends StatelessWidget {
  const _StaticFallback({required this.qibla});

  final double qibla;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        EmptyState(
          icon: Icons.explore_off,
          title: l10n.qiblaNoSensor,
        ),
        SectionCard(
          child: Column(
            children: [
              // Drawn Kaaba marker — no emoji.
              CustomPaint(
                size: const Size(44, 44),
                painter: _KaabaPainter(size: 44),
              ),
              const SizedBox(height: 8),
              Text(l10n.qiblaStaticInfo(qibla.round()),
                  style: t.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(l10n.qiblaFromCity(Prefs.locationLabel),
                  style: t.bodySmall
                      ?.copyWith(color: SukoonColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Draws a small Kaaba: dark cube with the gold band — no emoji, no asset.
class _KaabaPainter extends CustomPainter {
  _KaabaPainter({this.size = 24});

  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final s = size;
    final rect = Rect.fromCenter(
      center: canvasSize.center(Offset.zero),
      width: s,
      height: s,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.12));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF101010));
    // gold band
    final band = Rect.fromLTWH(rect.left, rect.top + s * 0.30, s, s * 0.16);
    canvas.drawRect(band, Paint()..color = SukoonColors.accent);
    // subtle border
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = SukoonColors.goldDeep,
    );
  }

  @override
  bool shouldRepaint(_KaabaPainter old) => old.size != size;
}

class _RosePainter extends CustomPainter {
  _RosePainter({required this.qibla, required this.aligned});

  final double qibla;
  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // qibla alignment zone arc (±3°)
    final zoneRect = Rect.fromCircle(center: center, radius: r - 12);
    final zonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = (aligned ? SukoonColors.lime : SukoonColors.accent)
          .withValues(alpha: aligned ? 0.95 : 0.55);
    final start = (qibla - 3 - 90) * math.pi / 180.0;
    canvas.drawArc(zoneRect, start, 6 * math.pi / 180.0, false, zonePaint);

    // outer ring
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = SukoonColors.stroke;
    canvas.drawCircle(center, r - 22, ring);

    // ticks every 5°, longer every 15°
    final tick = Paint()..color = SukoonColors.textFaint;
    for (var deg = 0; deg < 360; deg += 5) {
      final major = deg % 15 == 0;
      final a = (deg - 90) * math.pi / 180.0;
      final outer = Offset(center.dx + (r - 26) * math.cos(a),
          center.dy + (r - 26) * math.sin(a));
      final inner = Offset(
          center.dx + (r - (major ? 40 : 33)) * math.cos(a),
          center.dy + (r - (major ? 40 : 33)) * math.sin(a));
      tick
        ..strokeWidth = major ? 2.2 : 1.0
        ..color =
            major ? SukoonColors.textSecondary : SukoonColors.textFaint;
      canvas.drawLine(inner, outer, tick);
    }

    void label(String text, double deg, Color color, double fontSize) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final a = (deg - 90) * math.pi / 180.0;
      final pos = Offset(
        center.dx + (r - 58) * math.cos(a) - tp.width / 2,
        center.dy + (r - 58) * math.sin(a) - tp.height / 2,
      );
      tp.paint(canvas, pos);
    }

    label('N', 0, SukoonColors.accent, 18);
    label('E', 90, SukoonColors.textSecondary, 14);
    label('S', 180, SukoonColors.textSecondary, 14);
    label('W', 270, SukoonColors.textSecondary, 14);

    // Kaaba marker at the qibla bearing (drawn, not emoji).
    final qa = (qibla - 90) * math.pi / 180.0;
    final kc = Offset(center.dx + (r - 84) * math.cos(qa),
        center.dy + (r - 84) * math.sin(qa));
    canvas.save();
    canvas.translate(kc.dx, kc.dy);
    canvas.rotate(qa + math.pi / 2);
    canvas.translate(-13, -13);
    _KaabaPainter(size: 26).paint(canvas, const Size(26, 26));
    canvas.restore();

    // qibla pointer triangle at the rim
    final tip = Offset(center.dx + (r - 6) * math.cos(qa),
        center.dy + (r - 6) * math.sin(qa));
    final baseL = Offset(center.dx + (r - 20) * math.cos(qa - 0.045),
        center.dy + (r - 20) * math.sin(qa - 0.045));
    final baseR = Offset(center.dx + (r - 20) * math.cos(qa + 0.045),
        center.dy + (r - 20) * math.sin(qa + 0.045));
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(baseL.dx, baseL.dy)
        ..lineTo(baseR.dx, baseR.dy)
        ..close(),
      Paint()
        ..color = aligned ? SukoonColors.lime : SukoonColors.accent,
    );
  }

  @override
  bool shouldRepaint(_RosePainter old) =>
      old.qibla != qibla || old.aligned != aligned;
}
