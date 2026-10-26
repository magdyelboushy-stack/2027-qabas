import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/khatma_model.dart';
import 'khatma_ward_calculator.dart';

/// Business logic for the Smart Khatma system.
class KhatmaService {
  static const _key = 'khatma_active';

  // ═══════════════════════════════════════════════════════
  //  CRUD Operations
  // ═══════════════════════════════════════════════════════

  /// Load the active khatma from storage.
  static Future<KhatmaModel?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null || s.isEmpty) return null;
    try {
      final khatma = KhatmaModel.fromJsonString(s);
      // Daily reset check
      if (khatma.isActive && !khatma.isPaused && khatma.needsDailyReset) {
        _performDailyReset(khatma);
        await save(khatma);
      }
      return khatma;
    } catch (e) {
      debugPrint('Error loading khatma: $e');
      return null;
    }
  }

  /// Save khatma to storage.
  static Future<void> save(KhatmaModel khatma) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, khatma.toJsonString());
  }

  /// Create a new khatma.
  static Future<KhatmaModel> create({
    required String name,
    required int targetDays,
    required String divisionMode,
    required int sessionPages,
    required String notifyMode,
    required String notifStyle,
    String? specificTime,
    int afterPrayerDelayMinutes = 15,
  }) async {
    // Calculate dailyJuzGoal from targetDays
    final dailyPages = (604 / targetDays).ceil();
    final dailyJuz = dailyPages / 20.0;

    final khatma = KhatmaModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.isNotEmpty ? name : 'ختمتي',
      startDate: DateTime.now(),
      targetDays: targetDays,
      divisionMode: divisionMode,
      dailyJuzGoal: dailyJuz,
      sessionPages: sessionPages,
      notifyMode: notifyMode,
      notifStyle: notifStyle,
      specificTime: specificTime,
      afterPrayerDelayMinutes: afterPrayerDelayMinutes,
    );
    await save(khatma);
    return khatma;
  }

  /// Delete the active khatma.
  static Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // ═══════════════════════════════════════════════════════
  //  Reading Progress
  // ═══════════════════════════════════════════════════════

  /// Mark pages as read in the current session.
  static Future<KhatmaModel?> markPagesRead(KhatmaModel khatma, int pagesCount) async {
    khatma.todayPagesRead += pagesCount;
    khatma.currentPage = (khatma.currentPage + pagesCount).clamp(1, 605);
    khatma.lastReadDate = DateTime.now();
    khatma.recordToday();

    // Check completion
    if (khatma.currentPage > 604) {
      khatma.isActive = false;
      khatma.completedAt = DateTime.now();
    }

    await save(khatma);
    return khatma;
  }

  /// Called when user reads a page in the mushaf.
  static Future<KhatmaModel?> onPageRead(KhatmaModel khatma, int page) async {
    if (!khatma.isActive || khatma.isPaused) return khatma;

    // Only track if this page is within the expected range
    if (page >= khatma.currentPage && page <= khatma.currentPage + khatma.todayTarget) {
      final pagesRead = page - khatma.currentPage + 1;
      khatma.todayPagesRead += pagesRead;
      khatma.currentPage = page + 1;
      khatma.lastReadDate = DateTime.now();
      khatma.recordToday();

      if (khatma.currentPage > 604) {
        khatma.isActive = false;
        khatma.completedAt = DateTime.now();
      }
      await save(khatma);
    }
    return khatma;
  }

  // ═══════════════════════════════════════════════════════
  //  Pause / Resume / Reschedule
  // ═══════════════════════════════════════════════════════

  /// Pause the khatma.
  static Future<void> pause(KhatmaModel khatma) async {
    khatma.isPaused = true;
    khatma.pausedAt = DateTime.now();
    await save(khatma);
  }

  /// Resume the khatma.
  static Future<void> resume(KhatmaModel khatma) async {
    if (khatma.isPaused && khatma.pausedAt != null) {
      // Extend startDate by the paused duration to keep schedule fair
      final pausedDuration = DateTime.now().difference(khatma.pausedAt!);
      khatma.startDate = khatma.startDate.add(pausedDuration);
    }
    khatma.isPaused = false;
    khatma.pausedAt = null;
    await save(khatma);
  }

  /// Reschedule: change target days.
  static Future<void> reschedule(KhatmaModel khatma, int newTargetDays) async {
    final remaining = 604 - khatma.currentPage + 1;
    khatma.targetDays = newTargetDays;
    khatma.dailyJuzGoal = (remaining / newTargetDays / 20.0);
    await save(khatma);
  }

  // ═══════════════════════════════════════════════════════
  //  Smart Adaptation
  // ═══════════════════════════════════════════════════════

  /// Adapt schedule based on user behavior.
  /// If behind → reduce today's load slightly.
  /// If on track → maintain.
  static void adaptSchedule(KhatmaModel khatma) {
    if (khatma.isPaused || khatma.isCompleted) return;

    final elapsed = khatma.daysElapsed;
    final expectedPages = elapsed * khatma.dailyPageTarget;
    final actualPages = khatma.totalPagesRead;
    final ratio = expectedPages > 0 ? actualPages / expectedPages : 1.0;

    if (ratio < 0.6) {
      // Significantly behind → recalculate remaining days
      final remaining = 604 - khatma.currentPage + 1;
      final daysLeft = khatma.targetDays - elapsed;
      if (daysLeft > 0) {
        // Spread remaining pages over remaining days
        khatma.dailyJuzGoal = (remaining / daysLeft) / 20.0;
      }
    }
    // If on track or ahead → keep current pace
  }

  // ═══════════════════════════════════════════════════════
  //  Daily Reset
  // ═══════════════════════════════════════════════════════

  /// Daily reset: carry over missed pages.
  static void _performDailyReset(KhatmaModel khatma) {
    final missed = khatma.todayRemaining;
    // Cap carry-over to avoid overwhelming
    final maxCarry = (khatma.dailyPageTarget * 0.5).round();
    khatma.carryOverPages = missed.clamp(0, maxCarry);
    khatma.todayPagesRead = 0;
    khatma.lastReadDate = DateTime.now();

    // Adapt schedule
    adaptSchedule(khatma);
  }

  // ═══════════════════════════════════════════════════════
  //  Stats & Ward Info
  // ═══════════════════════════════════════════════════════

  /// Get rescue session info when user is behind.
  static Map<String, dynamic> getRescueSession(KhatmaModel khatma) {
    final behind = khatma.todayRemaining;
    final rescuePages = (behind / 2).ceil().clamp(2, 10);
    final ward = KhatmaWardCalculator.getSessionWard(
      currentPage: khatma.currentPage,
      sessionPages: rescuePages,
    );
    return {
      'pages': rescuePages,
      'from': khatma.currentPage,
      'to': (khatma.currentPage + rescuePages - 1).clamp(1, 604),
      'estimatedMinutes': KhatmaWardCalculator.estimateReadingMinutes(rescuePages),
      'ward': ward,
    };
  }

  /// Get stats for display.
  static Map<String, dynamic> getStats(KhatmaModel khatma) {
    final elapsed = khatma.daysElapsed;
    final pagesRead = khatma.totalPagesRead;
    final avgDaily = elapsed > 0 ? (pagesRead / elapsed) : 0.0;

    return {
      'daysElapsed': elapsed,
      'daysRemaining': khatma.estimatedDaysRemaining,
      'pagesRead': pagesRead,
      'pagesRemaining': 604 - pagesRead,
      'avgDailyPages': avgDaily.toStringAsFixed(1),
      'progress': khatma.overallProgress,
      'completionDate': DateTime.now().add(Duration(days: khatma.estimatedDaysRemaining)),
      'streak': khatma.streak,
      'bestStreak': khatma.bestStreak,
      'isOnTrack': khatma.isOnTrack,
      'isBehind': khatma.isBehind,
    };
  }

  /// Get today's ward details.
  static WardDetails getTodayWard(KhatmaModel khatma) {
    return KhatmaWardCalculator.getTodayWard(
      currentPage: khatma.currentPage,
      dailyTarget: khatma.todayTarget,
    );
  }

  /// Get current session ward details.
  static WardDetails getSessionWard(KhatmaModel khatma) {
    return KhatmaWardCalculator.getSessionWard(
      currentPage: khatma.currentPage,
      sessionPages: khatma.sessionPages,
    );
  }
}
