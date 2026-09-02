import 'package:flutter/material.dart';
import '../../../core/prayer_schedule.dart';
import '../../widgets/glass_card.dart';
import 'live_clock_widget.dart';

/// Rich Today Card with Big Solar Persian Date, Live Clock, and 4 Clean Columns
class TodayCard extends StatelessWidget {
  final PrayerSchedule schedule;
  final DateTime now;
  final bool isDark;

  const TodayCard({
    super.key,
    required this.schedule,
    required this.now,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final jt = schedule.jalali;
    final hj = schedule.hijri;
    final ramadanCountdown = schedule.ramadanCountdown;
    final kurdishMonth = kurdishMonthNames[(jt.month - 1).clamp(0, 11)];
    final kurdishYear = jt.year + 1321;
    final hijriMonth = hijriMonthNames[(hj.month - 1).clamp(0, 11)];
    final gregMonth = gregorianMonthNamesEn[(now.month - 1).clamp(0, 11)];

    final cardSubtitle = 'امروز، ${schedule.weekdayName} ${faDigits('${jt.day}')} ${schedule.monthName}';

    String ramadanRemaining;
    if (ramadanCountdown.months > 0 && ramadanCountdown.days > 0) {
      ramadanRemaining = '${faDigits('${ramadanCountdown.months}')} ماه و ${faDigits('${ramadanCountdown.days}')} روز';
    } else if (ramadanCountdown.months > 0) {
      ramadanRemaining = '${faDigits('${ramadanCountdown.months}')} ماه';
    } else if (ramadanCountdown.days > 0) {
      ramadanRemaining = '${faDigits('${ramadanCountdown.days}')} روز';
    } else {
      ramadanRemaining = 'ماه مبارک';
    }

    // 4 Columns in order: 1. شمسی, 2. کوردی, 3. قمری + رمضان, 4. میلادی
    Widget solarCol = _buildDateColumn(
      line1: '${schedule.weekdayName} ${faDigits('${jt.day}')} ${schedule.monthName}',
      line2: faDigits('${jt.year}'),
      isDark: isDark,
    );

    Widget kurdishCol = _buildDateColumn(
      line1: '${faDigits('${jt.day}')}ی $kurdishMonth',
      line2: faDigits('$kurdishYear'),
      isDark: isDark,
    );

    Widget hijriRamadanCol = _buildCombinedHijriRamadanColumn(
      hijriLine1: '${faDigits('${hj.day}')} $hijriMonth',
      hijriLine2: faDigits('${hj.year}'),
      ramadanText: ramadanRemaining,
      isDark: isDark,
    );

    Widget gregCol = _buildDateColumn(
      line1: '${now.day} $gregMonth',
      line2: '${now.year}',
      isDark: isDark,
    );

    return LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Greeting + Subtitle on the right, Live Digital Clock on the left
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'سلام علیکم و رحمه الله',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cardSubtitle,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Live Clock
              LiveClockWidget(
                fixedTime: now,
                isDark: isDark,
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
          // 4 Clean Column Items without individual inner capsule boxes
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 520;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: solarCol),
                    Expanded(child: kurdishCol),
                    Expanded(flex: 2, child: hijriRamadanCol),
                    Expanded(child: gregCol),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: solarCol),
                        Expanded(child: kurdishCol),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      height: 1,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                    ),
                    Row(
                      children: [
                        Expanded(flex: 2, child: hijriRamadanCol),
                        Expanded(child: gregCol),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateColumn({
    required String line1,
    required String line2,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          line1,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2.5),
        Text(
          line2,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCombinedHijriRamadanColumn({
    required String hijriLine1,
    required String hijriLine2,
    required String ramadanText,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hijri Date column
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                hijriLine1,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2.5),
              Text(
                hijriLine2,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Subtle vertical divider line
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 0.8,
          height: 24,
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
        ),
        // Ramadan countdown column
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                ramadanText,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2.5),
              Text(
                'تا رمضان',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
