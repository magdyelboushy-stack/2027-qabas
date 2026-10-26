import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:qcf_quran/qcf_quran.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../data/khatma_model.dart';
import '../../logic/khatma_service.dart';
import '../../logic/khatma_notification_service.dart';
import '../../logic/khatma_ward_calculator.dart';
import 'khatma_setup_screen.dart';
import 'qcf_mushaf_screen.dart';
import '../../../../core/translations/app_locale_keys.dart';

/// Dashboard showing Khatma progress, today's sessions, and stats.
class KhatmaProgressScreen extends StatefulWidget {
  const KhatmaProgressScreen({super.key});

  @override
  State<KhatmaProgressScreen> createState() => _KhatmaProgressScreenState();
}

class _KhatmaProgressScreenState extends State<KhatmaProgressScreen> {
  KhatmaModel? _khatma;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final k = await KhatmaService.load();
    if (mounted) setState(() { _khatma = k; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final accent = isDark ? const Color(0xFF2A8B68) : const Color(0xFF00695C);
    final bg = isDark ? const Color(0xFF071814) : const Color(0xFFFFF8E1);
    final isAr = Get.locale?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_khatma?.name ?? (isAr ? AppLocaleKeys.smartKhatmaTitle.tr : 'Smart Khatma'), style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: accent)),
        centerTitle: true,
        actions: [
          if (_khatma != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: isDark ? Colors.white54 : Colors.black45),
              onSelected: (v) async {
                if (v == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF0E241E) : Colors.white,
                      title: Text(isAr ? AppLocaleKeys.deleteKhatmaConfirmTitle.tr : 'Delete Khatma?', style: TextStyle(fontFamily: 'Cairo', color: isDark ? Colors.white : Colors.black87)),
                      content: Text(isAr ? AppLocaleKeys.deleteKhatmaWarning.tr : 'All progress will be lost', style: TextStyle(fontFamily: 'Cairo', color: isDark ? Colors.white54 : Colors.black45)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? AppLocaleKeys.cancelAction.tr : 'Cancel', style: TextStyle(fontFamily: 'Cairo', color: accent))),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAr ? AppLocaleKeys.deleteAction.tr : 'Delete', style: const TextStyle(fontFamily: 'Cairo', color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await KhatmaService.delete();
                    await KhatmaNotificationService.cancelAll();
                    if (mounted) setState(() => _khatma = null);
                  }
                } else if (v == 'pause_resume') {
                  if (_khatma!.isPaused) {
                    await KhatmaService.resume(_khatma!);
                  } else {
                    await KhatmaService.pause(_khatma!);
                  }
                  await _load();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'pause_resume', child: Row(
                  children: [
                    Icon(_khatma!.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: accent, size: 20),
                    const SizedBox(width: 8),
                    Text(_khatma!.isPaused ? (isAr ? AppLocaleKeys.resumeKhatma.tr : 'Resume Khatma') : (isAr ? AppLocaleKeys.pauseAction.tr : 'Pause Khatma'), style: TextStyle(fontFamily: 'Cairo', color: isDark ? Colors.white : Colors.black87)),
                  ],
                )),
                PopupMenuItem(value: 'delete', child: Row(
                  children: [
                    const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(isAr ? AppLocaleKeys.deleteKhatmaTitle.tr : 'Delete Khatma', style: TextStyle(fontFamily: 'Cairo', color: isDark ? Colors.white : Colors.black87)),
                  ],
                )),
              ],
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _khatma == null
              ? _buildNoKhatma(isDark, accent, isAr)
              : _buildDashboard(isDark, accent, isAr),
    );
  }

  // ─── No Active Khatma ───
  Widget _buildNoKhatma(bool isDark, Color accent, bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 80, color: accent.withOpacity(0.2)),
            const SizedBox(height: 20),
            Text(isAr ? AppLocaleKeys.noCurrentKhatma.tr : 'No Active Khatma', style: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text(isAr ? AppLocaleKeys.createSmartKhatmaDesc.tr : 'Create a smart Khatma with small sessions and reminders',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                elevation: 4,
              ),
              icon: const Icon(Icons.add_rounded, size: 24),
              label: Text(isAr ? AppLocaleKeys.createNewKhatma.tr : 'Create New Khatma', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _openSetup,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSetup() async {
    final result = await Navigator.push<KhatmaModel>(
      context,
      MaterialPageRoute(builder: (_) => const KhatmaSetupScreen()),
    );
    if (result != null && mounted) {
      setState(() { _loading = true; });
      await _load();
    }
  }

  // ─── Dashboard ───
  Widget _buildDashboard(bool isDark, Color accent, bool isAr) {
    final k = _khatma!;
    final stats = KhatmaService.getStats(k);
    final ward = KhatmaService.getTodayWard(k);
    
    return RefreshIndicator(
      color: accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── Overall Progress Circle ──
          Center(
            child: SizedBox(
              width: 180, height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 170, height: 170,
                    child: CircularProgressIndicator(
                      value: k.overallProgress,
                      strokeWidth: 10,
                      backgroundColor: accent.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(k.isPaused ? Colors.grey : accent),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(k.overallProgress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.bold, color: k.isPaused ? Colors.grey : accent)),
                      Text('${stats['pagesRead']} / 604',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (k.isPaused) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pause_circle_filled_rounded, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(isAr ? AppLocaleKeys.khatmaPaused.tr : 'Khatma is Paused', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // ── Streak Widget ──
          if (stats['streak'] > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [accent.withOpacity(0.2), accent.withOpacity(0.05)]),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${stats['streak']} ${isAr ? AppLocaleKeys.daysStreak.tr : "Days Streak"}', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      if (stats['bestStreak'] > stats['streak'])
                        Text(isAr ? 'أفضل التزام: ${stats['bestStreak']} أيام' : 'Best Streak: ${stats['bestStreak']} days', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Today's Progress & Ward ──
          _sectionCard(
            isDark, accent,
            icon: Icons.today_rounded,
            title: isAr ? AppLocaleKeys.todaysWard.tr : "Today's Portion",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(isAr ? ward.summaryAr : ward.summaryEn,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${k.todayPagesRead} / ${k.todayTarget} ${isAr ? AppLocaleKeys.pageWord.tr : "pages"}',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                    Text('${k.sessionsRemaining} ${isAr ? AppLocaleKeys.sessionsRemaining.tr : "sessions left"}',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: k.todayProgress,
                    minHeight: 10,
                    backgroundColor: accent.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(
                      k.todayProgress >= 1.0 ? Colors.green : accent,
                    ),
                  ),
                ),
                if (k.todayProgress >= 1.0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(isAr ? AppLocaleKeys.wardCompletedCongrats.tr : 'MashaAllah! Today\'s portion complete 🎉',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade400)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Start Session Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: k.isPaused ? Colors.grey : accent,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 6,
              ),
              icon: Icon(k.isPaused ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
              label: Text(
                k.isPaused 
                  ? (isAr ? AppLocaleKeys.khatmaStopped.tr : 'Khatma Paused')
                  : k.todayProgress >= 1.0
                    ? (isAr ? AppLocaleKeys.readMore.tr : 'Read More')
                    : (isAr ? AppLocaleKeys.startReading.tr : 'Start Reading'),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: k.isPaused ? null : () async {
                final sessionWard = KhatmaService.getSessionWard(k);
                await Navigator.push(context, MaterialPageRoute(builder: (_) => QcfMushafScreen(
                  initialPage: sessionWard.fromPage,
                  khatmaId: k.id,
                )));
                _load(); // Refresh after returning
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Rescue Session ──
          if (stats['isBehind'] == true && k.todayRemaining > k.sessionPages && !k.isPaused) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.15), Colors.red.withOpacity(0.08)]),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: const Text('⚡', style: TextStyle(fontSize: 28)),
                title: Text(isAr ? AppLocaleKeys.makeupDelay.tr : 'Catch Up Session',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text(isAr ? AppLocaleKeys.delayedPlanDesc.tr : 'You are behind schedule. Read a little extra to catch up.',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
              ),
            ),
          ],

          // ── Stats ──
          _sectionCard(
            isDark, accent,
            icon: Icons.bar_chart_rounded,
            title: isAr ? AppLocaleKeys.khatmaStats.tr : 'Khatma Stats',
            child: Column(
              children: [
                _statRow(isAr ? AppLocaleKeys.daysSinceStart.tr : 'Days Elapsed', '${stats['daysElapsed']}', isDark, accent),
                _statRow(isAr ? AppLocaleKeys.daysRemaining.tr : 'Days Remaining', '${stats['daysRemaining']}', isDark, accent),
                _statRow(isAr ? AppLocaleKeys.dailyAverage.tr : 'Daily Average', '${stats['avgDailyPages']} ${isAr ? AppLocaleKeys.pageWord.tr : "pages"}', isDark, accent),
                _statRow(isAr ? AppLocaleKeys.pagesCompleted.tr : 'Pages Read', '${stats['pagesRead']}', isDark, accent),
                _statRow(isAr ? AppLocaleKeys.pagesRemaining.tr : 'Pages Remaining', '${stats['pagesRemaining']}', isDark, accent),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Current Position Info ──
          _sectionCard(
            isDark, accent,
            icon: Icons.location_on_rounded,
            title: isAr ? AppLocaleKeys.currentLocation.tr : 'Current Position',
            child: Column(
              children: [
                _statRow(isAr ? AppLocaleKeys.pageLabel.tr : 'Page', '${k.currentPage}', isDark, accent),
                _statRow(isAr ? AppLocaleKeys.surahLabel.tr : 'Surah', isAr ? KhatmaWardCalculator.getSurahNameArForPage(k.currentPage) : KhatmaWardCalculator.getSurahNameEnForPage(k.currentPage), isDark, accent),
                _statRow(isAr ? AppLocaleKeys.juzLabel.tr : 'Juz', '${KhatmaWardCalculator.getJuzForPage(k.currentPage)}', isDark, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(bool isDark, Color accent, {required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF0E241E).withOpacity(0.6) : Colors.white.withOpacity(0.8),
        border: Border.all(color: accent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
            ],
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
          Text(value, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}
