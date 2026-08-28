part of 'main.dart';

// ignore_for_file: unused_element

// ─────────────────────── Shared Helpers & SF Symbols ───────────────────────

String faDigits(String s) =>
    s.replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);

class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool isDark;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.isDark = true,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(18);
    final isDark = widget.isDark;

    return AnimatedScale(
      scale: (_isPressed && widget.onTap != null) ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: widget.onTap != null
                  ? (val) => setState(() => _isPressed = val)
                  : null,
              borderRadius: br,
              splashColor: isDark
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                  : const Color(0xFF0284C7).withValues(alpha: 0.08),
              highlightColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              child: Container(
                width: double.infinity,
                padding: widget.padding,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.45, 1.0],
                          colors: [
                            const Color(0xFF1E293B).withValues(alpha: 0.62), // Translucent Slate-Navy Glass Sheen
                            const Color(0xFF0F172A).withValues(alpha: 0.70), // Midnight Blue Glass Body
                            const Color(0xFF070D1A).withValues(alpha: 0.78), // Deep Obsidian Blue Base
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.50, 1.0],
                          colors: [
                            const Color(0xFFFFFFFF).withValues(alpha: 0.88), // Pure Crisp White Glass Sheen
                            const Color(0xFFF8FAFC).withValues(alpha: 0.80), // Airy Light Frosted Body
                            const Color(0xFFEFF6FF).withValues(alpha: 0.74), // Subtle Morning Sky Tint Base
                          ],
                        ),
                  borderRadius: br,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF7DD3FC).withValues(alpha: 0.28) // Refractive Ice-Blue Glass Rim
                        : const Color(0xFFFFFFFF).withValues(alpha: 0.95), // Specular White Glass Rim
                    width: isDark ? 0.9 : 1.2,
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.38),
                            blurRadius: 26,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            blurRadius: 18,
                            spreadRadius: -2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.10),
                            blurRadius: 16,
                            spreadRadius: -2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Backward-compatible alias
class GlassCard extends LiquidGlassCard {
  const GlassCard({
    super.key,
    required super.child,
    super.padding,
    super.isDark,
    super.onTap,
  });
}

class _RefreshButton extends StatefulWidget {
  final bool isRefreshing;
  final VoidCallback? onPressed;
  final bool isDark;
  const _RefreshButton({
    required this.isRefreshing,
    this.onPressed,
    this.isDark = true,
  });

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    if (widget.isRefreshing) _controller.repeat();
  }

  @override
  void didUpdateWidget(_RefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing != oldWidget.isRefreshing) {
      if (widget.isRefreshing) {
        _controller.repeat();
      } else {
        _controller.animateTo(
          1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        ).then((_) {
          if (mounted) _controller.reset();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'به‌روزرسانی (Refresh • ⌘R)',
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      icon: RotationTransition(
        turns: _controller,
        child: Icon(
          CupertinoIcons.arrow_2_circlepath,
          color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
          size: 15,
        ),
      ),
      onPressed: widget.isRefreshing ? null : widget.onPressed,
    );
  }
}

class _StaggerItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggerItem({required this.index, required this.child});

  @override
  State<_StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<_StaggerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.index == 0) {
      _ctrl.forward();
    } else {
      _timer = Timer(Duration(milliseconds: 35 * widget.index), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class CardTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final bool isDark;

  const CardTitle(
    this.title, {
    super.key,
    required this.icon,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: (iconColor ?? const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                    size: 14.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      );
}

// ─────────────────────── Dashboard & Calendar View ───────────────────────

class Dashboard extends StatefulWidget {
  final PrayerData data;
  final DateTime now;
  final VoidCallback? onRefresh;
  final AppThemeMode? initialThemeMode;
  final ValueChanged<AppThemeMode>? onThemeChanged;

  const Dashboard({
    super.key,
    required this.data,
    required this.now,
    this.onRefresh,
    this.initialThemeMode,
    this.onThemeChanged,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? weather;
  String weatherError = '';
  bool _isLoadingWeather = false;
  bool _isRefreshing = false;
  late AppThemeMode _themeMode;

  late AzkarController _azkarController;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode ?? AppThemeMode.system;
    _azkarController = AzkarController(
      morningList: widget.data.fullMorningAzkar,
      eveningList: widget.data.fullEveningAzkar,
    );
    _azkarController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadWeather();
  }

  @override
  void dispose() {
    _azkarController.dispose();
    super.dispose();
  }

  bool _resolveIsDark(BuildContext context, bool isSolarNight) {
    switch (_themeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        final pb = MediaQuery.maybeOf(context)?.platformBrightness;
        if (pb != null) {
          return pb == Brightness.dark;
        }
        return isSolarNight;
    }
  }

  void _setThemeMode(AppThemeMode mode) {
    setState(() => _themeMode = mode);
    widget.onThemeChanged?.call(mode);
  }

  final IslamicDataRepository _repository = HttpIslamicDataRepository();

  Future<void> _loadWeather() async {
    setState(() {
      _isLoadingWeather = true;
      weatherError = '';
    });
    try {
      final w = await _repository.fetchWeather();
      if (mounted) {
        setState(() {
          if (w != null) {
            weather = w;
            weatherError = '';
          } else {
            weatherError = 'عدم اتصال به اینترنت';
          }
          _isLoadingWeather = false;
        });
        final schedule = PrayerSchedule.resolve(data: widget.data, now: widget.now);
        String? hadith;
        if (widget.data.hadiths.isNotEmpty) {
          hadith = widget.data.hadiths[schedule.jalali.day % widget.data.hadiths.length]['fa'] as String?;
        }
        DesktopIntegration.sync(schedule: schedule, hadith: hadith);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          weatherError = 'عدم اتصال به اینترنت';
          _isLoadingWeather = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    setState(() => _isRefreshing = true);
    await _loadWeather();
    widget.onRefresh?.call();
    final schedule = PrayerSchedule.resolve(data: widget.data, now: DateTime.now());
    String? hadith;
    if (widget.data.hadiths.isNotEmpty) {
      hadith = widget.data.hadiths[schedule.jalali.day % widget.data.hadiths.length]['fa'] as String?;
    }
    await DesktopIntegration.sync(schedule: schedule, hadith: hadith);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  IconData weatherSfIcon(int code) {
    if (code == 0) return CupertinoIcons.sun_max_fill;
    if (code <= 3) return CupertinoIcons.cloud_sun_fill;
    if (code <= 48) return CupertinoIcons.cloud_fog_fill;
    if (code <= 57) return CupertinoIcons.cloud_drizzle_fill;
    if (code <= 67) return CupertinoIcons.cloud_rain_fill;
    if (code <= 77) return CupertinoIcons.snow;
    if (code <= 82) return CupertinoIcons.cloud_heavyrain_fill;
    if (code <= 86) return CupertinoIcons.snow;
    return CupertinoIcons.cloud_bolt_rain_fill;
  }

  String weatherDesc(int code) {
    if (code == 0) return 'صاف و آفتابی';
    if (code <= 3) return 'نیمه‌ابری';
    if (code <= 48) return 'مه‌آلود';
    if (code <= 57) return 'باران ملایم';
    if (code <= 67) return 'بارانی';
    if (code <= 77) return 'برف خفیف';
    if (code <= 82) return 'رگبار باران';
    if (code <= 86) return 'بارش برف';
    return 'رعد و برق';
  }

  @override
  Widget build(BuildContext context) {
    final schedule = PrayerSchedule.resolve(data: widget.data, now: widget.now);
    final today = schedule.prayerTimes;
    final np = schedule.nextPrayer;
    final isDark = _resolveIsDark(context, schedule.isNight);

    Widget themeToggleBtn = Container(
      key: const ValueKey('themeToggleBtn'),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B).withValues(alpha: 0.62),
                  const Color(0xFF0F172A).withValues(alpha: 0.72),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFFFFF).withValues(alpha: 0.92),
                  const Color(0xFFF8FAFC).withValues(alpha: 0.85),
                ],
              ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isDark ? const Color(0xFF7DD3FC).withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Tooltip(
        message: _themeMode.tooltip,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const ValueKey('themeToggleInkWell'),
            onTap: () => _setThemeMode(_themeMode.next),
            borderRadius: BorderRadius.circular(9),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: Tween<double>(begin: 0.85, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                    ),
                    child: FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                  );
                },
                child: Icon(
                  _themeMode.icon,
                  key: ValueKey(_themeMode),
                  size: 15,
                  color: _themeMode == AppThemeMode.light
                      ? const Color(0xFFF59E0B)
                      : _themeMode == AppThemeMode.dark
                          ? const Color(0xFF38BDF8)
                          : (isDark ? const Color(0xFF34D399) : const Color(0xFF0284C7)),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Widget macHeader = LayoutBuilder(
      builder: (context, constraints) {
        final isVeryNarrow = constraints.maxWidth < 360;

        Widget brandBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'اذکار من',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        );

        Widget widgetBtn = Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E293B).withValues(alpha: 0.62),
                      const Color(0xFF0F172A).withValues(alpha: 0.72),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.92),
                      const Color(0xFFF8FAFC).withValues(alpha: 0.85),
                    ],
                  ),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isDark ? const Color(0xFF7DD3FC).withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'ویجت شناور رومیزی (⌘W)',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: Icon(
              CupertinoIcons.rectangle_stack,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 15,
            ),
            onPressed: () => MenuBarService.setWidgetMode(true),
          ),
        );

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isVeryNarrow ? 8 : 16,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              brandBadge,
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  themeToggleBtn,
                  if (MenuBarService.isSupported) ...[
                    const SizedBox(width: 6),
                    widgetBtn,
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );

    Widget nextPrayerCard = LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(18),
      child: Center(
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.clock_solid, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  np != null ? 'تا ${np.label}' : 'اذان',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  np != null ? '${faDigits(fmt(np.delta))} (ساعت ${faDigits(np.time)})' : '--:--',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ]),
      ),
    );

    final pIcons = {
      'fajr': CupertinoIcons.sunrise_fill,
      'sunrise': CupertinoIcons.sun_max_fill,
      'dhuhr': CupertinoIcons.sun_max,
      'asr': CupertinoIcons.cloud_sun_fill,
      'maghrib': CupertinoIcons.sunset_fill,
      'isha': CupertinoIcons.moon_stars_fill,
    };

    Widget buildPrayerCell(MapEntry<String, String> e, {bool compact = false}) {
      final active = schedule.activePrayerKey == e.key;
      return AnimatedScale(
        scale: active ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: compact ? 5 : 7,
          ),
          decoration: active
              ? BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.32),
                            const Color(0xFF059669).withValues(alpha: 0.22),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.20),
                            const Color(0xFF059669).withValues(alpha: 0.12),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF34D399).withValues(alpha: 0.65)
                        : const Color(0xFF059669).withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pIcons[e.key] ?? CupertinoIcons.clock,
                size: compact ? 14 : 16,
                color: active
                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 3),
              Text(
                e.value.replaceAll('اذان ', ''),
                style: TextStyle(
                  fontSize: compact ? 10.0 : 11.0,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                faDigits(today[e.key] ?? '--:--'),
                style: TextStyle(
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget compactPrayerTimesStrip = LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: BorderRadius.circular(18),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: prayerLabels.entries.map((e) => Expanded(child: Center(child: buildPrayerCell(e, compact: true)))).toList(),
        ),
      ),
    );

    // 1. Unified Prayer Row (Next Prayer countdown + Prayer Times in ONE row)
    Widget unifiedPrayerBar = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: nextPrayerCard),
                const SizedBox(width: 12),
                Expanded(flex: 12, child: compactPrayerTimesStrip),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              nextPrayerCard,
              const SizedBox(height: 10),
              compactPrayerTimesStrip,
            ],
          );
        }
      },
    );

    // 2. Bigger Weather Box with integrated Refresh button
    Widget weatherCard = LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(18),
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.22 : 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                weather != null ? weatherSfIcon(weather!['code'] as int) : CupertinoIcons.cloud_sun_fill,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'هوای بوکان',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    weather != null
                        ? '${faDigits('${weather!['temp'].round()}')}° سانتی‌گراد • ${weatherDesc(weather!['code'] as int)}'
                        : (_isLoadingWeather
                            ? 'در حال به‌روزرسانی...'
                            : (weatherError.isNotEmpty ? weatherError : 'در حال دریافت اطلاعات')),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'به‌روزرسانی آب و هوا و اوقات شرعی',
              child: _RefreshButton(
                isRefreshing: _isRefreshing || _isLoadingWeather,
                onPressed: _refreshAll,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );

    void openFullAzkarFromDashboard({String? category, bool storyMode = true, int initialIndex = 0}) async {
      final cat = category ?? 'morning';
      await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => AzkarView(
            data: widget.data,
            controller: _azkarController,
            initialCategory: cat,
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

    final activeAzkarCategory = 'morning';
    final azkarInfo = _azkarController.getProgressInfo(
      category: activeAzkarCategory,
      now: widget.now,
      prayerTimes: schedule.prayerTimes,
    );

    Widget zikrCard = LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(18),
      onTap: () => openFullAzkarFromDashboard(category: activeAzkarCategory, storyMode: true),
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Progress Ring
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: azkarInfo.percentage,
                    strokeWidth: 4.2,
                    strokeCap: StrokeCap.round,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      azkarInfo.isCompleted
                          ? const Color(0xFF10B981)
                          : (azkarInfo.percentage > 0
                              ? const Color(0xFF0284C7)
                              : (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706))),
                    ),
                  ),
                ),
                if (azkarInfo.isCompleted)
                  const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF10B981), size: 20)
                else
                  Text(
                    '${faDigits('${(azkarInfo.percentage * 100).round()}')}٪',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activeAzkarCategory == 'morning' ? 'اذکار صبح ☀️' : 'اذکار شام 🌙',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'قرائت و تسبیح',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            CupertinoIcons.chevron_left,
                            size: 11,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: azkarInfo.statusTitle,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 13.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (azkarInfo.countSummary != null) ...[
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: azkarInfo.countSummary,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    azkarInfo.statusSubtitle,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    Widget metricsBar = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 580;
        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 11, child: weatherCard),
                const SizedBox(width: 12),
                Expanded(flex: 10, child: zikrCard),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              weatherCard,
              const SizedBox(height: 10),
              zikrCard,
            ],
          );
        }
      },
    );

    final todayCard = TodayCard(schedule: schedule, now: widget.now, isDark: isDark);
    final hadithCard = HadithCard(data: widget.data, now: widget.now, isDark: isDark);
    final sunanCard = SunanCard(sunan: schedule.sunan, isDark: isDark);
    final quranCard = QuranJuzCard(data: widget.data, now: widget.now, isDark: isDark);

    return Stack(children: [
      Positioned.fill(
        child: LandscapeSvg(
          phase: schedule.phase,
          now: widget.now,
          prayerTimes: schedule.prayerTimes,
          hijriDay: schedule.hijri.day,
        ),
      ),
      Positioned.fill(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          color: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFFF8FAFC).withValues(alpha: 0.28),
        ),
      ),
      SafeArea(
        child: Column(children: [
          macHeader,
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top 1/3 viewport space to showcase animated landscape & celestial visuals
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final h = MediaQuery.of(context).size.height;
                          final topGap = (h * 0.26).clamp(100.0, 220.0);
                          return SizedBox(height: topGap);
                        },
                      ),
                      _StaggerItem(index: 0, child: todayCard),
                      const SizedBox(height: 14),
                      _StaggerItem(index: 1, child: unifiedPrayerBar),
                      const SizedBox(height: 14),
                      _StaggerItem(index: 2, child: metricsBar),
                      const SizedBox(height: 14),
                      _StaggerItem(index: 3, child: quranCard),
                      const SizedBox(height: 14),
                      _StaggerItem(
                        index: 4,
                        child: LayoutBuilder(builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 640;
                          if (isWide) {
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: sunanCard),
                                  const SizedBox(width: 14),
                                  Expanded(child: hadithCard),
                                ],
                              ),
                            );
                          } else {
                            return Column(
                              children: [
                                sunanCard,
                                const SizedBox(height: 14),
                                hadithCard,
                              ],
                            );
                          }
                        }),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class SunanCard extends StatelessWidget {
  final SunnahBundle sunan;
  final bool isDark;

  const SunanCard({super.key, required this.sunan, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          CardTitle(
            sunan.headerTitle,
            icon: CupertinoIcons.sparkles,
            iconColor: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 10),
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),

          // 1. Top Part: Time-based Sunnats
          if (sunan.timeBased.isNotEmpty) ...[
            Text(
              'سنت‌های دارای وقت و زمان‌دار:',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...sunan.timeBased.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.20 : 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: const Color(0xFFF59E0B), size: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.timeHint != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.22 : 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF38BDF8).withValues(alpha: 0.40)
                                          : const Color(0xFF0284C7).withValues(alpha: 0.30),
                                      width: 0.7,
                                    ),
                                  ),
                                  child: Text(
                                    item.timeHint!,
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            ),
          ],

          // 2. Bottom Part: Timeless / Friday Sunnats
          Text(
            sunan.isFridaySpecial ? 'سنت‌ها و آداب مبارک جمعه:' : 'سنت‌های مستمر و آداب نیکو:',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Column(
            children: sunan.timeless.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        size: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class HadithCard extends StatelessWidget {
  final PrayerData data;
  final DateTime now;
  final bool isDark;
  const HadithCard({super.key, required this.data, required this.now, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    if (data.hadiths.isEmpty) {
      return const SizedBox.shrink();
    }
    final jt = jalaliToday(now);
    final h = data.hadiths[jt.day % data.hadiths.length];
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

class QuranJuzCard extends StatefulWidget {
  final PrayerData data;
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
    if (widget.data.quranJuz.isNotEmpty) {
      final idx = (juzNum - 1).clamp(0, widget.data.quranJuz.length - 1);
      currentJuz = Map<String, dynamic>.from(widget.data.quranJuz[idx]);
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
                          'جزء ${faDigits('$juzNum')}',
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

          if (theme.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(
                CupertinoIcons.sparkles,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                size: 12,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'محور جزء: $theme',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ],

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

class AzkarDashboardCard extends StatefulWidget {
  final PrayerData data;
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

/// Digital Live Clock with Pulsating Animated Colon `:`
class LiveClockWidget extends StatefulWidget {
  final DateTime? fixedTime;
  final bool isDark;

  const LiveClockWidget({
    super.key,
    this.fixedTime,
    this.isDark = true,
  });

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _colonOpacity;
  Timer? _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.fixedTime ?? DateTime.now();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);
    _colonOpacity = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.fixedTime == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _currentTime = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = widget.fixedTime ?? _currentTime;
    final hourStr = faDigits(time.hour.toString().padLeft(2, '0'));
    final minStr = faDigits(time.minute.toString().padLeft(2, '0'));
    final isDark = widget.isDark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.clock,
            size: 14.0,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 5),
          Text(
            hourStr,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          FadeTransition(
            opacity: _colonOpacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                ':',
                style: TextStyle(
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  fontSize: 14.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Text(
            minStr,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

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

