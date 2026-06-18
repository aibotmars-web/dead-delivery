import 'dart:math';

import '../config/constants.dart';

enum CardType { chance, fate, rare }

/// Event card drawn after delivery (immutable)
class EventCard {
  final String id;
  final CardType type;
  final String title;
  final String description;
  final int moneyEffect;
  final double ratingEffect;
  final double speedEffect; // multiplier, 1.0 = no change
  final int durationSeconds; // 0 = instant

  const EventCard({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.moneyEffect = 0,
    this.ratingEffect = 0,
    this.speedEffect = 1.0,
    this.durationSeconds = 0,
  });

  bool get isPositive => moneyEffect > 0 || ratingEffect > 0;
  bool get isInstant => durationSeconds == 0;

  static CardType rollType() {
    final roll = Random().nextDouble();
    if (roll < GameConfig.chanceCardProb) return CardType.chance;
    if (roll < GameConfig.chanceCardProb + GameConfig.fateCardProb) {
      return CardType.fate;
    }
    return CardType.rare;
  }

  static EventCard draw() {
    final type = rollType();
    final pool = switch (type) {
      CardType.chance => _chanceCards,
      CardType.fate => _fateCards,
      CardType.rare => _rareCards,
    };
    return pool[Random().nextInt(pool.length)];
  }

  // ── Chance Cards (機會卡) ──────────────────────────
  static const _chanceCards = [
    EventCard(
      id: 'chance_big_tip',
      type: CardType.chance,
      title: '超大小費！',
      description: '客人覺得你態度超好，多給了 \$200',
      moneyEffect: 200,
      ratingEffect: 0.1,
    ),
    EventCard(
      id: 'chance_shortcut',
      type: CardType.chance,
      title: '發現捷徑',
      description: '找到一條沒有紅燈的小路',
      speedEffect: 1.3,
      durationSeconds: 120,
    ),
    EventCard(
      id: 'chance_double_order',
      type: CardType.chance,
      title: '加碼訂單',
      description: '順路再接一單，獎金 +\$100',
      moneyEffect: 100,
    ),
    EventCard(
      id: 'chance_five_star',
      type: CardType.chance,
      title: '五星好評',
      description: '客人給了五星評價！',
      ratingEffect: 0.3,
    ),
    EventCard(
      id: 'chance_coupon',
      type: CardType.chance,
      title: '路邊撿到折價券',
      description: '便利商店折價 \$50',
      moneyEffect: 50,
    ),
    EventCard(
      id: 'chance_weather_clear',
      type: CardType.chance,
      title: '天氣放晴',
      description: '雨停了！道路乾爽',
      speedEffect: 1.1,
      durationSeconds: 180,
    ),
    EventCard(
      id: 'chance_fan',
      type: CardType.chance,
      title: '忠實粉絲',
      description: '回頭客指定你送餐，小費 \$80',
      moneyEffect: 80,
      ratingEffect: 0.1,
    ),
    EventCard(
      id: 'chance_promo',
      type: CardType.chance,
      title: '平台加碼',
      description: '尖峰時段加成！獎金 +\$150',
      moneyEffect: 150,
    ),
    EventCard(
      id: 'chance_pet_bonus',
      type: CardType.chance,
      title: '可愛狗狗',
      description: '客人家的狗超可愛，心情大好！',
      ratingEffect: 0.2,
      speedEffect: 1.1,
      durationSeconds: 60,
    ),
    EventCard(
      id: 'chance_green_lights',
      type: CardType.chance,
      title: '一路綠燈',
      description: '運氣真好，連過三個綠燈！',
      speedEffect: 1.5,
      durationSeconds: 30,
    ),
    EventCard(
      id: 'chance_thank_you',
      type: CardType.chance,
      title: '感謝卡',
      description: '客人留了一張感謝卡，好暖心',
      ratingEffect: 0.2,
      moneyEffect: 30,
    ),
    EventCard(
      id: 'chance_bonus_zone',
      type: CardType.chance,
      title: '獎勵熱區',
      description: '你在獎勵區域完成訂單！+\$120',
      moneyEffect: 120,
    ),
  ];

  // ── Fate Cards (命運卡) ──────────────────────────
  static const _fateCards = [
    EventCard(
      id: 'fate_flat_tire',
      type: CardType.fate,
      title: '機車爆胎',
      description: '輪胎被釘子刺破，修車 -\$200',
      moneyEffect: -200,
      speedEffect: 0.5,
      durationSeconds: 60,
    ),
    EventCard(
      id: 'fate_rain',
      type: CardType.fate,
      title: '突然暴雨',
      description: '沒帶雨衣，全身濕透',
      speedEffect: 0.7,
      durationSeconds: 180,
      ratingEffect: -0.1,
    ),
    EventCard(
      id: 'fate_spill',
      type: CardType.fate,
      title: '餐點打翻',
      description: '一個急煞，湯灑出來了...',
      moneyEffect: -100,
      ratingEffect: -0.3,
    ),
    EventCard(
      id: 'fate_wrong_address',
      type: CardType.fate,
      title: '地址寫錯',
      description: '客人地址不對，多繞一圈',
      speedEffect: 0.8,
      durationSeconds: 120,
    ),
    EventCard(
      id: 'fate_traffic_jam',
      type: CardType.fate,
      title: '大塞車',
      description: '前方車禍，完全堵住',
      speedEffect: 0.3,
      durationSeconds: 90,
    ),
    EventCard(
      id: 'fate_bad_review',
      type: CardType.fate,
      title: '客訴一星',
      description: '客人說餐涼了，給了一星',
      ratingEffect: -0.5,
    ),
    EventCard(
      id: 'fate_ticket',
      type: CardType.fate,
      title: '紅單',
      description: '違規停車被開單 -\$300',
      moneyEffect: -300,
    ),
  ];

  // ── Rare Cards (稀有卡) ──────────────────────────
  static const _rareCards = [
    EventCard(
      id: 'rare_celebrity',
      type: CardType.rare,
      title: '✨ 網紅送餐',
      description: '送餐給知名網紅，被拍上限動！小費 \$500',
      moneyEffect: 500,
      ratingEffect: 0.5,
    ),
  ];
}
