import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/constants.dart';
import '../models/game_state.dart';

class DailySummaryOverlay extends StatelessWidget {
  final GameState state;
  final VoidCallback onNextDay;

  const DailySummaryOverlay({
    super.key,
    required this.state,
    required this.onNextDay,
  });

  @override
  Widget build(BuildContext context) {
    final player = state.player;
    final delivered = state.completedOrders
        .where((o) => o.status.name == 'delivered')
        .length;
    final failed = state.completedOrders
        .where((o) => o.status.name == 'failed')
        .length;
    final missionsComplete =
        state.dailyMissions.where((m) => m.isComplete).length;

    return Container(
      color: Colors.black.withAlpha(220),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(AppColors.bgDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(AppColors.orangeMain), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Day ${player.dayNumber} 結算',
                style: TextStyle(
                  color: Color(AppColors.orangeMain),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              _SummaryRow('完成外送', '$delivered 單',
                  color: Color(AppColors.neonGreen)),
              if (failed > 0)
                _SummaryRow('失敗訂單', '$failed 單',
                    color: Color(AppColors.coralRed)),
              _SummaryRow('今日收入', '\$${player.todayEarnings}',
                  color: Color(AppColors.neonGold)),
              _SummaryRow('目前評分', '${player.rating.toStringAsFixed(1)}',
                  color: Colors.white),
              _SummaryRow('總資產', '\$${player.money}',
                  color: Color(AppColors.neonGold)),
              _SummaryRow(
                  '每日任務', '$missionsComplete/${state.dailyMissions.length}',
                  color: Color(AppColors.tealMain)),

              const SizedBox(height: 24),

              // Performance evaluation
              _PerformanceChip(
                earnings: player.todayEarnings,
                deliveries: delivered,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onNextDay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(AppColors.orangeMain),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '繼續明天的工作',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow(this.label, this.value, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: Color(AppColors.uiGray), fontSize: 14)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PerformanceChip extends StatelessWidget {
  final int earnings;
  final int deliveries;

  const _PerformanceChip({
    required this.earnings,
    required this.deliveries,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, emoji) = _evaluate();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (String, Color, String) _evaluate() {
    if (earnings >= 1000 && deliveries >= 5) {
      return ('外送之神', Color(AppColors.neonGold), '👑');
    }
    if (earnings >= 500 && deliveries >= 3) {
      return ('超級外送員', Color(AppColors.neonGreen), '🌟');
    }
    if (deliveries >= 1) {
      return ('辛苦了！', Color(AppColors.tealMain), '💪');
    }
    return ('明天再加油', Color(AppColors.uiGray), '😴');
  }
}
