import 'package:flutter_test/flutter_test.dart';
import 'package:taiwan_delivery_bro/models/player.dart';
import 'package:taiwan_delivery_bro/models/equipment.dart';
import 'package:taiwan_delivery_bro/models/order.dart';
import 'package:taiwan_delivery_bro/models/event_card.dart';
import 'package:taiwan_delivery_bro/config/constants.dart';

void main() {
  group('Player', () {
    test('newPlayer has correct defaults', () {
      final player = Player.newPlayer();
      expect(player.money, GameConfig.startingMoney);
      expect(player.rating, GameConfig.startingRating);
      expect(player.totalDeliveries, 0);
      expect(player.scooter.level, 1);
      expect(player.bag.level, 1);
    });

    test('addMoney returns new player with updated money', () {
      final player = Player.newPlayer();
      final updated = player.addMoney(100);
      expect(updated.money, player.money + 100);
      expect(player.money, GameConfig.startingMoney); // original unchanged
    });

    test('adjustRating clamps between 1.0 and 5.0', () {
      final player = Player.newPlayer();
      final up = player.adjustRating(10.0);
      expect(up.rating, 5.0);
      final down = player.adjustRating(-10.0);
      expect(down.rating, 1.0);
    });

    test('serialization round-trip', () {
      final player = Player.newPlayer().addMoney(500).addAchievement('test');
      final json = player.toJson();
      final restored = Player.fromJson(json);
      expect(restored.money, player.money);
      expect(restored.achievements, contains('test'));
    });
  });

  group('Equipment', () {
    test('upgrade increases level', () {
      final scooter = Equipment.defaultScooter();
      expect(scooter.level, 1);
      final upgraded = scooter.upgrade();
      expect(upgraded.level, 2);
    });

    test('max level cannot upgrade further', () {
      final scooter = Equipment.scooterAtLevel(3);
      expect(scooter.isMaxLevel, true);
      final same = scooter.upgrade();
      expect(same.level, 3);
    });
  });

  group('Order', () {
    test('random order has valid fields', () {
      final order = Order.random(
        pickupX: 10, pickupY: 10,
        deliveryX: 20, deliveryY: 20,
      );
      expect(order.reward, greaterThanOrEqualTo(GameConfig.minOrderReward));
      expect(order.reward, lessThan(GameConfig.maxOrderReward));
      expect(order.status, OrderStatus.idle);
    });

    test('order state machine', () {
      final order = Order.random(
        pickupX: 0, pickupY: 0,
        deliveryX: 10, deliveryY: 10,
      );
      final accepted = order.accept();
      expect(accepted.status, OrderStatus.pickup);

      final pickedUp = accepted.pickUp();
      expect(pickedUp.status, OrderStatus.delivering);

      final delivered = pickedUp.deliver();
      expect(delivered.status, OrderStatus.delivered);
    });
  });

  group('EventCard', () {
    test('draw returns a card', () {
      final card = EventCard.draw();
      expect(card.id, isNotEmpty);
      expect(card.title, isNotEmpty);
    });

    test('rollType returns valid type', () {
      // Run multiple times to exercise randomness
      for (int i = 0; i < 100; i++) {
        final type = EventCard.rollType();
        expect(CardType.values, contains(type));
      }
    });
  });
}
