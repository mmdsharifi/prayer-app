import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/prayer_schedule.dart' show jalaliToday;
import '../../widgets/glass_card.dart';

class HadithCard extends StatelessWidget {
  final dynamic data;
  final DateTime now;
  final bool isDark;

  const HadithCard({
    super.key,
    required this.data,
    required this.now,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final dynamic hadithsList = data.hadiths;
    if (hadithsList is! List || hadithsList.isEmpty) {
      return const SizedBox.shrink();
    }
    final jt = jalaliToday(now);
    final h = hadithsList[jt.day % hadithsList.length];
    return LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CardTitle(
          'حدیث روز',
          icon: CupertinoIcons.quote_bubble_fill,
          iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          isDark: isDark,
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 1,
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        Text(
          'پیامبر (ص) می‌فرمایند:',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Text(
              h['ar'] ?? '',
              style: TextStyle(
                color: isDark ? const Color(0xFFFFFBEB) : const Color(0xFF0F172A),
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                height: 1.9,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 1,
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        Text(
          h['fa'] ?? '',
          style: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF334155),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.7,
          ),
        ),
        if ((h['ku'] ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            h['ku'] ?? '',
            style: TextStyle(
              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              height: 1.7,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'صحیح مسلم — اربعین النووی',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]),
    );
  }
}
