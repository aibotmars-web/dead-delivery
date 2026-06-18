/// Achievement definition (immutable)
class Achievement {
  final String id;
  final String title;
  final String description;
  final int rewardMoney;
  final bool Function(AchievementContext) check;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardMoney,
    required this.check,
  });

  static final allAchievements = [
    Achievement(
      id: 'first_delivery',
      title: '第一單！',
      description: '完成第一次外送',
      rewardMoney: 100,
      check: (ctx) => ctx.totalDeliveries >= 1,
    ),
    Achievement(
      id: 'delivery_10',
      title: '新手上路',
      description: '完成 10 次外送',
      rewardMoney: 300,
      check: (ctx) => ctx.totalDeliveries >= 10,
    ),
    Achievement(
      id: 'delivery_50',
      title: '外送老手',
      description: '完成 50 次外送',
      rewardMoney: 1000,
      check: (ctx) => ctx.totalDeliveries >= 50,
    ),
    Achievement(
      id: 'delivery_100',
      title: '外送達人',
      description: '完成 100 次外送',
      rewardMoney: 3000,
      check: (ctx) => ctx.totalDeliveries >= 100,
    ),
    Achievement(
      id: 'rich_10k',
      title: '小有積蓄',
      description: '累計賺到 \$10,000',
      rewardMoney: 500,
      check: (ctx) => ctx.totalEarnings >= 10000,
    ),
    Achievement(
      id: 'rich_50k',
      title: '台灣夢',
      description: '累計賺到 \$50,000',
      rewardMoney: 2000,
      check: (ctx) => ctx.totalEarnings >= 50000,
    ),
    Achievement(
      id: 'rating_5',
      title: '滿分評價',
      description: '評分達到 5.0 星',
      rewardMoney: 500,
      check: (ctx) => ctx.rating >= 5.0,
    ),
    Achievement(
      id: 'upgrade_scooter_max',
      title: 'Gogoro 車主',
      description: '機車升級到最高等級',
      rewardMoney: 1000,
      check: (ctx) => ctx.scooterLevel >= 3,
    ),
    Achievement(
      id: 'upgrade_bag_max',
      title: '保溫王',
      description: '外送箱升級到最高等級',
      rewardMoney: 1000,
      check: (ctx) => ctx.bagLevel >= 3,
    ),
    Achievement(
      id: 'login_7',
      title: '天天外送',
      description: '連續登入 7 天',
      rewardMoney: 1500,
      check: (ctx) => ctx.loginStreak >= 7,
    ),
  ];
}

/// Context passed to achievement checks
class AchievementContext {
  final int totalDeliveries;
  final int totalEarnings;
  final double rating;
  final int scooterLevel;
  final int bagLevel;
  final int loginStreak;

  const AchievementContext({
    required this.totalDeliveries,
    required this.totalEarnings,
    required this.rating,
    required this.scooterLevel,
    required this.bagLevel,
    required this.loginStreak,
  });
}
