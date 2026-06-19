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

  // ─── Color palette ───
  static const _cHelmet = Color(0xFFF5A623);
  static const _cHelmetDk = Color(0xFFD4830A);
  static const _cSkin = Color(0xFFF0C896);
  static const _cSkinDk = Color(0xFFD4A76A);
  static const _cEye = Color(0xFF0A0A1A);
  static const _cShine = Color(0xFFEEEEEE);
  static const _cShirt = Color(0xFF4ECDC4);
  static const _cShirtDk = Color(0xFF2D9B93);
  static const _cVest = Color(0xFFF5A623);
  static const _cVestDk = Color(0xFFD4830A);
  static const _cJeans = Color(0xFF5566AA);
  static const _cJeansDk = Color(0xFF445588);
  static const _cShoe = Color(0xFF5C4033);
  static const _cBag = Color(0xFFF5A623);
  static const _cBagDk = Color(0xFFD4830A);
  static const _cLogo = Color(0xFFFFD700);
  static const _cFrame = Color(0xFF555555);
  static const _cFrameDk = Color(0xFF333333);
  static const _cFrameLt = Color(0xFF888888);
  static const _cWheel = Color(0xFF1A1A1A);
  static const _cLight = Color(0xFFFFFF88);
  static const _cTail = Color(0xFFFF4444);
  static const _cShadow = Color(0x40000000);

  void _r(Canvas c, double x, double y, double w, double h, Color cl) {
    c.drawRect(Rect.fromLTWH(x, y, w, h), Paint()..color = cl);
  }

  @override
  void render(Canvas canvas) {
    if (_isRiding) {
      switch (_direction) {
        case 0: _scooterDown(canvas);
        case 1: _scooterLeft(canvas);
        case 2: _scooterRight(canvas);
        case 3: _scooterUp(canvas);
      }
    } else {
      switch (_direction) {
        case 0: _walkDown(canvas);
        case 1: _walkLeft(canvas);
        case 2: _walkRight(canvas);
        case 3: _walkUp(canvas);
      }
    }
  }

  // ══════════════════════════════════════════
  // WALKING — 4 top-down directional sprites
  // ══════════════════════════════════════════

  // ── Walk facing DOWN (south, toward camera) ──
  void _walkDown(Canvas canvas) {
    final p = size.x / 16;
    final step = _isMoving ? (_animFrame % 2 == 0 ? p : 0.0) : 0.0;

    // Shadow
    canvas.drawOval(Rect.fromLTWH(3 * p, 14.5 * p, 10 * p, 2 * p), Paint()..color = _cShadow);

    // Shoes
    _r(canvas, 4 * p, 14 * p + step, 3 * p, 1 * p, _cShoe);
    _r(canvas, 9 * p, 14 * p, 3 * p, 1 * p, _cShoe);

    // Legs
    _r(canvas, 4.5 * p, 11 * p, 2.5 * p, 3 * p + step, _cJeans);
    _r(canvas, 9 * p, 11 * p + step, 2.5 * p, 3 * p - step, _cJeans);
    _r(canvas, 4.5 * p, 11 * p, 2.5 * p, 0.5 * p, _cJeansDk);
    _r(canvas, 9 * p, 11 * p + step, 2.5 * p, 0.5 * p, _cJeansDk);

    // Body — shirt + vest
    _r(canvas, 4 * p, 6 * p, 8 * p, 5 * p, _cShirt);
    _r(canvas, 4 * p, 6 * p, 2 * p, 5 * p, _cVest);
    _r(canvas, 10 * p, 6 * p, 2 * p, 5 * p, _cVest);
    _r(canvas, 4 * p, 6 * p, 2 * p, 1 * p, _cVestDk);
    _r(canvas, 10 * p, 6 * p, 2 * p, 1 * p, _cVestDk);
    // Shirt collar
    _r(canvas, 7 * p, 6 * p, 2 * p, 1 * p, _cShirtDk);

    // Delivery bag (visible on front as strap)
    _r(canvas, 5 * p, 7 * p, 6 * p, 0.5 * p, _cBagDk);

    // Arms
    final armOff = _isMoving ? (_animFrame % 2 == 0 ? 0.7 * p : -0.7 * p) : 0.0;
    _r(canvas, 2.5 * p, 7 * p + armOff, 1.5 * p, 3 * p, _cSkin);
    _r(canvas, 12 * p, 7 * p - armOff, 1.5 * p, 3 * p, _cSkin);

    // Face
    _r(canvas, 5 * p, 3 * p, 6 * p, 3 * p, _cSkin);
    _r(canvas, 6 * p, 4 * p, 1.5 * p, 1.5 * p, _cEye);
    _r(canvas, 8.5 * p, 4 * p, 1.5 * p, 1.5 * p, _cEye);
    _r(canvas, 6 * p, 4 * p, 0.5 * p, 0.5 * p, _cShine);
    _r(canvas, 8.5 * p, 4 * p, 0.5 * p, 0.5 * p, _cShine);
    _r(canvas, 7 * p, 5.5 * p, 2 * p, 0.5 * p, _cSkinDk);

    // Helmet
    _r(canvas, 5 * p, 0, 6 * p, 0.5 * p, _cHelmetDk);
    _r(canvas, 4 * p, 0.5 * p, 8 * p, 2.5 * p, _cHelmet);
    _r(canvas, 5 * p, 1 * p, 6 * p, 0.5 * p, _cHelmetDk);
  }

  // ── Walk facing UP (north, away from camera) ──
  void _walkUp(Canvas canvas) {
    final p = size.x / 16;
    final step = _isMoving ? (_animFrame % 2 == 0 ? p : 0.0) : 0.0;

    canvas.drawOval(Rect.fromLTWH(3 * p, 14.5 * p, 10 * p, 2 * p), Paint()..color = _cShadow);

    // Shoes
    _r(canvas, 4 * p, 14 * p + step, 3 * p, 1 * p, _cShoe);
    _r(canvas, 9 * p, 14 * p, 3 * p, 1 * p, _cShoe);

    // Legs
    _r(canvas, 4.5 * p, 11 * p, 2.5 * p, 3 * p + step, _cJeans);
    _r(canvas, 9 * p, 11 * p + step, 2.5 * p, 3 * p - step, _cJeans);

    // Delivery backpack (most visible feature from behind)
    _r(canvas, 3.5 * p, 4 * p, 9 * p, 7 * p, _cBag);
    _r(canvas, 3.5 * p, 4 * p, 9 * p, 1.5 * p, _cBagDk);
    _r(canvas, 5 * p, 6 * p, 6 * p, 4 * p, _cLogo);
    _r(canvas, 5.5 * p, 6.5 * p, 5 * p, 3 * p, _cBagDk);
    // Bag straps over shoulders
    _r(canvas, 4.5 * p, 3 * p, 1 * p, 4 * p, _cBagDk);
    _r(canvas, 10.5 * p, 3 * p, 1 * p, 4 * p, _cBagDk);

    // Arms at sides
    final armOff = _isMoving ? (_animFrame % 2 == 0 ? 0.5 * p : -0.5 * p) : 0.0;
    _r(canvas, 2 * p, 6 * p + armOff, 1.5 * p, 3 * p, _cSkin);
    _r(canvas, 12.5 * p, 6 * p - armOff, 1.5 * p, 3 * p, _cSkin);

    // Back of head
    _r(canvas, 5 * p, 3 * p, 6 * p, 1 * p, _cSkinDk);

    // Helmet back
    _r(canvas, 5 * p, 0, 6 * p, 0.5 * p, _cHelmetDk);
    _r(canvas, 4 * p, 0.5 * p, 8 * p, 2.5 * p, _cHelmet);
    _r(canvas, 5 * p, 0.5 * p, 6 * p, 1 * p, _cHelmetDk);
  }

  // ── Walk facing LEFT (west, profile) ──
  void _walkLeft(Canvas canvas) {
    final p = size.x / 16;
    final step = _isMoving ? (_animFrame % 2 == 0 ? p : 0.0) : 0.0;

    canvas.drawOval(Rect.fromLTWH(3 * p, 14.5 * p, 10 * p, 2 * p), Paint()..color = _cShadow);

    // Shoes
    _r(canvas, 3 * p, 14 * p + step, 3.5 * p, 1 * p, _cShoe);
    _r(canvas, 7 * p, 14 * p, 3.5 * p, 1 * p, _cShoe);

    // Legs (side view, one forward one back)
    _r(canvas, 4 * p, 11 * p, 2.5 * p, 3 * p + step, _cJeans);
    _r(canvas, 7.5 * p, 11 * p + step, 2.5 * p, 3 * p - step, _cJeansDk);

    // Body (side view, vest on outside edges)
    _r(canvas, 4 * p, 6 * p, 7 * p, 5 * p, _cShirt);
    _r(canvas, 4 * p, 6 * p, 2 * p, 5 * p, _cVestDk);

    // Front arm
    final armOff = _isMoving ? (_animFrame % 2 == 0 ? p : -p) : 0.0;
    _r(canvas, 3 * p, 7 * p + armOff, 1.5 * p, 3 * p, _cSkin);

    // Delivery bag on back (right side of sprite)
    _r(canvas, 9 * p, 5 * p, 5 * p, 6 * p, _cBag);
    _r(canvas, 9 * p, 5 * p, 5 * p, 1 * p, _cBagDk);
    _r(canvas, 10 * p, 7 * p, 3 * p, 2.5 * p, _cLogo);

    // Face (side profile, facing left)
    _r(canvas, 4 * p, 3 * p, 6 * p, 3 * p, _cSkin);
    _r(canvas, 5 * p, 4 * p, 1.5 * p, 1.5 * p, _cEye);
    _r(canvas, 5 * p, 4 * p, 0.5 * p, 0.5 * p, _cShine);
    _r(canvas, 3.5 * p, 4.5 * p, 1 * p, 1 * p, _cSkinDk); // nose

    // Helmet (side)
    _r(canvas, 4 * p, 0, 6 * p, 0.5 * p, _cHelmetDk);
    _r(canvas, 3 * p, 0.5 * p, 8 * p, 2.5 * p, _cHelmet);
    _r(canvas, 3 * p, 1 * p, 2 * p, 2 * p, _cHelmetDk); // visor
  }

  // ── Walk facing RIGHT (east, profile) ──
  void _walkRight(Canvas canvas) {
    final p = size.x / 16;
    final step = _isMoving ? (_animFrame % 2 == 0 ? p : 0.0) : 0.0;

    canvas.drawOval(Rect.fromLTWH(3 * p, 14.5 * p, 10 * p, 2 * p), Paint()..color = _cShadow);

    // Shoes
    _r(canvas, 5.5 * p, 14 * p + step, 3.5 * p, 1 * p, _cShoe);
    _r(canvas, 9.5 * p, 14 * p, 3.5 * p, 1 * p, _cShoe);

    // Legs
    _r(canvas, 6 * p, 11 * p, 2.5 * p, 3 * p + step, _cJeansDk);
    _r(canvas, 9 * p, 11 * p + step, 2.5 * p, 3 * p - step, _cJeans);

    // Delivery bag on back (left side of sprite)
    _r(canvas, 2 * p, 5 * p, 5 * p, 6 * p, _cBag);
    _r(canvas, 2 * p, 5 * p, 5 * p, 1 * p, _cBagDk);
    _r(canvas, 3 * p, 7 * p, 3 * p, 2.5 * p, _cLogo);

    // Body
    _r(canvas, 5 * p, 6 * p, 7 * p, 5 * p, _cShirt);
    _r(canvas, 10 * p, 6 * p, 2 * p, 5 * p, _cVestDk);

    // Front arm
    final armOff = _isMoving ? (_animFrame % 2 == 0 ? p : -p) : 0.0;
    _r(canvas, 11.5 * p, 7 * p + armOff, 1.5 * p, 3 * p, _cSkin);

    // Face (side profile, facing right)
    _r(canvas, 6 * p, 3 * p, 6 * p, 3 * p, _cSkin);
    _r(canvas, 9.5 * p, 4 * p, 1.5 * p, 1.5 * p, _cEye);
    _r(canvas, 10.5 * p, 4 * p, 0.5 * p, 0.5 * p, _cShine);
    _r(canvas, 11.5 * p, 4.5 * p, 1 * p, 1 * p, _cSkinDk); // nose

    // Helmet
    _r(canvas, 6 * p, 0, 6 * p, 0.5 * p, _cHelmetDk);
    _r(canvas, 5 * p, 0.5 * p, 8 * p, 2.5 * p, _cHelmet);
    _r(canvas, 11 * p, 1 * p, 2 * p, 2 * p, _cHelmetDk); // visor
  }

  // ══════════════════════════════════════════════
  // SCOOTER — 4 top-down directional sprites
  // ══════════════════════════════════════════════

  // ── Scooter going DOWN (south) — top-down view ──
  void _scooterDown(Canvas canvas) {
    final p = size.x / 16;

    canvas.drawOval(Rect.fromLTWH(3 * p, 14.5 * p, 10 * p, 2 * p), Paint()..color = _cShadow);

    // Rear wheel (top of sprite = back of scooter)
    canvas.drawOval(Rect.fromLTWH(5.5 * p, 0, 5 * p, 2 * p), Paint()..color = _cWheel);
    canvas.drawOval(Rect.fromLTWH(6.5 * p, 0.4 * p, 3 * p, 1.2 * p), Paint()..color = _cFrameLt);

    // Delivery box (on back)
    _r(canvas, 4 * p, 1.5 * p, 8 * p, 4 * p, _cBag);
    _r(canvas, 4 * p, 1.5 * p, 8 * p, 1 * p, _cBagDk);
    _r(canvas, 5.5 * p, 3 * p, 5 * p, 2 * p, _cLogo);
    _r(canvas, 6 * p, 3.5 * p, 4 * p, 1 * p, _cBagDk);

    // Rider body from above (shoulders / teal shirt)
    _r(canvas, 5 * p, 5.5 * p, 6 * p, 2.5 * p, _cShirt);
    _r(canvas, 5 * p, 5.5 * p, 1.5 * p, 2.5 * p, _cVest);
    _r(canvas, 9.5 * p, 5.5 * p, 1.5 * p, 2.5 * p, _cVest);

    // Rider helmet from above (circle-ish)
    canvas.drawOval(Rect.fromLTWH(5.5 * p, 8 * p, 5 * p, 3 * p), Paint()..color = _cHelmet);
    canvas.drawOval(Rect.fromLTWH(6 * p, 8.5 * p, 4 * p, 2 * p), Paint()..color = _cHelmetDk);
    // Visor (dark strip at bottom of helmet)
    _r(canvas, 6.5 * p, 10.5 * p, 3 * p, 0.5 * p, _cEye);

    // Scooter body (narrow, between rider and front)
    _r(canvas, 6.5 * p, 11 * p, 3 * p, 1.5 * p, _cFrame);

    // Handlebars (wider than body)
    _r(canvas, 4 * p, 12 * p, 8 * p, 1 * p, _cFrameDk);
    _r(canvas, 3.5 * p, 12 * p, 1.5 * p, 1 * p, _cFrameLt); // left grip
    _r(canvas, 11 * p, 12 * p, 1.5 * p, 1 * p, _cFrameLt); // right grip

    // Headlight
    _r(canvas, 7 * p, 13 * p, 2 * p, 0.5 * p, _cLight);

    // Front wheel
    canvas.drawOval(Rect.fromLTWH(5.5 * p, 13.5 * p, 5 * p, 2 * p), Paint()..color = _cWheel);
    canvas.drawOval(Rect.fromLTWH(6.5 * p, 13.9 * p, 3 * p, 1.2 * p), Paint()..color = _cFrameLt);

    // Wheel spin
    if (_isMoving) {
      final a = _animFrame * pi / 4;
      final sp = Paint()..color = const Color(0xFF666666)..strokeWidth = 0.5;
      for (final wy in [1.0, 14.5]) {
        canvas.drawLine(
          Offset(8 * p + cos(a) * 2 * p, wy * p + sin(a) * 0.5 * p),
          Offset(8 * p - cos(a) * 2 * p, wy * p - sin(a) * 0.5 * p), sp);
      }
    }
  }

  // ── Scooter going UP (north) — top-down view ──
  void _scooterUp(Canvas canvas) {
    final p = size.x / 16;

    canvas.drawOval(Rect.fromLTWH(3 * p, 14.5 * p, 10 * p, 2 * p), Paint()..color = _cShadow);

    // Front wheel (top = direction of travel = north)
    canvas.drawOval(Rect.fromLTWH(5.5 * p, 0, 5 * p, 2 * p), Paint()..color = _cWheel);
    canvas.drawOval(Rect.fromLTWH(6.5 * p, 0.4 * p, 3 * p, 1.2 * p), Paint()..color = _cFrameLt);

    // Headlight (at top)
    _r(canvas, 7 * p, 1.8 * p, 2 * p, 0.5 * p, _cLight);

    // Handlebars
    _r(canvas, 4 * p, 2.5 * p, 8 * p, 1 * p, _cFrameDk);
    _r(canvas, 3.5 * p, 2.5 * p, 1.5 * p, 1 * p, _cFrameLt);
    _r(canvas, 11 * p, 2.5 * p, 1.5 * p, 1 * p, _cFrameLt);

    // Scooter body
    _r(canvas, 6.5 * p, 3.5 * p, 3 * p, 1.5 * p, _cFrame);

    // Rider helmet from above (seen from behind)
    canvas.drawOval(Rect.fromLTWH(5.5 * p, 5 * p, 5 * p, 3 * p), Paint()..color = _cHelmet);
    canvas.drawOval(Rect.fromLTWH(6 * p, 5.5 * p, 4 * p, 2 * p), Paint()..color = _cHelmetDk);

    // Rider body from above
    _r(canvas, 5 * p, 8 * p, 6 * p, 2.5 * p, _cShirt);
    _r(canvas, 5 * p, 8 * p, 1.5 * p, 2.5 * p, _cVest);
    _r(canvas, 9.5 * p, 8 * p, 1.5 * p, 2.5 * p, _cVest);

    // Delivery box (on back = bottom of sprite going up)
    _r(canvas, 4 * p, 10.5 * p, 8 * p, 4 * p, _cBag);
    _r(canvas, 4 * p, 10.5 * p, 8 * p, 1 * p, _cBagDk);
    _r(canvas, 5.5 * p, 12 * p, 5 * p, 2 * p, _cLogo);
    _r(canvas, 6 * p, 12.5 * p, 4 * p, 1 * p, _cBagDk);

    // Tail light
    _r(canvas, 7 * p, 14.5 * p, 2 * p, 0.5 * p, _cTail);

    // Rear wheel (bottom)
    canvas.drawOval(Rect.fromLTWH(5.5 * p, 14.5 * p, 5 * p, 2 * p), Paint()..color = _cWheel);
    canvas.drawOval(Rect.fromLTWH(6.5 * p, 14.9 * p, 3 * p, 1.2 * p), Paint()..color = _cFrameLt);
  }

  // ── Scooter going LEFT (west) — top-down side view ──
  void _scooterLeft(Canvas canvas) {
    final p = size.x / 16;

    canvas.drawOval(Rect.fromLTWH(2 * p, 14 * p, 12 * p, 2 * p), Paint()..color = _cShadow);

    // Front wheel (left = direction of travel)
    canvas.drawOval(Rect.fromLTWH(0, 10 * p, 3 * p, 5 * p), Paint()..color = _cWheel);
    canvas.drawOval(Rect.fromLTWH(0.5 * p, 11 * p, 2 * p, 3 * p), Paint()..color = _cFrameLt);

    // Headlight
    _r(canvas, 0.5 * p, 10 * p, 1 * p, 1.5 * p, _cLight);

    // Handlebar + front fork
    _r(canvas, 2.5 * p, 9 * p, 1.5 * p, 3 * p, _cFrameDk);
    _r(canvas, 2 * p, 8.5 * p, 2 * p, 1 * p, _cFrameLt); // grip

    // Scooter body (horizontal)
    _r(canvas, 3.5 * p, 10 * p, 7 * p, 4 * p, _cFrame);
    _r(canvas, 3.5 * p, 12 * p, 7 * p, 2 * p, _cFrameDk);
    // Seat
    _r(canvas, 5 * p, 9 * p, 4 * p, 2 * p, _cFrameDk);

    // Rider helmet (side profile, facing left)
    canvas.drawOval(Rect.fromLTWH(4 * p, 3 * p, 4 * p, 4 * p), Paint()..color = _cHelmet);
    _r(canvas, 4 * p, 4 * p, 1.5 * p, 2 * p, _cHelmetDk); // visor front
    // Face peek
    _r(canvas, 4.5 * p, 5 * p, 1 * p, 1 * p, _cSkin);
    _r(canvas, 4.5 * p, 5 * p, 0.5 * p, 0.5 * p, _cEye);

    // Rider body
    _r(canvas, 5 * p, 7 * p, 4 * p, 3 * p, _cShirt);
    _r(canvas, 5 * p, 7 * p, 1 * p, 3 * p, _cVest);
    // Arm on handlebar
    _r(canvas, 3.5 * p, 8 * p, 2 * p, 1.5 * p, _cSkin);

    // Delivery box (right = behind rider)
    _r(canvas, 9 * p, 3 * p, 5 * p, 7 * p, _cBag);
    _r(canvas, 9 * p, 3 * p, 5 * p, 1.5 * p, _cBagDk);
    _r(canvas, 10 * p, 5 * p, 3 * p, 3 * p, _cLogo);
    _r(canvas, 10.5 * p, 5.5 * p, 2 * p, 2 * p, _cBagDk);

    // Tail light
    _r(canvas, 13.5 * p, 11 * p, 0.5 * p, 1.5 * p, _cTail);

    // Rear wheel (right)
    canvas.drawOval(Rect.fromLTWH(13 * p, 10 * p, 3 * p, 5 * p), Paint()..color = _cWheel);
    canvas.drawOval(Rect.fromLTWH(13.5 * p, 11 * p, 2 * p, 3 * p), Paint()..color = _cFrameLt);
  }

  // ── Scooter going RIGHT (east) — top-down side view ──
  void _scooterRight(Canvas canvas) {
    final p = size.x / 16;

    canvas.drawOval(Rect.fromLTWH(2 * p, 14 * p, 12 * p, 2 * p), Paint()..color = _cShadow);

    // Rear wheel (left = behind)
    canvas.drawOval(Rect.fromLTWH(0, 10 * p, 3 * p, 5 * p), Paint()..color = _cWheel);
    canvas.drawOval(Rect.fromLTWH(0.5 * p, 11 * p, 2 * p, 3 * p), Paint()..color = _cFrameLt);

    // Tail light
    _r(canvas, 2 * p, 11 * p, 0.5 * p, 1.5 * p, _cTail);

    // Delivery box (left = behind rider)
    _r(canvas, 2 * p, 3 * p, 5 * p, 7 * p, _cBag);
    _r(canvas, 2 * p, 3 * p, 5 * p, 1.5 * p, _cBagDk);
    _r(canvas, 3 * p, 5 * p, 3 * p, 3 * p, _cLogo);
    _r(canvas, 3.5 * p, 5.5 * p, 2 * p, 2 * p, _cBagDk);

    // Scooter body
    _r(canvas, 5.5 * p, 10 * p, 7 * p, 4 * p, _cFrame);
    _r(canvas, 5.5 * p, 12 * p, 7 * p, 2 * p, _cFrameDk);
    _r(canvas, 7 * p, 9 * p, 4 * p, 2 * p, _cFrameDk); // seat

    // Rider body
    _r(canvas, 7 * p, 7 * p, 4 * p, 3 * p, _cShirt);
    _r(canvas, 10 * p, 7 * p, 1 * p, 3 * p, _cVest);
    // Arm on handlebar
    _r(canvas, 10.5 * p, 8 * p, 2 * p, 1.5 * p, _cSkin);

    // Rider helmet (side profile, facing right)
    canvas.drawOval(Rect.fromLTWH(8 * p, 3 * p, 4 * p, 4 * p), Paint()..color = _cHelmet);
    _r(canvas, 10.5 * p, 4 * p, 1.5 * p, 2 * p, _cHelmetDk); // visor
    _r(canvas, 10.5 * p, 5 * p, 1 * p, 1 * p, _cSkin);
    _r(canvas, 11 * p, 5 * p, 0.5 * p, 0.5 * p, _cEye);

    // Handlebar + front fork
    _r(canvas, 12 * p, 9 * p, 1.5 * p, 3 * p, _cFrameDk);
    _r(canvas, 12 * p, 8.5 * p, 2 * p, 1 * p, _cFrameLt); // grip

    // Headlight
    _r(canvas, 14.5 * p, 10 * p, 1 * p, 1.5 * p, _cLight);

    // Front wheel (right = direction of travel)
    canvas.drawOval(Rect.fromLTWH(13 * p, 10 * p, 3 * p, 5 * p), Paint()..color = _cWheel);
    canvas.drawOval(Rect.fromLTWH(13.5 * p, 11 * p, 2 * p, 3 * p), Paint()..color = _cFrameLt);
  }

  // ══════════════════════════════════
  // Movement logic (unchanged)
  // ══════════════════════════════════

  @override
  void update(double dt) {
    super.update(dt);

    _animTimer += dt;
    if (_animTimer > 0.15) {
      _animTimer = 0;
      _animFrame = (_animFrame + 1) % 8;
    }

    if (!_isMoving) return;

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
