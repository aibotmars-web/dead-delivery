import 'dart:math';

import '../../config/constants.dart';

class PoliceEncounter {
  final int fine;
  final int timePenalty;
  final String message;

  const PoliceEncounter({
    required this.fine,
    required this.timePenalty,
    required this.message,
  });
}

class PoliceSystem {
  final Random _rng = Random();
  double _sidewalkAccum = 0;

  static const _messages = [
    '騎車上人行道，罰款！',
    '先生/小姐，這裡不能騎車！',
    '臨檢！騎上人行道違規！',
    '人行道禁止騎乘機車！',
    '請靠邊停車，人行道違規！',
  ];

  PoliceEncounter? checkSidewalk(double dt, bool isOnSidewalk, bool isRiding) {
    if (!isRiding) {
      _sidewalkAccum = 0;
      return null;
    }

    if (isOnSidewalk) {
      _sidewalkAccum += dt;
    } else {
      _sidewalkAccum = (_sidewalkAccum - dt * 0.3).clamp(0.0, 100.0);
      return null;
    }

    if (_sidewalkAccum < GameConfig.policeSidewalkCheckInterval) return null;
    _sidewalkAccum = 0;

    if (_rng.nextDouble() >= GameConfig.policeAppearChance) return null;

    final fine = GameConfig.policeMinFine +
        _rng.nextInt(GameConfig.policeMaxFine - GameConfig.policeMinFine + 1);
    final message = _messages[_rng.nextInt(_messages.length)];

    return PoliceEncounter(
      fine: fine,
      timePenalty: GameConfig.policeTimePenalty,
      message: message,
    );
  }

  int? checkParkingTicket(bool isRedLine) {
    if (!isRedLine) return null;
    if (_rng.nextDouble() >= GameConfig.redLineTicketChance) return null;

    return GameConfig.parkingMinFine +
        _rng.nextInt(GameConfig.parkingMaxFine - GameConfig.parkingMinFine + 1);
  }

  void reset() {
    _sidewalkAccum = 0;
  }
}
