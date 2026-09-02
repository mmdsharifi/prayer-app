import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/azkar_controller.dart';
import '../../../core/prayer_schedule.dart' show faDigits;
import '../../widgets/glass_card.dart';
import '../../azkar/azkar_view.dart';

class AzkarDashboardCard extends StatefulWidget {
  final dynamic data;
  final AzkarController? controller;
  final Map<String, dynamic>? prayerTimes;
  final DateTime? now;
  final bool isDark;

  const AzkarDashboardCard({
    super.key,
    required this.data,
    this.controller,
    this.prayerTimes,
    this.now,
    this.isDark = true,
  });

  @override
  State<AzkarDashboardCard> createState() => _AzkarDashboardCardState();
}

class _AzkarDashboardCardState extends State<AzkarDashboardCard> {
  String _selectedTab = 'morning';
  late AzkarController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = AzkarController(
      morningList: widget.data.fullMorningAzkar,
      eveningList: widget.data.fullEveningAzkar,
      defaultCategory: _selectedTab,
    );
  }

  AzkarController get controller => widget.controller ?? _internalController;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final now = widget.now ?? DateTime.now();
    final prayerTimes = widget.prayerTimes ?? widget.data.times;

    final info = controller.getProgressInfo(
      category: _selectedTab,
      now: now,
      prayerTimes: prayerTimes,
    );

    void openFullAzkar({bool storyMode = false, int initialIndex = 0}) async {
      await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => AzkarView(
            data: widget.data,
            initialCategory: _selectedTab,
            initialStoryMode: storyMode,
            initialIndex: initialIndex,
            isDark: isDark,
          ),
        ),
      );
      if (mounted) {
        setState(() {});
      }
    }

    return LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Category Switchers
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;

              final titleWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B)
                          .withValues(alpha: isDark ? 0.20 : 0.14),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      CupertinoIcons.sparkles,
                      color: Color(0xFFF59E0B),
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'اذکار جامع صبح و شام',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              );

              final tabsWidget = Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFCBD5E1),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabBtn(
                      label: 'اذکار صبح ☀️',
                      isSelected: _selectedTab == 'morning',
                      onTap: () => setState(() => _selectedTab = 'morning'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 3),
                    _buildTabBtn(
                      label: 'اذکار شام 🌙',
                      isSelected: _selectedTab == 'evening',
                      onTap: () => setState(() => _selectedTab = 'evening'),
                      isDark: isDark,
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 8),
                    tabsWidget,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleWidget,
                  tabsWidget,
                ],
              );
            },
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),

          // Middle Section: Circular Progress Ring + Dynamic Status Message
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Progress Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: info.percentage,
                        strokeWidth: 5.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.black.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          info.isCompleted
                              ? const Color(0xFF10B981)
                              : (info.percentage > 0
                                  ? const Color(0xFF0284C7)
                                  : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (info.isCompleted)
                          const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF10B981), size: 22)
                        else
                          Text(
                            '${faDigits('${(info.percentage * 100).round()}')}٪',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 12.0,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Status Message and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (info.isCompleted)
                            const Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Icon(CupertinoIcons.star_fill, color: Color(0xFFF59E0B), size: 14),
                            )
                          else if (info.percentage > 0)
                            const Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Icon(CupertinoIcons.sparkles, color: Color(0xFF0284C7), size: 14),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Icon(
                                CupertinoIcons.clock,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                size: 13,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              info.statusTitle,
                              style: TextStyle(
                                color: info.isCompleted
                                    ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                fontSize: 13.0,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.statusSubtitle,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 11.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),

          // Action Buttons: Launch Story Mode / View Full List
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              Widget buildStoryBtn() => Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => openFullAzkar(storyMode: true),
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.play_rectangle_fill, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'قرائت استوری و تسبیح',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

              Widget buildListBtn() => Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFCBD5E1),
                        width: 0.8,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => openFullAzkar(storyMode: false),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.list_bullet,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'مشاهده فهرست کامل',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

              if (isNarrow) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: buildStoryBtn()),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: buildListBtn()),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: buildStoryBtn()),
                  const SizedBox(width: 10),
                  Expanded(child: buildListBtn()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0284C7) : const Color(0xFF0284C7))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              fontSize: 11.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
