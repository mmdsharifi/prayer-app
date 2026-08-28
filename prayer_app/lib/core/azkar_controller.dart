import 'package:flutter/foundation.dart';
import 'dhikr_model.dart';

class AzkarController extends ChangeNotifier {
  final List<DhikrItem> morningList;
  final List<DhikrItem> eveningList;

  String _activeCategory;
  bool _isStoryMode = false;
  int _storyIndex = 0;
  bool _isDetailsExpanded = false;
  String _activeDateKey = '';

  final Map<String, int> _counts = {};
  final Map<String, bool> _completed = {};

  AzkarController({
    required this.morningList,
    required this.eveningList,
    String defaultCategory = 'morning',
  }) : _activeCategory = defaultCategory {
    _syncDateKey();
  }

  void _syncDateKey() {
    final now = DateTime.now();
    final key = '${now.year}-${now.month}-${now.day}';
    if (_activeDateKey != key) {
      _activeDateKey = key;
      _counts.clear();
      _completed.clear();
    }
  }

  String get activeCategory => _activeCategory;
  bool get isStoryMode => _isStoryMode;
  int get storyIndex => _storyIndex;
  bool get isDetailsExpanded => _isDetailsExpanded;

  List<DhikrItem> get currentList =>
      _activeCategory == 'evening' ? eveningList : morningList;

  DhikrItem? get currentStoryDhikr {
    final list = currentList;
    if (list.isEmpty) return null;
    final idx = _storyIndex.clamp(0, list.length - 1);
    return list[idx];
  }

  int getCount(String id) {
    _syncDateKey();
    return _counts[id] ?? 0;
  }

  bool isDhikrCompleted(String id, int targetCount) {
    _syncDateKey();
    return _completed[id] ?? ((_counts[id] ?? 0) >= targetCount);
  }

  double getProgress([String? category]) {
    _syncDateKey();
    final cat = category ?? _activeCategory;
    final list = cat == 'evening' ? eveningList : morningList;
    if (list.isEmpty) return 0.0;

    int completedCount = 0;
    for (final item in list) {
      if (isDhikrCompleted(item.id, item.count)) {
        completedCount++;
      }
    }
    return completedCount / list.length;
  }

  ({int completed, int total}) getProgressCounts([String? category]) {
    _syncDateKey();
    final cat = category ?? _activeCategory;
    final list = cat == 'evening' ? eveningList : morningList;
    int completedCount = 0;
    for (final item in list) {
      if (isDhikrCompleted(item.id, item.count)) {
        completedCount++;
      }
    }
    return (completed: completedCount, total: list.length);
  }

  void setCategory(String category) {
    if (_activeCategory != category) {
      _activeCategory = category;
      _storyIndex = 0;
      _isDetailsExpanded = false;
      notifyListeners();
    }
  }

  void setStoryMode(bool enabled, {int initialIndex = 0}) {
    _isStoryMode = enabled;
    if (enabled) {
      final list = currentList;
      _storyIndex = initialIndex.clamp(0, list.isNotEmpty ? list.length - 1 : 0);
      _isDetailsExpanded = false;
    }
    notifyListeners();
  }

  void toggleDetails() {
    _isDetailsExpanded = !_isDetailsExpanded;
    notifyListeners();
  }

  void setDetailsExpanded(bool expanded) {
    if (_isDetailsExpanded != expanded) {
      _isDetailsExpanded = expanded;
      notifyListeners();
    }
  }

  void setStoryIndex(int index) {
    final list = currentList;
    if (list.isEmpty) return;
    final safeIdx = index.clamp(0, list.length - 1);
    if (_storyIndex != safeIdx) {
      _storyIndex = safeIdx;
      _isDetailsExpanded = false;
      notifyListeners();
    }
  }

  bool nextStory() {
    final list = currentList;
    if (_storyIndex < list.length - 1) {
      _storyIndex++;
      _isDetailsExpanded = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool prevStory() {
    if (_storyIndex > 0) {
      _storyIndex--;
      _isDetailsExpanded = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Increments counter by 1. Returns true if the dhikr reached its target.
  bool incrementCount(DhikrItem item) {
    _syncDateKey();
    final cur = _counts[item.id] ?? 0;
    if (cur < item.count) {
      final next = cur + 1;
      _counts[item.id] = next;
      if (next >= item.count) {
        _completed[item.id] = true;
      }
      notifyListeners();
      return next >= item.count;
    } else {
      _completed[item.id] = true;
      notifyListeners();
      return true;
    }
  }

  void toggleCompletedDirect(DhikrItem item) {
    _syncDateKey();
    final wasDone = isDhikrCompleted(item.id, item.count);
    if (wasDone) {
      _counts[item.id] = 0;
      _completed[item.id] = false;
    } else {
      _counts[item.id] = item.count;
      _completed[item.id] = true;
    }
    notifyListeners();
  }

  void resetItem(DhikrItem item) {
    _syncDateKey();
    _counts[item.id] = 0;
    _completed[item.id] = false;
    notifyListeners();
  }

  void resetCategory(String category) {
    _syncDateKey();
    final list = category == 'evening' ? eveningList : morningList;
    for (final item in list) {
      _counts[item.id] = 0;
      _completed[item.id] = false;
    }
    _storyIndex = 0;
    _isDetailsExpanded = false;
    notifyListeners();
  }

  AzkarProgressInfo getProgressInfo({
    required String category,
    required DateTime now,
    required Map<String, dynamic> prayerTimes,
  }) {
    _syncDateKey();
    final counts = getProgressCounts(category);
    final isMorning = category == 'morning';
    final isDone = counts.total > 0 && counts.completed >= counts.total;
    final pct = counts.total > 0 ? (counts.completed / counts.total) : 0.0;
    final pctInt = (pct * 100).round();

    // Calculate time remaining to target (sunrise for morning, maghrib/midnight for evening)
    final targetTimeKey = isMorning ? 'sunrise' : 'maghrib';
    final targetTimeString = prayerTimes[targetTimeKey]?.toString();
    Duration? remainingDuration;
    bool isPastTarget = false;

    if (targetTimeString != null && targetTimeString.contains(':')) {
      final parts = targetTimeString.split(':');
      final targetHour = int.tryParse(parts[0]) ?? 0;
      final targetMin = int.tryParse(parts[1]) ?? 0;
      final nowMinutes = now.hour * 60 + now.minute;
      final targetMinutes = targetHour * 60 + targetMin;
      final diffMinutes = targetMinutes - nowMinutes;

      if (diffMinutes > 0) {
        remainingDuration = Duration(minutes: diffMinutes);
      } else {
        isPastTarget = true;
      }
    }

    String timeRemainingText = '';
    if (remainingDuration != null) {
      final hrs = remainingDuration.inHours;
      final mins = remainingDuration.inMinutes % 60;
      if (hrs > 0 && mins > 0) {
        timeRemainingText = '${_faDigits('$hrs')} ساعت و ${_faDigits('$mins')} دقیقه';
      } else if (hrs > 0) {
        timeRemainingText = '${_faDigits('$hrs')} ساعت';
      } else {
        timeRemainingText = '${_faDigits('$mins')} دقیقه';
      }
    }

    final catLabel = isMorning ? 'اذکار صبح' : 'اذکار شام';
    final targetName = isMorning ? 'طلوع آفتاب' : 'غروب آفتاب';

    String statusTitle;
    String? countSummary;
    String statusSubtitle;

    if (isDone) {
      statusTitle = 'الحمدلله تمام $catLabel را خوانده‌اید 🌟';
      countSummary = '(${_faDigits('${counts.completed}')} از ${_faDigits('${counts.total}')} ذکر)';
      statusSubtitle = 'تمام ${_faDigits('${counts.total}')} ذکر با موفقیت قرائت شد';
    } else if (counts.completed == 0) {
      statusTitle = 'هنوز $catLabel را نخوانده‌اید';
      countSummary = null;
      if (remainingDuration != null) {
        statusSubtitle = '$timeRemainingText تا $targetName فرصت باقی است';
      } else if (isPastTarget) {
        statusSubtitle = 'وقت بافضیلت $targetName سپری شده، اما هنوز فرصت خواندن $catLabel باقی است';
      } else {
        statusSubtitle = 'فرصت قرائت ${_faDigits('${counts.total}')} ذکر پرفضیلت';
      }
    } else {
      statusTitle = '${_faDigits('$pctInt')}٪ از $catLabel را خوانده‌اید';
      countSummary = '(${_faDigits('${counts.completed}')} از ${_faDigits('${counts.total}')} ذکر)';
      if (remainingDuration != null) {
        statusSubtitle = '$timeRemainingText تا $targetName فرصت باقی است';
      } else if (isPastTarget) {
        statusSubtitle = 'وقت بافضیلت $targetName سپری شده، اما هنوز فرصت خواندن $catLabel باقی است';
      } else {
        statusSubtitle = 'فرصت قرائت ${_faDigits('${counts.total}')} ذکر پرفضیلت';
      }
    }

    return AzkarProgressInfo(
      percentage: pct,
      completedCount: counts.completed,
      totalCount: counts.total,
      statusTitle: statusTitle,
      countSummary: countSummary,
      statusSubtitle: statusSubtitle,
      timeRemainingText: timeRemainingText,
      isCompleted: isDone,
    );
  }

  static String _faDigits(String s) {
    const e = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const p = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(e[i], p[i]);
    }
    return s;
  }
}

class AzkarProgressInfo {
  final double percentage;
  final int completedCount;
  final int totalCount;
  final String statusTitle;
  final String? countSummary;
  final String statusSubtitle;
  final String timeRemainingText;
  final bool isCompleted;

  const AzkarProgressInfo({
    required this.percentage,
    required this.completedCount,
    required this.totalCount,
    required this.statusTitle,
    this.countSummary,
    required this.statusSubtitle,
    required this.timeRemainingText,
    required this.isCompleted,
  });
}

