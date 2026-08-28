import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';

/// Fullscreen or Modal View for Morning & Evening Adhkar
class AzkarView extends StatefulWidget {
  final PrayerData data;
  final AzkarController? controller;
  final String initialCategory; // 'morning' | 'evening'
  final bool initialStoryMode;
  final int initialIndex;
  final bool isDark;

  const AzkarView({
    super.key,
    required this.data,
    this.controller,
    this.initialCategory = 'morning',
    this.initialStoryMode = false,
    this.initialIndex = 0,
    this.isDark = true,
  });

  @override
  State<AzkarView> createState() => _AzkarViewState();
}

class _AzkarViewState extends State<AzkarView> {
  late AzkarController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_controller.activeCategory != widget.initialCategory) {
          _controller.setCategory(widget.initialCategory);
        }
        if (widget.initialStoryMode) {
          _controller.setStoryMode(true, initialIndex: widget.initialIndex);
        }
      });
    } else {
      _controller = AzkarController(
        morningList: widget.data.fullMorningAzkar,
        eveningList: widget.data.fullEveningAzkar,
        defaultCategory: widget.initialCategory,
      );
      _ownsController = true;
      if (widget.initialStoryMode) {
        _controller.setStoryMode(true, initialIndex: widget.initialIndex);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      final dhikr = _controller.currentStoryDhikr;
      if (dhikr != null && _controller.isStoryMode) {
        _controller.incrementCount(dhikr);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_controller.isStoryMode) {
        _controller.nextStory();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_controller.isStoryMode) {
        _controller.prevStory();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_controller.isStoryMode) {
        _controller.setStoryMode(false);
      } else {
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: isDark ? const Color(0xFF070D1A) : const Color(0xFFF1F5F9),
              body: Stack(
                children: [
                  // Subtle ambient background gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.2,
                          colors: isDark
                              ? [
                                  const Color(0xFF0F172A),
                                  const Color(0xFF070D1A),
                                ]
                              : [
                                  const Color(0xFFE2E8F0),
                                  const Color(0xFFF8FAFC),
                                ],
                        ),
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Column(
                      children: [
                        // Top Header Bar
                        _buildHeader(isDark),

                        // Main Content Area (Story Mode or List Mode)
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: _controller.isStoryMode
                                ? AzkarStoryView(
                                    key: const ValueKey('StoryView'),
                                    controller: _controller,
                                    isDark: isDark,
                                  )
                                : AzkarListView(
                                    key: const ValueKey('ListView'),
                                    controller: _controller,
                                    isDark: isDark,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final progress = _controller.getProgress();
    final counts = _controller.getProgressCounts();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.90),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 780;

          Widget categoryTabs = Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFCBD5E1),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCategoryTab(
                  label: 'اذکار صبح ☀️',
                  isSelected: _controller.activeCategory == 'morning',
                  onTap: () => _controller.setCategory('morning'),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildCategoryTab(
                  label: 'اذکار شام 🌙',
                  isSelected: _controller.activeCategory == 'evening',
                  onTap: () => _controller.setCategory('evening'),
                  isDark: isDark,
                ),
              ],
            ),
          );

          Widget viewToggle = Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFCBD5E1),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeBtn(
                  icon: CupertinoIcons.rectangle_grid_1x2_fill,
                  label: 'فهرست',
                  isActive: !_controller.isStoryMode,
                  onTap: () => _controller.setStoryMode(false),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _buildModeBtn(
                  icon: CupertinoIcons.play_rectangle_fill,
                  label: 'استوری',
                  isActive: _controller.isStoryMode,
                  onTap: () => _controller.setStoryMode(true),
                  isDark: isDark,
                ),
              ],
            ),
          );

          Widget progressPill = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2.2,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${faDigits('${counts.completed}')}/${faDigits('${counts.total}')} خوانده‌شده',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );

          Widget closeBtn = IconButton(
            tooltip: 'بستن (Esc)',
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              size: 24,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          );

          if (isNarrow) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    categoryTabs,
                    Row(
                      children: [
                        viewToggle,
                        const SizedBox(width: 4),
                        closeBtn,
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    progressPill,
                    TextButton.icon(
                      onPressed: () => _controller.resetCategory(_controller.activeCategory),
                      icon: Icon(
                        CupertinoIcons.arrow_counterclockwise,
                        size: 13,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      label: Text(
                        'ریست این بخش',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  categoryTabs,
                  const SizedBox(width: 12),
                  progressPill,
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  viewToggle,
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'شروع مجدد این بخش',
                    icon: Icon(
                      CupertinoIcons.arrow_counterclockwise,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      size: 18,
                    ),
                    onPressed: () => _controller.resetCategory(_controller.activeCategory),
                  ),
                  const SizedBox(width: 4),
                  closeBtn,
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.98,
      duration: const Duration(milliseconds: 160),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF0284C7) : const Color(0xFF0284C7))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Story / Focus View ───────────────────────

class AzkarStoryView extends StatelessWidget {
  final AzkarController controller;
  final bool isDark;

  const AzkarStoryView({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final list = controller.currentList;
    if (list.isEmpty) {
      return Center(
        child: Text(
          'ذکری برای این بخش یافت نشد.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
      );
    }

    final currentIndex = controller.storyIndex;
    final dhikr = list[currentIndex];
    final currentCount = controller.getCount(dhikr.id);
    final isDone = controller.isDhikrCompleted(dhikr.id, dhikr.count);

    return Column(
      children: [
        // 1. Instagram-style Segmented Story Bars
        _buildSegmentedBars(list, currentIndex, isDark),

        // 2. Focused Dhikr Area with Left/Right tap zones
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              return Stack(
                children: [
                  // Center Card Content
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 780),
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 16 : 32,
                        vertical: 12,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Order / Title badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF0284C7) : const Color(0xFF0284C7))
                                    .withValues(alpha: isDark ? 0.20 : 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                                      : const Color(0xFF0284C7).withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '${dhikr.title} • ذکر ${faDigits('${currentIndex + 1}')} از ${faDigits('${list.length}')}',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Main Arabic Typography (Always clearly displayed)
                            AnimatedScale(
                              scale: isDone ? 1.0 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDone
                                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.10)
                                            : const Color(0xFFCBD5E1)),
                                    width: isDone ? 1.4 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDone
                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                          : (isDark
                                              ? Colors.black.withValues(alpha: 0.3)
                                              : const Color(0xFF0F172A).withValues(alpha: 0.05)),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SelectableText(
                                      dhikr.arabic,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFFFFFBEB) : const Color(0xFF0F172A),
                                        fontSize: isNarrow ? 17.5 : 20.0,
                                        fontWeight: FontWeight.w700,
                                        height: 2.1,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Interactive Repetition Counter Button (Large & Tactile)
                            _buildCounterButton(dhikr, currentCount, isDone, isDark),
                            const SizedBox(height: 16),

                            // Expand / Collapse Details Button ("مشاهده بیشتر / ترجمه و فضیلت")
                            _buildExpandDetailsButton(isDark),

                            // Expanded Details Container (Farsi, Kurdish, Virtue, Source in smaller refined typography)
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 260),
                              sizeCurve: Curves.easeOutCubic,
                              firstCurve: Curves.easeOutCubic,
                              secondCurve: Curves.easeInCubic,
                              crossFadeState: controller.isDetailsExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: const SizedBox.shrink(),
                              secondChild: _buildDetailsCard(dhikr, isDark),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Left & Right Floating Navigation Chevrons
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        tooltip: 'ذکر بعدی (کلید چپ ←)',
                        padding: const EdgeInsets.all(12),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.8),
                          shape: const CircleBorder(),
                        ),
                        icon: Icon(
                          CupertinoIcons.chevron_left,
                          color: currentIndex < list.length - 1
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? Colors.white24 : Colors.black12),
                          size: 22,
                        ),
                        onPressed: currentIndex < list.length - 1
                            ? () => controller.nextStory()
                            : null,
                      ),
                    ),
                  ),

                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        tooltip: 'ذکر قبلی (کلید راست →)',
                        padding: const EdgeInsets.all(12),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.8),
                          shape: const CircleBorder(),
                        ),
                        icon: Icon(
                          CupertinoIcons.chevron_right,
                          color: currentIndex > 0
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? Colors.white24 : Colors.black12),
                          size: 22,
                        ),
                        onPressed: currentIndex > 0
                            ? () => controller.prevStory()
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedBars(List<DhikrItem> list, int currentIndex, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(list.length, (idx) {
          final isPast = idx < currentIndex;
          final isCurrent = idx == currentIndex;
          final itemDone = controller.isDhikrCompleted(list[idx].id, list[idx].count);

          Color barColor;
          if (itemDone) {
            barColor = const Color(0xFF10B981);
          } else if (isCurrent) {
            barColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
          } else if (isPast) {
            barColor = isDark ? Colors.white38 : Colors.black26;
          } else {
            barColor = isDark ? Colors.white12 : Colors.black12;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => controller.setStoryIndex(idx),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                height: isCurrent ? 4.5 : 3.5,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: barColor.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCounterButton(DhikrItem dhikr, int currentCount, bool isDone, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            final newlyCompleted = controller.incrementCount(dhikr);
            if (newlyCompleted && controller.storyIndex < controller.currentList.length - 1) {
              // Smooth small delay before offering or advancing
              Future.delayed(const Duration(milliseconds: 380), () {
                if (controller.isStoryMode && controller.isDhikrCompleted(dhikr.id, dhikr.count)) {
                  controller.nextStory();
                }
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: isDone
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    )
                  : LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0284C7), const Color(0xFF0369A1)]
                          : [const Color(0xFF0284C7), const Color(0xFF0EA5E9)],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDone
                      ? const Color(0xFF10B981).withValues(alpha: 0.35)
                      : const Color(0xFF0284C7).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDone ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.hand_draw_fill,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  isDone
                      ? 'تکمیل شد (${faDigits('$currentCount')} / ${faDigits('${dhikr.count}')})'
                      : 'تسبیح و شمارش: ${faDigits('$currentCount')} از ${faDigits('${dhikr.count}')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Space ␣',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandDetailsButton(bool isDark) {
    final expanded = controller.isDetailsExpanded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.toggleDetails(),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                size: 14,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
              const SizedBox(width: 6),
              Text(
                expanded ? 'بستن جزئیات' : 'مشاهده ترجمه فارسی، کوردی، فضیلت و منبع',
                style: TextStyle(
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(DhikrItem dhikr, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.9)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Persian Translation
          _buildDetailSection(
            title: 'ترجمه فارسی',
            content: dhikr.translationFa,
            icon: CupertinoIcons.chat_bubble_text_fill,
            iconColor: const Color(0xFF38BDF8),
            textColor: isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF1E293B),
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Kurdish Translation
          _buildDetailSection(
            title: 'مانای کوردی سۆرانی',
            content: dhikr.translationKu,
            icon: CupertinoIcons.globe,
            iconColor: const Color(0xFFF59E0B),
            textColor: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Virtue
          if (dhikr.virtue.isNotEmpty) ...[
            _buildDetailSection(
              title: 'فضیلت و پاداش ذکر',
              content: dhikr.virtue,
              icon: CupertinoIcons.sparkles,
              iconColor: const Color(0xFF10B981),
              textColor: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
              isDark: isDark,
            ),
            const SizedBox(height: 14),
          ],

          // Hadith Source
          if (dhikr.source.isNotEmpty) ...[
            _buildDetailSection(
              title: 'منبع و تخریج حدیث',
              content: dhikr.source,
              icon: CupertinoIcons.bookmark_fill,
              iconColor: const Color(0xFF818CF8),
              textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              isDark: isDark,
              isSmall: true,
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildDetailSection({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required bool isDark,
    bool isSmall = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 12),
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: iconColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SelectableText(
          content,
          style: TextStyle(
            color: textColor,
            fontSize: isSmall ? 11.0 : 12.5,
            fontWeight: isSmall ? FontWeight.w500 : FontWeight.w600,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── Accordion List View ───────────────────────

class AzkarListView extends StatelessWidget {
  final AzkarController controller;
  final bool isDark;

  const AzkarListView({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final list = controller.currentList;
    if (list.isEmpty) {
      return Center(
        child: Text(
          'موردی برای نمایش یافت نشد.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24 : 16,
                vertical: 12,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final dhikr = list[index];
                return _AzkarListItemCard(
                  key: ValueKey(dhikr.id),
                  dhikr: dhikr,
                  index: index,
                  controller: controller,
                  isDark: isDark,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _AzkarListItemCard extends StatefulWidget {
  final DhikrItem dhikr;
  final int index;
  final AzkarController controller;
  final bool isDark;

  const _AzkarListItemCard({
    super.key,
    required this.dhikr,
    required this.index,
    required this.controller,
    required this.isDark,
  });

  @override
  State<_AzkarListItemCard> createState() => _AzkarListItemCardState();
}

class _AzkarListItemCardState extends State<_AzkarListItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dhikr = widget.dhikr;
    final isDark = widget.isDark;
    final count = widget.controller.getCount(dhikr.id);
    final isDone = widget.controller.isDhikrCompleted(dhikr.id, dhikr.count);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
          width: isDone ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // Top Item Header: Title, Order & Interactive Counter
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title & Order badge
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isDone ? const Color(0xFF10B981) : const Color(0xFF0284C7))
                                .withValues(alpha: isDark ? 0.20 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            faDigits('${widget.index + 1}'),
                            style: TextStyle(
                              color: isDone
                                  ? const Color(0xFF10B981)
                                  : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            dhikr.title,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13.0,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions: Focus Mode Button + Counter Pill
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Story/Focus Launcher for this specific dhikr
                      IconButton(
                        tooltip: 'مشاهده در حالت استوری',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          size: 19,
                        ),
                        onPressed: () {
                          widget.controller.setStoryMode(true, initialIndex: widget.index);
                        },
                      ),
                      const SizedBox(width: 6),

                      // Interactive Tap Counter Pill
                      GestureDetector(
                        onTap: () => widget.controller.incrementCount(dhikr),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.15)
                                : const Color(0xFF0284C7).withValues(alpha: isDark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDone
                                    ? CupertinoIcons.check_mark_circled_solid
                                    : CupertinoIcons.hand_draw_fill,
                                size: 13,
                                color: isDone
                                    ? const Color(0xFF10B981)
                                    : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${faDigits('$count')}/${faDigits('${dhikr.count}')}',
                                style: TextStyle(
                                  color: isDone
                                      ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                                      : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Prominent Arabic Text (Always shown)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SelectableText(
                dhikr.arabic,
                style: TextStyle(
                  color: isDark ? const Color(0xFFFFFBEB) : const Color(0xFF0F172A),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  height: 1.9,
                ),
              ),
            ),

            // Divider and Expand/Collapse Bar
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                          size: 12,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isExpanded ? 'بستن ترجمه و فضیلت' : 'مشاهده ترجمه، کوردی، فضیلت و منبع',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                            fontSize: 11.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (isDone)
                      const Row(
                        children: [
                          Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF10B981), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'خوانده شد',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Expanded Details Section
            if (_isExpanded)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AzkarStoryView._buildDetailSection(
                      title: 'ترجمه فارسی',
                      content: dhikr.translationFa,
                      icon: CupertinoIcons.chat_bubble_text_fill,
                      iconColor: const Color(0xFF38BDF8),
                      textColor: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    AzkarStoryView._buildDetailSection(
                      title: 'مانای کوردی سۆرانی',
                      content: dhikr.translationKu,
                      icon: CupertinoIcons.globe,
                      iconColor: const Color(0xFFF59E0B),
                      textColor: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      isDark: isDark,
                    ),
                    if (dhikr.virtue.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      AzkarStoryView._buildDetailSection(
                        title: 'فضیلت و پاداش',
                        content: dhikr.virtue,
                        icon: CupertinoIcons.sparkles,
                        iconColor: const Color(0xFF10B981),
                        textColor: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                        isDark: isDark,
                      ),
                    ],
                    if (dhikr.source.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      AzkarStoryView._buildDetailSection(
                        title: 'منبع حدیث',
                        content: dhikr.source,
                        icon: CupertinoIcons.bookmark_fill,
                        iconColor: const Color(0xFF818CF8),
                        textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        isDark: isDark,
                        isSmall: true,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
