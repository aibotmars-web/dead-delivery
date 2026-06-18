import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/game_state.dart';
import '../models/order.dart';

/// HUD overlay: top status bar + bottom action bar
class HudOverlay extends StatelessWidget {
  final GameState state;
  final VoidCallback onPhoneTap;
  final VoidCallback onPauseTap;
  final VoidCallback onMountTap;
  final VoidCallback onPickUp;
  final VoidCallback onDeliver;

  const HudOverlay({
    super.key,
    required this.state,
    required this.onPhoneTap,
    required this.onPauseTap,
    required this.onMountTap,
    required this.onPickUp,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(state: state, onPauseTap: onPauseTap),
        const Spacer(),
        _BottomBar(
          state: state,
          onPhoneTap: onPhoneTap,
          onMountTap: onMountTap,
          onPickUp: onPickUp,
          onDeliver: onDeliver,
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameState state;
  final VoidCallback onPauseTap;

  const _TopBar({required this.state, required this.onPauseTap});

  @override
  Widget build(BuildContext context) {
    final order = state.activeOrder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Timer (show if active order)
          if (order != null) ...[
            Icon(
              Icons.timer,
              color: order.isOverTime
                  ? Color(AppColors.coralRed)
                  : Color(AppColors.neonGreen),
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              order.isOverTime
                  ? '-${_formatTime(order.elapsedSeconds - order.timeLimitSeconds)}'
                  : _formatTime(order.remainingSeconds),
              style: TextStyle(
                color: order.isOverTime
                    ? Color(AppColors.coralRed)
                    : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (order.isOverTime) ...[
              const SizedBox(width: 4),
              Text(
                'x${order.rewardMultiplier.toStringAsFixed(1)}',
                style: TextStyle(
                  color: Color(AppColors.neonGold),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(width: 12),
          ],

          // Money
          Text(
            '💰\$${state.player.money}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),

          // Rating
          Text(
            '⭐${state.player.rating.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const Spacer(),

          // Game time & Day number
          Text(
            '${state.gameTimeString}  Day ${state.player.dayNumber}',
            style: TextStyle(
              color: Color(AppColors.uiGray),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),

          // Pause button
          GestureDetector(
            onTap: onPauseTap,
            child: const Icon(Icons.pause, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  String _formatTime(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.toInt() % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

class _BottomBar extends StatelessWidget {
  final GameState state;
  final VoidCallback onPhoneTap;
  final VoidCallback onMountTap;
  final VoidCallback onPickUp;
  final VoidCallback onDeliver;

  const _BottomBar({
    required this.state,
    required this.onPhoneTap,
    required this.onMountTap,
    required this.onPickUp,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Phone button
          _ActionButton(
            icon: '📱',
            label: '手機',
            onTap: onPhoneTap,
          ),
          const SizedBox(width: 12),

          // Context action (pickup / deliver)
          if (state.phase == GamePhase.pickingUp)
            _ActionButton(
              icon: '🍱',
              label: '取餐',
              onTap: onPickUp,
            )
          else if (state.phase == GamePhase.delivering)
            _ActionButton(
              icon: '📦',
              label: '送達',
              onTap: onDeliver,
            ),

          const Spacer(),

          // Current order status
          Expanded(
            flex: 3,
            child: _OrderStatusWidget(order: state.activeOrder),
          ),
          const Spacer(),

          // Mount/Dismount
          _ActionButton(
            icon: state.player.isRiding ? '🚶' : '🛵',
            label: state.player.isRiding ? '下車' : '上車',
            onTap: onMountTap,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusWidget extends StatelessWidget {
  final Order? order;

  const _OrderStatusWidget({this.order});

  @override
  Widget build(BuildContext context) {
    if (order == null) {
      return Text(
        '目前沒有訂單',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(AppColors.uiGray), fontSize: 12),
      );
    }

    final statusText = switch (order!.status) {
      OrderStatus.idle => '等待中',
      OrderStatus.pickup => '前往 ${order!.restaurantName} 取餐',
      OrderStatus.delivering => '送往 ${order!.customerName}',
      OrderStatus.delivered => '已送達！',
      OrderStatus.failed => '訂單失敗',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          statusText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${order!.foodName} — \$${order!.reward}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(AppColors.neonGold),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
