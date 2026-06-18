import 'dart:math';

import '../config/constants.dart';

/// Daily mission model (immutable)
class DailyMission {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final int reward;
  final bool isClaimed;

  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    this.currentValue = 0,
    this.reward = GameConfig.dailyMissionReward,
    this.isClaimed = false,
  });

  bool get isComplete => currentValue >= targetValue;

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0;

  DailyMission updateProgress(int value) =>
      DailyMission(
        id: id,
        title: title,
        description: description,
        targetValue: targetValue,
        currentValue: value,
        reward: reward,
        isClaimed: isClaimed,
      );

  DailyMission claim() =>
      DailyMission(
        id: id,
        title: title,
        description: description,
        targetValue: targetValue,
        currentValue: currentValue,
        reward: reward,
        isClaimed: true,
      );

  static List<DailyMission> generateDaily() {
    final pool = List<DailyMission>.from(_missionPool);
    pool.shuffle(Random());
    return pool.take(GameConfig.dailyMissionCount).toList();
  }

  static const _missionPool = [
    DailyMission(
      id: 'daily_deliver_3',
      title: '三單達成',
      description: '完成 3 次外送',
      targetValue: 3,
    ),
    DailyMission(
      id: 'daily_deliver_5',
      title: '五單達成',
      description: '完成 5 次外送',
      targetValue: 5,
      reward: 150,
    ),
    DailyMission(
      id: 'daily_earn_500',
      title: '日賺五百',
      description: '今日收入達 \$500',
      targetValue: 500,
    ),
    DailyMission(
      id: 'daily_earn_1000',
      title: '千元大關',
      description: '今日收入達 \$1,000',
      targetValue: 1000,
      reward: 200,
    ),
    DailyMission(
      id: 'daily_on_time_3',
      title: '準時達人',
      description: '連續 3 單準時送達',
      targetValue: 3,
    ),
    DailyMission(
      id: 'daily_tip_collect',
      title: '收小費',
      description: '今天收到至少 1 次小費',
      targetValue: 1,
    ),
    DailyMission(
      id: 'daily_event_survive',
      title: '事件生存者',
      description: '成功處理 2 次隨機事件',
      targetValue: 2,
    ),
    DailyMission(
      id: 'daily_no_fail',
      title: '零失敗',
      description: '今天 0 單失敗',
      targetValue: 1, // special: 1 = maintained status
    ),
    DailyMission(
      id: 'daily_card_draw',
      title: '抽卡日',
      description: '抽到 3 張卡片',
      targetValue: 3,
    ),
    DailyMission(
      id: 'daily_rating_up',
      title: '評價提升',
      description: '今日評分提升 0.3 以上',
      targetValue: 1, // tracked as boolean
    ),
  ];
}
