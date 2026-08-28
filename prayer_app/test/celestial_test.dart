import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/main.dart';

void main() {
  group('CelestialTrajectoryCalculator Tests', () {
    final prayerTimes = {
      'fajr': '04:30',
      'sunrise': '06:00',
      'dhuhr': '12:30',
      'asr': '16:00',
      'maghrib': '19:30',
      'isha': '21:00',
    };

    test('Sun rises in the East (right side, high x) at sunrise', () {
      final now = DateTime(2026, 8, 28, 6, 0); // At sunrise
      final pos = CelestialTrajectoryCalculator.calculate(
        now: now,
        prayerTimes: prayerTimes,
        hijriDay: 14,
      );

      expect(pos.isSun, isTrue);
      expect(pos.isVisible, isTrue);
      expect(pos.x, greaterThan(0.70)); // On the right (East)
      expect(pos.y, greaterThan(0.30)); // Lower in the sky (near horizon)
      expect(pos.altitude, lessThan(0.40));
    });

    test('Sun reaches highest point (zenith / center) at Dhuhr', () {
      final now = DateTime(2026, 8, 28, 12, 30); // At Dhuhr
      final pos = CelestialTrajectoryCalculator.calculate(
        now: now,
        prayerTimes: prayerTimes,
        hijriDay: 14,
      );

      expect(pos.isSun, isTrue);
      expect(pos.isVisible, isTrue);
      expect(pos.x, closeTo(0.50, 0.08)); // In the center
      expect(pos.y, lessThan(0.18)); // Highest elevation
      expect(pos.altitude, closeTo(1.0, 0.15));
    });

    test('Sun moves to the West (left side, low x) towards Maghrib', () {
      final now = DateTime(2026, 8, 28, 19, 15); // Just before sunset
      final pos = CelestialTrajectoryCalculator.calculate(
        now: now,
        prayerTimes: prayerTimes,
        hijriDay: 14,
      );

      expect(pos.isSun, isTrue);
      expect(pos.isVisible, isTrue);
      expect(pos.x, lessThan(0.30)); // On the left (West)
      expect(pos.y, greaterThan(0.30)); // Descending towards horizon
    });

    test('Moon takes over during night hours (e.g. 23:00)', () {
      final now = DateTime(2026, 8, 28, 23, 0); // Deep night
      final pos = CelestialTrajectoryCalculator.calculate(
        now: now,
        prayerTimes: prayerTimes,
        hijriDay: 14,
      );

      expect(pos.isSun, isFalse);
      expect(pos.isVisible, isTrue);
      expect(pos.x, inInclusiveRange(0.0, 1.0));
      expect(pos.y, inInclusiveRange(0.0, 1.0));
    });
  });

  group('MoonPhaseCalculator Tests', () {
    test('Calculates full moon near 14th-15th Hijri', () {
      final phase = MoonPhaseCalculator.calculate(14);
      expect(phase.isFullMoon, isTrue);
      expect(phase.illumination, closeTo(1.0, 0.1));
      expect(phase.nameFa, contains('بدر'));
    });

    test('Calculates crescent near 2nd-3rd Hijri', () {
      final phase = MoonPhaseCalculator.calculate(3);
      expect(phase.isFullMoon, isFalse);
      expect(phase.isCrescent, isTrue);
      expect(phase.illumination, lessThan(0.35));
      expect(phase.nameFa, contains('هلال'));
    });

    test('Calculates quarter moon near 8th Hijri', () {
      final phase = MoonPhaseCalculator.calculate(8);
      expect(phase.illumination, closeTo(0.5, 0.15));
      expect(phase.nameFa, contains('تربیع'));
    });
  });

  group('DynamicCelestialSky Widget Tests', () {
    final prayerTimes = {
      'fajr': '04:30',
      'sunrise': '06:00',
      'dhuhr': '12:30',
      'asr': '16:00',
      'maghrib': '19:30',
      'isha': '21:00',
    };

    testWidgets('Renders sun correctly during noon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCelestialSky(
              phase: ScenePhase.noon,
              now: DateTime(2026, 8, 28, 12, 30),
              prayerTimes: prayerTimes,
              hijriDay: 14,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(DynamicCelestialSky), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Renders moon correctly during night', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCelestialSky(
              phase: ScenePhase.night,
              now: DateTime(2026, 8, 28, 23, 30),
              prayerTimes: prayerTimes,
              hijriDay: 14,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(DynamicCelestialSky), findsOneWidget);
    });

    testWidgets('Handles various screen sizes responsively', (tester) async {
      // Mobile size
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCelestialSky(
              phase: ScenePhase.morning,
              now: DateTime(2026, 8, 28, 8, 0),
              prayerTimes: prayerTimes,
              hijriDay: 14,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(DynamicCelestialSky), findsOneWidget);

      // Desktop wide size
      tester.view.physicalSize = const Size(1920, 1080);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicCelestialSky(
              phase: ScenePhase.morning,
              now: DateTime(2026, 8, 28, 8, 0),
              prayerTimes: prayerTimes,
              hijriDay: 14,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(DynamicCelestialSky), findsOneWidget);

      // Reset
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
