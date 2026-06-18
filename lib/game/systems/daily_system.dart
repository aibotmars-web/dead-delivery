import '../../config/constants.dart';
import '../../models/daily_mission.dart';
import '../../models/game_state.dart';


/// Manages daily missions, login streaks, and day transitions
class DailySystem {
  /// Process a new day: reset daily counters, generate missions, update streak
  GameState processNewDay(GameState state) {
    final player = state.player;
    final now = DateTime.now();
    final lastLogin = player.lastLoginDate;

    // Calculate streak
    final dayDiff = now.difference(lastLogin).inDays;
    final newStreak = dayDiff == 1
        ? player.loginStreak + 1
        : dayDiff == 0
            ? player.loginStreak
            : 1; // reset if missed a day

    // Login streak reward
    final streakIndex =
        (newStreak - 1).clamp(0, GameConfig.loginStreakRewards.length - 1);
    final streakReward = GameConfig.loginStreakRewards[streakIndex];

    final updatedPlayer = player.copyWith(
      todayDeliveries: 0,
      todayEarnings: 0,
      loginStreak: newStreak,
      lastLoginDate: now,
      dayNumber: player.dayNumber + 1,
      money: player.money + streakReward,
    );

    return state.copyWith(
      player: updatedPlayer,
      dailyMissions: DailyMission.generateDaily(),
      completedOrders: const [],
      recentCards: const [],
    );
  }

  /// Update mission progress based on action type
  List<DailyMission> updateMissionProgress(
    List<DailyMission> missions,
    MissionAction action,
    int value,
  ) {
    return missions.map((mission) {
      final newValue = switch (action) {
        MissionAction.delivery when mission.id.contains('deliver') =>
          mission.currentValue + value,
        MissionAction.earn when mission.id.contains('earn') =>
          mission.currentValue + value,
        MissionAction.onTime when mission.id == 'daily_on_time_3' =>
          mission.currentValue + value,
        MissionAction.tipReceived when mission.id == 'daily_tip_collect' =>
          mission.currentValue + value,
        MissionAction.eventSurvived when mission.id == 'daily_event_survive' =>
          mission.currentValue + value,
        MissionAction.cardDrawn when mission.id == 'daily_card_draw' =>
          mission.currentValue + value,
        _ => null,
      };
      if (newValue != null) return mission.updateProgress(newValue);
      return mission;
    }).toList();
  }

  /// Claim a completed mission reward. Returns updated state.
  GameState claimMission(GameState state, int missionIndex) {
    if (missionIndex >= state.dailyMissions.length) return state;

    final mission = state.dailyMissions[missionIndex];
    if (!mission.isComplete || mission.isClaimed) return state;

    final updatedMissions = List<DailyMission>.from(state.dailyMissions);
    updatedMissions[missionIndex] = mission.claim();

    var player = state.player.addMoney(mission.reward);

    // Check if all missions complete → bonus
    final allClaimed = updatedMissions.every((m) => m.isClaimed);
    if (allClaimed) {
      player = player.addMoney(GameConfig.dailyMissionBonusAll);
    }

    return state.copyWith(
      player: player,
      dailyMissions: updatedMissions,
    );
  }
}

enum MissionAction {
  delivery,
  earn,
  onTime,
  tipReceived,
  eventSurvived,
  cardDrawn,
}
