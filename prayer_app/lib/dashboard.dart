part of 'main.dart';

// ignore_for_file: unused_element

// ─────────────────────── Shared Helpers & SF Symbols ───────────────────────

String faDigits(String s) =>
    s.replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: BorderRadius.circular(18),
      onTap: _isLoadingWeather ? null : () => _refreshAll(),
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.22 : 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                weather != null ? weatherSfIcon(weather!['code'] as int) : CupertinoIcons.cloud_sun_fill,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'هوای بوکان',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weather != null
                        ? '${faDigits('${weather!['temp'].round()}')}° سانتی‌گراد • ${weatherDesc(weather!['code'] as int)}'
                        : (_isLoadingWeather
                            ? 'در حال به‌روزرسانی...'
                            : (weatherError.isNotEmpty ? weatherError : 'در حال دریافت اطلاعات')),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      height: 1.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: 'به‌روزرسانی آب و هوا و اوقات شرعی',
              child: DashboardRefreshButton(
                isRefreshing: _isRefreshing || _isLoadingWeather,
                onPressed: _refreshAll,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );

    void openFullAzkarFromDashboard({String? category, bool storyMode = true, int? initialIndex}) async {
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

    final activeAzkarCategory = AzkarController.resolveCategoryForTime(
      now: widget.now,
      prayerTimes: schedule.prayerTimes,
    );
    final azkarInfo = _azkarController.getProgressInfo(
      category: activeAzkarCategory,
      now: widget.now,
      prayerTimes: schedule.prayerTimes,
    );

    Widget zikrCard = LiquidGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    value: azkarInfo.percentage,
                    strokeWidth: 4.0,
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              activeAzkarCategory == 'morning'
                                  ? CupertinoIcons.sun_max_fill
                                  : CupertinoIcons.moon_stars_fill,
                              size: 13,
                              color: activeAzkarCategory == 'morning'
                                  ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706))
                                  : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                activeAzkarCategory == 'morning' ? 'اذکار صبح' : 'اذکار شام',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                              height: 1.1,
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            height: 1.2,
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
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
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
                      StaggerItem(index: 0, child: todayCard),
                      const SizedBox(height: 14),
                      StaggerItem(index: 1, child: unifiedPrayerBar),
                      const SizedBox(height: 14),
                      StaggerItem(index: 2, child: metricsBar),
                      const SizedBox(height: 14),
                      StaggerItem(index: 3, child: quranCard),
                      const SizedBox(height: 14),
                      StaggerItem(
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


