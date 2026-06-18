import '../../models/achievement.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';

/// Checks and awards achievements after state changes
class AchievementChecker {
  /// Check all achievements against current state.
  /// Returns updated player with newly earned achievements and total bonus money.
  ({Player player, List<Achievement> newlyEarned}) check(GameState state) {
    final ctx = AchievementContext(
      totalDeliveries: state.player.totalDeliveries,
      totalEarnings: state.player.money, // simplified: use current money
      rating: state.player.rating,
      scooterLevel: state.player.scooter.level,
      bagLevel: state.player.bag.level,
      loginStreak: state.player.loginStreak,
    );

    var player = state.player;
    final newlyEarned = <Achievement>[];

    for (final achievement in Achievement.allAchievements) {
      if (player.hasAchievement(achievement.id)) continue;
      if (achievement.check(ctx)) {
        player = player
            .addAchievement(achievement.id)
            .addMoney(achievement.rewardMoney);
        newlyEarned.add(achievement);
      }
    }

    return (player: player, newlyEarned: newlyEarned);
  }
}
