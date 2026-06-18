import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/achievement.dart';
import '../models/daily_mission.dart';
import '../models/equipment.dart';
import '../models/game_state.dart';
import '../models/order.dart';

class PhoneOverlay extends StatefulWidget {
  final GameState state;
  final VoidCallback onClose;
  final void Function(int index) onAcceptOrder;
  final VoidCallback onUpgradeScooter;
  final VoidCallback onUpgradeBag;
  final void Function(int index) onClaimMission;

  const PhoneOverlay({
    super.key,
    required this.state,
    required this.onClose,
    required this.onAcceptOrder,
    required this.onUpgradeScooter,
    required this.onUpgradeBag,
    required this.onClaimMission,
  });

  @override
  State<PhoneOverlay> createState() => _PhoneOverlayState();
}

class _PhoneOverlayState extends State<PhoneOverlay> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: LayoutBuilder(
              builder: (context, _) {
              final screen = MediaQuery.of(context).size;
              final phoneW = (screen.width * 0.85).clamp(280.0, 360.0);
              final phoneH = (screen.height * 0.78).clamp(400.0, 560.0);
              return Container(
              width: phoneW,
              height: phoneH,
              decoration: BoxDecoration(
                color: Color(AppColors.bgDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(AppColors.uiGray), width: 2),
              ),
              child: Column(
                children: [
                  _PhoneTabBar(
                    selectedIndex: _selectedTab,
                    onTabChanged: (i) => setState(() => _selectedTab = i),
                    missionNotify: widget.state.dailyMissions
                        .any((m) => m.isComplete && !m.isClaimed),
                  ),
                  Expanded(
                    child: switch (_selectedTab) {
                      0 => _OrderListTab(
                        orders: widget.state.availableOrders,
                        activeOrder: widget.state.activeOrder,
                        onAccept: widget.onAcceptOrder,
                      ),
                      1 => _EquipmentTab(
                        state: widget.state,
                        onUpgradeScooter: widget.onUpgradeScooter,
                        onUpgradeBag: widget.onUpgradeBag,
                      ),
                      2 => _MissionTab(
                        missions: widget.state.dailyMissions,
                        onClaim: widget.onClaimMission,
                      ),
                      3 => _AchievementTab(state: widget.state),
                      4 => _StatsTab(state: widget.state),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onClose,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(AppColors.bgLight),
                        ),
                        child: const Text('關閉手機'),
                      ),
                    ),
                  ),
                ],
              ),
            );
            },
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneTabBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTabChanged;
  final bool missionNotify;

  const _PhoneTabBar({
    required this.selectedIndex,
    required this.onTabChanged,
    this.missionNotify = false,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = [
      ('📋', '訂單'),
      ('🛵', '裝備'),
      ('🎯', '任務'),
      ('🏆', '成就'),
      ('📊', '統計'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(AppColors.uiGray), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(tabs.length, (i) {
          final isSelected = i == selectedIndex;
          final (icon, label) = tabs[i];
          return GestureDetector(
            onTap: () => onTabChanged(i),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 18)),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Color(AppColors.orangeMain)
                            : Color(AppColors.uiGray),
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (i == 2 && missionNotify)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(AppColors.coralRed),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Tab 0: Orders ──

class _OrderListTab extends StatelessWidget {
  final List<Order> orders;
  final Order? activeOrder;
  final void Function(int) onAccept;

  const _OrderListTab({
    required this.orders,
    this.activeOrder,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    if (activeOrder != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('目前訂單',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _OrderCard(order: activeOrder!, isActive: true),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Text(
          '目前沒有可接的訂單\n等一下會有新的！',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(AppColors.uiGray), fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _OrderCard(
          order: orders[index],
          onAccept: () => onAccept(index),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isActive;
  final VoidCallback? onAccept;

  const _OrderCard({
    required this.order,
    this.isActive = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(AppColors.bgLight),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: Color(AppColors.orangeMain), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(order.restaurantName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('\$${order.reward}',
                style: TextStyle(
                    color: Color(AppColors.neonGold),
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text('${order.foodName} → ${order.customerName}',
              style:
                  TextStyle(color: Color(AppColors.uiGray), fontSize: 12)),
          Text('限時 ${order.timeLimitSeconds ~/ 60} 分鐘',
              style:
                  TextStyle(color: Color(AppColors.uiGray), fontSize: 11)),
          if (onAccept != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppColors.orangeMain),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                child: const Text('接單',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab 1: Equipment ──

class _EquipmentTab extends StatelessWidget {
  final GameState state;
  final VoidCallback onUpgradeScooter;
  final VoidCallback onUpgradeBag;

  const _EquipmentTab({
    required this.state,
    required this.onUpgradeScooter,
    required this.onUpgradeBag,
  });

  @override
  Widget build(BuildContext context) {
    final player = state.player;
    final scooterSpeed = switch (player.scooter.level) {
      1 => GameConfig.scooterSpeedLv1,
      2 => GameConfig.scooterSpeedLv2,
      3 => GameConfig.scooterSpeedLv3,
      _ => GameConfig.scooterSpeedLv1,
    };
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _EquipmentCard(
          emoji: '🛵',
          equipment: player.scooter,
          statLabel: '速度',
          statValue: '${scooterSpeed.toStringAsFixed(0)} tiles/s',
          money: player.money,
          onUpgrade: onUpgradeScooter,
        ),
        const SizedBox(height: 10),
        _EquipmentCard(
          emoji: '📦',
          equipment: player.bag,
          statLabel: '保溫',
          statValue: '-${player.foodCoolRate.toStringAsFixed(1)}%/min',
          money: player.money,
          onUpgrade: onUpgradeBag,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(AppColors.bgLight).withAlpha(120),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Color(AppColors.uiGray).withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('更多裝備',
                  style: TextStyle(
                      color: Color(AppColors.uiGray), fontSize: 13)),
              const SizedBox(height: 8),
              _LockedSlot(emoji: '⛑️', name: '安全帽'),
              _LockedSlot(emoji: '📹', name: '行車記錄器'),
              _LockedSlot(emoji: '🎧', name: '藍芽耳機'),
              _LockedSlot(emoji: '🧤', name: '手套'),
              _LockedSlot(emoji: '👟', name: '雨鞋'),
            ],
          ),
        ),
      ],
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final String emoji;
  final Equipment equipment;
  final String statLabel;
  final String statValue;
  final int money;
  final VoidCallback onUpgrade;

  const _EquipmentCard({
    required this.emoji,
    required this.equipment,
    required this.statLabel,
    required this.statValue,
    required this.money,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final cost = equipment.upgradeCost;
    final canUpgrade = cost != null && money >= cost;
    final isMax = equipment.isMaxLevel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(AppColors.bgLight),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMax
              ? Color(AppColors.neonGold).withAlpha(100)
              : Color(AppColors.uiGray).withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(equipment.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Color(AppColors.orangeMain).withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Lv.${equipment.level}',
                        style: TextStyle(
                            color: Color(AppColors.orangeMain), fontSize: 11)),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(equipment.description,
                    style: TextStyle(
                        color: Color(AppColors.uiGray), fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('$statLabel: ',
                      style: TextStyle(
                          color: Color(AppColors.uiGray), fontSize: 11)),
                  Text(statValue,
                      style: TextStyle(
                          color: Color(AppColors.neonGreen), fontSize: 11)),
                ]),
              ],
            ),
          ),
          if (isMax)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(AppColors.neonGold).withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('MAX',
                  style: TextStyle(
                      color: Color(AppColors.neonGold),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            )
          else
            GestureDetector(
              onTap: canUpgrade ? onUpgrade : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: canUpgrade
                      ? Color(AppColors.orangeMain)
                      : Color(AppColors.bgDarkest),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text('升級',
                        style: TextStyle(
                          color: canUpgrade
                              ? Colors.white
                              : Color(AppColors.uiGray),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        )),
                    Text('\$$cost',
                        style: TextStyle(
                          color: canUpgrade
                              ? Color(AppColors.neonGold)
                              : Color(AppColors.uiGray),
                          fontSize: 10,
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LockedSlot extends StatelessWidget {
  final String emoji;
  final String name;

  const _LockedSlot({required this.emoji, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(name,
              style: TextStyle(color: Color(AppColors.uiGray), fontSize: 12)),
          const Spacer(),
          Text('Phase 2 解鎖',
              style: TextStyle(
                  color: Color(AppColors.uiGray).withAlpha(120),
                  fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Tab 2: Missions ──

class _MissionTab extends StatelessWidget {
  final List<DailyMission> missions;
  final void Function(int) onClaim;

  const _MissionTab({required this.missions, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return Center(
        child: Text('今天沒有任務',
            style: TextStyle(color: Color(AppColors.uiGray), fontSize: 14)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final m = missions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(AppColors.bgLight),
            borderRadius: BorderRadius.circular(8),
            border: m.isComplete && !m.isClaimed
                ? Border.all(color: Color(AppColors.neonGreen), width: 1)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(m.title,
                      style: TextStyle(
                        color:
                            m.isClaimed ? Color(AppColors.uiGray) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      )),
                ),
                if (m.isClaimed)
                  Text('✅ 已領取',
                      style: TextStyle(
                          color: Color(AppColors.uiGray), fontSize: 11))
                else if (m.isComplete)
                  GestureDetector(
                    onTap: () => onClaim(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(AppColors.neonGreen),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('領取',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  Text('\$${m.reward}',
                      style: TextStyle(
                          color: Color(AppColors.neonGold), fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              Text(m.description,
                  style: TextStyle(
                      color: Color(AppColors.uiGray), fontSize: 11)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: m.progress,
                  backgroundColor: Color(AppColors.bgDarkest),
                  valueColor: AlwaysStoppedAnimation(
                    m.isComplete
                        ? Color(AppColors.neonGreen)
                        : Color(AppColors.orangeMain),
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 2),
              Text('${m.currentValue}/${m.targetValue}',
                  style: TextStyle(
                      color: Color(AppColors.uiGray), fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}

// ── Tab 3: Achievements ──

class _AchievementTab extends StatelessWidget {
  final GameState state;

  const _AchievementTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final player = state.player;
    final all = Achievement.allAchievements;
    final earned = player.achievements.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(children: [
            Text('$earned/${all.length}',
                style: TextStyle(
                    color: Color(AppColors.neonGold),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text('成就已解鎖',
                style: TextStyle(
                    color: Color(AppColors.uiGray), fontSize: 12)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: all.length,
            itemBuilder: (context, index) {
              final a = all[index];
              final unlocked = player.hasAchievement(a.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: unlocked
                      ? Color(AppColors.neonGold).withAlpha(15)
                      : Color(AppColors.bgLight),
                  borderRadius: BorderRadius.circular(8),
                  border: unlocked
                      ? Border.all(
                          color: Color(AppColors.neonGold).withAlpha(80))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? Color(AppColors.neonGold).withAlpha(40)
                            : Color(AppColors.bgDarkest),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          unlocked ? '🏆' : '🔒',
                          style: TextStyle(
                              fontSize: unlocked ? 20 : 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title,
                              style: TextStyle(
                                color: unlocked
                                    ? Color(AppColors.neonGold)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              )),
                          Text(a.description,
                              style: TextStyle(
                                  color: Color(AppColors.uiGray),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(unlocked ? '已獲得' : '\$${a.rewardMoney}',
                            style: TextStyle(
                              color: unlocked
                                  ? Color(AppColors.neonGreen)
                                  : Color(AppColors.neonGold),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Tab 4: Stats ──

class _StatsTab extends StatelessWidget {
  final GameState state;

  const _StatsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final player = state.player;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatRow('遊戲天數', 'Day ${player.dayNumber}'),
          _StatRow('總外送次數', '${player.totalDeliveries}'),
          _StatRow('今日外送', '${player.todayDeliveries}'),
          _StatRow('今日收入', '\$${player.todayEarnings}'),
          _StatRow('總資產', '\$${player.money}'),
          _StatRow('評分', '⭐ ${player.rating.toStringAsFixed(1)}'),
          _StatRow('機車', '${player.scooter.name} Lv.${player.scooter.level}'),
          _StatRow('外送箱', '${player.bag.name} Lv.${player.bag.level}'),
          _StatRow('連續登入', '${player.loginStreak} 天'),
          _StatRow('成就', '${player.achievements.length}/10'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  color: Color(AppColors.uiGray), fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
