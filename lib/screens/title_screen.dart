import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/constants.dart';
import '../services/save_service.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Title / main menu screen
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    _checkSave();
  }

  Future<void> _checkSave() async {
    final saved = await SaveService.loadPlayer();
    if (mounted) setState(() => _hasSave = saved != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.bgDarkest),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game logo / title
              Text(
                '🛵',
                style: const TextStyle(fontSize: 64),
              )
                  .animate(
                    onPlay: (c) => c.repeat(reverse: true),
                  )
                  .moveY(begin: 0, end: -10, duration: 800.ms),
              const SizedBox(height: 16),
              const Text(
                '台灣外送哥',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Taiwan Delivery Bro',
                style: TextStyle(
                  color: Color(AppColors.orangeMain),
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 60),

              // Start button
              _MenuButton(
                label: '🏍️ 開始外送',
                onTap: () async {
                  await SaveService.clearAll();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const GameScreen(),
                    ),
                  );
                },
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

              const SizedBox(height: 16),

              // Continue button (if save exists)
              if (_hasSave)
                _MenuButton(
                  label: '📱 繼續上次',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const GameScreen(),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

              if (_hasSave) const SizedBox(height: 16),

              _MenuButton(
                label: '⚙️ 設定',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                secondary: true,
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),

              const SizedBox(height: 40),

              Text(
                'v0.1.0 — Phase 1 MVP',
                style: TextStyle(
                  color: Color(AppColors.uiGray),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool secondary;

  const _MenuButton({
    required this.label,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary
              ? Color(AppColors.bgLight)
              : Color(AppColors.orangeMain),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
