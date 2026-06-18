import 'dart:math';

import '../../models/order.dart';
import '../components/map_component.dart';

/// Spawns new delivery orders at intervals
class OrderSpawner {
  final MapComponent map;
  final Random _rng = Random();

  double _timeSinceLastSpawn = 0;
  static const double _spawnInterval = 15.0; // seconds
  static const int _maxAvailableOrders = 3;

  OrderSpawner({required this.map});

  /// Returns a new order if it's time to spawn one, null otherwise
  Order? tick(double dt, int currentAvailableCount) {
    _timeSinceLastSpawn += dt;

    if (_timeSinceLastSpawn < _spawnInterval) return null;
    if (currentAvailableCount >= _maxAvailableOrders) return null;

    _timeSinceLastSpawn = 0;

    // Pick random restaurant → random customer
    if (map.restaurantPositions.isEmpty || map.customerPositions.isEmpty) {
      return null;
    }

    final restaurant =
        map.restaurantPositions[_rng.nextInt(map.restaurantPositions.length)];
    final customer =
        map.customerPositions[_rng.nextInt(map.customerPositions.length)];

    return Order.random(
      pickupX: restaurant.x,
      pickupY: restaurant.y,
      deliveryX: customer.x,
      deliveryY: customer.y,
    );
  }

  void reset() {
    _timeSinceLastSpawn = 0;
  }
}
