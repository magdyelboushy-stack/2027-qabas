import 'dart:convert';

/// Data model for a Quran completion (Khatma) plan.
class KhatmaModel {
  String id;
  String name; // اسم الختمة
  DateTime startDate;

  /// Target completion days (7, 30, 40, custom)
  int targetDays;

  /// Division mode: 'juz' | 'hizb' | 'page'
  String divisionMode;

  /// Daily juz goal: 0.5, 1, 2, 3
  double dailyJuzGoal;

  /// Pages per micro-session (2, 4, 5, 10)
  int sessionPages;

  /// Notification mode: 'specific_time' | 'after_prayer' | 'both'
  String notifyMode;

  /// Notification style: 'tadabbur' | 'motivational' | 'short'
  String notifStyle;

  /// Specific notification time (e.g. "07:00", "19:00")
  String? specificTime;

  /// Delay in minutes after each prayer (e.g. 15 means 15 min after adhan)
  int afterPrayerDelayMinutes;

  /// Current reading position (1-604)
  int currentPage;

  /// Pages read TODAY (resets daily)
  int todayPagesRead;

  /// Last date the user read
  DateTime lastReadDate;

  /// Is this khatma active?
  bool isActive;

  /// Is paused?
  bool isPaused;

  /// Pause date
  DateTime? pausedAt;

  /// Completion date
  DateTime? completedAt;

  /// Pages that were missed and redistributed
  int carryOverPages;

  /// Consecutive reading days streak
  int streak;

  /// Best ever streak
  int bestStreak;

  /// Dates the user read on (ISO date strings: "2026-06-11")
  List<String> readDates;

  KhatmaModel({
    required this.id,
    this.name = 'ختمتي',
    required this.startDate,
    this.targetDays = 30,
    this.divisionMode = 'page',
    this.dailyJuzGoal = 1,
    this.sessionPages = 2,
    this.notifyMode = 'after_prayer',
    this.notifStyle = 'motivational',
    this.specificTime,
    this.afterPrayerDelayMinutes = 15,
    this.currentPage = 1,
    this.todayPagesRead = 0,
    DateTime? lastReadDate,
    this.isActive = true,
    this.isPaused = false,
    this.pausedAt,
    this.completedAt,
    this.carryOverPages = 0,
    this.streak = 0,
    this.bestStreak = 0,
    List<String>? readDates,
  })  : lastReadDate = lastReadDate ?? DateTime.now(),
        readDates = readDates ?? [];

  // ═══════════════════════════════════════════════════════
  //  Computed Properties
  // ═══════════════════════════════════════════════════════

  /// Daily page target based on dailyJuzGoal (dynamically adapts)
  int get dailyPageTarget {
    return (dailyJuzGoal * 20).ceil();
  }

  /// Pages needed today (goal + any carryover, capped to not exceed remaining)
  int get todayTarget {
    final base = dailyPageTarget;
    final total = base + carryOverPages;
    final remaining = 604 - currentPage + 1;
    return total > remaining ? remaining : total;
  }

  /// Pages remaining today
  int get todayRemaining => (todayTarget - todayPagesRead).clamp(0, 604);

  /// Sessions remaining today
  int get sessionsRemaining => (todayRemaining / sessionPages).ceil();

  /// Overall khatma progress (0.0 - 1.0)
  double get overallProgress => isCompleted ? 1.0 : ((currentPage - 1) / 604).clamp(0.0, 1.0);

  /// Today's progress (0.0 - 1.0)
  double get todayProgress =>
      todayTarget > 0 ? (todayPagesRead / todayTarget).clamp(0.0, 1.0) : 0.0;

  /// Estimated days remaining
  int get estimatedDaysRemaining {
    final remaining = 604 - currentPage + 1;
    final daily = dailyPageTarget;
    return daily > 0 ? (remaining / daily).ceil() : 999;
  }

  /// Current session page range [from, to]
  List<int> get currentSessionRange {
    final from = currentPage;
    final to = (currentPage + sessionPages - 1).clamp(1, 604);
    return [from, to];
  }

  /// Is khatma completed?
  bool get isCompleted => currentPage > 604 || completedAt != null;

  /// Is on track (read today or today is start day)?
  bool get isOnTrack {
    final todayStr = _dateKey(DateTime.now());
    return readDates.contains(todayStr) || todayPagesRead > 0;
  }

  /// Is behind schedule
  bool get isBehind {
    if (isPaused || isCompleted) return false;
    final elapsed = DateTime.now().difference(startDate).inDays + 1;
    final expectedPages = (elapsed * dailyPageTarget).clamp(0, 604);
    return (currentPage - 1) < expectedPages * 0.8; // 80% threshold
  }

  /// Is today a new day (needs reset)?
  bool get needsDailyReset {
    final now = DateTime.now();
    return lastReadDate.year != now.year ||
        lastReadDate.month != now.month ||
        lastReadDate.day != now.day;
  }

  /// Total pages read
  int get totalPagesRead => isCompleted ? 604 : (currentPage - 1).clamp(0, 604);

  /// Days since start
  int get daysElapsed => DateTime.now().difference(startDate).inDays + 1;

  // ═══════════════════════════════════════════════════════
  //  Streak helpers
  // ═══════════════════════════════════════════════════════

  /// Record today as a read day
  void recordToday() {
    final todayStr = _dateKey(DateTime.now());
    if (!readDates.contains(todayStr)) {
      readDates.add(todayStr);
      _recalculateStreak();
    }
  }

  void _recalculateStreak() {
    int count = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final dayStr = _dateKey(now.subtract(Duration(days: i)));
      if (readDates.contains(dayStr)) {
        count++;
      } else {
        break;
      }
    }
    streak = count;
    if (streak > bestStreak) bestStreak = streak;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ═══════════════════════════════════════════════════════
  //  Serialization
  // ═══════════════════════════════════════════════════════

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'targetDays': targetDays,
    'divisionMode': divisionMode,
    'dailyJuzGoal': dailyJuzGoal,
    'sessionPages': sessionPages,
    'notifyMode': notifyMode,
    'notifStyle': notifStyle,
    'specificTime': specificTime,
    'afterPrayerDelayMinutes': afterPrayerDelayMinutes,
    'currentPage': currentPage,
    'todayPagesRead': todayPagesRead,
    'lastReadDate': lastReadDate.toIso8601String(),
    'isActive': isActive,
    'isPaused': isPaused,
    'pausedAt': pausedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'carryOverPages': carryOverPages,
    'streak': streak,
    'bestStreak': bestStreak,
    'readDates': readDates,
    '_version': 2, // Migration marker
  };

  factory KhatmaModel.fromJson(Map<String, dynamic> json) {
    final version = json['_version'] as int? ?? 1;

    // ── Migration from v1 ──
    if (version < 2) {
      return _migrateFromV1(json);
    }

    return KhatmaModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'ختمتي',
      startDate: DateTime.parse(json['startDate'] as String),
      targetDays: json['targetDays'] as int? ?? 30,
      divisionMode: json['divisionMode'] as String? ?? 'page',
      dailyJuzGoal: (json['dailyJuzGoal'] as num).toDouble(),
      sessionPages: json['sessionPages'] as int,
      notifyMode: json['notifyMode'] as String? ?? 'after_prayer',
      notifStyle: json['notifStyle'] as String? ?? 'motivational',
      specificTime: json['specificTime'] as String?,
      afterPrayerDelayMinutes: json['afterPrayerDelayMinutes'] as int? ?? 15,
      currentPage: json['currentPage'] as int,
      todayPagesRead: json['todayPagesRead'] as int,
      lastReadDate: DateTime.tryParse(json['lastReadDate'] as String? ?? '') ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      isPaused: json['isPaused'] as bool? ?? false,
      pausedAt: json['pausedAt'] != null ? DateTime.tryParse(json['pausedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'] as String) : null,
      carryOverPages: json['carryOverPages'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      readDates: (json['readDates'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Migrate from v1 (old format) to v2
  static KhatmaModel _migrateFromV1(Map<String, dynamic> json) {
    final dailyJuz = (json['dailyJuzGoal'] as num?)?.toDouble() ?? 1.0;
    final dailyPages = (dailyJuz * 20).round();
    final currentPage = json['currentPage'] as int? ?? 1;
    final remaining = 604 - currentPage + 1;
    final estimatedDays = dailyPages > 0 ? (remaining / dailyPages).ceil() : 30;

    return KhatmaModel(
      id: json['id'] as String,
      name: 'ختمتي الحالية', // Default name for migrated khatma
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      targetDays: estimatedDays + (DateTime.now().difference(
        DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      ).inDays),
      divisionMode: 'page', // Default for old khatma
      dailyJuzGoal: dailyJuz,
      sessionPages: json['sessionPages'] as int? ?? 2,
      notifyMode: json['notifyMode'] as String? ?? 'after_prayer',
      notifStyle: 'motivational',
      specificTime: json['specificTime'] as String?,
      afterPrayerDelayMinutes: json['afterPrayerDelayMinutes'] as int? ?? 15,
      currentPage: currentPage,
      todayPagesRead: json['todayPagesRead'] as int? ?? 0,
      lastReadDate: DateTime.tryParse(json['lastReadDate'] as String? ?? '') ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      carryOverPages: json['carryOverPages'] as int? ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory KhatmaModel.fromJsonString(String s) =>
      KhatmaModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
