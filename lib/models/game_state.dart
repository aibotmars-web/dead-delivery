import 'player.dart';
import 'order.dart';
import 'event_card.dart';
import 'daily_mission.dart';

/// Top-level game state (immutable)
class GameState {
  final Player player;
  final Order? activeOrder;
  final List<Order> availableOrders;
  final List<Order> completedOrders;
  final List<EventCard> recentCards;
  final List<DailyMission> dailyMissions;
  final double activeSpeedMultiplier;
  final double activeSpeedDuration; // remaining seconds
  final bool isPaused;
  final bool isPhoneOpen;
  final GamePhase phase;
  final int gameMinute; // 0-1440, game clock (660 = 11:00 AM)
  final bool showTutorial;

  const GameState({
    required this.player,
    this.activeOrder,
    this.availableOrders = const [],
    this.completedOrders = const [],
    this.recentCards = const [],
    this.dailyMissions = const [],
    this.activeSpeedMultiplier = 1.0,
    this.activeSpeedDuration = 0,
    this.isPaused = false,
    this.isPhoneOpen = false,
    this.phase = GamePhase.freeRoam,
    this.gameMinute = 660, // 11:00 AM
    this.showTutorial = false,
  });

  factory GameState.initial({bool isNewPlayer = true}) => GameState(
    player: Player.newPlayer(),
    dailyMissions: DailyMission.generateDaily(),
    showTutorial: isNewPlayer,
  );

  String get gameTimeString {
    final hour = (gameMinute ~/ 60).toString().padLeft(2, '0');
    final min = (gameMinute % 60).toString().padLeft(2, '0');
    return '$hour:$min';
  }

  GameState copyWith({
    Player? player,
    Order? activeOrder,
    bool clearActiveOrder = false,
    List<Order>? availableOrders,
    List<Order>? completedOrders,
    List<EventCard>? recentCards,
    List<DailyMission>? dailyMissions,
    double? activeSpeedMultiplier,
    double? activeSpeedDuration,
    bool? isPaused,
    bool? isPhoneOpen,
    GamePhase? phase,
    int? gameMinute,
    bool? showTutorial,
  }) {
    return GameState(
      player: player ?? this.player,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      availableOrders: availableOrders ?? this.availableOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      recentCards: recentCards ?? this.recentCards,
      dailyMissions: dailyMissions ?? this.dailyMissions,
      activeSpeedMultiplier:
          activeSpeedMultiplier ?? this.activeSpeedMultiplier,
      activeSpeedDuration:
          activeSpeedDuration ?? this.activeSpeedDuration,
      isPaused: isPaused ?? this.isPaused,
      isPhoneOpen: isPhoneOpen ?? this.isPhoneOpen,
      phase: phase ?? this.phase,
      gameMinute: gameMinute ?? this.gameMinute,
      showTutorial: showTutorial ?? this.showTutorial,
    );
  }

  double get effectiveSpeed =>
      player.moveSpeed * activeSpeedMultiplier;

  int get todayCompletedCount =>
      completedOrders
          .where((o) => o.status == OrderStatus.delivered)
          .length;

  bool get allDailyMissionsComplete =>
      dailyMissions.every((m) => m.isComplete);

  bool get allDailyMissionsClaimed =>
      dailyMissions.every((m) => m.isClaimed);
}

enum GamePhase {
  freeRoam,      // 自由移動中
  pickingUp,     // 前往餐廳取餐
  delivering,    // 送餐途中
  eventPopup,    // 事件彈窗
  cardDraw,      // 抽卡動畫
  summary,       // 每日結算
  policeStop,    // 警察臨檢
  parkingTicket, // 停車罰單
}
