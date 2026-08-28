import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

class CelestialPosition {
  final double x; // 0.0 (left / West) to 1.0 (right / East)
  final double y; // 0.0 (zenith / Top) to 1.0 (horizon / Bottom)
  final double altitude; // 0.0 (horizon/below) to 1.0 (zenith)
  final bool isSun; // true = sun, false = moon
  final bool isVisible;
  final Color primaryColor;
  final Color glowColor;
  final double radius;

  const CelestialPosition({
    required this.x,
    required this.y,
    required this.altitude,
    required this.isSun,
    required this.isVisible,
    required this.primaryColor,
    required this.glowColor,
    this.radius = 46.0,
  });
}

class MoonPhaseInfo {
  final int hijriDay;
  final double illumination; // 0.0 (New Moon) to 1.0 (Full Moon)
  final bool isFullMoon;
  final bool isCrescent;
  final String nameFa;
  final double shadowOffset; // -1.0 to 1.0 for crescent/gibbous shading

  const MoonPhaseInfo({
    required this.hijriDay,
    required this.illumination,
    required this.isFullMoon,
    required this.isCrescent,
    required this.nameFa,
    required this.shadowOffset,
  });
}

class MoonPhaseCalculator {
  static MoonPhaseInfo calculate(int hijriDay) {
    final day = hijriDay.clamp(1, 30);
    // Synodic lunar cycle is ~29.53 days
    final cycleFraction = (day - 1) / 29.53;
    final illumination = (1.0 - cos(cycleFraction * 2 * pi)) / 2.0;

    final isFullMoon = day >= 13 && day <= 16;
    final isCrescent = day <= 4 || day >= 27;

    String nameFa;
    if (day == 1 || day == 30) {
      nameFa = 'هلال اول ماه (محاق)';
    } else if (day >= 2 && day <= 4) {
      nameFa = 'هلال متزاید (Crescent)';
    } else if (day >= 5 && day <= 9) {
      nameFa = 'تربیع اول (First Quarter)';
    } else if (day >= 10 && day <= 12) {
      nameFa = 'احدب متزاید (Gibbous)';
    } else if (day >= 13 && day <= 16) {
      nameFa = 'بدر کامل (Full Moon 🌕)';
    } else if (day >= 17 && day <= 21) {
      nameFa = 'احدب متناقص (Waning Gibbous)';
    } else if (day >= 22 && day <= 26) {
      nameFa = 'تربیع دوم (Third Quarter)';
    } else {
      nameFa = 'هلال آخر ماه (Waning Crescent)';
    }

    // Shadow offset calculation for crescent/gibbous visual rendering
    // day 1: +1.0 (fully covered from right/left), day 14: 0.0 (full), day 29: -1.0
    final shadowOffset = cos(cycleFraction * 2 * pi);

    return MoonPhaseInfo(
      hijriDay: day,
      illumination: illumination,
      isFullMoon: isFullMoon,
      isCrescent: isCrescent,
      nameFa: nameFa,
      shadowOffset: shadowOffset,
    );
  }
}

class CelestialTrajectoryCalculator {
  static int _parseTimeToMinutes(String? timeStr, {int defaultMinutes = 0}) {
    if (timeStr == null || !timeStr.contains(':')) return defaultMinutes;
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  static CelestialPosition calculate({
    required DateTime now,
    required Map<String, dynamic> prayerTimes,
    required int hijriDay,
  }) {
    final nowMinutes = now.hour * 60 + now.minute + (now.second / 60.0);

    final fajr = _parseTimeToMinutes(prayerTimes['fajr'] as String?, defaultMinutes: 270); // 04:30
    final sunrise = _parseTimeToMinutes(prayerTimes['sunrise'] as String?, defaultMinutes: 360); // 06:00
    final dhuhr = _parseTimeToMinutes(prayerTimes['dhuhr'] as String?, defaultMinutes: 750); // 12:30
    final maghrib = _parseTimeToMinutes(prayerTimes['maghrib'] as String?, defaultMinutes: 1170); // 19:30

    final isDaytime = nowMinutes >= sunrise && nowMinutes <= maghrib;
    final isDawn = nowMinutes >= fajr && nowMinutes < sunrise;

    if (isDaytime) {
      // SUN IN THE SKY
      if (nowMinutes <= dhuhr) {
        // Sunrise to Dhuhr (Ascending from East/Right to Zenith/Center)
        final duration = (dhuhr - sunrise).clamp(1, 1440);
        final t = ((nowMinutes - sunrise) / duration).clamp(0.0, 1.0);

        final x = 0.86 - (0.36 * t); // 0.86 (East) -> 0.50 (Center)
        final altitude = sin(t * pi / 2.0); // 0.0 -> 1.0
        final y = 0.42 - (0.30 * altitude); // 0.42 (Horizon) -> 0.12 (Zenith)

        final primaryColor = Color.lerp(
          const Color(0xFFF59E0B), // Warm Sunrise Amber
          const Color(0xFFFEF08A), // Bright Solar Yellow
          t,
        )!;

        final glowColor = Color.lerp(
          const Color(0xFFF97316), // Warm Orange Aura
          const Color(0xFFFDE047), // Radiant Sunburst Aura
          t,
        )!;

        return CelestialPosition(
          x: x,
          y: y,
          altitude: altitude,
          isSun: true,
          isVisible: true,
          primaryColor: primaryColor,
          glowColor: glowColor,
          radius: 46.0 + (altitude * 4.0),
        );
      } else {
        // Dhuhr to Maghrib (Descending from Zenith/Center to West/Left)
        final duration = (maghrib - dhuhr).clamp(1, 1440);
        final t = ((nowMinutes - dhuhr) / duration).clamp(0.0, 1.0);

        final x = 0.50 - (0.38 * t); // 0.50 (Center) -> 0.12 (West)
        final altitude = cos(t * pi / 2.0); // 1.0 -> 0.0
        final y = 0.12 + (0.30 * (1.0 - altitude)); // 0.12 (Zenith) -> 0.42 (Horizon)

        final primaryColor = Color.lerp(
          const Color(0xFFFEF08A), // Bright Solar Yellow
          const Color(0xFFF97316), // Deep Sunset Amber
          t,
        )!;

        final glowColor = Color.lerp(
          const Color(0xFFFDE047), // Radiant Sunburst
          const Color(0xFFEA580C), // Fiery Sunset Corona
          t,
        )!;

        return CelestialPosition(
          x: x,
          y: y,
          altitude: altitude,
          isSun: true,
          isVisible: true,
          primaryColor: primaryColor,
          glowColor: glowColor,
          radius: 46.0 + (altitude * 4.0),
        );
      }
    } else if (isDawn) {
      // Dawn / Pre-sunrise glow rising up from East
      final duration = (sunrise - fajr).clamp(1, 1440);
      final t = ((nowMinutes - fajr) / duration).clamp(0.0, 1.0);

      final x = 0.94 - (0.08 * t);
      final y = 0.65 - (0.23 * t); // Rising up to 0.42
      final altitude = 0.15 * t;

      return CelestialPosition(
        x: x,
        y: y,
        altitude: altitude,
        isSun: true,
        isVisible: true,
        primaryColor: const Color(0xFFF59E0B).withValues(alpha: 0.85),
        glowColor: const Color(0xFFFB7185),
        radius: 42.0,
      );
    } else {
      // NIGHTTIME: MOON IN THE SKY
      double nightProgress;
      if (nowMinutes > maghrib) {
        // Maghrib (19:30) to Midnight (24:00)
        final totalNightSpan = (1440 - maghrib) + sunrise;
        final elapsed = nowMinutes - maghrib;
        nightProgress = (elapsed / totalNightSpan).clamp(0.0, 1.0);
      } else {
        // Midnight (00:00) to Sunrise (06:00)
        final totalNightSpan = (1440 - maghrib) + sunrise;
        final elapsed = (1440 - maghrib) + nowMinutes;
        nightProgress = (elapsed / totalNightSpan).clamp(0.0, 1.0);
      }

      // Moon traverses from East (0.86) across zenith (0.50) to West (0.14)
      final x = 0.86 - (0.72 * nightProgress);
      final altitude = sin(nightProgress * pi); // Peaks at midnight
      final y = 0.42 - (0.28 * altitude);

      return CelestialPosition(
        x: x,
        y: y,
        altitude: altitude,
        isSun: false,
        isVisible: true,
        primaryColor: const Color(0xFFF8FAFC),
        glowColor: const Color(0xFF93C5FD),
        radius: 38.0,
      );
    }
  }
}

class DynamicCelestialSky extends StatefulWidget {
  final ScenePhase phase;
  final DateTime now;
  final Map<String, dynamic> prayerTimes;
  final int hijriDay;

  const DynamicCelestialSky({
    super.key,
    required this.phase,
    required this.now,
    required this.prayerTimes,
    required this.hijriDay,
  });

  @override
  State<DynamicCelestialSky> createState() => _DynamicCelestialSkyState();
}

class _DynamicCelestialSkyState extends State<DynamicCelestialSky>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // 6-second slow breathing sine pulse for atmospheric corona
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = CelestialTrajectoryCalculator.calculate(
      now: widget.now,
      prayerTimes: widget.prayerTimes,
      hijriDay: widget.hijriDay,
    );

    final moonPhase = MoonPhaseCalculator.calculate(widget.hijriDay);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: CelestialPainter(
              position: position,
              moonPhase: moonPhase,
              pulse: _pulseController.value,
              phase: widget.phase,
            ),
          );
        },
      ),
    );
  }
}

class CelestialPainter extends CustomPainter {
  final CelestialPosition position;
  final MoonPhaseInfo moonPhase;
  final double pulse;
  final ScenePhase phase;

  CelestialPainter({
    required this.position,
    required this.moonPhase,
    required this.pulse,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!position.isVisible || size.width <= 0 || size.height <= 0) return;

    final cx = size.width * position.x;
    final cy = size.height * position.y;
    final center = Offset(cx, cy);
    final r = position.radius;

    // Breathing pulse calculation: smoothly interpolates size and opacity
    final pulseScale = 1.0 + (0.08 * sin(pulse * pi));
    final pulseOpacity = 0.85 + (0.15 * cos(pulse * pi));

    if (position.isSun) {
      _paintSun(canvas, center, r, pulseScale, pulseOpacity);
    } else {
      _paintMoon(canvas, center, r, pulseScale, pulseOpacity);
    }
  }

  void _paintSun(Canvas canvas, Offset center, double r, double pulseScale, double pulseOpacity) {
    // 1. Layer 1: Broad Atmospheric Corona Glow
    final broadGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          position.glowColor.withValues(alpha: (0.28 * pulseOpacity).clamp(0.0, 1.0)),
          position.glowColor.withValues(alpha: (0.12 * pulseOpacity).clamp(0.0, 1.0)),
          position.glowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.8 * pulseScale));

    canvas.drawCircle(center, r * 2.8 * pulseScale, broadGlowPaint);

    // 2. Layer 2: Radiant Inner Corona Ring
    final innerCoronaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          position.primaryColor.withValues(alpha: (0.45 * pulseOpacity).clamp(0.0, 1.0)),
          position.primaryColor.withValues(alpha: (0.18 * pulseOpacity).clamp(0.0, 1.0)),
          position.primaryColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.85 * pulseScale));

    canvas.drawCircle(center, r * 1.85 * pulseScale, innerCoronaPaint);

    // 3. Layer 3: Solid Solar Disc with Radiant Shading
    final sunDiscPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        colors: [
          Colors.white,
          position.primaryColor,
          position.glowColor,
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r, sunDiscPaint);

    // 4. Layer 4: Brilliant White-Hot Solar Core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.60));

    canvas.drawCircle(center, r * 0.60, corePaint);
  }

  void _paintMoon(Canvas canvas, Offset center, double r, double pulseScale, double pulseOpacity) {
    // 1. Layer 1: Soft Silver-Blue Moonlight Aura
    final moonlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          position.glowColor.withValues(alpha: (0.24 * pulseOpacity).clamp(0.0, 1.0)),
          position.glowColor.withValues(alpha: (0.08 * pulseOpacity).clamp(0.0, 1.0)),
          position.glowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * 2.5 * pulseScale));

    canvas.drawCircle(center, r * 2.5 * pulseScale, moonlightPaint);

    // 2. Layer 2: Moon Base Disc
    final moonBasePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.25),
        colors: [
          const Color(0xFFFFFFFF),
          const Color(0xFFE2E8F0),
          const Color(0xFFCBD5E1),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    if (moonPhase.isFullMoon) {
      // Full Moon: Draw Complete Disc with subtle maria (craters)
      canvas.drawCircle(center, r, moonBasePaint);

      // Subtle Crater Textures
      final craterPaint = Paint()
        ..color = const Color(0xFF94A3B8).withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center + Offset(-r * 0.25, -r * 0.15), r * 0.22, craterPaint);
      canvas.drawCircle(center + Offset(r * 0.28, r * 0.20), r * 0.18, craterPaint);
      canvas.drawCircle(center + Offset(r * 0.05, r * 0.35), r * 0.14, craterPaint);
    } else {
      // Crescent or Quarter: Mask with dark shadow based on Hijri Day
      canvas.save();
      final moonClipPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: r));
      canvas.clipPath(moonClipPath);

      // Draw Illuminated base
      canvas.drawCircle(center, r, moonBasePaint);

      // Draw Shadow Disc to create Crescent/Quarter shape
      final shadowOffsetFactor = moonPhase.shadowOffset; // -1 to 1
      final shadowCenterX = center.dx + (r * 1.15 * shadowOffsetFactor);
      final shadowCenter = Offset(shadowCenterX, center.dy);

      final shadowPaint = Paint()
        ..color = const Color(0xFF0F172A).withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(shadowCenter, r * 0.95, shadowPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CelestialPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.position.x != position.x ||
        oldDelegate.position.y != position.y ||
        oldDelegate.position.isSun != position.isSun ||
        oldDelegate.moonPhase.hijriDay != moonPhase.hijriDay;
  }
}
