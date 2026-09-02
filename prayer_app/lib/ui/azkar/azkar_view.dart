import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import 'azkar_completion_dialog.dart';

/// Fullscreen or Modal View for Morning & Evening Adhkar
class AzkarView extends StatefulWidget {
  final PrayerData data;
  final AzkarController? controller;
  final String initialCategory; // 'morning' | 'evening'
  final bool initialStoryMode;
  final int? initialIndex;
  final bool isDark;

  const AzkarView({
    super.key,
    required this.data,
    this.controller,
    this.initialCategory = 'morning',
    this.initialStoryMode = false,
    this.initialIndex,
    this.isDark = true,
  });

  @override
  State<AzkarView> createState() => _AzkarViewState();
}

class _AzkarViewState extends State<AzkarView> {
  late AzkarController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _ownsController = false;
  bool _completionDialogShown = false;

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
        final targetIdx = widget.initialIndex ?? _controller.getResumeIndex(widget.initialCategory);
        if (widget.initialStoryMode) {
          _controller.setStoryMode(true, initialIndex: targetIdx);
        } else {
          _controller.setStoryIndex(targetIdx);
        }
      });
    } else {
      _controller = AzkarController(
        morningList: widget.data.fullMorningAzkar,
        eveningList: widget.data.fullEveningAzkar,
        defaultCategory: widget.initialCategory,
      );
      _ownsController = true;
      final targetIdx = widget.initialIndex ?? _controller.getResumeIndex(widget.initialCategory);
      if (widget.initialStoryMode) {
        _controller.setStoryMode(true, initialIndex: targetIdx);
      } else {
        _controller.setStoryIndex(targetIdx);
      }
    }

    _controller.addListener(_checkCategoryCompletion);
  }

  void _checkCategoryCompletion() {
    final counts = _controller.getProgressCounts();
    final isDone = counts.total > 0 && counts.completed >= counts.total;
    if (isDone && !_completionDialogShown) {
      _completionDialogShown = true;
      Future.delayed(const Duration(milliseconds: 380), () {
        if (!mounted) return;
        final isMorning = _controller.activeCategory == 'morning';
        AzkarCompletionDialog.show(
          context,
          categoryTitle: isMorning ? 'اذکار صبح' : 'اذکار شام',
          isDark: widget.isDark,
          onReturnToDashboard: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      });
    } else if (!isDone) {
      _completionDialogShown = false;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.removeListener(_checkCategoryCompletion);
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
        _controller.handleStoryAction(dhikr);
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

          final isMorning = _controller.activeCategory == 'morning';

          Widget titleAndProgress = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMorning ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_stars_fill,
                size: 15,
                color: isMorning
                    ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706))
                    : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
              ),
              const SizedBox(width: 5),
              Text(
                isMorning ? 'اذکار صبح' : 'اذکار شام',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Text(
                  '•',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.4,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0
                        ? const Color(0xFF10B981)
                        : (progress > 0
                            ? const Color(0xFF0284C7)
                            : (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706))),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${faDigits('${counts.completed}')}/${faDigits('${counts.total}')} خوانده‌شده',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          );

          Widget viewToggle = Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
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
                  tooltip: 'نمای فهرست',
                  isActive: !_controller.isStoryMode,
                  onTap: () => _controller.setStoryMode(false),
                  isDark: isDark,
                ),
                const SizedBox(width: 3),
                _buildModeBtn(
                  icon: CupertinoIcons.rectangle_fill_on_rectangle_fill,
                  tooltip: 'نمای استوری',
                  isActive: _controller.isStoryMode,
                  onTap: () => _controller.setStoryMode(true),
                  isDark: isDark,
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
                    titleAndProgress,
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
              titleAndProgress,
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

  Widget _buildModeBtn({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
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
            child: Icon(
              icon,
              size: 16,
              color: isActive
                  ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Story / Focus View ───────────────────────

String formatDhikrHeaderTitle(DhikrItem dhikr) {
  if (dhikr.title.contains('بار') || dhikr.title.contains('مرتبه')) {
    return dhikr.title;
  }
  final countStr = dhikr.count == 1 ? '۱ مرتبه' : '${faDigits('${dhikr.count}')} مرتبه';
  return '${dhikr.title} • $countStr';
}

class SmoothAnimatedCountText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const SmoothAnimatedCountText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.22),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Text(
        text,
        key: ValueKey<String>(text),
        style: style,
      ),
    );
  }
}

class _StoryCardInteractive extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _StoryCardInteractive({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<_StoryCardInteractive> createState() => _StoryCardInteractiveState();
}

class _StoryCardInteractiveState extends State<_StoryCardInteractive> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

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
      return const Center(child: Text('موردی برای نمایش وجود ندارد.'));
    }

    final currentIndex = controller.storyIndex;
    final dhikr = list[currentIndex];
    final currentCount = controller.getCount(dhikr.id);
    final isDone = controller.isDhikrCompleted(dhikr.id, dhikr.count);

    return Column(
      children: [
        // 1. Interactive Segmented Progress Bar (Top)
        _buildSegmentedBars(list, currentIndex, isDark),

        // 2. Focused Dhikr Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isPhone = screenWidth < 600;
              final isTablet = screenWidth >= 600 && screenWidth < 960;
              final isDesktop = screenWidth >= 960;

              // Responsive font size for Arabic Dhikr Box
              final double arabicFontSize = isDesktop
                  ? 27.0
                  : (isTablet ? 23.5 : 19.5);
              final double cardMaxWidth = isDesktop ? 920 : (isTablet ? 800 : 600);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPhone ? 16 : 32,
                        vertical: isPhone ? 16 : 24,
                      ),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: cardMaxWidth),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _StoryCardInteractive(
                            key: ValueKey<String>('story_${dhikr.id}'),
                            onTap: () => controller.handleStoryAction(dhikr),
                            child: Container(
                              width: double.infinity,
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top Header: Number in small box + Title + Repeat count
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isDone ? const Color(0xFF10B981) : const Color(0xFF0284C7))
                                              .withValues(alpha: isDark ? 0.20 : 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          faDigits('${currentIndex + 1}'),
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
                                      Expanded(
                                        child: Text(
                                          formatDhikrHeaderTitle(dhikr),
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

                                // Main Arabic Typography (Spacious, prominent)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isPhone ? 16 : 28,
                                    vertical: isPhone ? 28 : 42,
                                  ),
                                  child: SelectableText(
                                    dhikr.arabic,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFFFFFBEB) : const Color(0xFF0F172A),
                                      fontSize: arabicFontSize,
                                      fontWeight: FontWeight.w500,
                                      height: 2.25,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),

                                // Bottom Expand / Collapse Bar
                                if (dhikr.translationFa.isNotEmpty || dhikr.translationKu.isNotEmpty || dhikr.virtue.isNotEmpty || dhikr.source.isNotEmpty) ...[
                                  InkWell(
                                    onTap: () => controller.toggleDetails(),
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
                                        children: [
                                          Icon(
                                            controller.isDetailsExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                                            size: 12,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            controller.isDetailsExpanded ? 'مشاهده کمتر' : 'مشاهده بیشتر',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Smooth Animated Details Content
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeInOutCubic,
                                    alignment: Alignment.topCenter,
                                    child: controller.isDetailsExpanded
                                        ? Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.black.withValues(alpha: 0.25)
                                                  : const Color(0xFFF8FAFC),
                                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                            ),
                                            child: _buildUnifiedDetailsContent(dhikr, isDark, isPhone),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            },
          ),
        ),

        // 3. Fixed Bottom Control Bar (Previous, Counter, Next)
        _buildBottomControls(
          dhikr: dhikr,
          currentCount: currentCount,
          isDone: isDone,
          currentIndex: currentIndex,
          totalCount: list.length,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBottomControls({
    required DhikrItem dhikr,
    required int currentCount,
    required bool isDone,
    required int currentIndex,
    required int totalCount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF070D1A).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavBtn(
                  icon: CupertinoIcons.chevron_right,
                  tooltip: 'ذکر قبلی (کلید راست →)',
                  isEnabled: currentIndex > 0,
                  onTap: () => controller.prevStory(),
                  isDark: isDark,
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: _buildCounterButton(dhikr, currentCount, isDone, isDark),
                ),
                const SizedBox(width: 14),
                _buildNavBtn(
                  icon: CupertinoIcons.chevron_left,
                  tooltip: 'ذکر بعدی (کلید چپ ←)',
                  isEnabled: currentIndex < totalCount - 1,
                  onTap: () => controller.nextStory(),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBtn({
    required IconData icon,
    required String tooltip,
    required bool isEnabled,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: isEnabled ? 0.09 : 0.03)
                  : Colors.black.withValues(alpha: isEnabled ? 0.06 : 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: isEnabled ? 0.14 : 0.04)
                    : Colors.black.withValues(alpha: isEnabled ? 0.09 : 0.03),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: isEnabled
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white24 : Colors.black26),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedBars(List<DhikrItem> list, int currentIndex, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: List.generate(list.length, (idx) {
          final isPast = idx < currentIndex;
          final isCurrent = idx == currentIndex;
          final itemDone = controller.isDhikrCompleted(list[idx].id, list[idx].count);

          return _SegmentedBarItem(
            item: list[idx],
            index: idx,
            isCurrent: isCurrent,
            isPast: isPast,
            isDone: itemDone,
            isDark: isDark,
            onTap: () => controller.setStoryIndex(idx),
          );
        }),
      ),
    );
  }

  Widget _buildCounterButton(DhikrItem dhikr, int currentCount, bool isDone, bool isDark) {
    return _StoryCounterButton(
      dhikr: dhikr,
      currentCount: currentCount,
      isDone: isDone,
      isDark: isDark,
      onTap: () => controller.handleStoryAction(dhikr),
    );
  }

  Widget _buildUnifiedDetailsContent(DhikrItem dhikr, bool isDark, bool isPhone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Persian Translation
        if (dhikr.translationFa.isNotEmpty) ...[
          _buildDetailSection(
            title: 'ترجمه فارسی',
            content: dhikr.translationFa,
            icon: CupertinoIcons.text_quote,
            iconColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            textColor: isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF1E293B),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
        ],

        // Kurdish Translation
        if (dhikr.translationKu.isNotEmpty) ...[
          _buildDetailSection(
            title: 'مانای کوردی سۆرانی',
            content: dhikr.translationKu,
            icon: CupertinoIcons.globe,
            iconColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            textColor: isDark ? Colors.white.withValues(alpha: 0.88) : const Color(0xFF1E293B),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
        ],

        // Virtue
        if (dhikr.virtue.isNotEmpty) ...[
          _buildDetailSection(
            title: 'فضیلت و پاداش ذکر',
            content: dhikr.virtue,
            icon: CupertinoIcons.sparkles,
            iconColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            textColor: isDark ? Colors.white70 : const Color(0xFF334155),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
        ],

        // Hadith Source
        if (dhikr.source.isNotEmpty) ...[
          _buildDetailSection(
            title: 'منبع و تخریج حدیث',
            content: dhikr.source,
            icon: CupertinoIcons.bookmark,
            iconColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            isDark: isDark,
            isSmall: true,
          ),
        ],
      ],
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
    final titleGrey = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bodyText = isDark ? Colors.white.withValues(alpha: 0.90) : const Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: titleGrey, size: isSmall ? 12 : 13),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                color: titleGrey,
                fontSize: isSmall ? 11.5 : 12.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SelectableText(
          content,
          style: TextStyle(
            color: isSmall ? (isDark ? Colors.white60 : const Color(0xFF64748B)) : bodyText,
            fontSize: isSmall ? 12.0 : 14.5,
            fontWeight: isSmall ? FontWeight.w500 : FontWeight.w400,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

class _SegmentedBarItem extends StatefulWidget {
  final DhikrItem item;
  final int index;
  final bool isCurrent;
  final bool isPast;
  final bool isDone;
  final bool isDark;
  final VoidCallback onTap;

  const _SegmentedBarItem({
    required this.item,
    required this.index,
    required this.isCurrent,
    required this.isPast,
    required this.isDone,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SegmentedBarItem> createState() => _SegmentedBarItemState();
}

class _SegmentedBarItemState extends State<_SegmentedBarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color barColor;
    if (widget.isDone) {
      barColor = _isHovered ? const Color(0xFF34D399) : const Color(0xFF10B981);
    } else if (widget.isCurrent) {
      barColor = widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    } else if (widget.isPast) {
      barColor = _isHovered
          ? (widget.isDark ? Colors.white70 : Colors.black54)
          : (widget.isDark ? Colors.white38 : Colors.black26);
    } else {
      barColor = _isHovered
          ? (widget.isDark ? Colors.white38 : Colors.black38)
          : (widget.isDark ? Colors.white12 : Colors.black12);
    }

    final double height = widget.isCurrent ? 4.0 : 3.5;

    return Expanded(
      child: Tooltip(
        message: '${widget.item.title} (ذکر ${faDigits('${widget.index + 1}')})',
        waitDuration: const Duration(milliseconds: 250),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                height: height,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: widget.isCurrent
                      ? [
                          BoxShadow(
                            color: barColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryCounterButton extends StatefulWidget {
  final DhikrItem dhikr;
  final int currentCount;
  final bool isDone;
  final bool isDark;
  final VoidCallback onTap;

  const _StoryCounterButton({
    required this.dhikr,
    required this.currentCount,
    required this.isDone,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_StoryCounterButton> createState() => _StoryCounterButtonState();
}

class _StoryCounterButtonState extends State<_StoryCounterButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.965 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.isDone
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    )
                  : LinearGradient(
                      colors: widget.isDark
                          ? [const Color(0xFF0284C7), const Color(0xFF0369A1)]
                          : [const Color(0xFF0284C7), const Color(0xFF0EA5E9)],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.isDone
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
                  widget.isDone ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.hand_draw_fill,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: SmoothAnimatedCountText(
                    text: widget.isDone
                        ? 'تکمیل شد (${faDigits('${widget.currentCount}')} / ${faDigits('${widget.dhikr.count}')})'
                        : 'تسبیح و شمارش: ${faDigits('${widget.currentCount}')} از ${faDigits('${widget.dhikr.count}')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
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
        ),
      ),
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
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final dhikr = widget.dhikr;
    final count = widget.controller.getCount(dhikr.id);
    final isDone = widget.controller.isDhikrCompleted(dhikr.id, dhikr.count);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => widget.controller.incrementCount(dhikr),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
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
                              Expanded(
                                child: Text(
                                  formatDhikrHeaderTitle(dhikr),
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
                        const SizedBox(width: 8),

                        // Interactive Tap Counter Pill with Smooth Animated Counter Number
                        Container(
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
                              SmoothAnimatedCountText(
                                text: '${faDigits('$count')}/${faDigits('${dhikr.count}')}',
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
                      ],
                    ),
                  ),

                  // Prominent Arabic Text (Always shown)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SelectableText(
                      dhikr.arabic,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFFFBEB) : const Color(0xFF0F172A),
                        fontSize: 17.5,
                        fontWeight: FontWeight.w500,
                        height: 2.1,
                        letterSpacing: 0.1,
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
                        children: [
                          Icon(
                            _isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                            size: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isExpanded ? 'مشاهده کمتر' : 'مشاهده بیشتر',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

            // Smooth Animated Expanded Details Section
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? Container(
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
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  ),
),
);
  }
}
