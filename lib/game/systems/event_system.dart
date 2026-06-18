import 'dart:math';

import '../../config/constants.dart';
import '../../models/city_event.dart';
import '../../models/event_card.dart';
import '../../models/game_state.dart';


/// Manages random city events and card draws
class EventSystem {
  final Random _rng = Random();
  double _timeSinceLastCheck = 0;

  /// Check for city events periodically. Returns event or null.
  CityEvent? tickCityEvent(double dt) {
    _timeSinceLastCheck += dt;

    if (_timeSinceLastCheck < GameConfig.cityEventCheckInterval) return null;
    _timeSinceLastCheck = 0;

    if (_rng.nextDouble() > GameConfig.cityEventChance) return null;

    return CityEvent.tryTrigger();
  }

  /// Draw a card after completing a delivery
  EventCard drawCard() => EventCard.draw();

  /// Apply a city event choice to game state (returns new state)
  GameState applyCityEventChoice(GameState state, EventChoice choice) {
    var player = state.player;

    // Money effect
    if (choice.moneyEffect != 0) {
      player = player.addMoney(choice.moneyEffect);
    }

    // Rating effect
    if (choice.ratingEffect != 0) {
      player = player.adjustRating(choice.ratingEffect);
    }

    // Speed effect with duration
    double speedMult = state.activeSpeedMultiplier;
    double speedDur = state.activeSpeedDuration;
    if (choice.speedEffect != 1.0 && choice.durationSeconds > 0) {
      speedMult = choice.speedEffect;
      speedDur = choice.durationSeconds.toDouble();
    }

    return state.copyWith(
      player: player,
      activeSpeedMultiplier: speedMult,
      activeSpeedDuration: speedDur,
      phase: GamePhase.delivering,
    );
  }

  /// Apply a drawn card's effects to game state (returns new state)
  GameState applyCard(GameState state, EventCard card) {
    var player = state.player;

    if (card.moneyEffect != 0) {
      player = player.addMoney(card.moneyEffect);
    }
    if (card.ratingEffect != 0) {
      player = player.adjustRating(card.ratingEffect);
    }

    double speedMult = state.activeSpeedMultiplier;
    double speedDur = state.activeSpeedDuration;
    if (card.speedEffect != 1.0 && card.durationSeconds > 0) {
      speedMult = card.speedEffect;
      speedDur = card.durationSeconds.toDouble();
    }

    return state.copyWith(
      player: player,
      recentCards: [...state.recentCards, card],
      activeSpeedMultiplier: speedMult,
      activeSpeedDuration: speedDur,
      phase: GamePhase.freeRoam,
    );
  }

  void reset() {
    _timeSinceLastCheck = 0;
  }
}
