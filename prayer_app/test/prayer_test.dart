import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/main.dart';

void main() {
  group('Date & Time Utilities (Jalali & Gregorian)', () {
    test('gregorianToJalali handles multiple years, seasons, and leap years', () {
      // 1405 Farvardin 1 (Nowruz 2026)
      final d1 = gregorianToJalali(2026, 3, 21);
      expect(d1.year, 1405);
      expect(d1.month, 1);
      expect(d1.day, 1);

      // 1405 Shahrivar 5
      final d2 = gregorianToJalali(2026, 8, 27);
      expect(d2.year, 1405);
      expect(d2.month, 6);
      expect(d2.day, 5);

      // 1405 Dey 1 (Winter Solstice 2026)
      final d3 = gregorianToJalali(2026, 12, 22);
      expect(d3.year, 1405);
      expect(d3.month, 10);
      expect(d3.day, 1);

      // 1405 Esfand 29 (End of year 1405)
      final d4 = gregorianToJalali(2027, 3, 20);
      expect(d4.year, 1405);
      expect(d4.month, 12);
      expect(d4.day, 29);

      // 1403 Farvardin 1 (Leap year 2024)
      final d5 = gregorianToJalali(2024, 3, 20);
      expect(d5.year, 1403);
      expect(d5.month, 1);
      expect(d5.day, 1);
    });

    test('jalaliToday returns correct record from DateTime', () {
      final now = DateTime(2026, 8, 27);
      final jt = jalaliToday(now);
      expect(jt.year, 1405);
      expect(jt.month, 6);
      expect(jt.day, 5);
    });

    test('toMin converts HH:MM to minutes from midnight', () {
      expect(toMin('00:00'), 0.0);
      expect(toMin('04:30'), 270.0);
      expect(toMin('12:00'), 720.0);
      expect(toMin('23:59'), 1439.0);
    });

    test('fmt formats duration into H:MM string', () {
      expect(fmt(const Duration(hours: 1, minutes: 24)), '1:24');
      expect(fmt(const Duration(hours: 0, minutes: 5)), '0:05');
      expect(fmt(const Duration(hours: 10, minutes: 0)), '10:00');
    });

    test('faDigits converts Western numbers to Persian digits', () {
      expect(faDigits('12:34'), '۱۲:۳۴');
      expect(faDigits('0123456789'), '۰۱۲۳۴۵۶۷۸۹');
      expect(faDigits('No numbers here'), 'No numbers here');
    });
  });

  group('Schedule Boundary Resolution', () {
    final mockToday = {
      'fajr': '04:30',
      'sunrise': '06:00',
      'dhuhr': '12:30',
      'asr': '16:00',
      'maghrib': '19:15',
      'isha': '20:45',
    };

    test('resolves exact prayer names', () {
      expect(resolveBoundary('fajr', mockToday), 270.0);
      expect(resolveBoundary('dhuhr', mockToday), 750.0);
      expect(resolveBoundary('always', mockToday), -1.0);
    });

    test('resolves plus expressions', () {
      expect(resolveBoundary('fajr+20', mockToday), 290.0);
      expect(resolveBoundary('sunrise+15', mockToday), 375.0);
    });

    test('resolves minus expressions', () {
      expect(resolveBoundary('dhuhr-30', mockToday), 720.0);
      expect(resolveBoundary('maghrib-15', mockToday), 1140.0);
    });
  });

  group('Next Prayer Calculations & Edge Cases', () {
    final mockPrayerData = PrayerData(
      {
        '6-5': {
          'fajr': '04:30',
          'sunrise': '06:00',
          'dhuhr': '12:30',
          'asr': '16:00',
          'maghrib': '19:15',
          'isha': '20:45',
        },
        '6-6': {
          'fajr': '04:31',
          'sunrise': '06:01',
          'dhuhr': '12:30',
          'asr': '16:00',
          'maghrib': '19:14',
          'isha': '20:44',
        },
      },
      {'6': 31},
    );

    test('calculates next prayer before Fajr early morning', () {
      final now = DateTime(2026, 8, 27, 3, 30); // 3:30 AM -> next is Fajr (04:30)
      final np = calculateNextPrayer(mockPrayerData, now);
      expect(np, isNotNull);
      expect(np!.label, 'اذان صبح');
      expect(np.time, '04:30');
      expect(np.delta.inMinutes, 60);
    });

    test('calculates next prayer exactly at prayer time (transitions to next)', () {
      // Exactly at 12:30, 12:30 > 12:30 is false, so next is Asr (16:00)
      final now = DateTime(2026, 8, 27, 12, 30);
      final np = calculateNextPrayer(mockPrayerData, now);
      expect(np, isNotNull);
      expect(np!.label, 'اذان عصر');
      expect(np.time, '16:00');
      expect(np.delta.inMinutes, 210);
    });

    test('calculates next prayer in morning', () {
      final now = DateTime(2026, 8, 27, 8, 0); // 8:00 AM -> next is Dhuhr (12:30)
      final np = calculateNextPrayer(mockPrayerData, now);
      expect(np, isNotNull);
      expect(np!.label, 'اذان ظهر');
      expect(np.time, '12:30');
      expect(np.delta.inMinutes, 270);
    });

    test('calculates next prayer in afternoon', () {
      final now = DateTime(2026, 8, 27, 13, 0); // 13:00 -> next is Asr (16:00)
      final np = calculateNextPrayer(mockPrayerData, now);
      expect(np, isNotNull);
      expect(np!.label, 'اذان عصر');
      expect(np.time, '16:00');
      expect(np.delta.inMinutes, 180);
    });

    test('wraps around to next day Fajr after Isha', () {
      final now = DateTime(2026, 8, 27, 22, 0); // 22:00 -> after Isha (20:45), next is tomorrow Fajr (04:31)
      final np = calculateNextPrayer(mockPrayerData, now);
      expect(np, isNotNull);
      expect(np!.label, 'اذان صبح');
      expect(np.time, '04:31');
      expect(np.delta.inMinutes, 391);
    });

    test('returns null safely when prayer data is missing', () {
      final emptyData = PrayerData({}, {});
      final np = calculateNextPrayer(emptyData, DateTime(2026, 8, 27));
      expect(np, isNull);
    });
  });

  group('Smart Azkar Suggestions & Rules', () {
    final mockPrayerData = PrayerData(
      {
        '6-5': {
          'fajr': '04:30',
          'sunrise': '06:00',
          'dhuhr': '12:30',
          'asr': '16:00',
          'maghrib': '19:15',
          'isha': '20:45',
        },
      },
      {'6': 31},
    );
    mockPrayerData.schedule = [
      {
        'from': 'fajr',
        'to': 'sunrise+25',
        'label': 'اذکار صبحگاه',
        'arabic': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
        'note': 'بعد از نماز صبح تا طلوع آفتاب'
      },
      {
        'from': 'asr',
        'to': 'maghrib',
        'label': 'اذکار شامگاه',
        'arabic': 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ',
        'note': 'بعد از نماز عصر تا مغرب'
      },
      {
        'from': 'always',
        'to': 'always',
        'label': 'استغفار و صلوات',
        'arabic': 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
        'note': 'در هر زمان از شبانه‌روز'
      }
    ];

    test('suggests morning azkar during morning window', () {
      final now = DateTime(2026, 8, 27, 5, 15); // 05:15 is between fajr (04:30) and sunrise+25 (06:25)
      final zikr = getSmartZikr(mockPrayerData, now);
      expect(zikr['active'], isTrue);
      expect(zikr['label'], 'اذکار صبحگاه');
    });

    test('suggests evening azkar during afternoon window', () {
      final now = DateTime(2026, 8, 27, 17, 0); // 17:00 is between asr (16:00) and maghrib (19:15)
      final zikr = getSmartZikr(mockPrayerData, now);
      expect(zikr['active'], isTrue);
      expect(zikr['label'], 'اذکار شامگاه');
    });

    test('falls back to general zikr outside specific windows', () {
      final now = DateTime(2026, 8, 27, 10, 0); // 10:00 AM outside morning & evening
      final zikr = getSmartZikr(mockPrayerData, now);
      expect(zikr['active'], isFalse);
      expect(zikr['label'], 'استغفار و صلوات');
    });
  });

  group('Scene Phase and Theme Detection', () {
    final mockToday = {
      'fajr': '04:30',
      'sunrise': '06:00',
      'dhuhr': '12:30',
      'asr': '16:00',
      'maghrib': '19:15',
      'isha': '20:45',
    };

    test('detects correct scene phases throughout 24 hours', () {
      expect(phaseFor(DateTime(2026, 8, 27, 5, 0), mockToday), ScenePhase.dawn);
      expect(phaseFor(DateTime(2026, 8, 27, 8, 0), mockToday), ScenePhase.morning);
      expect(phaseFor(DateTime(2026, 8, 27, 13, 0), mockToday), ScenePhase.noon);
      expect(phaseFor(DateTime(2026, 8, 27, 17, 0), mockToday), ScenePhase.afternoon);
      expect(phaseFor(DateTime(2026, 8, 27, 19, 0), mockToday), ScenePhase.sunset);
      expect(phaseFor(DateTime(2026, 8, 27, 21, 0), mockToday), ScenePhase.evening);
      expect(phaseFor(DateTime(2026, 8, 27, 23, 30), mockToday), ScenePhase.night);
      expect(phaseFor(DateTime(2026, 8, 27, 2, 0), mockToday), ScenePhase.midnight);
    });

    test('isNightTheme returns true for night and false for day', () {
      expect(isNightTheme(DateTime(2026, 8, 27, 12, 0), mockToday), isFalse);
      expect(isNightTheme(DateTime(2026, 8, 27, 15, 0), mockToday), isFalse);
      expect(isNightTheme(DateTime(2026, 8, 27, 22, 0), mockToday), isTrue);
      expect(isNightTheme(DateTime(2026, 8, 27, 3, 0), mockToday), isTrue);
    });
  });

  group('Deep PrayerSchedule Domain Module', () {
    final mockPrayerData = PrayerData(
      {
        '6-5': {
          'fajr': '04:30',
          'sunrise': '06:00',
          'dhuhr': '12:30',
          'asr': '16:00',
          'maghrib': '19:15',
          'isha': '20:45',
        },
      },
      {'6': 31},
    );
    mockPrayerData.schedule = [
      {
        'from': 'always',
        'to': 'always',
        'label': 'ذکر روز',
        'arabic': 'الحمد لله',
        'note': 'عمومی'
      }
    ];

    test('resolves full schedule into typed value objects', () {
      final now = DateTime(2026, 8, 27, 11, 0); // 11:00 AM -> next is Dhuhr (12:30)
      final schedule = PrayerSchedule.resolve(data: mockPrayerData, now: now);

      expect(schedule.jalali.year, 1405);
      expect(schedule.jalali.month, 6);
      expect(schedule.jalali.day, 5);
      expect(schedule.weekdayName, 'پنجشنبه');
      expect(schedule.monthName, 'شهریور');
      expect(schedule.nextPrayer, isNotNull);
      expect(schedule.nextPrayer!.key, 'dhuhr');
      expect(schedule.nextPrayer!.label, 'اذان ظهر');
      expect(schedule.nextPrayer!.time, '12:30');
      expect(schedule.nextPrayer!.delta.inMinutes, 90);
      expect(schedule.activePrayerKey, 'dhuhr');
      expect(schedule.phase, ScenePhase.morning);
      expect(schedule.isNight, isFalse);
      expect(schedule.zikr.label, 'ذکر روز');
      expect(schedule.fasting.isTomorrowFast, isFalse); // Friday is not sunnah fast by default
      expect(schedule.kurdishDate, contains('خەرمانان'));
      expect(schedule.kurdishDate, contains('۲۷۲۶'));
      expect(schedule.ramadanCountdown.text, contains('تا رمضان'));
    });

    test('calculates accurate Kurdish date and Ramadan countdown', () {
      final now = DateTime(2026, 8, 28, 6, 30); // Friday 6 Shahrivar 1405 / 14 Rabi' I 1448
      final schedule = PrayerSchedule.resolve(data: mockPrayerData, now: now);

      expect(schedule.kurdishDate, '۶ی خەرمانانی ۲۷۲۶');
      expect(schedule.ramadanCountdown.months, 5);
      expect(schedule.ramadanCountdown.days, 16);
      expect(schedule.ramadanCountdown.text, '۵ ماه و ۱۶ روز تا رمضان');
    });
  });

  group('IslamicDataRepository Seam & Adapters', () {
    test('AssetIslamicDataRepository fallback provides weather defaults', () async {
      const repo = AssetIslamicDataRepository();
      final weather = await repo.fetchWeather();
      expect(weather, isNotNull);
      expect(weather!['temp'], 20.0);
      expect(weather['code'], 0);
    });
  });
}
