import '../config/constants.dart';

enum EquipmentType { scooter, bag }

/// Equipment model (immutable)
class Equipment {
  final EquipmentType type;
  final int level;
  final String name;
  final String description;

  const Equipment({
    required this.type,
    required this.level,
    required this.name,
    required this.description,
  });

  factory Equipment.defaultScooter() => const Equipment(
    type: EquipmentType.scooter,
    level: 1,
    name: '二手小50',
    description: '基本代步工具，速度普通',
  );

  factory Equipment.defaultBag() => const Equipment(
    type: EquipmentType.bag,
    level: 1,
    name: '普通外送袋',
    description: '基本保溫，食物容易冷掉',
  );

  factory Equipment.scooterAtLevel(int level) => switch (level) {
    1 => Equipment.defaultScooter(),
    2 => const Equipment(
      type: EquipmentType.scooter,
      level: 2,
      name: '改裝勁戰',
      description: '速度提升，穩定性佳',
    ),
    3 => const Equipment(
      type: EquipmentType.scooter,
      level: 3,
      name: '電動車 Gogoro',
      description: '最高速度，環保又穩',
    ),
    _ => Equipment.defaultScooter(),
  };

  factory Equipment.bagAtLevel(int level) => switch (level) {
    1 => Equipment.defaultBag(),
    2 => const Equipment(
      type: EquipmentType.bag,
      level: 2,
      name: '保溫外送箱',
      description: '保溫效果好，食物不易冷',
    ),
    3 => const Equipment(
      type: EquipmentType.bag,
      level: 3,
      name: '頂級保溫箱',
      description: '超強保溫+防震，食物完美送達',
    ),
    _ => Equipment.defaultBag(),
  };

  int? get upgradeCost {
    if (type == EquipmentType.scooter) {
      return switch (level) {
        1 => GameConfig.scooterLv2Cost,
        2 => GameConfig.scooterLv3Cost,
        _ => null, // max level
      };
    } else {
      return switch (level) {
        1 => GameConfig.bagLv2Cost,
        2 => GameConfig.bagLv3Cost,
        _ => null,
      };
    }
  }

  bool get isMaxLevel => level >= 3;

  Equipment upgrade() {
    if (isMaxLevel) return this;
    return type == EquipmentType.scooter
        ? Equipment.scooterAtLevel(level + 1)
        : Equipment.bagAtLevel(level + 1);
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'level': level,
  };

  factory Equipment.fromJson(Map<String, dynamic> json) {
    final type = EquipmentType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => EquipmentType.scooter,
    );
    final level = json['level'] as int? ?? 1;
    return type == EquipmentType.scooter
        ? Equipment.scooterAtLevel(level)
        : Equipment.bagAtLevel(level);
  }
}
