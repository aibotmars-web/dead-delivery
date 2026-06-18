import 'equipment.dart';
import '../config/constants.dart';

/// Player state model (immutable)
class Player {
  final String name;
  final int money;
  final double rating;
  final int totalDeliveries;
  final int todayDeliveries;
  final int todayEarnings;
  final int loginStreak;
  final DateTime lastLoginDate;
  final Equipment scooter;
  final Equipment bag;
  final List<String> achievements;
  final int dayNumber;
  final bool isRiding;

  const Player({
    required this.name,
    required this.money,
    required this.rating,
    required this.totalDeliveries,
    required this.todayDeliveries,
    required this.todayEarnings,
    required this.loginStreak,
    required this.lastLoginDate,
    required this.scooter,
    required this.bag,
    required this.achievements,
    required this.dayNumber,
    this.isRiding = false,
  });

  factory Player.newPlayer({String name = '外送哥'}) {
    return Player(
      name: name,
      money: GameConfig.startingMoney,
      rating: GameConfig.startingRating,
      totalDeliveries: 0,
      todayDeliveries: 0,
      todayEarnings: 0,
      loginStreak: 1,
      lastLoginDate: DateTime.now(),
      scooter: Equipment.defaultScooter(),
      bag: Equipment.defaultBag(),
      achievements: const [],
      dayNumber: 1,
    );
  }

  Player copyWith({
    String? name,
    int? money,
    double? rating,
    int? totalDeliveries,
    int? todayDeliveries,
    int? todayEarnings,
    int? loginStreak,
    DateTime? lastLoginDate,
    Equipment? scooter,
    Equipment? bag,
    List<String>? achievements,
    int? dayNumber,
    bool? isRiding,
  }) {
    return Player(
      name: name ?? this.name,
      money: money ?? this.money,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      todayDeliveries: todayDeliveries ?? this.todayDeliveries,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      loginStreak: loginStreak ?? this.loginStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      scooter: scooter ?? this.scooter,
      bag: bag ?? this.bag,
      achievements: achievements ?? this.achievements,
      dayNumber: dayNumber ?? this.dayNumber,
      isRiding: isRiding ?? this.isRiding,
    );
  }

  double get moveSpeed {
    if (!isRiding) return GameConfig.walkSpeed;
    return switch (scooter.level) {
      1 => GameConfig.scooterSpeedLv1,
      2 => GameConfig.scooterSpeedLv2,
      3 => GameConfig.scooterSpeedLv3,
      _ => GameConfig.scooterSpeedLv1,
    };
  }

  double get foodSpillChance {
    return switch (scooter.level) {
      1 => 0.15,
      2 => 0.08,
      3 => 0.03,
      _ => 0.15,
    };
  }

  double get foodCoolRate {
    return switch (bag.level) {
      1 => 5.0, // -5% per minute
      2 => 2.0,
      3 => 0.5,
      _ => 5.0,
    };
  }

  bool hasAchievement(String id) => achievements.contains(id);

  Player addMoney(int amount) => copyWith(money: money + amount);

  Player addAchievement(String id) {
    if (hasAchievement(id)) return this;
    return copyWith(achievements: [...achievements, id]);
  }

  Player adjustRating(double delta) {
    final newRating = (rating + delta).clamp(1.0, 5.0);
    return copyWith(rating: newRating);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'money': money,
    'rating': rating,
    'totalDeliveries': totalDeliveries,
    'todayDeliveries': todayDeliveries,
    'todayEarnings': todayEarnings,
    'loginStreak': loginStreak,
    'lastLoginDate': lastLoginDate.toIso8601String(),
    'scooterLevel': scooter.level,
    'bagLevel': bag.level,
    'achievements': achievements,
    'dayNumber': dayNumber,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] as String? ?? '外送哥',
      money: json['money'] as int? ?? GameConfig.startingMoney,
      rating: (json['rating'] as num?)?.toDouble() ?? GameConfig.startingRating,
      totalDeliveries: json['totalDeliveries'] as int? ?? 0,
      todayDeliveries: json['todayDeliveries'] as int? ?? 0,
      todayEarnings: json['todayEarnings'] as int? ?? 0,
      loginStreak: json['loginStreak'] as int? ?? 1,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'] as String)
          : DateTime.now(),
      scooter: Equipment.scooterAtLevel(json['scooterLevel'] as int? ?? 1),
      bag: Equipment.bagAtLevel(json['bagLevel'] as int? ?? 1),
      achievements: (json['achievements'] as List<dynamic>?)
              ?.cast<String>() ?? const [],
      dayNumber: json['dayNumber'] as int? ?? 1,
    );
  }
}
