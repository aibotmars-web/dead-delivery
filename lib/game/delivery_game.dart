import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/game_state.dart';
import '../models/order.dart' as models;
import '../models/player.dart';
import '../models/city_event.dart';
import '../models/event_card.dart';
import '../services/audio_service.dart';
import 'components/player_component.dart';
import 'components/map_component.dart';
import 'systems/order_spawner.dart';
import 'systems/event_system.dart';
import 'systems/achievement_checker.dart';
import 'systems/daily_system.dart';
import 'systems/police_system.dart';

class DeliveryGame extends FlameGame
    with HasCollisionDetection, TapCallbacks, DragCallbacks {
  GameState _state = GameState.initial();
  late MapComponent mapComponent;
  late PlayerComponent playerComponent;
  late _TargetMarker _targetMarker;
  late OrderSpawner _orderSpawner;
  final EventSystem _eventSystem = EventSystem();
  final AchievementChecker _achievementChecker = AchievementChecker();
  final DailySystem _dailySystem = DailySystem();
  final PoliceSystem _policeSystem = PoliceSystem();
  double _hudNotifyAccum = 0;
  double _gameClockAccum = 0;

  CityEvent? currentCityEvent;
  EventCard? currentCard;
  PoliceEncounter? currentPoliceEncounter;
  int? currentParkingFine;
  GamePhase? _phaseBeforePolice;

  final void Function(GameState state)? onStateChanged;

  DeliveryGame({this.onStateChanged});

  GameState get state => _state;

  @override
  Color backgroundColor() => Color(AppColors.bgDarkest);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.center;

    mapComponent = MapComponent();
    await world.add(mapComponent);

    _orderSpawner = OrderSpawner(map: mapComponent);

    playerComponent = PlayerComponent(
      position: Vector2(
        GameConfig.mapWidth / 2 * GameConfig.displayTileSize,
        GameConfig.mapHeight / 2 * GameConfig.displayTileSize,
      ),
    );
    await world.add(playerComponent);

    _targetMarker = _TargetMarker();
    await world.add(_targetMarker);

    camera.follow(playerComponent);

    _notifyState();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_state.isPaused || _state.isPhoneOpen) return;
    if (_state.phase == GamePhase.eventPopup ||
        _state.phase == GamePhase.cardDraw ||
        _state.phase == GamePhase.summary ||
        _state.phase == GamePhase.policeStop ||
        _state.phase == GamePhase.parkingTicket) return;

    // Phase correction: if order is active but phase drifted to freeRoam
    if (_state.activeOrder != null && _state.phase == GamePhase.freeRoam) {
      final correctedPhase =
          _state.activeOrder!.status == models.OrderStatus.pickup
              ? GamePhase.pickingUp
              : GamePhase.delivering;
      _state = _state.copyWith(phase: correctedPhase);
    }

    if (!mapComponent.isLoaded) return;

    // Detect current tile for sidewalk mechanics
    final tileX = (playerComponent.position.x / GameConfig.displayTileSize)
        .floor().clamp(0, GameConfig.mapWidth - 1);
    final tileY = (playerComponent.position.y / GameConfig.displayTileSize)
        .floor().clamp(0, GameConfig.mapHeight - 1);
    final currentTile = mapComponent.getTileAt(tileX, tileY);
    final isOnSidewalk = currentTile == TileType.sidewalk;

    // Sync riding state + sidewalk speed boost
    playerComponent.isRiding = _state.player.isRiding;
    final baseSpeed = _state.effectiveSpeed;
    final sidewalkBoost = (isOnSidewalk && _state.player.isRiding)
        ? GameConfig.sidewalkSpeedBoost : 1.0;
    playerComponent.setSpeed(baseSpeed * sidewalkBoost);

    // Speed effect decay
    if (_state.activeSpeedDuration > 0) {
      final remaining = _state.activeSpeedDuration - dt;
      if (remaining <= 0) {
        _state = _state.copyWith(
          activeSpeedMultiplier: 1.0,
          activeSpeedDuration: 0,
        );
      } else {
        _state = _state.copyWith(activeSpeedDuration: remaining);
      }
    }

    // Order timer
    if (_state.activeOrder != null) {
      final updatedOrder = _state.activeOrder!.tick(dt);
      if (updatedOrder.rewardMultiplier <= 0) {
        final failedOrder = updatedOrder.fail();
        _state = _state.copyWith(
          player: _state.player.copyWith(
            rating: (_state.player.rating - 0.3).clamp(1.0, 5.0),
          ),
          completedOrders: [..._state.completedOrders, failedOrder],
          clearActiveOrder: true,
          phase: GamePhase.freeRoam,
        );
        _targetMarker.target = null;
        _notifyState();
      } else {
        _state = _state.copyWith(activeOrder: updatedOrder);
      }
    }

    // Game clock: 1 real second = 1 game minute
    _gameClockAccum += dt;
    if (_gameClockAccum >= 1.0) {
      final minutesToAdd = _gameClockAccum.toInt();
      _gameClockAccum -= minutesToAdd;
      final newMinute = _state.gameMinute + minutesToAdd;
      _state = _state.copyWith(gameMinute: newMinute);

      // Day ends at 23:00 (1380 minutes)
      if (newMinute >= 1380 && _state.activeOrder == null) {
        _state = _state.copyWith(phase: GamePhase.summary);
        _notifyState();
        return;
      }
    }

    // Throttled HUD notification (~4 times/sec for smooth timer)
    _hudNotifyAccum += dt;
    if (_hudNotifyAccum >= 0.25) {
      _hudNotifyAccum = 0;
      _notifyState();
    }

    // Spawn new orders (stop spawning after 22:00)
    if (_state.gameMinute < 1320) {
      final newOrder = _orderSpawner.tick(dt, _state.availableOrders.length);
      if (newOrder != null) {
        _state = _state.copyWith(
          availableOrders: [..._state.availableOrders, newOrder],
        );
        _notifyState();
      }
    }

    // Proximity detection — auto pickup / deliver
    if (_state.activeOrder != null) {
      final pPos = playerComponent.position;
      final threshold = GameConfig.displayTileSize * 1.8;

      if (_state.phase == GamePhase.pickingUp) {
        final target = Vector2(
            _state.activeOrder!.pickupX, _state.activeOrder!.pickupY);
        if (pPos.distanceTo(target) < threshold) {
          pickUpOrder();
        }
      } else if (_state.phase == GamePhase.delivering) {
        final target = Vector2(
            _state.activeOrder!.deliveryX, _state.activeOrder!.deliveryY);
        if (pPos.distanceTo(target) < threshold) {
          deliverOrder();
        }
      }
    }

    // Update target marker based on order status, not just phase
    if (_state.activeOrder != null) {
      if (_state.activeOrder!.status == models.OrderStatus.pickup) {
        _targetMarker.target = Vector2(
            _state.activeOrder!.pickupX, _state.activeOrder!.pickupY);
        _targetMarker.isPickup = true;
      } else if (_state.activeOrder!.status == models.OrderStatus.delivering) {
        _targetMarker.target = Vector2(
            _state.activeOrder!.deliveryX, _state.activeOrder!.deliveryY);
        _targetMarker.isPickup = false;
      }
    } else {
      _targetMarker.target = null;
    }

    // City events
    if (_state.activeOrder != null &&
        _state.phase == GamePhase.delivering) {
      final event = _eventSystem.tickCityEvent(dt);
      if (event != null) {
        currentCityEvent = event;
        _state = _state.copyWith(phase: GamePhase.eventPopup);
        AudioService.instance.playSfx(SfxType.eventPopup);
        _notifyState();
        return;
      }
    }

    // Police check: riding on sidewalk = risk of getting caught
    if (playerComponent.isMoving && _state.player.isRiding) {
      final encounter = _policeSystem.checkSidewalk(
          dt, isOnSidewalk, _state.player.isRiding);
      if (encounter != null) {
        currentPoliceEncounter = encounter;
        _phaseBeforePolice = _state.phase;
        playerComponent.stop();
        _state = _state.copyWith(phase: GamePhase.policeStop);
        AudioService.instance.playSfx(SfxType.policeSiren);
        _notifyState();
      }
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_state.isPaused || _state.isPhoneOpen) return;
    if (_state.phase != GamePhase.freeRoam &&
        _state.phase != GamePhase.pickingUp &&
        _state.phase != GamePhase.delivering) return;

    final worldPos = camera.globalToLocal(event.canvasPosition);

    // Find nearest walkable tile as destination
    final dest = mapComponent.findNearestWalkable(worldPos);
    if (dest == null) return;

    // Use A* pathfinding — riding scooter prefers sidewalks (faster but risky)
    final path = mapComponent.findPath(
      playerComponent.position, dest,
      preferSidewalks: _state.player.isRiding,
    );
    if (path != null && path.isNotEmpty) {
      playerComponent.moveAlongPath(path);
    } else {
      // Fallback: direct move to nearest walkable
      playerComponent.moveTo(dest);
    }
  }

  // ── Public API for Flutter UI ──

  void acceptOrder(int index) {
    if (index >= _state.availableOrders.length) return;
    if (_state.activeOrder != null) return;

    final order = _state.availableOrders[index].accept();
    final remaining = List<models.Order>.from(_state.availableOrders)
      ..removeAt(index);
    _state = _state.copyWith(
      activeOrder: order,
      availableOrders: remaining,
      phase: GamePhase.pickingUp,
    );
    AudioService.instance.playSfx(SfxType.orderAccept);
    _notifyState();
    _resumePathToTarget(GamePhase.pickingUp);
  }

  void pickUpOrder() {
    if (_state.activeOrder == null) return;
    _state = _state.copyWith(
      activeOrder: _state.activeOrder!.pickUp(),
      phase: GamePhase.delivering,
    );
    AudioService.instance.playSfx(SfxType.pickup);
    _notifyState();
    _resumePathToTarget(GamePhase.delivering);
  }

  void deliverOrder() {
    if (_state.activeOrder == null) return;
    final delivered = _state.activeOrder!.deliver();
    final earnings = delivered.totalEarnings;

    // Rating adjustment based on delivery speed
    final ratingDelta = delivered.isOverTime ? -0.1 : 0.1;

    var player = _state.player.copyWith(
      money: _state.player.money + earnings,
      totalDeliveries: _state.player.totalDeliveries + 1,
      todayDeliveries: _state.player.todayDeliveries + 1,
      todayEarnings: _state.player.todayEarnings + earnings,
      rating: (_state.player.rating + ratingDelta).clamp(1.0, 5.0),
    );

    // Check parking line for red line ticket
    final ptx = (playerComponent.position.x / GameConfig.displayTileSize)
        .floor().clamp(0, GameConfig.mapWidth - 1);
    final pty = (playerComponent.position.y / GameConfig.displayTileSize)
        .floor().clamp(0, GameConfig.mapHeight - 1);
    final parkingLine = mapComponent.getParkingLineAt(ptx, pty);
    final isRedLine = parkingLine == ParkingLine.red;
    final ticketFine = _policeSystem.checkParkingTicket(isRedLine);

    // If got a ticket, show parking ticket phase first
    final nextPhase = ticketFine != null
        ? GamePhase.parkingTicket
        : GamePhase.cardDraw;
    if (ticketFine != null) {
      currentParkingFine = ticketFine;
    }

    _state = _state.copyWith(
      player: player,
      completedOrders: [..._state.completedOrders, delivered],
      clearActiveOrder: true,
      phase: nextPhase,
    );

    _state = _state.copyWith(
      dailyMissions: _dailySystem.updateMissionProgress(
        _state.dailyMissions, MissionAction.delivery, 1),
    );
    _state = _state.copyWith(
      dailyMissions: _dailySystem.updateMissionProgress(
        _state.dailyMissions, MissionAction.earn, earnings),
    );

    if (delivered.tip != null && delivered.tip! > 0) {
      _state = _state.copyWith(
        dailyMissions: _dailySystem.updateMissionProgress(
          _state.dailyMissions, MissionAction.tipReceived, 1),
      );
    }

    if (!delivered.isOverTime) {
      _state = _state.copyWith(
        dailyMissions: _dailySystem.updateMissionProgress(
          _state.dailyMissions, MissionAction.onTime, 1),
      );
    }

    final result = _achievementChecker.check(_state);
    if (result.newlyEarned.isNotEmpty) {
      _state = _state.copyWith(player: result.player);
      AudioService.instance.playSfx(SfxType.achievement);
    }

    AudioService.instance.playSfx(SfxType.deliver);
    currentCard = _eventSystem.drawCard();
    if (currentCard != null && currentCard!.type == CardType.rare) {
      AudioService.instance.playSfx(SfxType.cardRare);
    } else {
      AudioService.instance.playSfx(SfxType.cardDraw);
    }
    _targetMarker.target = null;
    _notifyState();
  }

  void applyCurrentCard() {
    if (currentCard == null) return;
    _state = _eventSystem.applyCard(_state, currentCard!);

    _state = _state.copyWith(
      dailyMissions: _dailySystem.updateMissionProgress(
        _state.dailyMissions, MissionAction.cardDrawn, 1),
    );

    currentCard = null;
    _notifyState();
  }

  void applyCityEventChoice(EventChoice choice) {
    if (currentCityEvent == null) return;
    _state = _eventSystem.applyCityEventChoice(_state, choice);

    _state = _state.copyWith(
      dailyMissions: _dailySystem.updateMissionProgress(
        _state.dailyMissions, MissionAction.eventSurvived, 1),
    );

    currentCityEvent = null;
    _notifyState();
    _resumePathToTarget(_state.phase);
  }

  void dismissPoliceStop() {
    if (currentPoliceEncounter == null) return;
    final fine = currentPoliceEncounter!.fine;
    final timePenalty = currentPoliceEncounter!.timePenalty;

    var player = _state.player.copyWith(
      money: (_state.player.money - fine).clamp(0, 999999),
    );

    // Add time penalty to active order if exists
    var order = _state.activeOrder;
    if (order != null) {
      order = order.addTimePenalty(timePenalty.toDouble());
    }

    final resumePhase = _phaseBeforePolice ?? GamePhase.freeRoam;
    _state = _state.copyWith(
      player: player,
      activeOrder: order,
      phase: resumePhase,
    );
    currentPoliceEncounter = null;
    _phaseBeforePolice = null;
    _notifyState();
    _resumePathToTarget(resumePhase);
  }

  void _resumePathToTarget(GamePhase phase) {
    if (_state.activeOrder == null || !mapComponent.isLoaded) return;
    Vector2? dest;
    if (phase == GamePhase.pickingUp) {
      dest = Vector2(_state.activeOrder!.pickupX, _state.activeOrder!.pickupY);
    } else if (phase == GamePhase.delivering) {
      dest = Vector2(_state.activeOrder!.deliveryX, _state.activeOrder!.deliveryY);
    }
    if (dest == null) return;
    final walkable = mapComponent.findNearestWalkable(dest);
    if (walkable == null) return;
    final path = mapComponent.findPath(
      playerComponent.position, walkable,
      preferSidewalks: _state.player.isRiding,
    );
    if (path != null && path.isNotEmpty) {
      playerComponent.moveAlongPath(path);
    } else {
      playerComponent.moveTo(walkable);
    }
  }

  void dismissParkingTicket() {
    if (currentParkingFine == null) return;
    AudioService.instance.playSfx(SfxType.parkingTicket);
    _state = _state.copyWith(
      player: _state.player.copyWith(
        money: (_state.player.money - currentParkingFine!).clamp(0, 999999),
      ),
      phase: GamePhase.cardDraw,
    );
    currentParkingFine = null;
    _notifyState();
  }

  void claimDailyMission(int index) {
    _state = _dailySystem.claimMission(_state, index);
    AudioService.instance.playSfx(SfxType.coin);
    _notifyState();
  }

  void toggleMount() {
    final willRide = !_state.player.isRiding;
    _state = _state.copyWith(
      player: _state.player.copyWith(isRiding: willRide),
    );
    AudioService.instance.playSfx(
        willRide ? SfxType.scooterStart : SfxType.scooterStop);
    _notifyState();
  }

  void upgradeScooter() {
    final cost = _state.player.scooter.upgradeCost;
    if (cost == null || _state.player.money < cost) return;
    _state = _state.copyWith(
      player: _state.player.copyWith(
        money: _state.player.money - cost,
        scooter: _state.player.scooter.upgrade(),
      ),
    );
    AudioService.instance.playSfx(SfxType.coin);
    final result = _achievementChecker.check(_state);
    if (result.newlyEarned.isNotEmpty) {
      _state = _state.copyWith(player: result.player);
    }
    _notifyState();
  }

  void upgradeBag() {
    final cost = _state.player.bag.upgradeCost;
    if (cost == null || _state.player.money < cost) return;
    _state = _state.copyWith(
      player: _state.player.copyWith(
        money: _state.player.money - cost,
        bag: _state.player.bag.upgrade(),
      ),
    );
    AudioService.instance.playSfx(SfxType.coin);
    final result = _achievementChecker.check(_state);
    if (result.newlyEarned.isNotEmpty) {
      _state = _state.copyWith(player: result.player);
    }
    _notifyState();
  }

  void togglePhone() {
    _state = _state.copyWith(isPhoneOpen: !_state.isPhoneOpen);
    _notifyState();
  }

  void togglePause() {
    _state = _state.copyWith(isPaused: !_state.isPaused);
    _notifyState();
  }

  void processNextDay() {
    _state = _dailySystem.processNewDay(_state);
    _state = _state.copyWith(
      gameMinute: 660, // Reset to 11:00 AM
      phase: GamePhase.freeRoam,
      clearActiveOrder: true,
      availableOrders: const [],
    );
    _gameClockAccum = 0;
    _hudNotifyAccum = 0;
    _orderSpawner.reset();
    _eventSystem.reset();
    _policeSystem.reset();
    AudioService.instance.playSfx(SfxType.dayEnd);
    _notifyState();
  }

  void dismissTutorial() {
    _state = _state.copyWith(showTutorial: false);
    _notifyState();
  }

  void loadPlayer(Player loadedPlayer) {
    _state = _state.copyWith(player: loadedPlayer);
    _notifyState();
  }

  void setPhase(GamePhase phase) {
    _state = _state.copyWith(phase: phase);
    _notifyState();
  }

  void _notifyState() {
    onStateChanged?.call(_state);
  }
}

/// Pulsing marker that shows where restaurant/customer is
class _TargetMarker extends PositionComponent {
  Vector2? target;
  bool isPickup = true;
  double _pulse = 0;

  _TargetMarker() : super(priority: 50);

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt * 3;
    if (_pulse > pi * 2) _pulse -= pi * 2;
  }

  @override
  void render(Canvas canvas) {
    if (target == null) return;

    final px = target!.x;
    final py = target!.y;
    final pulseSize = 8 + sin(_pulse) * 4;
    final alpha = (150 + (sin(_pulse) * 80)).toInt().clamp(80, 230);

    final color = isPickup
        ? Color.fromARGB(alpha, 255, 215, 0) // gold for pickup
        : Color.fromARGB(alpha, 78, 205, 196); // teal for delivery

    // Outer glow
    canvas.drawCircle(
      Offset(px, py),
      pulseSize + 8,
      Paint()..color = color.withAlpha(40),
    );

    // Main ring
    canvas.drawCircle(
      Offset(px, py),
      pulseSize,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Center dot
    canvas.drawCircle(
      Offset(px, py),
      3,
      Paint()..color = color,
    );

    // Arrow above
    final arrowY = py - pulseSize - 12 + sin(_pulse * 2) * 3;
    final arrowPath = Path()
      ..moveTo(px, arrowY + 8)
      ..lineTo(px - 5, arrowY)
      ..lineTo(px + 5, arrowY)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = color);

    // Label
    final label = isPickup ? '🍜 取餐' : '📦 送達';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(px - tp.width / 2, arrowY - 16));
  }
}
