import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.bgDarkest),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '設定',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _SettingsSection(
                title: '遊戲',
                children: [
                  _SettingsItem(
                    icon: Icons.volume_up,
                    label: '音效',
                    trailing: Switch(
                      value: AudioService.instance.sfxEnabled,
                      onChanged: (v) {
                        setState(() => AudioService.instance.setSfxEnabled(v));
                        if (v) AudioService.instance.playSfx(SfxType.buttonTap);
                      },
                      activeColor: Color(AppColors.orangeMain),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.music_note,
                    label: '背景音樂',
                    trailing: Switch(
                      value: AudioService.instance.musicEnabled,
                      onChanged: (v) {
                        setState(() => AudioService.instance.setMusicEnabled(v));
                      },
                      activeColor: Color(AppColors.orangeMain),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _SettingsSection(
                title: '資料',
                children: [
                  _SettingsItem(
                    icon: Icons.delete_outline,
                    label: '重置遊戲',
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                    onTap: () => _confirmReset(context),
                  ),
                ],
              ),

              const Spacer(),

              Center(
                child: Column(
                  children: [
                    Text(
                      '台灣外送哥 v0.1.0',
                      style: TextStyle(
                        color: Color(AppColors.uiGray),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phase 1 MVP',
                      style: TextStyle(
                        color: Color(AppColors.uiGray),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(AppColors.bgDark),
        title: const Text('確認重置', style: TextStyle(color: Colors.white)),
        content: Text(
          '這會刪除所有遊戲進度，確定要重置嗎？',
          style: TextStyle(color: Color(AppColors.uiGray)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await SaveService.clearAll();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: Text(
              '重置',
              style: TextStyle(color: Color(AppColors.coralRed)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Color(AppColors.orangeMain),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(AppColors.bgDark),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}
