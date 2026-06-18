// Game constants for Taiwan Delivery Bro
// 台灣外送哥 - 遊戲常數

class GameConfig {
  // Map
  static const int mapWidth = 50;
  static const int mapHeight = 50;
  static const double tileSize = 16.0;
  static const double scaleFactor = 2.0;
  static const double displayTileSize = tileSize * scaleFactor;

  // Player movement speed (tiles per second)
  static const double walkSpeed = 1.0;
  static const double scooterSpeedLv1 = 3.0;
  static const double scooterSpeedLv2 = 4.0;
  static const double scooterSpeedLv3 = 5.0;
  static const double rainSpeedMultiplier = 0.7;
  static const double nightMarketSpeedMultiplier = 0.5;

  // Order
  static const int minOrderReward = 30;
  static const int maxOrderReward = 150;
  static const int minTimeLimit = 180; // 3 minutes in seconds
  static const int maxTimeLimit = 480; // 8 minutes in seconds
  static const double onTimeMultiplier = 1.0;
  static const double earlyMultiplier = 1.2;
  static const double lateMultiplier1 = 0.8; // < 2min late
  static const double lateMultiplier2 = 0.5; // < 5min late

  // Tips probability
  static const double tipNoneChance = 0.60;
  static const double tipSmallChance = 0.25; // $10-30
  static const double tipMediumChance = 0.10; // $50-100
  static const double tipLargeChance = 0.05; // $200+

  // Event probability
  static const double cityEventChance = 0.12; // 12% per check
  static const int cityEventCheckInterval = 30; // seconds

  // Card probability
  static const double chanceCardProb = 0.60;
  static const double fateCardProb = 0.35;
  static const double rareCardProb = 0.05;

  // Equipment costs
  static const int scooterLv2Cost = 2000;
  static const int scooterLv3Cost = 8000;
  static const int bagLv2Cost = 1000;
  static const int bagLv3Cost = 5000;

  // Daily
  static const int dailyMissionCount = 3;
  static const int dailyMissionReward = 100;
  static const int dailyMissionBonusAll = 500;

  // Login streak rewards
  static const List<int> loginStreakRewards = [
    200, 300, 500, 500, 800, 800, 1500
  ];

  // Police system (sidewalk riding)
  static const int policeSidewalkCheckInterval = 10;
  static const double policeAppearChance = 0.15;
  static const int policeMinFine = 100;
  static const int policeMaxFine = 300;
  static const int policeTimePenalty = 30;
  static const double sidewalkSpeedBoost = 1.3;

  // Parking system
  static const double redLineTicketChance = 0.25;
  static const int parkingMinFine = 200;
  static const int parkingMaxFine = 500;

  // Starting values
  static const int startingMoney = 500;
  static const double startingRating = 3.0;
}

class AppColors {
  // Background
  static const int bgDarkest = 0xFF0A0A1A;
  static const int bgDark = 0xFF1A1A2E;
  static const int bgMedium = 0xFF16213E;
  static const int bgLight = 0xFF2C2C44;

  // Ground / Building
  static const int roadGray = 0xFF4A4A68;
  static const int sidewalkGray = 0xFF6B6B8D;
  static const int brownMedium = 0xFF8B7355;
  static const int brownLight = 0xFFA08D6E;
  static const int brownDark = 0xFF5C4033;
  static const int brownDarkest = 0xFF3D2B1F;

  // Character / Objects
  static const int white = 0xFFE8E8E8;
  static const int grayLight = 0xFFB0B0B0;
  static const int orangeMain = 0xFFF5A623;
  static const int orangeDark = 0xFFD4830A;
  static const int tealMain = 0xFF4ECDC4;
  static const int tealDark = 0xFF2D9B93;
  static const int coralRed = 0xFFFF6B6B;
  static const int darkRed = 0xFFCC4444;

  // Neon / Night market
  static const int neonPink = 0xFFFF2D78;
  static const int neonCyan = 0xFF00E5FF;
  static const int neonGold = 0xFFFFD700;
  static const int neonPurple = 0xFF7B68EE;
  static const int neonGreen = 0xFF00FF88;
  static const int neonRed = 0xFFFF4444;

  // Skin / Food
  static const int skinLight = 0xFFF0C896;
  static const int skinDark = 0xFFD4A76A;
  static const int green = 0xFF8BC34A;
  static const int foodPink = 0xFFE57373;

  // UI
  static const int uiWhite = 0xFFFFFFFF;
  static const int uiGray = 0xFF888888;
  static const int uiDarkGray = 0xFF333333;
  static const int uiBlack = 0xFF000000;
}
