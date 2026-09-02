import 'package:flutter/cupertino.dart';
import '../main.dart';

String faDigits(String s) =>
    s.replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);

/// Accurate astronomical conversion from Gregorian date to Jalali (Solar Hijri)
({int year, int month, int day}) gregorianToJalali(int gy, int gm, int gd) {
  const gDaysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  int gy2 = (gm > 2) ? (gy + 1) : gy;
  int gDays = 355666 +
      (365 * gy) +
      ((gy2 + 3) ~/ 4) -
      ((gy2 + 99) ~/ 100) +
      ((gy2 + 399) ~/ 400) +
      gd;
  for (int i = 0; i < gm - 1; ++i) {
    gDays += gDaysInMonth[i];
  }

  int jy = -1595 + (33 * (gDays ~/ 12053));
  gDays %= 12053;

  jy += 4 * (gDays ~/ 1461);
  gDays %= 1461;

  if (gDays > 365) {
    jy += ((gDays - 1) ~/ 365);
    gDays = (gDays - 1) % 365;
  }

  int jm = 0;
  int jd = 0;
  if (gDays < 186) {
    jm = 1 + (gDays ~/ 31);
    jd = 1 + (gDays % 31);
  } else {
    jm = 7 + ((gDays - 186) ~/ 30);
    jd = 1 + ((gDays - 186) % 30);
  }
  return (year: jy, month: jm, day: jd);
}

({int year, int month, int day}) jalaliToday(DateTime now) {
  return gregorianToJalali(now.year, now.month, now.day);
}

String fmt(Duration d) =>
    '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';

double toMin(String t) {
  final p = t.split(':');
  return double.parse(p[0]) * 60 + double.parse(p[1]);
}

const monthNames = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
];

const prayerLabels = {
  'fajr': 'اذان صبح',
  'sunrise': 'طلوع آفتاب',
  'dhuhr': 'اذان ظهر',
  'asr': 'اذان عصر',
  'maghrib': 'اذان مغرب',
  'isha': 'اذان عشاء',
};

const prayerSfSymbolMap = {
  'fajr': 'sunrise.fill',
  'sunrise': 'sun.max.fill',
  'dhuhr': 'sun.max',
  'asr': 'cloud.sun.fill',
  'maghrib': 'sunset.fill',
  'isha': 'moon.stars.fill',
};

const prayerCupertinoIconMap = {
  'fajr': CupertinoIcons.sunrise_fill,
  'sunrise': CupertinoIcons.sun_max_fill,
  'dhuhr': CupertinoIcons.sun_max,
  'asr': CupertinoIcons.cloud_sun_fill,
  'maghrib': CupertinoIcons.sunset_fill,
  'isha': CupertinoIcons.moon_stars_fill,
};

const persianWeekdays = {
  DateTime.monday: 'دوشنبه',
  DateTime.tuesday: 'سه‌شنبه',
  DateTime.wednesday: 'چهارشنبه',
  DateTime.thursday: 'پنجشنبه',
  DateTime.friday: 'جمعه',
  DateTime.saturday: 'شنبه',
  DateTime.sunday: 'یکشنبه',
};

enum AppThemeMode {
  system,
  light,
  dark;

  String get labelFa {
    switch (this) {
      case AppThemeMode.system:
        return 'سیستم';
      case AppThemeMode.light:
        return 'روشن';
      case AppThemeMode.dark:
        return 'تاریک';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.system:
        return CupertinoIcons.circle_righthalf_fill;
      case AppThemeMode.light:
        return CupertinoIcons.sun_max_fill;
      case AppThemeMode.dark:
        return CupertinoIcons.moon_fill;
    }
  }

  AppThemeMode get next {
    switch (this) {
      case AppThemeMode.system:
        return AppThemeMode.light;
      case AppThemeMode.light:
        return AppThemeMode.dark;
      case AppThemeMode.dark:
        return AppThemeMode.system;
    }
  }

  String get tooltip {
    switch (this) {
      case AppThemeMode.system:
        return 'حالت تم: سیستم (خودکار) — کلیک برای تغییر به روشن';
      case AppThemeMode.light:
        return 'حالت تم: روشن (روز) — کلیک برای تغییر به تاریک';
      case AppThemeMode.dark:
        return 'حالت تم: تاریک (شب) — کلیک برای تغییر به سیستم';
    }
  }
}

({int year, int month, int day}) gregorianToHijri(int gy, int gm, int gd) {
  int a = (14 - gm) ~/ 12;
  int y = gy + 4800 - a;
  int m = gm + 12 * a - 3;
  int jdn = gd + ((153 * m + 2) ~/ 5) + 365 * y + (y ~/ 4) - (y ~/ 100) + (y ~/ 400) - 32045;
  int l = jdn - 1948440 + 10632;
  int n = (l - 1) ~/ 10631;
  l = l - 10631 * n + 354;
  int j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
  l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
  int hm = (24 * l) ~/ 709;
  int hd = l - ((709 * hm) ~/ 24);
  int hy = 30 * n + j - 30;
  return (year: hy, month: hm, day: hd);
}

const hijriMonthNames = [
  'محرم', 'صفر', 'ربیع‌الاول', 'ربیع‌الثانی', 'جمادی‌الاول', 'جمادی‌الثانی',
  'رجب', 'شعبان', 'رمضان', 'شوال', 'ذی‌القعده', 'ذی‌الحجه'
];

const gregorianMonthNamesEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

const kurdishMonthNames = [
  'خاکەلێوە',
  'گوڵان',
  'جۆزەردان',
  'پووشپەڕ',
  'گەلاوێژ',
  'خەرمانان',
  'ڕەزبەر',
  'خەزەڵوەر',
  'سەرماوەز',
  'بەفرانبار',
  'ڕێبەندان',
  'ڕەشەمێ',
];

const kurdishWeekdays = {
  DateTime.monday: 'دووشەممە',
  DateTime.tuesday: 'سێشەممە',
  DateTime.wednesday: 'چوارشەممە',
  DateTime.thursday: 'پێنجشەممە',
  DateTime.friday: 'هەینی',
  DateTime.saturday: 'شەممە',
  DateTime.sunday: 'یەکشەممە',
};

class RamadanCountdown {
  final int months;
  final int days;
  final int totalDays;
  final String text;

  const RamadanCountdown({
    required this.months,
    required this.days,
    required this.totalDays,
    required this.text,
  });
}

RamadanCountdown calculateRamadanCountdown(({int year, int month, int day}) hj) {
  if (hj.month == 9) {
    return RamadanCountdown(
      months: 0,
      days: 0,
      totalDays: 0,
      text: 'ماه مبارک رمضان (روز ${faDigits('${hj.day}')})',
    );
  }

  int daysInHijriMonth(int m) => (m % 2 == 1) ? 30 : 29;

  int daysInCurrentMonth = daysInHijriMonth(hj.month);
  int remainingDaysInCurrentMonth = (daysInCurrentMonth - hj.day).clamp(0, 30);

  int interveningMonthsCount = 0;
  int totalDays = remainingDaysInCurrentMonth;

  int m = (hj.month % 12) + 1;
  while (m != 9) {
    interveningMonthsCount++;
    totalDays += daysInHijriMonth(m);
    m = (m % 12) + 1;
  }

  int months = interveningMonthsCount;
  int days = remainingDaysInCurrentMonth;
  if (days >= 30) {
    months += 1;
    days -= 30;
  }

  String text;
  if (months > 0 && days > 0) {
    text = '${faDigits('$months')} ماه و ${faDigits('$days')} روز تا رمضان';
  } else if (months > 0) {
    text = '${faDigits('$months')} ماه تا رمضان';
  } else if (days > 0) {
    text = '${faDigits('$days')} روز تا رمضان';
  } else {
    text = 'فردا آغاز ماه مبارک رمضان';
  }

  return RamadanCountdown(
    months: months,
    days: days,
    totalDays: totalDays,
    text: text,
  );
}

class SunnahItem {
  final String title;
  final String description;
  final IconData icon;
  final String? timeHint;

  const SunnahItem({
    required this.title,
    required this.description,
    required this.icon,
    this.timeHint,
  });
}

class SunnahBundle {
  final String headerTitle;
  final List<SunnahItem> timeBased;
  final List<SunnahItem> timeless;
  final bool isFridaySpecial;

  const SunnahBundle({
    required this.headerTitle,
    required this.timeBased,
    required this.timeless,
    required this.isFridaySpecial,
  });
}

SunnahBundle resolveSunnahBundle(DateTime now, ({int year, int month, int day}) jt, Map<String, String> prayerTimes) {
  final isFriday = now.weekday == DateTime.friday;
  final isThursdayEve = now.weekday == DateTime.thursday && now.hour >= 17;
  final isFridaySpecial = isFriday || isThursdayEve;

  // Time-based sunan
  final timeBased = <SunnahItem>[];
  final h = now.hour * 60 + now.minute;
  final sunrise = prayerTimes['sunrise'] != null ? toMin(prayerTimes['sunrise']!) : 360.0;
  final dhuhr = prayerTimes['dhuhr'] != null ? toMin(prayerTimes['dhuhr']!) : 720.0;
  final fajr = prayerTimes['fajr'] != null ? toMin(prayerTimes['fajr']!) : 300.0;

  if (h >= sunrise + 20 && h < dhuhr - 20) {
    timeBased.add(const SunnahItem(
      title: 'صلاة الضحی (نماز چاشت)',
      description: '۲ تا ۸ رکعت پس از طلوع کامل آفتاب تا قبل از زوال',
      icon: CupertinoIcons.sun_max,
      timeHint: 'اکنون تا اذان ظهر',
    ));
  } else if (h >= 0 && h < fajr - 30) {
    timeBased.add(const SunnahItem(
      title: 'نماز شب و وتر (قیام اللیل)',
      description: 'بهترین نماز پس از فرایض، انس با پروردگار در دل شب',
      icon: CupertinoIcons.moon_stars,
      timeHint: 'پیش از اذان صبح',
    ));
  } else {
    timeBased.add(const SunnahItem(
      title: 'سنن رواتب و اذکار بعد از نماز',
      description: '۱۲ رکعت سنت مؤکده در شبانه‌روز و تعقیبات پس از فرض',
      icon: CupertinoIcons.sparkles,
      timeHint: 'همراه نمازهای فرض',
    ));
  }

  // Fasting reminder if applicable
  final tomorrow = now.add(const Duration(days: 1));
  final jtTom = jalaliToday(tomorrow);
  final tomorrowFast = tomorrow.weekday == DateTime.thursday ||
      tomorrow.weekday == DateTime.monday ||
      jtTom.day == 13 || jtTom.day == 14 || jtTom.day == 15;
  if (tomorrowFast) {
    timeBased.add(SunnahItem(
      title: 'روزه سنت فردا',
      description: tomorrow.weekday == DateTime.monday || tomorrow.weekday == DateTime.thursday
          ? 'سنت روزهای دوشنبه و پنجشنبه'
          : 'سنت ایام بیض (سیزدهم تا پانزدهم ماه)',
      icon: CupertinoIcons.flame,
      timeHint: 'نیت روزه امشب',
    ));
  }

  // Timeless / related sunan
  final timeless = <SunnahItem>[];
  if (isFridaySpecial) {
    timeless.add(const SunnahItem(
      title: 'صلوات بر پیامبر ﷺ',
      description: 'سنت موکد روز جمعه جهت کسب شفاعت و نورانیت دل',
      icon: CupertinoIcons.sparkles,
      timeHint: 'طول روز جمعه',
    ));
    timeless.add(const SunnahItem(
      title: 'قرائت سوره کهف',
      description: 'نوری میان دو جمعه و حفظ از فتنه‌ها',
      icon: CupertinoIcons.book_fill,
      timeHint: 'پیش از غروب آفتاب',
    ));
    timeless.add(const SunnahItem(
      title: 'غسل جمعه',
      description: 'غسل، نظافت، پوشیدن لباس پاکیزه و استعمال عطر',
      icon: CupertinoIcons.drop_fill,
    ));
    timeless.add(const SunnahItem(
      title: 'زود رفتن به مسجد',
      description: 'شتاب برای حضور در نماز جمعه و استماع خطبه',
      icon: CupertinoIcons.building_2_fill,
    ));
    timeless.add(const SunnahItem(
      title: 'دعا',
      description: 'تضرع و دعا به ویژه در واپسین ساعت عصر جمعه (ساعت استجابت)',
      icon: CupertinoIcons.hand_raised_fill,
    ));
  } else {
    timeless.add(const SunnahItem(
      title: 'کثرت استغفار و توبه',
      description: '«أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ» روزانه بیش از ۱۰۰ بار',
      icon: CupertinoIcons.heart_fill,
      timeHint: 'در طول روز',
    ));
    timeless.add(const SunnahItem(
      title: 'صدقه و نیکی پنهانی',
      description: 'خاموش‌کننده خشم پروردگار و برکت در رزق و عمر',
      icon: CupertinoIcons.hand_thumbsup_fill,
      timeHint: 'فرصت روزانه',
    ));
    timeless.add(const SunnahItem(
      title: 'تلاوت روزانه و صدقه',
      description: 'انس با کلام‌الله و انفاق حتی به اندازه یک خرما',
      icon: CupertinoIcons.book_fill,
    ));
    timeless.add(const SunnahItem(
      title: 'اذکار خواب و بیداری',
      description: 'آیةالکرسی، اخلاص و معوذتین و اذکار مأثوره',
      icon: CupertinoIcons.moon_fill,
    ));
  }

  return SunnahBundle(
    headerTitle: isFridaySpecial ? 'سنت‌های مبارک جمعه' : 'سنت‌های روزانه و مستحبات',
    timeBased: timeBased,
    timeless: timeless,
    isFridaySpecial: isFridaySpecial,
  );
}

class NextPrayerInfo {
  final String key;
  final String label;
  final String time;
  final Duration delta;
  final String sfSymbol;
  final IconData icon;

  const NextPrayerInfo({
    required this.key,
    required this.label,
    required this.time,
    required this.delta,
    required this.sfSymbol,
    required this.icon,
  });
}

class FastingInfo {
  final bool isTomorrowFast;
  final String title;
  final String subtitle;
  final String? reminder;

  const FastingInfo({
    required this.isTomorrowFast,
    required this.title,
    required this.subtitle,
    this.reminder,
  });
}

class ZikrInfo {
  final String label;
  final String arabic;
  final String note;
  final bool isActive;

  const ZikrInfo({
    required this.label,
    required this.arabic,
    required this.note,
    required this.isActive,
  });
}

/// Deep Domain Module for Prayer Schedule, Boundaries, and Astronomical Calculations
class PrayerSchedule {
  final ({int year, int month, int day}) jalali;
  final ({int year, int month, int day}) hijri;
  final DateTime gregorian;
  final String weekdayName;
  final String monthName;
  final String kurdishDate;
  final RamadanCountdown ramadanCountdown;
  final String fullDateLine;
  final NextPrayerInfo? nextPrayer;
  final String? activePrayerKey;
  final ScenePhase phase;
  final bool isNight;
  final FastingInfo fasting;
  final ZikrInfo zikr;
  final SunnahBundle sunan;
  final Map<String, String> prayerTimes;

  const PrayerSchedule({
    required this.jalali,
    required this.hijri,
    required this.gregorian,
    required this.weekdayName,
    required this.monthName,
    required this.kurdishDate,
    required this.ramadanCountdown,
    required this.fullDateLine,
    required this.nextPrayer,
    required this.activePrayerKey,
    required this.phase,
    required this.isNight,
    required this.fasting,
    required this.zikr,
    required this.sunan,
    required this.prayerTimes,
  });

  static PrayerSchedule resolve({
    required PrayerData data,
    required DateTime now,
  }) {
    final jt = jalaliToday(now);
    final hj = gregorianToHijri(now.year, now.month, now.day);
    final weekdayName = persianWeekdays[now.weekday] ?? 'امروز';
    final monthName = monthNames[(jt.month - 1).clamp(0, 11)];
    final hijriMonthName = hijriMonthNames[(hj.month - 1).clamp(0, 11)];
    final gregMonthName = gregorianMonthNamesEn[(now.month - 1).clamp(0, 11)];
    final kurdishMonth = kurdishMonthNames[(jt.month - 1).clamp(0, 11)];
    final kurdishYear = jt.year + 1321;
    final kurdishDate = '${faDigits('${jt.day}')}ی $kurdishMonthی ${faDigits('$kurdishYear')}';

    final ramadanCountdown = calculateRamadanCountdown(hj);

    final solarStr = '$weekdayName ${faDigits('${jt.day}')} $monthName ${faDigits('${jt.year}')}';
    final hijriStr = '${faDigits('${hj.day}')} $hijriMonthName ${faDigits('${hj.year}')}';
    final gregStr = '${now.day} $gregMonthName ${now.year}';
    final fullDateLine = 'امروز: $solarStr • $hijriStr • $gregStr';

    final todayRaw = data.times['${jt.month}-${jt.day}'];
    final prayerTimes = <String, String>{};
    if (todayRaw is Map) {
      for (final e in todayRaw.entries) {
        if (e.value is String) prayerTimes[e.key.toString()] = e.value.toString();
      }
    }

    // Resolve Next Prayer
    NextPrayerInfo? nextPrayer;
    const order = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final nowMin = now.hour * 60 + now.minute;

    if (prayerTimes.isNotEmpty) {
      for (final k in order) {
        final val = prayerTimes[k];
        if (val == null) continue;
        final parts = val.split(':');
        final t = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        if (t > nowMin) {
          nextPrayer = NextPrayerInfo(
            key: k,
            label: prayerLabels[k] ?? k,
            time: val,
            delta: Duration(minutes: t - nowMin),
            sfSymbol: prayerSfSymbolMap[k] ?? 'clock.fill',
            icon: prayerCupertinoIconMap[k] ?? CupertinoIcons.clock,
          );
          break;
        }
      }

      if (nextPrayer == null) {
        final nd = jalaliToday(now.add(const Duration(days: 1)));
        final tm = data.times['${nd.month}-${nd.day}'];
        if (tm != null && tm['fajr'] != null) {
          final parts = (tm['fajr'] as String).split(':');
          final t = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          nextPrayer = NextPrayerInfo(
            key: 'fajr',
            label: prayerLabels['fajr']!,
            time: tm['fajr'] as String,
            delta: Duration(minutes: t - nowMin + 24 * 60),
            sfSymbol: prayerSfSymbolMap['fajr']!,
            icon: prayerCupertinoIconMap['fajr']!,
          );
        }
      }
    }

    // Resolve Active Prayer
    String? activePrayerKey = nextPrayer?.key;

    // Resolve Scene Phase
    ScenePhase phase = ScenePhase.night;
    bool isNight = true;

    if (prayerTimes.isNotEmpty &&
        prayerTimes['fajr'] != null &&
        prayerTimes['sunrise'] != null &&
        prayerTimes['dhuhr'] != null &&
        prayerTimes['asr'] != null &&
        prayerTimes['maghrib'] != null &&
        prayerTimes['isha'] != null) {
      final h = now.hour * 60.0 + now.minute;
      final fajr = toMin(prayerTimes['fajr']!);
      final sunrise = toMin(prayerTimes['sunrise']!);
      final dhuhr = toMin(prayerTimes['dhuhr']!);
      final asr = toMin(prayerTimes['asr']!);
      final maghrib = toMin(prayerTimes['maghrib']!);
      final isha = toMin(prayerTimes['isha']!);

      if (h >= fajr && h < sunrise) {
        phase = ScenePhase.dawn;
      } else if (h >= sunrise && h < dhuhr) {
        phase = ScenePhase.morning;
      } else if (h >= dhuhr && h < asr) {
        phase = ScenePhase.noon;
      } else if (h >= asr && h < maghrib - 30) {
        phase = ScenePhase.afternoon;
      } else if (h >= maghrib - 30 && h < maghrib + 45) {
        phase = ScenePhase.sunset;
      } else if (h >= maghrib + 45 && h < isha + 90) {
        phase = ScenePhase.evening;
      } else if (h >= 0 && h < fajr - 90) {
        phase = ScenePhase.midnight;
      } else {
        phase = ScenePhase.night;
      }

      isNight = (h >= maghrib - 30 || h < fajr);
    }

    // Resolve Fasting Info
    final tomorrow = now.add(const Duration(days: 1));
    final jtTom = jalaliToday(tomorrow);
    final tomorrowFast = tomorrow.weekday == DateTime.thursday ||
        tomorrow.weekday == DateTime.monday ||
        jtTom.day == 13 ||
        jtTom.day == 14 ||
        jtTom.day == 15;

    final fasting = FastingInfo(
      isTomorrowFast: tomorrowFast,
      title: tomorrowFast ? 'فردا روزه سنت است!' : 'فردا روزه سنت نیست',
      subtitle: 'فردا: ${persianWeekdays[tomorrow.weekday] ?? "—"} ${monthNames[(jtTom.month - 1).clamp(0, 11)]} ${faDigits('${jtTom.day}')}',
      reminder: tomorrowFast ? 'امشب نیت کن 🌟' : null,
    );

    // Resolve Smart Zikr
    final rawZikr = getSmartZikr(data, now);
    final zikr = ZikrInfo(
      label: rawZikr['label'] as String? ?? 'ذکر',
      arabic: rawZikr['arabic'] as String? ?? '',
      note: rawZikr['note'] as String? ?? '',
      isActive: rawZikr['active'] as bool? ?? false,
    );

    // Resolve Sunan Bundle
    final sunan = resolveSunnahBundle(now, jt, prayerTimes);

    return PrayerSchedule(
      jalali: jt,
      hijri: hj,
      gregorian: now,
      weekdayName: weekdayName,
      monthName: monthName,
      kurdishDate: kurdishDate,
      ramadanCountdown: ramadanCountdown,
      fullDateLine: fullDateLine,
      nextPrayer: nextPrayer,
      activePrayerKey: activePrayerKey,
      phase: phase,
      isNight: isNight,
      fasting: fasting,
      zikr: zikr,
      sunan: sunan,
      prayerTimes: prayerTimes,
    );
  }
}
