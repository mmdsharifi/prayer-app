import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/prayer_schedule.dart' show jalaliToday, faDigits;
import '../../widgets/glass_card.dart';

class QuranJuzCard extends StatefulWidget {
  final dynamic data;
  final DateTime now;
  final bool isDark;

  const QuranJuzCard({
    super.key,
    required this.data,
    required this.now,
    this.isDark = true,
  });

  @override
  State<QuranJuzCard> createState() => _QuranJuzCardState();
}

class _QuranJuzCardState extends State<QuranJuzCard> {
  int _ayahIndex = 0;
  bool _isForward = true;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final jt = jalaliToday(widget.now);
    // Follows the day of the month (e.g. Day 5 -> Juz 5)
    final juzNum = ((jt.day - 1) % 30) + 1;

    Map<String, dynamic>? currentJuz;
    final dynamic quranJuzList = widget.data.quranJuz;
    if (quranJuzList is List && quranJuzList.isNotEmpty) {
      final idx = (juzNum - 1).clamp(0, quranJuzList.length - 1);
      currentJuz = Map<String, dynamic>.from(quranJuzList[idx]);
    }

    final theme = currentJuz?['theme'] ?? '';
    final verses = (currentJuz?['verses'] as List?) ?? [];

    final totalVerses = verses.length;
    final safeIdx = totalVerses > 0 ? (_ayahIndex % totalVerses) : 0;
    final currentAyah = totalVerses > 0 ? verses[safeIdx] : null;

    return LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with details and controls
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final headerInfo = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.book_fill,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'آیاتی از قرآن',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: isNarrow ? 12.5 : 14.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          theme.isNotEmpty
                              ? 'جزء ${faDigits('$juzNum')} • $theme'
                              : 'جزء ${faDigits('$juzNum')}',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: isNarrow ? 10.0 : 11.0,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final controls = totalVerses > 1
                  ? Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.40) : Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'آیه قبلی',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              CupertinoIcons.chevron_right,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                              size: 14,
                            ),
                            onPressed: () {
                              setState(() {
                                _isForward = false;
                                _ayahIndex = (_ayahIndex - 1 + totalVerses) % totalVerses;
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${faDigits('${safeIdx + 1}')}/${faDigits('$totalVerses')}',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'آیه بعدی',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              CupertinoIcons.chevron_left,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                              size: 14,
                            ),
                            onPressed: () {
                              setState(() {
                                _isForward = true;
                                _ayahIndex = (_ayahIndex + 1) % totalVerses;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink();

              if (isNarrow) {
                return Column(
                  children: [
                    headerInfo,
                    if (totalVerses > 1) ...[
                      const SizedBox(height: 6),
                      Align(alignment: Alignment.centerLeft, child: controls),
                    ],
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: headerInfo),
                    if (totalVerses > 1) ...[
                      const SizedBox(width: 8),
                      controls,
                    ],
                  ],
                );
              }
            },
          ),

          // Divider line
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),

          // 2. Animated Ayah Area (No box-in-a-box)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(_isForward ? 0.06 : -0.06, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey<int>(safeIdx),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic text
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        currentAyah?['ar'] ?? 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFFFBEB) : const Color(0xFF0F172A),
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          height: 1.95,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Divider line
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    height: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  ),

                  // Surah badge & Ayah title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentAyah?['surah'] ?? '',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (totalVerses > 1)
                        Text(
                          'آیه انتخابی کلیدی ${faDigits('${safeIdx + 1}')}',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Persian Translation
                  Text(
                    currentAyah?['fa'] ?? '',
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF334155),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.7,
                    ),
                  ),

                  // Tafsir Section with light line
                  if ((currentAyah?['tafsir'] ?? '').isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      height: 1,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                    ),
                    Row(children: [
                      Icon(
                        CupertinoIcons.sparkles,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'نکته و تفسیر آیه:',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      currentAyah!['tafsir'],
                      style: TextStyle(
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        fontSize: 11.5,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
