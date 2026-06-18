import 'dart:math';

/// City-level random event with player choices (immutable)
class CityEvent {
  final String id;
  final String title;
  final String description;
  final List<EventChoice> choices;
  final double probability;

  const CityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.choices,
    this.probability = 0.1,
  });

  static CityEvent? tryTrigger() {
    final rng = Random();
    // Weighted random selection
    final roll = rng.nextDouble();
    double cumulative = 0;
    for (final event in allEvents) {
      cumulative += event.probability;
      if (roll < cumulative) return event;
    }
    return null;
  }

  static const allEvents = [
    CityEvent(
      id: 'event_rain',
      title: '突然下大雨了！',
      description: '天色暗了下來，大雨傾盆而至。',
      choices: [
        EventChoice(
          text: '穿雨衣繼續送',
          description: '速度降低 20%，但餐點安全',
          moneyEffect: 0,
          speedEffect: 0.8,
          durationSeconds: 300,
        ),
        EventChoice(
          text: '硬騎不穿',
          description: '速度不變，但餐點品質下降',
          moneyEffect: 0,
          foodQualityEffect: -0.3,
        ),
      ],
      probability: 0.15,
    ),
    CityEvent(
      id: 'event_temple_parade',
      title: '廟會出巡！',
      description: '媽祖遶境經過，整條路都封了。',
      choices: [
        EventChoice(
          text: '繞路走',
          description: '多花一點時間',
          speedEffect: 0.6,
          durationSeconds: 120,
        ),
        EventChoice(
          text: '下車用走的穿過去',
          description: '很慢但能過',
          speedEffect: 0.3,
          durationSeconds: 60,
        ),
      ],
      probability: 0.08,
    ),
    CityEvent(
      id: 'event_road_run',
      title: '路跑活動封路',
      description: '市區馬拉松比賽，多條道路封閉。',
      choices: [
        EventChoice(
          text: '走小巷繞過去',
          description: '速度降低但能通過',
          speedEffect: 0.7,
          durationSeconds: 180,
        ),
        EventChoice(
          text: '等比賽結束',
          description: '等 3 分鐘，然後恢復正常',
          speedEffect: 0.0,
          durationSeconds: 180,
        ),
      ],
      probability: 0.05,
    ),
    CityEvent(
      id: 'event_scooter_breakdown',
      title: '機車拋錨了！',
      description: '引擎突然發不動，冒出白煙。',
      choices: [
        EventChoice(
          text: '路邊修車',
          description: '花 \$150 快修',
          moneyEffect: -150,
          speedEffect: 0.0,
          durationSeconds: 30,
        ),
        EventChoice(
          text: '用走的先送餐',
          description: '很慢但不花錢',
          speedEffect: 0.2,
          durationSeconds: 120,
        ),
      ],
      probability: 0.10,
    ),
    CityEvent(
      id: 'event_customer_gone',
      title: '客人不見了',
      description: '到了送餐地點，怎麼按門鈴都沒人應。',
      choices: [
        EventChoice(
          text: '打電話等他',
          description: '等 2 分鐘',
          speedEffect: 0.0,
          durationSeconds: 120,
        ),
        EventChoice(
          text: '放門口拍照',
          description: '省時間但評價可能降',
          ratingEffect: -0.2,
        ),
      ],
      probability: 0.12,
    ),
    CityEvent(
      id: 'event_utensils',
      title: '客人問有沒有備用餐具',
      description: '「不好意思，可以幫我拿湯匙嗎？」',
      choices: [
        EventChoice(
          text: '回去拿',
          description: '浪費時間但評價上升',
          ratingEffect: 0.3,
          speedEffect: 0.0,
          durationSeconds: 60,
        ),
        EventChoice(
          text: '抱歉沒有',
          description: '繼續送下一單',
          ratingEffect: -0.1,
        ),
      ],
      probability: 0.10,
    ),
    CityEvent(
      id: 'event_car_accident',
      title: '前方車禍',
      description: '前面發生擦撞，警察在指揮交通。',
      choices: [
        EventChoice(
          text: '慢慢通過',
          description: '速度降低',
          speedEffect: 0.5,
          durationSeconds: 90,
        ),
        EventChoice(
          text: '回頭繞路',
          description: '花更多時間繞一大圈',
          speedEffect: 0.7,
          durationSeconds: 150,
        ),
      ],
      probability: 0.08,
    ),
    CityEvent(
      id: 'event_slip',
      title: '下車送餐時滑倒！',
      description: '地板溼滑，你腳底一滑⋯⋯',
      choices: [
        EventChoice(
          text: '餐沒事！',
          description: '幸好抓穩了（50% 機率）',
          moneyEffect: 0,
        ),
        EventChoice(
          text: '餐灑了...',
          description: '要賠客人餐費 -\$100',
          moneyEffect: -100,
          ratingEffect: -0.3,
        ),
      ],
      probability: 0.07,
    ),
    CityEvent(
      id: 'event_night_market',
      title: '夜市超擠！',
      description: '逢甲夜市人擠人，機車根本進不去。',
      choices: [
        EventChoice(
          text: '停遠一點用走的',
          description: '走路過去取餐',
          speedEffect: 0.4,
          durationSeconds: 120,
        ),
        EventChoice(
          text: '硬鑽進去',
          description: '有可能被罵或撞到人',
          ratingEffect: -0.2,
          moneyEffect: -50,
        ),
      ],
      probability: 0.10,
    ),
    CityEvent(
      id: 'event_stray_dog',
      title: '路邊有流浪狗',
      description: '一隻小狗在路邊看著你，好像很餓。',
      choices: [
        EventChoice(
          text: '給牠吃一點',
          description: '花 \$30 買飼料，心情好',
          moneyEffect: -30,
          ratingEffect: 0.2,
        ),
        EventChoice(
          text: '趕時間先走',
          description: '繼續送餐',
        ),
      ],
      probability: 0.05,
    ),
  ];
}

/// A single choice within a city event (immutable)
class EventChoice {
  final String text;
  final String description;
  final int moneyEffect;
  final double ratingEffect;
  final double speedEffect; // multiplier, 1.0 = no change
  final double foodQualityEffect;
  final int durationSeconds;

  const EventChoice({
    required this.text,
    this.description = '',
    this.moneyEffect = 0,
    this.ratingEffect = 0,
    this.speedEffect = 1.0,
    this.foodQualityEffect = 0,
    this.durationSeconds = 0,
  });
}
