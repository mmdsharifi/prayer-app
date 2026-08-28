import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/main.dart';

void main() {
  testWidgets('GlassCard renders child widget correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text('تست کارت شیشه‌ای'),
          ),
        ),
      ),
    );

    expect(find.text('تست کارت شیشه‌ای'), findsOneWidget);
  });

  testWidgets('CardTitle displays icon and title text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CardTitle(
            'عنوان تستی',
            icon: Icons.mosque,
          ),
        ),
      ),
    );

    expect(find.text('عنوان تستی'), findsOneWidget);
    expect(find.byIcon(Icons.mosque), findsOneWidget);
  });

  testWidgets('HadithCard renders Hadith details properly', (WidgetTester tester) async {
    final mockData = PrayerData(
      {
        '6-6': {
          'fajr': '04:30',
          'sunrise': '06:00',
          'dhuhr': '12:30',
          'asr': '16:00',
          'maghrib': '19:15',
          'isha': '20:45',
        }
      },
      {'6': 31},
    );
    mockData.hadiths = [
      {
        'ar': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
        'fa': 'همانا اعمال به نیت‌ها بستگی دارند',
        'ku': 'کردەوەکان بەپێی نیەتەکانن',
      }
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HadithCard(
            data: mockData,
            now: DateTime(2026, 8, 27),
          ),
        ),
      ),
    );

    expect(find.text('حدیث روز'), findsOneWidget);
    expect(find.textContaining('پیامبر'), findsOneWidget);
    expect(find.text('همانا اعمال به نیت‌ها بستگی دارند'), findsOneWidget);
  });

  testWidgets('QuranJuzCard renders Juz 5 verses and cycles to next verse', (WidgetTester tester) async {
    final mockData = PrayerData(
      {
        '6-5': {
          'fajr': '04:30',
          'sunrise': '06:00',
          'dhuhr': '12:30',
          'asr': '16:00',
          'maghrib': '19:15',
          'isha': '20:45',
        }
      },
      {'6': 31},
    );
    mockData.quranJuz = [
      {}, {}, {}, {},
      {
        'title': 'جزء ۵ (سوره نساء ۲۴ تا ۱۴۷)',
        'surah_info': 'سوره نساء (آیات ۲۴ الی ۱۴۷)',
        'page_info': 'صفحات ۷۷ تا ۱۰۰',
        'theme': 'امانت‌داری، عدالت در داوری',
        'verses': [
          {
            'ar': 'إِنَّ اللَّهَ يَأْمُرُكُمْ أَن تُؤَدُّوا الْأَمَانَاتِ إِلَىٰ أَهْلِهَا',
            'fa': 'همانا خداوند به شما فرمان می‌دهد که امانت‌ها را به صاحبانشان بازگردانید',
            'surah': 'سوره النساء: ۵۸',
            'tafsir': 'شایسته‌سالاری در سپردن امانت‌ها و مسئولیت‌ها',
          },
          {
            'ar': 'وَاعْبُدُوا اللَّهَ وَلَا تُشْرِكُوا بِهِ شَيْئًا',
            'fa': 'و خدا را بپرستید و چیزی را شریک او نسازید',
            'surah': 'سوره النساء: ۳۶',
            'tafsir': 'منشور جامع حقوق دهگانه در اسلام',
          },
        ],
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranJuzCard(
            data: mockData,
            // 2026-08-27 corresponds to 5 Shahrivar (Juz 5)
            now: DateTime(2026, 8, 27),
          ),
        ),
      ),
    );

    // Initial Ayah 1 (Nisa 58)
    expect(find.text('آیاتی از قرآن'), findsOneWidget);
    expect(find.textContaining('جزء ۵'), findsAtLeastNWidgets(1));
    expect(find.textContaining('امانت‌ها را به صاحبانشان بازگردانید'), findsOneWidget);
    expect(find.text('نکته و تفسیر آیه:'), findsOneWidget);

    // Tap next verse chevron control
    await tester.tap(find.byTooltip('آیه بعدی'));
    await tester.pumpAndSettle();

    // Now shows Ayah 2 (Nisa 36)
    expect(find.textContaining('چیزی را شریک او نسازید'), findsOneWidget);
  });

  testWidgets('Dashboard renders flawlessly at 320px mobile width without overflow', (WidgetTester tester) async {
    final mockData = PrayerData(
      {
        '6-5': {
          'fajr': '04:30',
          'sunrise': '06:00',
          'dhuhr': '12:30',
          'asr': '16:00',
          'maghrib': '19:15',
          'isha': '20:45',
        }
      },
      {'6': 31},
    );
    mockData.hadiths = [
      {
        'ar': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
        'fa': 'همانا اعمال به نیت‌ها بستگی دارند',
        'ku': 'کردەوەکان بەپێی نیەتەکانن',
      }
    ];
    mockData.schedule = [];
    mockData.azkar = {
      'daily_short': {'fa': 'سبحان الله وبحمده', 'ar': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ'},
      'friday': {'fa': 'اللهم صل علی محمد', 'ar': 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ'},
      'thursday': {'fa': 'استغفر الله', 'ar': 'أَسْتَغْفِرُ اللَّهَ'},
      'fajr_prayer': {'fa': 'لا اله الا الله', 'ar': 'لَا إِلَهَ إِلَّا اللَّهُ'},
      'maghrib_prayer': {'fa': 'الحمد لله', 'ar': 'الْحَمْدُ لِلَّهِ'},
      'night_sleep': {'fa': 'باسمک ربی', 'ar': 'بِاسْمِكَ رَبِّي'},
      'morning_wake': {'fa': 'الحمد لله الذی احیانا', 'ar': 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا'},
      'sunnah_fast': {'fa': 'اللهم لک صمت', 'ar': 'اللَّهُمَّ لَكَ صُمْتُ'},
      'general': [
        {'fa': 'یا حی یا قیوم', 'ar': 'يَا حَيُّ يَا قَيُّومُ'},
      ],
      'quran_parts': [],
    };
    mockData.quranJuz = [
      {}, {}, {}, {},
      {
        'title': 'جزء ۵ (سوره نساء ۲۴ تا ۱۴۷)',
        'surah_info': 'سوره نساء (آیات ۲۴ الی ۱۴۷)',
        'page_info': 'صفحات ۷۷ تا ۱۰۰',
        'theme': 'امانت‌داری، عدالت در داوری',
        'verses': [
          {
            'ar': 'إِنَّ اللَّهَ يَأْمُرُكُمْ أَن تُؤَدُّوا الْأَمَانَاتِ إِلَىٰ أَهْلِهَا',
            'fa': 'همانا خداوند به شما فرمان می‌دهد که امانت‌ها را به صاحبانشان بازگردانید',
            'surah': 'سوره النساء: ۵۸',
            'tafsir': 'شایسته‌سالاری در سپردن امانت‌ها و مسئولیت‌ها',
          },
        ],
      },
    ];

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Dashboard(
            data: mockData,
            now: DateTime(2026, 8, 27, 12, 0),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('اذکار من'), findsOneWidget);
    expect(find.text('آیاتی از قرآن'), findsOneWidget);
    expect(find.textContaining('جزء ۵'), findsAtLeastNWidgets(1));
    expect(find.byType(SunanCard), findsOneWidget);
  });

  testWidgets('LiquidGlassCard renders distinct themes for Light and Dark modes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              LiquidGlassCard(
                isDark: false,
                child: Text('کارت روشن'),
              ),
              LiquidGlassCard(
                isDark: true,
                child: Text('کارت تاریک'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('کارت روشن'), findsOneWidget);
    expect(find.text('کارت تاریک'), findsOneWidget);
  });

  testWidgets('Dashboard theme switcher toggles between system, light, and dark modes', (WidgetTester tester) async {
    final mockData = PrayerData(
      {
        '6-6': {
          'fajr': '04:30',
          'sunrise': '06:00',
          'dhuhr': '12:30',
          'asr': '16:00',
          'maghrib': '19:15',
          'isha': '20:45',
        }
      },
      {'6': 31},
    );
    mockData.hadiths = [
      {'ar': 'حديث', 'fa': 'حدیث', 'ku': 'فەرموودە'}
    ];
    mockData.schedule = [];
    mockData.azkar = {'daily_short': {'fa': 'ذکر', 'ar': 'ذكر'}};
    mockData.quranJuz = [
      {}, {}, {}, {}, {},
      {'surah_info': 'سوره نساء', 'page_info': 'ص ۷۷', 'theme': 'امانت', 'verses': []}
    ];

    AppThemeMode? changedMode;

    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Dashboard(
            data: mockData,
            now: DateTime(2026, 8, 27, 12, 0),
            initialThemeMode: AppThemeMode.system,
            onThemeChanged: (mode) => changedMode = mode,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Verify initial render in System mode (showing system half-circle icon)
    expect(find.text('اذکار من'), findsOneWidget);
    final themeBtnFinder = find.byKey(const ValueKey('themeToggleInkWell'));
    expect(themeBtnFinder, findsOneWidget);
    expect(find.byKey(const ValueKey(AppThemeMode.system)), findsOneWidget);

    // Tap single theme toggle button -> cycles to Light mode (sun icon)
    await tester.tap(themeBtnFinder);
    await tester.pump(const Duration(milliseconds: 350));
    expect(changedMode, AppThemeMode.light);
    expect(find.byKey(const ValueKey(AppThemeMode.light)), findsOneWidget);

    // Tap single theme toggle button -> cycles to Dark mode (moon icon)
    await tester.tap(themeBtnFinder);
    await tester.pump(const Duration(milliseconds: 350));
    expect(changedMode, AppThemeMode.dark);
    expect(find.byKey(const ValueKey(AppThemeMode.dark)), findsOneWidget);

    // Tap single theme toggle button -> cycles back to System mode
    await tester.tap(themeBtnFinder);
    await tester.pump(const Duration(milliseconds: 350));
    expect(changedMode, AppThemeMode.system);
    expect(find.byKey(const ValueKey(AppThemeMode.system)), findsOneWidget);
  });

  testWidgets('TodayCard renders prominent Solar date, Live Clock with icon, and 4 date boxes', (WidgetTester tester) async {
    final schedule = PrayerSchedule.resolve(
      data: PrayerData({}, {}),
      now: DateTime(2026, 8, 28, 6, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayCard(
            schedule: schedule,
            now: DateTime(2026, 8, 28, 6, 30),
            isDark: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Title & Subtitle: سلام علیکم و رحمه الله / امروز، جمعه ۶ شهریور
    expect(find.text('سلام علیکم و رحمه الله'), findsOneWidget);
    expect(find.text('امروز، جمعه ۶ شهریور'), findsOneWidget);

    // 2. Live digital clock with grey icon and correct digits
    expect(find.byType(LiveClockWidget), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.clock), findsOneWidget);
    expect(find.text('۰۶'), findsOneWidget);
    expect(find.text(':'), findsOneWidget);
    expect(find.text('۳۰'), findsOneWidget);

    // 3. Box 1 (شمسی): جمعه ۶ شهریور / ۱۴۰۵
    expect(find.text('جمعه ۶ شهریور'), findsOneWidget);
    expect(find.text('۱۴۰۵'), findsOneWidget);

    // 4. Box 2 (کوردی): ۶ی خەرمانان / ۲۷۲۶
    expect(find.text('۶ی خەرمانان'), findsOneWidget);
    expect(find.text('۲۷۲۶'), findsOneWidget);

    // 5. Box 3 (قمری و رمضان): ۱۴ ربیع‌الاول / ۱۴۴۸ و ۵ ماه و ۱۶ روز / تا رمضان
    expect(find.text('۱۴ ربیع‌الاول'), findsOneWidget);
    expect(find.text('۱۴۴۸'), findsOneWidget);
    expect(find.text('۵ ماه و ۱۶ روز'), findsOneWidget);
    expect(find.text('تا رمضان'), findsOneWidget);

    // 6. Box 4 (میلادی): 28 Aug / 2026
    expect(find.text('28 Aug'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
  });
}
