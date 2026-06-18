import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../game/delivery_game.dart';
import '../models/game_state.dart';

import '../widgets/hud_overlay.dart';
import '../widgets/phone_overlay.dart';
import '../widgets/event_popup.dart';
import '../widgets/card_draw_overlay.dart';
import '../widgets/daily_summary_overlay.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/police_stop_overlay.dart';
import '../widgets/parking_ticket_overlay.dart';
import '../services/save_service.dart';

/// Main game screen with Flame game + Flutter HUD overlay
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final DeliveryGame _game;
  GameState _gameState = GameState.initial();
  bool _scheduledRebuild = false;
  int _lastSavedDeliveries = 0;

  @override
  void initState() {
    super.initState();
    _game = DeliveryGame(
      onStateChanged: (state) {
        // Auto-save after each delivery
        if (state.player.totalDeliveries > _lastSavedDeliveries) {
          _lastSavedDeliveries = state.player.totalDeliveries;
          SaveService.savePlayer(state.player);
        }
        _gameState = state;
        if (!_scheduledRebuild && mounted) {
          _scheduledRebuild = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scheduledRebuild = false;
            if (mounted) setState(() {});
          });
        }
      },
    );
    _loadSave();
  }

  Future<void> _loadSave() async {
    final saved = await SaveService.loadPlayer();
    if (saved != null) {
      _game.loadPlayer(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.bgDarkest),
      body: SafeArea(
        child: Stack(
          children: [
            // Flame game layer
            GameWidget(game: _game),

            // HUD overlay
            HudOverlay(
              state: _gameState,
              onPhoneTap: () => _game.togglePhone(),
              onPauseTap: () => _game.togglePause(),
              onMountTap: () => _game.toggleMount(),
              onPickUp: () => _game.pickUpOrder(),
              onDeliver: () => _game.deliverOrder(),
            ),

            // Phone UI overlay
            if (_gameState.isPhoneOpen)
              PhoneOverlay(
                state: _gameState,
                onClose: () => _game.togglePhone(),
                onAcceptOrder: (index) => _game.acceptOrder(index),
                onUpgradeScooter: () => _game.upgradeScooter(),
                onUpgradeBag: () => _game.upgradeBag(),
                onClaimMission: (index) => _game.claimDailyMission(index),
              ),

            // City event popup
            if (_gameState.phase == GamePhase.eventPopup &&
                _game.currentCityEvent != null)
              EventPopup(
                event: _game.currentCityEvent,
                onChoiceSelected: (choice) {
                  _game.applyCityEventChoice(choice);
                },
              ),

            // Card draw overlay
            if (_gameState.phase == GamePhase.cardDraw &&
                _game.currentCard != null)
              CardDrawOverlay(
                card: _game.currentCard!,
                onDismiss: () => _game.applyCurrentCard(),
              ),

            // Police stop overlay
            if (_gameState.phase == GamePhase.policeStop &&
                _game.currentPoliceEncounter != null)
              PoliceStopOverlay(
                encounter: _game.currentPoliceEncounter!,
                onDismiss: () => _game.dismissPoliceStop(),
              ),

            // Parking ticket overlay
            if (_gameState.phase == GamePhase.parkingTicket &&
                _game.currentParkingFine != null)
              ParkingTicketOverlay(
                fine: _game.currentParkingFine!,
                onDismiss: () => _game.dismissParkingTicket(),
              ),

            // Daily summary overlay
            if (_gameState.phase == GamePhase.summary)
              DailySummaryOverlay(
                state: _gameState,
                onNextDay: () {
                  _game.processNextDay();
                  SaveService.savePlayer(_gameState.player);
                },
              ),

            // Tutorial overlay
            if (_gameState.showTutorial)
              TutorialOverlay(
                onComplete: () => _game.dismissTutorial(),
              ),

            // Pause overlay
            if (_gameState.isPaused)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '暫停',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _game.togglePause(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(AppColors.orangeMain),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('繼續遊戲', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
