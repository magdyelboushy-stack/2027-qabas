import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../logic/ramadan_service.dart';
import 'package:mihrab/features/auth/data/auth_service.dart';
import 'package:mihrab/core/services/ad_service.dart'; // ✅ AdMob

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<Map<String, dynamic>>> _leaderboardFuture;
  // final auth = GoogleAuthService();

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = RamadanService.getLeaderboard();
    AdService.showInterstitialAd(); // ✅ Interstitial ad
  }

  @override
  Widget build(BuildContext context) {
    // final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = const Color(0xFFD4AF37);
    final bg = isDark ? const Color(0xFF071814) : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF151925) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('لوحة الأبطال 🏆',
            style: TextStyle(fontFamily: 'Cairo')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: gold));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('حدث خطأ في تحميل البيانات',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.white : Colors.black)));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
                child: Text('لا يوجد منافسين بعد.. كن الأول!',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.white : Colors.black)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final currentUser = AuthService.userNotifier.value;
              final isMe = user['name'] == currentUser?['name'];

              // Top 3 medals
              String prefix = '${index + 1}';
              Color? rankColor;
              if (index == 0) {
                prefix = '🥇';
                rankColor = const Color(0xFFFFD700);
              } else if (index == 1) {
                prefix = '🥈';
                rankColor = const Color(0xFFC0C0C0);
              } else if (index == 2) {
                prefix = '🥉';
                rankColor = const Color(0xFFCD7F32);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? gold.withOpacity(0.2) : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: isMe ? Border.all(color: gold) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        prefix,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: index < 3 ? 24 : 18,
                          fontWeight: FontWeight.bold,
                          color: rankColor ??
                              (isDark ? Colors.white : Colors.black),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: user['image_url'] != null &&
                              user['image_url'].toString().isNotEmpty
                          ? CachedNetworkImageProvider(user['image_url'])
                          : null,
                      backgroundColor: gold.withOpacity(0.2),
                      child: user['image_url'] == null ||
                              user['image_url'].toString().isEmpty
                          ? Text(user['name'][0].toUpperCase(),
                              style: TextStyle(
                                  color: gold, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'],
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user['level'] != null
                                ? RamadanService.levels.firstWhere(
                                    (e) => e['minXP'] <= user['total_xp'],
                                    orElse: () =>
                                        RamadanService.levels.last)['name']
                                : 'مبتدئ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${user['total_xp']} XP',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
