import 'dart:math';

import '../config/constants.dart';

enum OrderStatus { idle, pickup, delivering, delivered, failed }

/// Delivery order model (immutable)
class Order {
  final String id;
  final String restaurantName;
  final String customerName;
  final String foodName;
  final int reward;
  final int timeLimitSeconds;
  final double pickupX;
  final double pickupY;
  final double deliveryX;
  final double deliveryY;
  final OrderStatus status;
  final double elapsedSeconds;
  final double foodQuality; // 0.0 - 1.0
  final int? tip;

  const Order({
    required this.id,
    required this.restaurantName,
    required this.customerName,
    required this.foodName,
    required this.reward,
    required this.timeLimitSeconds,
    required this.pickupX,
    required this.pickupY,
    required this.deliveryX,
    required this.deliveryY,
    this.status = OrderStatus.idle,
    this.elapsedSeconds = 0,
    this.foodQuality = 1.0,
    this.tip,
  });

  Order copyWith({
    OrderStatus? status,
    double? elapsedSeconds,
    double? foodQuality,
    int? tip,
  }) {
    return Order(
      id: id,
      restaurantName: restaurantName,
      customerName: customerName,
      foodName: foodName,
      reward: reward,
      timeLimitSeconds: timeLimitSeconds,
      pickupX: pickupX,
      pickupY: pickupY,
      deliveryX: deliveryX,
      deliveryY: deliveryY,
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      foodQuality: foodQuality ?? this.foodQuality,
      tip: tip ?? this.tip,
    );
  }

  double get remainingSeconds =>
      (timeLimitSeconds - elapsedSeconds).clamp(0, timeLimitSeconds.toDouble());

  bool get isOverTime => elapsedSeconds > timeLimitSeconds;

  double get rewardMultiplier {
    final overtime = elapsedSeconds - timeLimitSeconds;
    if (overtime <= -60) return GameConfig.earlyMultiplier; // 1min early
    if (overtime <= 0) return GameConfig.onTimeMultiplier;
    if (overtime <= 120) return GameConfig.lateMultiplier1;
    if (overtime <= 300) return GameConfig.lateMultiplier2;
    return 0.0; // too late, order fails
  }

  int get finalReward => (reward * rewardMultiplier).round();

  int get totalEarnings => finalReward + (tip ?? 0);

  Order accept() => copyWith(status: OrderStatus.pickup);

  Order pickUp() => copyWith(status: OrderStatus.delivering);

  Order deliver() {
    final tipAmount = _rollTip();
    return copyWith(
      status: OrderStatus.delivered,
      tip: tipAmount,
    );
  }

  Order fail() => copyWith(status: OrderStatus.failed);

  Order tick(double dt) => copyWith(
    elapsedSeconds: elapsedSeconds + dt,
  );

  Order addTimePenalty(double seconds) => copyWith(
    elapsedSeconds: elapsedSeconds + seconds,
  );

  Order degradeFood(double rate) {
    final newQuality = (foodQuality - rate).clamp(0.0, 1.0);
    return copyWith(foodQuality: newQuality);
  }

  static int _rollTip() {
    final roll = Random().nextDouble();
    if (roll < GameConfig.tipNoneChance) return 0;
    if (roll < GameConfig.tipNoneChance + GameConfig.tipSmallChance) {
      return 10 + Random().nextInt(21); // 10-30
    }
    if (roll <
        GameConfig.tipNoneChance +
            GameConfig.tipSmallChance +
            GameConfig.tipMediumChance) {
      return 50 + Random().nextInt(51); // 50-100
    }
    return 200 + Random().nextInt(101); // 200-300
  }

  static final _restaurants = [
    '鼎泰豐', '50嵐', '麥當勞', '路邊滷味', '夜市雞排',
    '便當快餐', '手搖飲料店', '拉麵屋', '燒烤店',
  ];

  static final _customers = [
    '陳先生', '林小姐', '王同學', '張阿姨', '李大哥',
    '黃太太', '吳小弟', '劉奶奶', '蔡老闆',
  ];

  static final _foods = [
    '小籠包', '珍珠奶茶', '大麥克套餐', '滷味拼盤', '雞排加大',
    '排骨便當', '芋頭牛奶', '豚骨拉麵', '烤肉串',
  ];

  factory Order.random({
    required double pickupX,
    required double pickupY,
    required double deliveryX,
    required double deliveryY,
  }) {
    final rng = Random();
    return Order(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      restaurantName: _restaurants[rng.nextInt(_restaurants.length)],
      customerName: _customers[rng.nextInt(_customers.length)],
      foodName: _foods[rng.nextInt(_foods.length)],
      reward: GameConfig.minOrderReward +
          rng.nextInt(GameConfig.maxOrderReward - GameConfig.minOrderReward),
      timeLimitSeconds: GameConfig.minTimeLimit +
          rng.nextInt(GameConfig.maxTimeLimit - GameConfig.minTimeLimit),
      pickupX: pickupX,
      pickupY: pickupY,
      deliveryX: deliveryX,
      deliveryY: deliveryY,
    );
  }
}
