import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter, FontFeature;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import 'core/prayer_schedule.dart';
import 'core/dhikr_model.dart';
import 'core/azkar_controller.dart';
import 'data/islamic_data_repository.dart';
import 'ui/azkar/azkar_view.dart';
import 'celestial_system.dart';

export 'core/prayer_schedule.dart';
export 'core/dhikr_model.dart';
export 'core/azkar_controller.dart';
export 'data/islamic_data_repository.dart';
export 'ui/azkar/azkar_view.dart';
export 'celestial_system.dart';

part 'dashboard.dart';
part 'menubar_service.dart';

void main() => runApp(const PrayerApp());

// ─────────────────────────── Data ───────────────────────────

class PrayerData {
  final Map<String, dynamic> times;
  final Map<String, int> months;
  Map<String, dynamic> azkar = const {};
  List<DhikrItem> fullMorningAzkar = const [];
  List<DhikrItem> fullEveningAzkar = const [];
  List<dynamic> schedule = const [];
  List hadiths = const [];
  List<dynamic> quranJuz = const [];
  PrayerData(this.times, this.months);

  static Future<PrayerData> load() async {
    final s = await rootBundle.loadString('assets/times.json');
    final j = jsonDecode(s);
    final d = PrayerData(
        j['times'], Map<String, dynamic>.from(j['months']).cast<String, int>());
    d.azkar = jsonDecode(await rootBundle.loadString('assets/azkar.json'));
    try {
      final fullAzkarJson =
          jsonDecode(await rootBundle.loadString('assets/azkar_full.json'));
      d.fullMorningAzkar = ((fullAzkarJson['morning'] as List?) ?? [])
          .map((e) => DhikrItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      d.fullEveningAzkar = ((fullAzkarJson['evening'] as List?) ?? [])
          .map((e) => DhikrItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      d.fullMorningAzkar = [];
      d.fullEveningAzkar = [];
    }
    d.schedule =
        (jsonDecode(await rootBundle.loadString('assets/schedule.json')))['schedule_rules'];
    d.hadiths = (jsonDecode(await rootBundle.loadString('assets/hadith.json')))['hadiths'];
    try {
      d.quranJuz = (jsonDecode(await rootBundle.loadString('assets/quran_juz.json')))['juz_list'];
    } catch (_) {
      d.quranJuz = [];
    }
    return d;
  }
}

/// Resolve a schedule boundary like "fajr", "sunrise+25", "dhuhr-20"
double resolveBoundary(String expr, Map<String, dynamic> today) {
  if (expr == 'always') return -1;
  final plusMatch = RegExp(r'^([a-z]+)\+(\d+)$').firstMatch(expr);
  final minusMatch = RegExp(r'^([a-z]+)-(\d+)$').firstMatch(expr);
  if (plusMatch != null) return toMin(today[plusMatch.group(1)]!) + double.parse(plusMatch.group(2)!);
  if (minusMatch != null) return toMin(today[minusMatch.group(1)]!) - double.parse(minusMatch.group(2)!);
  return toMin(today[expr]!);
}

/// Calculate the next upcoming prayer time and countdown Duration
({String label, String time, Duration delta})? calculateNextPrayer(PrayerData data, DateTime now) {
  final jt = jalaliToday(now);
  final today = data.times['${jt.month}-${jt.day}'];
  if (today == null) return null;
  const order = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
  final nowMin = now.hour * 60 + now.minute;
  for (final k in order) {
    final val = today[k];
    if (val == null) continue;
    final parts = (val as String).split(':');
    final t = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    if (t > nowMin) {
      return (
        label: prayerLabels[k]!,
        time: val,
        delta: Duration(minutes: t - nowMin)
      );
    }
  }
  final nd = jalaliToday(now.add(const Duration(days: 1)));
  final tm = data.times['${nd.month}-${nd.day}'];
  if (tm == null || tm['fajr'] == null) return null;
  final parts = (tm['fajr'] as String).split(':');
  final t = int.parse(parts[0]) * 60 + int.parse(parts[1]);
  return (
    label: prayerLabels['fajr']!,
    time: tm['fajr'] as String,
    delta: Duration(minutes: t - nowMin + 24 * 60)
  );
}

/// Smart azkar suggestion based on current time vs schedule rules
Map<String, dynamic> getSmartZikr(PrayerData data, DateTime now) {
  final jt = jalaliToday(now);
  final today = data.times['${jt.month}-${jt.day}'];
  if (today == null) return {'label': 'ذکر', 'arabic': '', 'note': '', 'active': false};
  final nowMin = (now.hour * 60 + now.minute).toDouble();

  // Priority: find active window
  for (final rule in data.schedule) {
    final from = rule['from'] as String;
    final to = rule['to'] as String;
    if (from == 'always') continue;
    final f = resolveBoundary(from, today);
    double t;
    if (to == 'fajr') {
      t = resolveBoundary('fajr', today) + 24 * 60;
    } else {
      t = resolveBoundary(to, today);
    }
    double nf = f, nt = t;
    if (nt < nf) {
      if (nowMin < nf) {
        nf -= 24 * 60;
      } else {
        nt += 24 * 60;
      }
    }
    if (nowMin >= nf && nowMin < nt) {
      return {'label': rule['label'], 'arabic': rule['arabic'], 'note': rule['note'], 'active': true};
    }
  }
  // Fallback: general zikr
  final gen = data.schedule.firstWhere((r) => r['from'] == 'always', orElse: () => {});
  if (gen.isNotEmpty) {
    return {'label': gen['label'], 'arabic': gen['arabic'], 'note': gen['note'], 'active': false};
  }
  return {'label': '', 'arabic': '', 'note': '', 'active': false};
}

enum ScenePhase { dawn, morning, noon, afternoon, sunset, evening, night, midnight }

ScenePhase phaseFor(DateTime now, Map<String, dynamic>? today) {
  final h = now.hour * 60.0 + now.minute;
  if (today == null) return ScenePhase.night;
  final fajr = toMin(today['fajr']);
  final sunrise = toMin(today['sunrise']);
  final dhuhr = toMin(today['dhuhr']);
  final asr = toMin(today['asr']);
  final maghrib = toMin(today['maghrib']);
  final isha = toMin(today['isha']);

  if (h >= fajr && h < sunrise) return ScenePhase.dawn;
  if (h >= sunrise && h < dhuhr) return ScenePhase.morning;
  if (h >= dhuhr && h < asr) return ScenePhase.noon;
  if (h >= asr && h < maghrib - 30) return ScenePhase.afternoon;
  if (h >= maghrib - 30 && h < maghrib + 45) return ScenePhase.sunset;
  if (h >= maghrib + 45 && h < isha + 90) return ScenePhase.evening;
  if (h >= 0 && h < fajr - 90) return ScenePhase.midnight;
  return ScenePhase.night;
}

bool isNightTheme(DateTime now, Map<String, dynamic>? today) {
  if (today == null) return true;
  final h = now.hour * 60.0 + now.minute;
  return h >= toMin(today['maghrib']) - 30 || h < toMin(today['fajr']);
}

class LandscapeSvg extends StatelessWidget {
  final ScenePhase phase;
  final DateTime? now;
  final Map<String, dynamic>? prayerTimes;
  final int? hijriDay;

  const LandscapeSvg({
    super.key,
    required this.phase,
    this.now,
    this.prayerTimes,
    this.hijriDay,
  });

  static const sceneMap = {
    ScenePhase.dawn: 'assets/scenes/dawn.svg',
    ScenePhase.morning: 'assets/scenes/morning.svg',
    ScenePhase.noon: 'assets/scenes/noon.svg',
    ScenePhase.afternoon: 'assets/scenes/afternoon.svg',
    ScenePhase.sunset: 'assets/scenes/sunset.svg',
    ScenePhase.evening: 'assets/scenes/evening.svg',
    ScenePhase.night: 'assets/scenes/night.svg',
    ScenePhase.midnight: 'assets/scenes/midnight.svg',
  };

  static const skySceneMap = {
    ScenePhase.dawn: 'assets/scenes/sky_dawn.svg',
    ScenePhase.morning: 'assets/scenes/sky_morning.svg',
    ScenePhase.noon: 'assets/scenes/sky_noon.svg',
    ScenePhase.afternoon: 'assets/scenes/sky_afternoon.svg',
    ScenePhase.sunset: 'assets/scenes/sky_sunset.svg',
    ScenePhase.evening: 'assets/scenes/sky_evening.svg',
    ScenePhase.night: 'assets/scenes/sky_night.svg',
    ScenePhase.midnight: 'assets/scenes/sky_midnight.svg',
  };

  static const landscapeSceneMap = {
    ScenePhase.dawn: 'assets/scenes/landscape_dawn.svg',
    ScenePhase.morning: 'assets/scenes/landscape_morning.svg',
    ScenePhase.noon: 'assets/scenes/landscape_noon.svg',
    ScenePhase.afternoon: 'assets/scenes/landscape_afternoon.svg',
    ScenePhase.sunset: 'assets/scenes/landscape_sunset.svg',
    ScenePhase.evening: 'assets/scenes/landscape_evening.svg',
    ScenePhase.night: 'assets/scenes/landscape_night.svg',
    ScenePhase.midnight: 'assets/scenes/landscape_midnight.svg',
  };

  @override
  Widget build(BuildContext context) {
    final effectiveNow = now ?? DateTime.now();
    final effectivePrayerTimes = prayerTimes ?? {
      'fajr': '04:30',
      'sunrise': '06:00',
      'dhuhr': '12:30',
      'asr': '16:00',
      'maghrib': '19:30',
      'isha': '21:00',
    };
    final effectiveHijriDay = hijriDay ?? 14;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Sky Layer (Rearmost background)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1400),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          child: SvgPicture.asset(
            skySceneMap[phase]!,
            key: ValueKey<String>('sky_${phase.name}'),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // 2. Dynamic Celestial Sky (Sun / Moon in the sky, behind mountains and horizon)
        DynamicCelestialSky(
          phase: phase,
          now: effectiveNow,
          prayerTimes: effectivePrayerTimes,
          hijriDay: effectiveHijriDay,
        ),

        // 3. Foreground Landscape Layer (Mountains, Lake, Ridge Trees, Meadow Hills, Flora)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1400),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          child: SvgPicture.asset(
            landscapeSceneMap[phase]!,
            key: ValueKey<String>('landscape_${phase.name}'),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // 4. Ambient Particles
        _AmbientParticles(phase: phase),
      ],
    );
  }
}

class _AmbientParticles extends StatefulWidget {
  final ScenePhase phase;
  const _AmbientParticles({this.phase = ScenePhase.noon});

  @override
  State<_AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<_AmbientParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        painter: _ParticlesPainter(
          t: _ctrl.value,
          phase: widget.phase,
        ),
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double t;
  final ScenePhase phase;

  _ParticlesPainter({required this.t, required this.phase});

  // Cloud seeds: (baseX, baseY, width, height, speedFactor, yBobFreq)
  static const _clouds = [
    (0.08, 0.06, 220.0, 48.0, 1.0, 1),
    (0.38, 0.09, 280.0, 56.0, 0.8, 2),
    (0.72, 0.05, 200.0, 44.0, 1.2, 1),
    (0.22, 0.14, 180.0, 40.0, 0.9, 2),
    (0.58, 0.12, 240.0, 50.0, 1.1, 1),
    (0.88, 0.08, 210.0, 46.0, 0.7, 2),
  ];

  // Water ripple lines: (xRatio, yRatio, widthRatio, freq, phaseOffset)
  // Confined to the open lake region behind trees and foreground hills
  static const _ripples = [
    (0.26, 0.740, 0.22, 1, 0.0),
    (0.44, 0.750, 0.28, 2, 1.5),
    (0.60, 0.745, 0.22, 1, 3.1),
    (0.32, 0.760, 0.25, 2, 0.8),
    (0.52, 0.755, 0.28, 1, 4.2),
    (0.22, 0.770, 0.20, 1, 5.0),
    (0.42, 0.765, 0.26, 2, 3.7),
    (0.58, 0.770, 0.24, 1, 1.2),
  ];

  // Specular sparkles on water: (xRatio, yRatio, scale, freq, phaseOffset)
  // Kept within open lake surface (x: 0.18 to 0.70, y: 0.73 to 0.78)
  static const _sparkles = [
    (0.62, 0.740, 1.2, 2, 0.0),
    (0.56, 0.750, 1.1, 3, 1.8),
    (0.66, 0.745, 1.3, 2, 3.2),
    (0.48, 0.755, 1.2, 3, 4.6),
    (0.54, 0.765, 1.4, 2, 0.9),
    (0.38, 0.745, 1.0, 4, 2.5),
    (0.44, 0.760, 1.3, 3, 5.3),
    (0.30, 0.755, 1.1, 2, 3.9),
    (0.50, 0.770, 1.2, 3, 1.2),
    (0.24, 0.760, 1.0, 4, 4.1),
    (0.35, 0.768, 1.2, 2, 0.6),
    (0.64, 0.760, 1.1, 3, 2.2),
  ];

  // Floating ambient motes / fireflies: (xBase, yBase, radius, xFreq, yFreq, phase)
  static const _ambientMotes = [
    (0.12, 0.40, 2.5, 1, 2, 0.4),
    (0.28, 0.35, 3.0, 2, 1, 1.8),
    (0.45, 0.48, 2.2, 1, 3, 3.2),
    (0.62, 0.38, 3.5, 2, 2, 4.6),
    (0.78, 0.44, 2.8, 1, 1, 0.9),
    (0.90, 0.32, 2.0, 3, 2, 2.5),
    (0.20, 0.60, 2.4, 2, 1, 5.1),
    (0.35, 0.68, 3.2, 1, 2, 3.6),
    (0.50, 0.62, 2.6, 3, 1, 1.2),
    (0.68, 0.65, 3.0, 1, 3, 4.8),
    (0.85, 0.58, 2.2, 2, 2, 0.3),
  ];

  ({Color main, Color accent, Color glow, Color mote, double brightness}) _phaseColors() {
    switch (phase) {
      case ScenePhase.morning:
        return (
          main: const Color(0xFFFFFFFF),
          accent: const Color(0xFFFFE082),
          glow: const Color(0xFFFFD54F),
          mote: const Color(0xFFFFF9C4),
          brightness: 0.95,
        );
      case ScenePhase.noon:
        return (
          main: const Color(0xFFFFFFFF),
          accent: const Color(0xFFFFF59D),
          glow: const Color(0xFFFFEE58),
          mote: const Color(0xFFFFFDE7),
          brightness: 1.0,
        );
      case ScenePhase.afternoon:
        return (
          main: const Color(0xFFFFF8E1),
          accent: const Color(0xFFFFD54F),
          glow: const Color(0xFFFFB74D),
          mote: const Color(0xFFFFE082),
          brightness: 0.9,
        );
      case ScenePhase.sunset:
        return (
          main: const Color(0xFFFFE0B2),
          accent: const Color(0xFFFFAB40),
          glow: const Color(0xFFFF7043),
          mote: const Color(0xFFFFCC80),
          brightness: 0.85,
        );
      case ScenePhase.dawn:
        return (
          main: const Color(0xFFFFF3E0),
          accent: const Color(0xFFFFCC80),
          glow: const Color(0xFFCE93D8),
          mote: const Color(0xFFF8BBD0),
          brightness: 0.8,
        );
      case ScenePhase.evening:
        return (
          main: const Color(0xFFE0F7FA),
          accent: const Color(0xFFFFE082),
          glow: const Color(0xFF80DEEA),
          mote: const Color(0xFFB2EBF2),
          brightness: 0.75,
        );
      case ScenePhase.night:
      case ScenePhase.midnight:
        return (
          main: const Color(0xFFFFFFFF),
          accent: const Color(0xFFE1F5FE),
          glow: const Color(0xFF81D4FA),
          mote: const Color(0xFFE0F7FA),
          brightness: 0.7,
        );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final conf = _phaseColors();
    final twoPi = math.pi * 2.0;

    // ─────────────────────── 1. Ultra-Soft Drifting Clouds ───────────────────────
    for (int i = 0; i < _clouds.length; i++) {
      final c = _clouds[i];
      final baseX = size.width * c.$1;
      final baseY = size.height * c.$2;
      final w = c.$3;
      final h = c.$4;
      final speedFactor = c.$5;
      final yBobFreq = c.$6;

      // Seamless horizontal wrapping
      final totalWidth = size.width + w + 100;
      final currentX = ((baseX + t * totalWidth * 0.4 * speedFactor) % totalWidth) - (w / 2);
      final currentY = baseY + math.sin(t * twoPi * yBobFreq + i) * 6.0;

      final cloudOpacity = (0.09 + 0.03 * (i % 3)) * conf.brightness;
      final cloudPaint = Paint()
        ..color = Colors.white.withValues(alpha: cloudOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(currentX, currentY), width: w, height: h),
        Radius.circular(h / 2),
      );
      canvas.drawRRect(rrect, cloudPaint);

      // Secondary soft puff bubble for organic look
      final puffRadius = h * 0.7;
      canvas.drawCircle(
        Offset(currentX - w * 0.15, currentY - h * 0.2),
        puffRadius,
        cloudPaint,
      );
      canvas.drawCircle(
        Offset(currentX + w * 0.18, currentY - h * 0.15),
        puffRadius * 0.85,
        cloudPaint,
      );
    }

    // ─────────────────────── 2. Breathing Celestial Sun/Moon Aura ───────────────────────
    final sunColX = size.width * 0.78;
    final lakeCenterY = size.height * 0.79;
    // Buttery smooth cosine pulse
    final glowPulse = 0.82 + 0.18 * (0.5 + 0.5 * math.cos(t * twoPi * 1.0));

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          conf.glow.withValues(alpha: 0.25 * conf.brightness * glowPulse),
          conf.glow.withValues(alpha: 0.08 * conf.brightness * glowPulse),
          conf.glow.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCenter(
        center: Offset(sunColX, lakeCenterY),
        width: size.width * 0.50,
        height: size.height * 0.22,
      ));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sunColX, lakeCenterY),
        width: size.width * 0.50,
        height: size.height * 0.22,
      ),
      glowPaint,
    );

    // ─────────────────────── 3. Silky Smooth Cubic Water Waves ───────────────────────
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < _ripples.length; i++) {
      final r = _ripples[i];
      final rxRatio = r.$1;
      final ryRatio = r.$2;
      final rwRatio = r.$3;
      final freq = r.$4;
      final pOffset = r.$5;

      // Perfectly smooth harmonic oscillation
      final phaseVal = t * twoPi * freq + pOffset;
      final smoothWave = 0.5 + 0.5 * math.sin(phaseVal); // 0.0 .. 1.0
      final waveDrift = math.sin(phaseVal) * (size.width * 0.025);

      final cx = size.width * rxRatio + waveDrift;
      final cy = size.height * ryRatio + math.cos(phaseVal) * 2.2;
      final w = size.width * rwRatio * (0.88 + 0.12 * smoothWave);

      final alpha = (0.18 + 0.55 * smoothWave) * conf.brightness;
      ripplePaint
        ..strokeWidth = (1.2 + 1.2 * smoothWave).clamp(1.0, 2.8)
        ..color = (i % 2 == 0 ? conf.main : conf.accent).withValues(alpha: alpha);

      final leftX = cx - w / 2;
      final rightX = cx + w / 2;
      final waveHeight = 3.8 * math.sin(phaseVal);

      // Silky cubic bezier curve instead of quadratic
      final path = Path()
        ..moveTo(leftX, cy)
        ..cubicTo(
          leftX + w * 0.30, cy - waveHeight,
          leftX + w * 0.70, cy - waveHeight,
          rightX, cy,
        );
      canvas.drawPath(path, ripplePaint);
    }

    // ─────────────────────── 4. Specular Diamond Sparkles & Flares ───────────────────────
    for (int i = 0; i < _sparkles.length; i++) {
      final s = _sparkles[i];
      final sx = size.width * s.$1;
      final sy = size.height * s.$2;
      final scale = s.$3;
      final freq = s.$4;
      final pOffset = s.$5;

      final rawSine = math.sin(t * twoPi * freq + pOffset);
      if (rawSine <= 0) continue;

      // Sharp smooth bell curve: sin(x)^4
      final sparkVal = math.pow(rawSine, 4.0).toDouble();
      if (sparkVal < 0.04) continue;

      final sparkAlpha = (sparkVal * conf.brightness).clamp(0.0, 1.0);
      final sparkColor = (i % 3 == 0 ? conf.accent : conf.main).withValues(alpha: sparkAlpha);
      final r = (2.2 * scale * sparkVal).clamp(0.5, 5.5);

      // Inner Core
      canvas.drawCircle(Offset(sx, sy), r * 0.75, Paint()..color = sparkColor);

      // Soft Glow Aura
      canvas.drawCircle(
        Offset(sx, sy),
        r * 2.5,
        Paint()..color = conf.glow.withValues(alpha: 0.32 * sparkAlpha),
      );

      // 4-Point Star Flare
      if (sparkVal > 0.30) {
        final flarePaint = Paint()
          ..color = conf.main.withValues(alpha: (sparkAlpha * 0.90).clamp(0.0, 1.0))
          ..strokeWidth = 1.2 * scale
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        final flareLen = r * 3.4;
        canvas.drawLine(Offset(sx - flareLen, sy), Offset(sx + flareLen, sy), flarePaint);
        canvas.drawLine(Offset(sx, sy - flareLen * 0.55), Offset(sx, sy + flareLen * 0.55), flarePaint);
      }
    }

    // ─────────────────────── 5. Swift-Style Floating Ambient Light Motes ───────────────────────
    for (int i = 0; i < _ambientMotes.length; i++) {
      final m = _ambientMotes[i];
      final xBase = m.$1 * size.width;
      final yBase = m.$2 * size.height;
      final r = m.$3;
      final xFreq = m.$4;
      final yFreq = m.$5;
      final phaseOff = m.$6;

      final mx = xBase + math.sin(t * twoPi * xFreq + phaseOff) * 35.0;
      final my = yBase + math.cos(t * twoPi * yFreq + phaseOff * 1.5) * 22.0;
      final motePulse = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(t * twoPi * (xFreq + yFreq) + phaseOff));
      final moteAlpha = (0.25 + 0.50 * motePulse) * conf.brightness;

      final motePaint = Paint()
        ..color = conf.mote.withValues(alpha: moteAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(mx, my), r * (0.8 + 0.3 * motePulse), motePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.phase != phase;
}
// ─────────────────────────── App ───────────────────────────

class PrayerApp extends StatelessWidget {
  const PrayerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'اذکار من',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Vazirmatn',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F3D2E)),
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final IslamicDataRepository _repository = HttpIslamicDataRepository();
  late Future<PrayerData> _future;
  Timer? _timer;
  PrayerData? _cachedData;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadData().then((data) {
      _cachedData = data;
      final schedule = PrayerSchedule.resolve(data: data, now: DateTime.now());
      String? hadith;
      if (data.hadiths.isNotEmpty) {
        hadith = data.hadiths[schedule.jalali.day % data.hadiths.length]['fa'] as String?;
      }
      DesktopIntegration.sync(schedule: schedule, hadith: hadith);
      return data;
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        setState(() {});
      }
      if (_cachedData != null) {
        final schedule = PrayerSchedule.resolve(data: _cachedData!, now: DateTime.now());
        String? hadith;
        if (_cachedData!.hadiths.isNotEmpty) {
          hadith = _cachedData!.hadiths[schedule.jalali.day % _cachedData!.hadiths.length]['fa'] as String?;
        }
        DesktopIntegration.sync(schedule: schedule, hadith: hadith);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FutureBuilder<PrayerData>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            _cachedData = snap.data;
            return Dashboard(
              data: snap.data!,
              now: DateTime.now(),
              onRefresh: () {
                if (mounted) setState(() {});
              },
            );
          },
        ),
      ),
    );
  }
}
