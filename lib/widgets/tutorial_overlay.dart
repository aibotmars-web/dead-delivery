import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/constants.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialOverlay({super.key, required this.onComplete});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _step = 0;

  static const _steps = [
    (
      title: '歡迎來到台灣外送哥！',
      desc: '你是一位外送員，在台灣的街頭穿梭送餐。\n接訂單、取餐、送達，賺取收入！',
      icon: '🛵',
    ),
    (
      title: '接單流程',
      desc: '按左下角「手機」按鈕打開手機\n選擇訂單後按「接單」開始',
      icon: '📱',
    ),
    (
      title: '導航與取餐',
      desc: '點擊地圖任意位置移動\n靠近餐廳會自動取餐\n按「上車」騎機車更快！',
      icon: '🗺️',
    ),
    (
      title: '送達與獎勵',
      desc: '取餐後前往客戶位置\n準時送達可獲得全額獎勵\n每次送達都會抽一張卡片！',
      icon: '📦',
    ),
    (
      title: '小心路上事件！',
      desc: '送餐途中可能遇到隨機事件\n做出選擇會影響評分和收入\n祝你外送愉快！',
      icon: '⚡',
    ),
  ];

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    return GestureDetector(
      onTap: _next,
      child: Container(
        color: Colors.black.withAlpha(200),
        child: Center(
          child: Container(
            key: ValueKey(_step),
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(AppColors.bgDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(AppColors.tealMain), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(step.icon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  step.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  step.desc,
                  style: TextStyle(
                    color: Color(AppColors.uiGray),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _step
                            ? Color(AppColors.tealMain)
                            : Color(AppColors.uiGray).withAlpha(100),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                Text(
                  _step < _steps.length - 1 ? '點擊繼續' : '點擊開始外送！',
                  style: TextStyle(
                    color: Color(AppColors.tealMain),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ).animate(key: ValueKey(_step))
              .fadeIn(duration: 200.ms)
              .slideX(begin: 0.1, duration: 300.ms, curve: Curves.easeOut),
        ),
      ),
    );
  }
}
