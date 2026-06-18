import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/constants.dart';
import '../models/event_card.dart';

/// Card draw animation overlay after delivery
class CardDrawOverlay extends StatelessWidget {
  final EventCard card;
  final VoidCallback onDismiss;

  const CardDrawOverlay({
    super.key,
    required this.card,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = switch (card.type) {
      CardType.chance => Color(AppColors.neonGold),
      CardType.fate => Color(AppColors.coralRed),
      CardType.rare => Color(AppColors.neonPurple),
    };

    final typeLabel = switch (card.type) {
      CardType.chance => '★ 機會 ★',
      CardType.fate => '☠ 命運 ☠',
      CardType.rare => '✦ 稀有 ✦',
    };

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withAlpha(200),
        child: Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(AppColors.bgDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withAlpha(100),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Card type
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: borderColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  card.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  card.description,
                  style: TextStyle(
                    color: Color(AppColors.uiGray),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Effects
                if (card.moneyEffect != 0)
                  _EffectRow(
                    icon: '💰',
                    text: card.moneyEffect > 0
                        ? '+\$${card.moneyEffect}'
                        : '-\$${card.moneyEffect.abs()}',
                    isPositive: card.moneyEffect > 0,
                  ),
                if (card.ratingEffect != 0)
                  _EffectRow(
                    icon: '⭐',
                    text: card.ratingEffect > 0
                        ? '+${card.ratingEffect.toStringAsFixed(1)}'
                        : '${card.ratingEffect.toStringAsFixed(1)}',
                    isPositive: card.ratingEffect > 0,
                  ),
                if (card.speedEffect != 1.0)
                  _EffectRow(
                    icon: '🏎️',
                    text: card.speedEffect > 1.0
                        ? '速度 x${card.speedEffect.toStringAsFixed(1)} (${card.durationSeconds}秒)'
                        : '速度 x${card.speedEffect.toStringAsFixed(1)} (${card.durationSeconds}秒)',
                    isPositive: card.speedEffect > 1.0,
                  ),

                const SizedBox(height: 20),

                Text(
                  '點擊任意處繼續',
                  style: TextStyle(
                    color: Color(AppColors.uiGray),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .scale(begin: const Offset(0.3, 0.3), duration: 400.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 200.ms),
        ),
      ),
    );
  }
}

class _EffectRow extends StatelessWidget {
  final String icon;
  final String text;
  final bool isPositive;

  const _EffectRow({
    required this.icon,
    required this.text,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isPositive
                  ? Color(AppColors.neonGreen)
                  : Color(AppColors.coralRed),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
