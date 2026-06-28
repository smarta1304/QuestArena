// WHAT THIS FILE DOES:
// Shows the player's summary, stats, and quick-start button.
// UI updated to Dark Arena theme. All providers unchanged.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/user_providers.dart';
import '../../../data/models/match_history_model.dart';
import '../store_screen.dart';
import '../../../core/utils/rank_calculator.dart';
import '../../../ui/widgets/character_avatar.dart';
import '../../../ui/widgets/neon_swirl_background.dart';
import 'package:intl/intl.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab>
    with TickerProviderStateMixin {
  late AnimationController _heroAnim;
  late AnimationController _xpAnim;
  late AnimationController _statsAnim;
  late AnimationController _historyAnim;
  late Animation<double> _xpFill;
  double _xpTarget = 0;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _xpAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _statsAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _historyAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _xpFill = Tween<double>(begin: 0, end: 0).animate(_xpAnim);
    _runEntrance();
  }

  Future<void> _runEntrance() async {
    _heroAnim.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _statsAnim.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _historyAnim.forward();
  }

  void _startXpAnim(double target) {
    if (_xpTarget == target) return;
    _xpTarget = target;
    _xpFill = Tween<double>(begin: 0, end: target)
        .animate(CurvedAnimation(parent: _xpAnim, curve: Curves.easeOutCubic));
    _xpAnim.forward(from: 0);
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _xpAnim.dispose();
    _statsAnim.dispose();
    _historyAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgBase,
        body: Center(
          child: CircularProgressIndicator(
              color: AppColors.neonCyan, strokeWidth: 1.5),
        ),
      ),
      error: (e, s) => Scaffold(
        backgroundColor: AppColors.bgBase,
        body: Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.neonPink))),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.bgBase,
            body: Center(
                child: Text('User not found',
                    style: TextStyle(color: AppColors.textSecondary))),
          );
        }

        // ── Wire XP bar to real data ─────────────────────────────────────
        final xpRatio = (user.xp / user.xpToNextLevel).clamp(0.0, 1.0);
        _startXpAnim(xpRatio);

        // ── Rank color from existing RankCalculator ──────────────────────
        final rankColor = RankCalculator.getRankColor(user.rank);

        // ── Match character from saved avatarId, fallback to first ───────
        final character = kCharacters.firstWhere(
              (c) => c.id == (user.avatarUrl ?? ''),
          orElse: () => kCharacters.first,
        );

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          body: NeonSwirlBackground(
            colors: const [AppColors.neonAmber, AppColors.neonCyan],
            child: SafeArea(
              child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ────────────────────────────────────────────
                  FadeTransition(
                    opacity: _heroAnim,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'DASHBOARD',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const StoreScreen()));
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.neonAmber.withOpacity(0.3),
                                  width: 0.5),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.neonAmber.withOpacity(0.15),
                                    blurRadius: 8)
                              ],
                            ),
                            child: const Icon(Icons.storefront_rounded,
                                color: AppColors.neonAmber, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Profile hero card ──────────────────────────────────
                  FadeTransition(
                    opacity: _heroAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                          begin: const Offset(0, -0.12), end: Offset.zero)
                          .animate(CurvedAnimation(
                          parent: _heroAnim, curve: Curves.easeOutCubic)),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: rankColor.withOpacity(0.35), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                                color: rankColor.withOpacity(0.10),
                                blurRadius: 20,
                                spreadRadius: 2),
                          ],
                        ),
                        child: Row(
                          children: [
                            // ── Avatar (CustomPainter character) ──────────
                            CharacterAvatar(
                              character: character,
                              size: 72,
                              showGlow: true,
                              showBorder: true,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.username,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Text('Rank: ',
                                          style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                      Text(user.rank,
                                          style: TextStyle(
                                              color: rankColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // ── Animated XP bar ───────────────────
                                  AnimatedBuilder(
                                    animation: _xpFill,
                                    builder: (_, __) => Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: AppColors.bgInputField,
                                                borderRadius:
                                                BorderRadius.circular(3),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor: _xpFill.value
                                                  .clamp(0.0, 1.0),
                                              child: Container(
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                      colors: [
                                                        rankColor,
                                                        rankColor
                                                            .withOpacity(0.6)
                                                      ]),
                                                  borderRadius:
                                                  BorderRadius.circular(3),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: rankColor
                                                            .withOpacity(0.6),
                                                        blurRadius: 6),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Level ${user.level}  –  ${user.xp}/${user.xpToNextLevel} XP',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Quick Stats ────────────────────────────────────────
                  FadeTransition(
                    opacity: _statsAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                          begin: const Offset(0, 0.15), end: Offset.zero)
                          .animate(CurvedAnimation(
                          parent: _statsAnim, curve: Curves.easeOutCubic)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QUICK STATS',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  value: user.totalWins.toString(),
                                  label: 'WINS',
                                  color: AppColors.neonCyan,
                                  icon: Icons.emoji_events_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  value: user.totalLosses.toString(),
                                  label: 'LOSSES',
                                  color: AppColors.neonPink,
                                  icon: Icons.close_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Recent History ─────────────────────────────────────
                  FadeTransition(
                    opacity: _historyAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECENT HISTORY',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ref.watch(matchHistoryProvider).when(
                          loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.neonCyan, strokeWidth: 1.5)),
                          error: (e, s) => Text('History Error: $e',
                              style: const TextStyle(
                                  color: AppColors.neonPink, fontSize: 12)),
                          data: (history) {
                            if (history.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding:
                                const EdgeInsets.symmetric(vertical: 40),
                                decoration: BoxDecoration(
                                  color: AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.divider, width: 0.5),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.history_rounded,
                                        color: AppColors.textMuted
                                            .withOpacity(0.4),
                                        size: 36),
                                    const SizedBox(height: 12),
                                    const Text('No match history yet.',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    const Text(
                                        'Start a battle to see your results!',
                                        style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12)),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: history.length,
                              separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = history[index];
                                final color = item.isWin
                                    ? AppColors.neonCyan
                                    : AppColors.neonPink;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: color.withOpacity(0.2),
                                        width: 0.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          border: Border.all(
                                              color: color.withOpacity(0.4),
                                              width: 0.5),
                                        ),
                                        child: Icon(
                                            item.isWin
                                                ? Icons.check_rounded
                                                : Icons.close_rounded,
                                            color: color,
                                            size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.isWin
                                                  ? 'Victory vs ${item.opponentName}'
                                                  : 'Defeat by ${item.opponentName}',
                                              style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              '${DateFormat('MMM d, HH:mm').format(item.playedAt)}  •  ${item.myScore}-${item.opponentScore}',
                                              style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            item.isWin ? 'WIN' : 'LOSS',
                                            style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.5),
                                          ),
                                          Text('+${item.xpGained} XP',
                                              style: const TextStyle(
                                                  color: AppColors.neonAmber,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)
              ],
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
