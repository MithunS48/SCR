import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/gamification_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_overlay.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GamificationProvider>().loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<GamificationProvider>().loadLeaderboard(),
          ),
        ],
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, gamif, _) {
          return LoadingOverlay(
            isLoading: gamif.isLoading,
            child: gamif.leaderboard.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.leaderboard_outlined,
                            size: 64, color: AppTheme.textSecondary),
                        SizedBox(height: 12),
                        Text('No data yet',
                            style:
                                TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // ── Top 3 podium ─────────────────────────────
                      if (gamif.leaderboard.length >= 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary.withOpacity(0.05),
                                Colors.amber.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _PodiumItem(
                                  entry: gamif.leaderboard[1],
                                  height: 80,
                                  isCurrentUser: gamif.leaderboard[1]
                                          .userId ==
                                      currentUser?.id),
                              _PodiumItem(
                                  entry: gamif.leaderboard[0],
                                  height: 110,
                                  isFirst: true,
                                  isCurrentUser: gamif.leaderboard[0]
                                          .userId ==
                                      currentUser?.id),
                              _PodiumItem(
                                  entry: gamif.leaderboard[2],
                                  height: 60,
                                  isCurrentUser: gamif.leaderboard[2]
                                          .userId ==
                                      currentUser?.id),
                            ],
                          ),
                        ),

                      // ── Full list ────────────────────────────────
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: gamif.leaderboard.length,
                          itemBuilder: (context, index) {
                            final entry = gamif.leaderboard[index];
                            final isCurrentUser =
                                entry.userId == currentUser?.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? AppTheme.primary.withOpacity(0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: isCurrentUser
                                    ? Border.all(
                                        color: AppTheme.primary
                                            .withOpacity(0.3))
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Rank
                                  SizedBox(
                                    width: 36,
                                    child: entry.rank <= 3
                                        ? _RankMedal(rank: entry.rank)
                                        : Text(
                                            '#${entry.rank}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                  ),

                                  // Avatar
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isCurrentUser
                                        ? AppTheme.primary
                                        : AppTheme.primary.withOpacity(0.15),
                                    child: Text(
                                      entry.displayName[0].toUpperCase(),
                                      style: TextStyle(
                                        color: isCurrentUser
                                            ? Colors.white
                                            : AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name + badges
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.displayName +
                                              (isCurrentUser ? ' (You)' : ''),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isCurrentUser
                                                ? AppTheme.primary
                                                : AppTheme.textPrimary,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.emoji_events,
                                                size: 12,
                                                color: Colors.amber),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${entry.badgeCount} badge${entry.badgeCount == 1 ? '' : 's'}',
                                              style: const TextStyle(
                                                  color:
                                                      AppTheme.textSecondary,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Points
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${entry.totalPoints}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: isCurrentUser
                                              ? AppTheme.primary
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                      const Text('pts',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _RankMedal extends StatelessWidget {
  final int rank;
  const _RankMedal({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.amber, Colors.grey[400]!, Colors.brown[300]!];
    final icons  = ['🥇', '🥈', '🥉'];
    return Text(icons[rank - 1], style: const TextStyle(fontSize: 20));
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final bool isFirst;
  final bool isCurrentUser;

  const _PodiumItem({
    required this.entry,
    required this.height,
    this.isFirst = false,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFirst
        ? Colors.amber
        : entry.rank == 2
            ? Colors.grey[400]!
            : Colors.brown[300]!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isFirst)
          const Text('👑', style: TextStyle(fontSize: 22)),
        CircleAvatar(
          radius: isFirst ? 28 : 22,
          backgroundColor:
              isCurrentUser ? AppTheme.primary : color.withOpacity(0.3),
          child: Text(
            entry.displayName[0].toUpperCase(),
            style: TextStyle(
              color: isCurrentUser ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 20 : 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          entry.displayName.length > 8
              ? '${entry.displayName.substring(0, 8)}...'
              : entry.displayName,
          style: TextStyle(
              fontSize: isFirst ? 12 : 10, fontWeight: FontWeight.w500),
        ),
        Text('${entry.totalPoints} pts',
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Container(
          width: isFirst ? 80 : 65,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(isFirst ? 0.8 : 0.5),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
