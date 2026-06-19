import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/constants.dart';

class PlayerComponent extends PositionComponent {
  Vector2? _targetPosition;
  List<Vector2> _waypoints = [];
  int _waypointIndex = 0;
  double _speed = GameConfig.scooterSpeedLv1 * GameConfig.displayTileSize;
  bool _isMoving = false;
  bool _isRiding = false;
  double _animTimer = 0;
  int _animFrame = 0;
  int _direction = 0; // 0=down 1=left 2=right 3=up

  PlayerComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(GameConfig.displayTileSize),
          anchor: Anchor.center,
        );

  bool get isMoving => _isMoving;

  set isRiding(bool v) => _isRiding = v;

  @override
  void render(Canvas canvas) {
    final halfW = size.x / 2;
    final halfH = size.y / 2;

    canvas.save();
    canvas.translate(halfW, halfH);

    // Rotate based on movement direction
    // Default sprite faces right for scooter, down for walking
    if (_isRiding) {
      switch (_direction) {
        case 0: canvas.rotate(pi / 2);   // down
        case 1: canvas.rotate(pi);        // left
        case 2: break;                    // right (default)
        case 3: canvas.rotate(-pi / 2);  // up
      }
    } else {
      switch (_direction) {
        case 0: break;                    // down (default)
        case 1: canvas.scale(-1, 1);     // left = mirror
        case 2: break;                    // right (same as down for walk)
        case 3: canvas.rotate(pi);        // up = flip
      }
    }

    canvas.translate(-halfW, -halfH);

    if (_isRiding) {
      _renderScooter(canvas);
    } else {
      _renderWalking(canvas);
    }

    canvas.restore();
  }

  void _renderWalking(Canvas canvas) {
    final s = size.x;
    final p = s / 16;

    // Helmet
    final helmet = Paint()..color = Color(AppColors.orangeMain);
    final helmetDark = Paint()..color = Color(AppColors.orangeDark);
    canvas.drawRect(Rect.fromLTWH(4 * p, 0, 8 * p, 3 * p), helmet);
    canvas.drawRect(Rect.fromLTWH(3 * p, 1 * p, 10 * p, 2 * p), helmet);
    canvas.drawRect(Rect.fromLTWH(4 * p, 0, 8 * p, 1 * p), helmetDark);

    // Face
    final skin = Paint()..color = Color(AppColors.skinLight);
    final skinDark = Paint()..color = Color(AppColors.skinDark);
    canvas.drawRect(Rect.fromLTWH(4 * p, 3 * p, 8 * p, 4 * p), skin);
    final eye = Paint()..color = Color(AppColors.bgDarkest);
    canvas.drawRect(Rect.fromLTWH(5 * p, 4 * p, 2 * p, 2 * p), eye);
    canvas.drawRect(Rect.fromLTWH(9 * p, 4 * p, 2 * p, 2 * p), eye);
    final shine = Paint()..color = Color(AppColors.white);
    canvas.drawRect(Rect.fromLTWH(5 * p, 4 * p, 1 * p, 1 * p), shine);
    canvas.drawRect(Rect.fromLTWH(9 * p, 4 * p, 1 * p, 1 * p), shine);
    canvas.drawRect(Rect.fromLTWH(7 * p, 6 * p, 2 * p, 1 * p), skinDark);

    // Body
    final vest = Paint()..color = Color(AppColors.orangeMain);
    final vestDark = Paint()..color = Color(AppColors.orangeDark);
    final shirt = Paint()..color = Color(AppColors.tealMain);
    canvas.drawRect(Rect.fromLTWH(3 * p, 7 * p, 10 * p, 5 * p), vest);
    canvas.drawRect(Rect.fromLTWH(5 * p, 7 * p, 6 * p, 5 * p), shirt);
    canvas.drawRect(Rect.fromLTWH(3 * p, 7 * p, 2 * p, 5 * p), vestDark);
    canvas.drawRect(Rect.fromLTWH(11 * p, 7 * p, 2 * p, 5 * p), vestDark);

    // Arms with walk animation
    final armOff = _isMoving ? (_animFrame % 2 == 0 ? 1 * p : -1 * p) : 0.0;
    canvas.drawRect(
        Rect.fromLTWH(2 * p, 8 * p + armOff, 1 * p, 3 * p), skin);
    canvas.drawRect(
        Rect.fromLTWH(13 * p, 8 * p - armOff, 1 * p, 3 * p), skin);

    // Legs with walk animation
    final jeans = Paint()..color = Color(AppColors.bgLight);
    final legOff = _isMoving ? (_animFrame % 2 == 0 ? 1 * p : 0.0) : 0.0;
    canvas.drawRect(
        Rect.fromLTWH(4 * p, 12 * p, 3 * p, 3 * p + legOff), jeans);
    canvas.drawRect(
        Rect.fromLTWH(9 * p, 12 * p + legOff, 3 * p, 3 * p - legOff), jeans);

    // Shoes
    final shoes = Paint()..color = Color(AppColors.brownDark);
    canvas.drawRect(Rect.fromLTWH(3 * p, 15 * p, 4 * p, 1 * p), shoes);
    canvas.drawRect(Rect.fromLTWH(9 * p, 15 * p, 4 * p, 1 * p), shoes);

    // Delivery bag on back
    final bag = Paint()..color = Color(AppColors.orangeMain);
    final bagDark = Paint()..color = Color(AppColors.orangeDark);
    canvas.drawRect(Rect.fromLTWH(5 * p, 8 * p, 6 * p, 4 * p), bag);
    canvas.drawRect(Rect.fromLTWH(5 * p, 8 * p, 6 * p, 1 * p), bagDark);
    canvas.drawRect(
        Rect.fromLTWH(7 * p, 9 * p, 2 * p, 2 * p),
        Paint()..color = Color(AppColors.neonGold));

    // Shadow
    canvas.drawOval(
        Rect.fromLTWH(2 * p, 15 * p, 12 * p, 2 * p),
        Paint()..color = Colors.black.withAlpha(60));
  }

  void _renderScooter(Canvas canvas) {
    final s = size.x;
    final p = s / 16;

    // Scooter body (gray frame)
    final frame = Paint()..color = const Color(0xFF555555);
    final frameDark = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(Rect.fromLTWH(2 * p, 9 * p, 12 * p, 4 * p), frame);
    canvas.drawRect(Rect.fromLTWH(1 * p, 11 * p, 14 * p, 2 * p), frameDark);

    // Wheels
    final wheel = Paint()..color = const Color(0xFF1A1A1A);
    final wheelRim = Paint()..color = const Color(0xFF888888);
    canvas.drawCircle(Offset(4 * p, 14 * p), 2 * p, wheel);
    canvas.drawCircle(Offset(4 * p, 14 * p), 1 * p, wheelRim);
    canvas.drawCircle(Offset(12 * p, 14 * p), 2 * p, wheel);
    canvas.drawCircle(Offset(12 * p, 14 * p), 1 * p, wheelRim);

    // Wheel spin animation
    if (_isMoving) {
      final spoke = Paint()
        ..color = const Color(0xFF666666)
        ..strokeWidth = 0.5;
      final angle = _animFrame * pi / 4;
      for (final cx in [4.0, 12.0]) {
        canvas.drawLine(
          Offset(cx * p + cos(angle) * 1.5 * p, 14 * p + sin(angle) * 1.5 * p),
          Offset(cx * p - cos(angle) * 1.5 * p, 14 * p - sin(angle) * 1.5 * p),
          spoke,
        );
      }
    }

    // Handlebar
    canvas.drawRect(Rect.fromLTWH(12 * p, 7 * p, 2 * p, 3 * p), frameDark);
    canvas.drawRect(Rect.fromLTWH(11 * p, 6 * p, 4 * p, 1 * p), frame);

    // Headlight
    canvas.drawRect(
        Rect.fromLTWH(13 * p, 8 * p, 2 * p, 1 * p),
        Paint()..color = const Color(0xFFFFFF88));

    // Rider (small, sitting)
    final skin = Paint()..color = Color(AppColors.skinLight);
    final helmet = Paint()..color = Color(AppColors.orangeMain);
    // Helmet
    canvas.drawRect(Rect.fromLTWH(6 * p, 1 * p, 5 * p, 3 * p), helmet);
    canvas.drawRect(
        Rect.fromLTWH(6 * p, 1 * p, 5 * p, 1 * p),
        Paint()..color = Color(AppColors.orangeDark));
    // Face
    canvas.drawRect(Rect.fromLTWH(7 * p, 4 * p, 3 * p, 2 * p), skin);
    // Eyes
    canvas.drawRect(
        Rect.fromLTWH(7 * p, 4 * p, 1 * p, 1 * p),
        Paint()..color = Color(AppColors.bgDarkest));
    canvas.drawRect(
        Rect.fromLTWH(9 * p, 4 * p, 1 * p, 1 * p),
        Paint()..color = Color(AppColors.bgDarkest));
    // Body sitting
    canvas.drawRect(
        Rect.fromLTWH(5 * p, 6 * p, 6 * p, 4 * p),
        Paint()..color = Color(AppColors.orangeMain));
    canvas.drawRect(
        Rect.fromLTWH(6 * p, 6 * p, 4 * p, 4 * p),
        Paint()..color = Color(AppColors.tealMain));

    // Delivery box on back
    final box = Paint()..color = Color(AppColors.orangeMain);
    canvas.drawRect(Rect.fromLTWH(1 * p, 4 * p, 5 * p, 5 * p), box);
    canvas.drawRect(
        Rect.fromLTWH(1 * p, 4 * p, 5 * p, 1 * p),
        Paint()..color = Color(AppColors.orangeDark));
    canvas.drawRect(
        Rect.fromLTWH(2 * p, 6 * p, 3 * p, 2 * p),
        Paint()..color = Color(AppColors.neonGold));

    // Shadow
    canvas.drawOval(
        Rect.fromLTWH(1 * p, 15 * p, 14 * p, 2 * p),
        Paint()..color = Colors.black.withAlpha(60));
  }

  @override
  void update(double dt) {
    super.update(dt);

    _animTimer += dt;
    if (_animTimer > 0.15) {
      _animTimer = 0;
      _animFrame = (_animFrame + 1) % 8;
    }

    if (!_isMoving) return;

    // Get current target
    if (_targetPosition == null) {
      if (_waypointIndex < _waypoints.length) {
        _targetPosition = _waypoints[_waypointIndex];
      } else {
        _isMoving = false;
        return;
      }
    }

    final diff = _targetPosition! - position;
    final distance = diff.length;

    // Update direction
    if (diff.x.abs() > diff.y.abs()) {
      _direction = diff.x > 0 ? 2 : 1;
    } else {
      _direction = diff.y > 0 ? 0 : 3;
    }

    final moveAmount = _speed * dt;
    if (distance < moveAmount + 1.0) {
      position.setFrom(_targetPosition!);
      _waypointIndex++;
      if (_waypointIndex < _waypoints.length) {
        _targetPosition = _waypoints[_waypointIndex];
      } else {
        _targetPosition = null;
        _isMoving = false;
        _waypoints = [];
        _waypointIndex = 0;
      }
    } else {
      position += diff.normalized() * moveAmount;
    }
  }

  void moveAlongPath(List<Vector2> path) {
    if (path.isEmpty) return;
    _waypoints = path;
    _waypointIndex = 0;
    _targetPosition = _waypoints[0];
    _isMoving = true;
  }

  void moveTo(Vector2 target) {
    _waypoints = [target];
    _waypointIndex = 0;
    _targetPosition = target;
    _isMoving = true;
  }

  void setSpeed(double tilesPerSecond) {
    _speed = tilesPerSecond * GameConfig.displayTileSize;
  }

  void stop() {
    _targetPosition = null;
    _waypoints = [];
    _waypointIndex = 0;
    _isMoving = false;
  }
}
