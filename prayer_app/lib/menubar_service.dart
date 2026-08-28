part of 'main.dart';

class DesktopIntegration {
  static const MethodChannel _channel = MethodChannel('prayer_app/menubar');

  static bool get isSupported => !kIsWeb && Platform.isMacOS;

  /// Update native macOS status item & dropdown menu from deep PrayerSchedule
  static Future<void> sync({
    required PrayerSchedule schedule,
    String? hadith,
  }) async {
    if (!isSupported) return;

    try {
      final np = schedule.nextPrayer;
      if (np == null) return;

      final hours = np.delta.inHours;
      final mins = np.delta.inMinutes % 60;
      final remainingFormatted =
          '${faDigits(hours.toString().padLeft(2, '0'))}:${faDigits(mins.toString().padLeft(2, '0'))}';

      final dateStr =
          '${schedule.weekdayName} ${faDigits('${schedule.jalali.day}')} ${schedule.monthName} ${faDigits('${schedule.jalali.year}')}';

      final timesMap = <String, String>{};
      for (final key in prayerLabels.keys) {
        if (schedule.prayerTimes[key] != null) {
          timesMap[key] = faDigits(schedule.prayerTimes[key]!);
        }
      }

      await _channel.invokeMethod('updateMenuBar', {
        'title': remainingFormatted,
        'sfSymbol': np.sfSymbol,
        'remainingTime': remainingFormatted,
        'nextPrayer': {
          'key': np.key,
          'label': np.label,
          'sfSymbol': np.sfSymbol,
          'time': faDigits(np.time),
          'delta': remainingFormatted,
        },
        'times': timesMap,
        'zikr': schedule.zikr.label.isNotEmpty ? schedule.zikr.label : null,
        'hadith': hadith,
        'date': dateStr,
      });
    } catch (e) {
      debugPrint('DesktopIntegration error: $e');
    }
  }

  static Future<void> setWidgetMode(bool isWidget) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('setWidgetMode', {'isWidget': isWidget});
    } catch (_) {}
  }

  static Future<void> showWindow() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('showWindow');
    } catch (_) {}
  }

  static Future<void> hideWindow() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('hideWindow');
    } catch (_) {}
  }

  static Future<void> toggleWindow() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('toggleWindow');
    } catch (_) {}
  }

  static Future<void> setAlwaysOnTop(bool isTop) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('setAlwaysOnTop', {'isTop': isTop});
    } catch (_) {}
  }
}

// Backward-compatible alias for existing callers
class MenuBarService extends DesktopIntegration {
  static bool get isSupported => DesktopIntegration.isSupported;
  static Future<void> setWidgetMode(bool isWidget) => DesktopIntegration.setWidgetMode(isWidget);
  static Future<void> showWindow() => DesktopIntegration.showWindow();
  static Future<void> hideWindow() => DesktopIntegration.hideWindow();
  static Future<void> toggleWindow() => DesktopIntegration.toggleWindow();
  static Future<void> setAlwaysOnTop(bool isTop) => DesktopIntegration.setAlwaysOnTop(isTop);

  static Future<void> update({
    required PrayerData data,
    required DateTime now,
    Map<String, dynamic>? weather,
  }) async {
    final schedule = PrayerSchedule.resolve(data: data, now: now);
    String? hadith;
    if (data.hadiths.isNotEmpty) {
      final h = data.hadiths[schedule.jalali.day % data.hadiths.length];
      hadith = h['fa'] as String?;
    }
    await DesktopIntegration.sync(schedule: schedule, hadith: hadith);
  }
}
