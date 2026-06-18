import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player.dart';

/// Handles save/load via SharedPreferences
class SaveService {
  static const _playerKey = 'player_data';
  static const _lastDayKey = 'last_day';

  static Future<Player?> loadPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_playerKey);
    if (jsonStr == null) return null;
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Player.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePlayer(Player player) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(player.toJson());
    await prefs.setString(_playerKey, jsonStr);
  }

  static Future<bool> isNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDay = prefs.getString(_lastDayKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastDay != today) {
      await prefs.setString(_lastDayKey, today);
      return true;
    }
    return false;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
