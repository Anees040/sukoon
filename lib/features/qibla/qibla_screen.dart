import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          // Follow the shortest rotation path without delayed feel.
          _heading = _heading == null ? h : _heading! + angleDelta(_heading!, h);
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
            _StaticFallback(qibla: qibla, pulse: _pulse)
          else if (_heading == null)
            const Padding(
              padding: EdgeInsets.only(top: 96),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _Dial(heading: _heading!, qibla: qibla, pulse: _pulse, live: true),
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
  const _Dial({
    required this.heading,
    required this.qibla,
    required this.pulse,
    required this.live,
  });

  final double heading;
  final double qibla;
  final AnimationController pulse;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final aligned = live && angleDelta(heading, qibla).abs() <= 3.0;
    const dialSize = 320.0;
    return Center(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final glow = aligned ? 0.25 + 0.25 * pulse.value : 0.0;
          return Container(
            width: dialSize,
            height: dialSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SukoonColors.surface,
              border: Border.all(
                color: aligned
                    ? SukoonColors.lime
                    : (live ? SukoonColors.stroke : SukoonColors.accentDim),
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
                  child: SizedBox(
                    width: dialSize,
                    height: dialSize,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(dialSize, dialSize),
                          painter: _RosePainter(qibla: qibla, aligned: aligned),
                        ),
                        _RingQiblaMarker(qibla: qibla, dialSize: dialSize),
                      ],
                    ),
                  ),
                ),
                // Fixed pointer at the top (what you're facing).
                const Positioned(
                  top: 6,
                  child: Icon(Icons.keyboard_arrow_up,
                      size: 30, color: SukoonColors.accent),
                ),
                // Center needle pointing up.
                Icon(
                  Icons.navigation,
                  size: 52,
                  color: aligned
                      ? SukoonColors.lime
                      : (live ? SukoonColors.accent : SukoonColors.textSecondary),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: SukoonColors.accent,
                  ),
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
    final shownCardinal = _bearingCardinal(shown);
    final qiblaCardinal = _bearingCardinal(qibla);

    return Column(
      children: [
        Text('${shown.round()}° $shownCardinal',
            style: t.displayMedium?.copyWith(
                color: aligned ? SukoonColors.lime : SukoonColors.text)),
        const SizedBox(height: 6),
        Text('${qibla.round()}° $qiblaCardinal',
            style: t.titleMedium?.copyWith(color: SukoonColors.textSecondary)),
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
        const SizedBox(height: 12),
        Text(l10n.qiblaFromCity(Prefs.locationLabel),
            style: t.bodySmall?.copyWith(color: SukoonColors.textSecondary)),
      ],
    );
  }
}

class _StaticFallback extends StatelessWidget {
  const _StaticFallback({required this.qibla, required this.pulse});

  final double qibla;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        SectionCard(
          borderColor: SukoonColors.warning,
          child: Row(
            children: [
              const Icon(Icons.explore_off, color: SukoonColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.qiblaNoSensor,
                    style: t.titleSmall?.copyWith(color: SukoonColors.text)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Dial(heading: 0, qibla: qibla, pulse: pulse, live: false),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            children: [
              // Drawn Kaaba marker — no emoji.
              const _QiblaHeroIcon(size: 44),
              const SizedBox(height: 8),
              Text('${qibla.round()}° ${_bearingCardinal(qibla)}',
                  style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(l10n.qiblaStaticInfo(qibla.round()),
                  style: t.bodyMedium
                      ?.copyWith(color: SukoonColors.textSecondary),
                  textAlign: TextAlign.center),
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

class _QiblaHeroIcon extends StatelessWidget {
  const _QiblaHeroIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 8,
            spreadRadius: 0.5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SvgPicture.asset('assets/illustrations/qibla_kaaba.svg'),
    );
  }
}

class _RingQiblaMarker extends StatelessWidget {
  const _RingQiblaMarker({required this.qibla, required this.dialSize});

  final double qibla;
  final double dialSize;

  @override
  Widget build(BuildContext context) {
    const markerSize = 30.0;
    final radius = dialSize / 2;
    final markerRadius = radius - 84;
    final qa = (qibla - 90) * math.pi / 180.0;
    final cx = radius + markerRadius * math.cos(qa) - markerSize / 2;
    final cy = radius + markerRadius * math.sin(qa) - markerSize / 2;

    return Positioned(
      left: cx,
      top: cy,
      child: Transform.rotate(
        angle: qa + math.pi / 2,
        child: const _QiblaHeroIcon(size: markerSize),
      ),
    );
  }
}

String _bearingCardinal(double degrees) {
  const points = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final idx = ((normalizeDegrees(degrees) + 22.5) / 45.0).floor() % 8;
  return points[idx];
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

    // qibla pointer triangle at the rim
    final qa = (qibla - 90) * math.pi / 180.0;
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
