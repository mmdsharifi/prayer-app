import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockMorningAzkar = [
    const DhikrItem(
      id: 'm1',
      category: 'morning',
      order: 1,
      count: 1,
      title: 'آية الكرسي',
      arabic: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...',
      translationFa: 'خداوند یکتا و پاینده است...',
      translationKu: 'خوا ئەو زاتەیە کە هیچ پەرستراوێک نییە...',
      virtue: 'حفظ از شیطان تا شامگاه',
      source: 'صحیح الترغیب',
    ),
    const DhikrItem(
      id: 'm2',
      category: 'morning',
      order: 2,
      count: 3,
      title: 'اخلاص و معوذتین',
      arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ...',
      translationFa: 'بگو او خدای یگانه است...',
      translationKu: 'بڵێ خوا یەک و تاقانەیە...',
      virtue: 'کفایت از هر بدی',
      source: 'سنن أبی داود',
    ),
  ];

  final mockEveningAzkar = [
    const DhikrItem(
      id: 'e1',
      category: 'evening',
      order: 1,
      count: 1,
      title: 'امسینا و امسی الملک',
      arabic: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ...',
      translationFa: 'شب کردیم در حالی که ملک از آن خداست...',
      translationKu: 'ئێوارەمان بەسەردا هات موڵک بۆ خوایە...',
      virtue: 'پناه به خدا از عذاب قبر',
      source: 'صحیح مسلم',
    ),
  ];

  group('DhikrItem Model & JSON Parsing', () {
    test('serializes and deserializes correctly', () {
      final item = mockMorningAzkar.first;
      final json = item.toJson();
      expect(json['id'], 'm1');
      expect(json['arabic'], contains('اللَّهُ لَا إِلَٰهَ'));
      expect(json['translation_fa'], contains('خداوند'));
      expect(json['translation_ku'], contains('خوا'));

      final reconstructed = DhikrItem.fromJson(json);
      expect(reconstructed.id, item.id);
      expect(reconstructed.title, item.title);
      expect(reconstructed.arabic, item.arabic);
      expect(reconstructed.translationFa, item.translationFa);
      expect(reconstructed.translationKu, item.translationKu);
      expect(reconstructed.virtue, item.virtue);
      expect(reconstructed.source, item.source);
      expect(reconstructed.count, 1);
    });

    test('parses real assets/azkar_full.json correctly', () {
      final jsonStr = File('assets/azkar_full.json').readAsStringSync();
      final j = jsonDecode(jsonStr);

      final morning = (j['morning'] as List)
          .map((e) => DhikrItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final evening = (j['evening'] as List)
          .map((e) => DhikrItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      expect(morning.length, greaterThanOrEqualTo(15));
      expect(evening.length, greaterThanOrEqualTo(15));

      for (final m in morning) {
        expect(m.arabic, isNotEmpty);
        expect(m.translationFa, isNotEmpty);
        expect(m.translationKu, isNotEmpty);
        expect(m.source, isNotEmpty);
        expect(m.count, greaterThan(0));
      }
    });
  });

  group('AzkarController Logic', () {
    test('handles category switching and story navigation', () {
      final ctrl = AzkarController(
        morningList: mockMorningAzkar,
        eveningList: mockEveningAzkar,
      );

      expect(ctrl.activeCategory, 'morning');
      expect(ctrl.currentList.length, 2);
      expect(ctrl.currentStoryDhikr?.id, 'm1');

      ctrl.setStoryMode(true);
      expect(ctrl.isStoryMode, isTrue);

      final advanced = ctrl.nextStory();
      expect(advanced, isTrue);
      expect(ctrl.storyIndex, 1);
      expect(ctrl.currentStoryDhikr?.id, 'm2');

      // End of morning list
      final cantAdvance = ctrl.nextStory();
      expect(cantAdvance, isFalse);

      ctrl.prevStory();
      expect(ctrl.storyIndex, 0);

      ctrl.setCategory('evening');
      expect(ctrl.activeCategory, 'evening');
      expect(ctrl.currentList.length, 1);
      expect(ctrl.currentStoryDhikr?.id, 'e1');
    });

    test('tracks repetition counter and marks completion', () {
      final ctrl = AzkarController(
        morningList: mockMorningAzkar,
        eveningList: mockEveningAzkar,
      );

      final item = mockMorningAzkar[1]; // requires 3 repetitions
      expect(ctrl.getCount(item.id), 0);
      expect(ctrl.isDhikrCompleted(item.id, item.count), isFalse);

      // Tap 1
      bool done = ctrl.incrementCount(item);
      expect(done, isFalse);
      expect(ctrl.getCount(item.id), 1);
      expect(ctrl.isDhikrCompleted(item.id, item.count), isFalse);

      // Tap 2
      done = ctrl.incrementCount(item);
      expect(done, isFalse);
      expect(ctrl.getCount(item.id), 2);

      // Tap 3 -> Reached target
      done = ctrl.incrementCount(item);
      expect(done, isTrue);
      expect(ctrl.getCount(item.id), 3);
      expect(ctrl.isDhikrCompleted(item.id, item.count), isTrue);

      // Progress calculation
      final progress = ctrl.getProgress('morning');
      expect(progress, 0.5); // 1 of 2 completed

      // Direct toggle and reset
      ctrl.toggleCompletedDirect(item);
      expect(ctrl.isDhikrCompleted(item.id, item.count), isFalse);

      ctrl.toggleCompletedDirect(item);
      expect(ctrl.isDhikrCompleted(item.id, item.count), isTrue);

      ctrl.resetCategory('morning');
      expect(ctrl.getCount(item.id), 0);
      expect(ctrl.isDhikrCompleted(item.id, item.count), isFalse);
    });

    test('toggles detail expansion', () {
      final ctrl = AzkarController(
        morningList: mockMorningAzkar,
        eveningList: mockEveningAzkar,
      );

      expect(ctrl.isDetailsExpanded, isFalse);
      ctrl.toggleDetails();
      expect(ctrl.isDetailsExpanded, isTrue);
      ctrl.toggleDetails();
      expect(ctrl.isDetailsExpanded, isFalse);
    });

    test('generates AzkarProgressInfo for 0%, in-progress, and 100% states with sunrise countdown', () {
      final ctrl = AzkarController(
        morningList: mockMorningAzkar, // 2 items
        eveningList: mockEveningAzkar, // 1 item
      );

      final prayerTimes = {
        'fajr': '05:00',
        'sunrise': '06:30',
        'dhuhr': '12:30',
        'asr': '16:00',
        'maghrib': '19:30',
        'isha': '21:00',
      };

      // 1. State: 0% before sunrise (5:30 AM -> 1 hr to sunrise)
      final info0Before = ctrl.getProgressInfo(
        category: 'morning',
        now: DateTime(2026, 8, 28, 5, 30),
        prayerTimes: prayerTimes,
      );
      expect(info0Before.percentage, 0.0);
      expect(info0Before.isCompleted, isFalse);
      expect(info0Before.statusTitle, contains('هنوز اذکار صبح را نخوانده‌اید'));
      expect(info0Before.statusSubtitle, contains('تا طلوع آفتاب'));
      expect(info0Before.statusSubtitle, contains('۱ ساعت'));

      // 2. State: 0% after sunrise (7:30 AM)
      final info0After = ctrl.getProgressInfo(
        category: 'morning',
        now: DateTime(2026, 8, 28, 7, 30),
        prayerTimes: prayerTimes,
      );
      expect(info0After.percentage, 0.0);
      expect(info0After.statusTitle, contains('هنوز اذکار صبح را نخوانده‌اید'));
      expect(info0After.statusSubtitle, contains('سپری شده'));

      // 3. State: 50% (1 of 2 completed) at 5:45 AM (45 min to sunrise)
      ctrl.incrementCount(mockMorningAzkar[0]); // completes m1 (count: 1)
      final info50 = ctrl.getProgressInfo(
        category: 'morning',
        now: DateTime(2026, 8, 28, 5, 45),
        prayerTimes: prayerTimes,
      );
      expect(info50.percentage, 0.5);
      expect(info50.isCompleted, isFalse);
      expect(info50.statusTitle, contains('۵۰٪ از اذکار صبح را خوانده‌اید'));
      expect(info50.countSummary, '(۱ از ۲ ذکر)');
      expect(info50.statusSubtitle, contains('۴۵ دقیقه تا طلوع آفتاب فرصت باقی است'));

      // 4. State: 100% (both completed)
      ctrl.toggleCompletedDirect(mockMorningAzkar[1]); // completes m2
      final info100 = ctrl.getProgressInfo(
        category: 'morning',
        now: DateTime(2026, 8, 28, 6, 0),
        prayerTimes: prayerTimes,
      );
      expect(info100.percentage, 1.0);
      expect(info100.isCompleted, isTrue);
      expect(info100.statusTitle, contains('الحمدلله تمام اذکار صبح را خوانده‌اید'));
      expect(info100.countSummary, '(۲ از ۲ ذکر)');
      expect(info100.statusSubtitle, contains('با موفقیت قرائت شد'));
    });
  });

  group('AzkarView Widgets', () {
    testWidgets('renders AzkarView in Story mode, shows Arabic initially and expands details on click',
        (tester) async {
      final data = PrayerData({}, {});
      data.fullMorningAzkar = mockMorningAzkar;
      data.fullEveningAzkar = mockEveningAzkar;

      await tester.pumpWidget(
        MaterialApp(
          home: AzkarView(
            data: data,
            initialCategory: 'morning',
            initialStoryMode: true,
            isDark: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Arabic text is prominent
      expect(find.textContaining('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ'), findsOneWidget);

      // Verify "مشاهده بیشتر" button is visible
      final expandBtn = find.text('مشاهده بیشتر');
      expect(expandBtn, findsOneWidget);

      // Tap to expand details
      await tester.tap(expandBtn);
      await tester.pumpAndSettle();

      // Translations and virtue should now be visible
      expect(find.text('ترجمه فارسی'), findsOneWidget);
      expect(find.textContaining('خداوند یکتا و پاینده است'), findsOneWidget);
      expect(find.text('مانای کوردی سۆرانی'), findsOneWidget);
      expect(find.textContaining('خوا ئەو زاتەیە'), findsOneWidget);
      expect(find.text('فضیلت و پاداش ذکر'), findsOneWidget);
      expect(find.text('منبع و تخریج حدیث'), findsOneWidget);

      // Tap counter button on m1 (count: 1)
      final counterBtn = find.textContaining('تسبیح و شمارش');
      expect(counterBtn, findsOneWidget);
      await tester.tap(counterBtn);
      await tester.pumpAndSettle();

      // Should have auto-advanced to m2 ('اخلاص و معوذتین')
      expect(find.textContaining('اخلاص و معوذتین'), findsOneWidget);

      // Tap m2 three times to complete final dhikr
      await tester.tap(find.text('Space ␣'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Space ␣'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Space ␣'));
      await tester.pumpAndSettle();

      // Final item completed
      expect(find.textContaining('تکمیل شد'), findsOneWidget);
    });

    testWidgets('renders AzkarView in List mode with accordion items', (tester) async {
      final data = PrayerData({}, {});
      data.fullMorningAzkar = mockMorningAzkar;
      data.fullEveningAzkar = mockEveningAzkar;

      await tester.pumpWidget(
        MaterialApp(
          home: AzkarView(
            data: data,
            initialCategory: 'morning',
            initialStoryMode: false,
            isDark: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // List should contain both mock morning dhikrs
      expect(find.textContaining('آية الكرسي'), findsOneWidget);
      expect(find.textContaining('اخلاص و معوذتین'), findsOneWidget);

      // Tap to expand second item
      final expandTriggers = find.text('مشاهده بیشتر');
      expect(expandTriggers, findsNWidgets(2));

      await tester.tap(expandTriggers.at(1));
      await tester.pumpAndSettle();

      expect(find.textContaining('بگو او خدای یگانه است'), findsOneWidget);
      expect(find.textContaining('بڵێ خوا یەک و تاقانەیە'), findsOneWidget);
    });

    testWidgets('Tahlil dhikr completes at count 10', (tester) async {
      final controller = AzkarController(
        morningList: mockMorningAzkar,
        eveningList: mockEveningAzkar,
      );
      final tahlilDhikr = DhikrItem(
        id: 'm_tahlil_100',
        category: 'morning',
        order: 19,
        count: 100,
        title: 'تهلیل و توحید (۱۰ یا ۱۰۰ بار)',
        arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        translationFa: '',
        translationKu: '',
        virtue: '',
        source: '',
      );

      for (int i = 0; i < 9; i++) {
        controller.incrementCount(tahlilDhikr);
        expect(controller.isDhikrCompleted('m_tahlil_100', 100), isFalse);
      }

      // 10th count completes it
      final completed = controller.incrementCount(tahlilDhikr);
      expect(completed, isTrue);
      expect(controller.isDhikrCompleted('m_tahlil_100', 100), isTrue);
      expect(controller.getCount('m_tahlil_100'), 10);
    });

    testWidgets('Dashboard renders compact zikrCard with Circular Progress Ring and dynamic remaining time', (tester) async {
      final prayerTimes = {
        'fajr': '05:00',
        'sunrise': '06:30',
        'dhuhr': '12:30',
        'asr': '16:00',
        'maghrib': '19:30',
        'isha': '21:00',
      };
      final data = PrayerData({'6-6': prayerTimes}, {'6': 31});
      data.fullMorningAzkar = mockMorningAzkar; // 2 items
      data.fullEveningAzkar = mockEveningAzkar; // 1 item

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Dashboard(
              data: data,
              now: DateTime(2026, 8, 28, 5, 30),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Large card should be removed from dashboard
      expect(find.byType(AzkarDashboardCard), findsNothing);

      // 2. Compact zikrCard should contain circular progress ring, 0% and time remaining
      expect(find.text('اذکار صبح'), findsOneWidget);
      expect(find.text('۰٪'), findsOneWidget);
      expect(find.textContaining('هنوز اذکار صبح را نخوانده‌اید'), findsOneWidget);

      // 3. Tap on zikrCard launches AzkarView
      await tester.tap(find.text('اذکار صبح'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AzkarView), findsOneWidget);
    });

    testWidgets('shows celebratory completion dialog with confetti when all azkar completed', (tester) async {
      final data = PrayerData({}, {});
      data.fullMorningAzkar = [mockMorningAzkar.first]; // 1 item (count: 1)
      data.fullEveningAzkar = mockEveningAzkar;

      await tester.pumpWidget(
        MaterialApp(
          home: AzkarView(
            data: data,
            initialCategory: 'morning',
            initialStoryMode: true,
            isDark: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Complete the single item
      await tester.tap(find.text('Space ␣'));
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Celebratory dialog appears
      expect(find.text('«الْحَمْدُ لِلَّٰهِ»'), findsOneWidget);
      expect(find.text('اذکار امروز خوانده شده'), findsOneWidget);
      expect(find.text('بازگشت به صفحه اصلی'), findsOneWidget);
      expect(find.text('«أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ»'), findsOneWidget);
    });
  });
}
