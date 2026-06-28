// WHAT THIS FILE DOES:
// Displays the global rankings with a "Hall of Fame" feel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../providers/user_providers.dart';
import '../../widgets/character_avatar.dart';
import '../../widgets/neon_swirl_background.dart';

class LeaderboardTab extends ConsumerStatefulWidget {
  const LeaderboardTab({super.key});

  @override
  ConsumerState<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<LeaderboardTab>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('RANKINGS',
            style: TextStyle(
                letterSpacing: 3, fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: NeonSwirlBackground(
        colors: const [AppColors.neonAmber, AppColors.neonViolet],
        child: leaderboardAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonAmber)),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (players) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isMe = player.uid == currentUser?.uid;

              final character = kCharacters.firstWhere(
                (c) => c.id == (player.avatarUrl ?? ''),
                orElse: () => kCharacters.first,
              );

              Widget content = Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.neonViolet.withValues(alpha: 0.1)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMe ? AppColors.neonViolet : AppColors.divider,
                    width: isMe ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Rank Number
                    SizedBox(
                      width: 40,
                      child: _RankBadge(index: index),
                    ),

                    // Avatar
                    CharacterAvatar(
                      character: character,
                      size: 40,
                      showGlow: isMe,
                      showBorder: true,
                    ),

                    const SizedBox(width: 16),

                    // Name & Rank Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.username,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isMe ? FontWeight.bold : FontWeight.w600,
                              color: isMe
                                  ? AppColors.neonAmber
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text('LVL ${player.level} • ${player.rank}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),

                    // XP
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${player.xp}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.neonAmber)),
                        const Text('XP',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );

              // Staggered entrance
              final animation = CurvedAnimation(
                parent: _staggerController,
                curve: Interval(
                  (index * 0.06).clamp(0.0, 1.0),
                  ((index * 0.06) + 0.4).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              );

              content = SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: content,
                ),
              );

              // Shimmer for Top 3
              if (index < 3) {
                content = AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment(-2.0 + _shimmerController.value * 4,
                              0.0),
                          end: Alignment(
                              -1.0 + _shimmerController.value * 4, 0.0),
                          colors: const [
                            Colors.transparent,
                            Colors.white,
                            Colors.transparent
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: child,
                    );
                  },
                  child: content,
                );
              }

              return content;
            },
          );
        },
      ),
    ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int index;
  const _RankBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 0)
      return const Icon(Icons.workspace_premium,
          color: AppColors.neonAmber, size: 28);
    if (index == 1)
      return const Icon(Icons.workspace_premium,
          color: AppColors.rankSilver, size: 24);
    if (index == 2)
      return const Icon(Icons.workspace_premium,
          color: AppColors.rankBronze, size: 24);

    return Text(
      '${index + 1}',
      style: const TextStyle(
          color: AppColors.textMuted, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }
}
