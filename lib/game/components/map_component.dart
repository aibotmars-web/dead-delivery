import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/constants.dart';

enum ParkingLine { white, red, yellow }

class MapComponent extends PositionComponent {
  List<List<TileType>> _tiles = [];
  List<List<int>> _tileVariant = [];
  Map<int, ParkingLine> _parkingLines = {};
  final int mapWidth = GameConfig.mapWidth;
  final int mapHeight = GameConfig.mapHeight;
  final double tileDisplaySize = GameConfig.displayTileSize;

  final List<Vector2> restaurantPositions = [];
  final List<Vector2> customerPositions = [];

  ui.Image? _sheet;
  final _paint = Paint()..filterQuality = FilterQuality.none;

  // Zone definitions: (x1, y1, x2, y2)
  static const _zoneNightMarket = (16, 16, 34, 34);
  static const _zoneResidential = (0, 0, 15, 15);
  static const _zoneCommercial = (30, 0, 49, 15);
  static const _zoneTemple = (0, 35, 15, 49);
  static const _zoneApartments = (35, 35, 49, 49);

  Rect _spr(int col, int row) =>
      Rect.fromLTWH(col * 17.0, row * 17.0, 16, 16);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(
      mapWidth * tileDisplaySize,
      mapHeight * tileDisplaySize,
    );
    _generateMap();
    _generateParkingLines();
    try {
      _sheet = await _loadImage('assets/tiles/kenney_city_sheet.png');
    } catch (_) {}
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _generateMap() {
    final rng = Random(42);

    _tiles = List.generate(
      mapHeight,
      (_) => List.filled(mapWidth, TileType.ground),
    );
    _tileVariant = List.generate(
      mapHeight,
      (y) => List.generate(mapWidth, (x) => rng.nextInt(100)),
    );

    // Main Roads (2-tile wide)
    for (final y in [12, 13, 25, 26, 38, 39]) {
      for (int x = 0; x < mapWidth; x++) {
        _tiles[y][x] = TileType.road;
      }
    }
    for (final x in [10, 11, 24, 25, 40, 41]) {
      for (int y = 0; y < mapHeight; y++) {
        _tiles[y][x] = TileType.road;
      }
    }

    // Secondary roads (1-tile wide)
    for (final y in [5, 18, 32, 45]) {
      for (int x = 2; x < mapWidth - 2; x++) {
        if (_tiles[y][x] == TileType.ground) _tiles[y][x] = TileType.road;
      }
    }
    for (final x in [4, 17, 32, 46]) {
      for (int y = 2; y < mapHeight - 2; y++) {
        if (_tiles[y][x] == TileType.ground) _tiles[y][x] = TileType.road;
      }
    }

    // Dead-end shortcut
    for (int x = 28; x < 35; x++) {
      _tiles[20][x] = TileType.road;
    }
    for (int y = 15; y < 20; y++) {
      _tiles[y][34] = TileType.road;
    }

    // Sidewalks
    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (_tiles[y][x] == TileType.ground && _hasAdjacentRoad(x, y)) {
          _tiles[y][x] = TileType.sidewalk;
        }
      }
    }

    // Zone fills
    _fillNightMarket(_zoneNightMarket);
    _fillBuildingZone(_zoneResidential);
    _fillBuildingZone(_zoneCommercial);
    _fillBuildingZone(_zoneTemple);
    _fillBuildingZone(_zoneApartments);

    // 3 Restaurants
    final restaurants = [(12, 14), (26, 24), (42, 6)];
    for (final (rx, ry) in restaurants) {
      for (int dy = 0; dy < 2; dy++) {
        for (int dx = 0; dx < 2; dx++) {
          if (ry + dy < mapHeight && rx + dx < mapWidth) {
            _tiles[ry + dy][rx + dx] = TileType.restaurant;
          }
        }
      }
      restaurantPositions.add(Vector2(
        (rx + 1) * tileDisplaySize,
        (ry + 1) * tileDisplaySize,
      ));
    }

    // 5 Customers
    final customers = [(6, 8), (8, 42), (35, 6), (44, 42), (22, 28)];
    for (final (cx, cy) in customers) {
      _tiles[cy][cx] = TileType.customer;
      customerPositions.add(Vector2(
        (cx + 0.5) * tileDisplaySize,
        (cy + 0.5) * tileDisplaySize,
      ));
    }
  }

  void _generateParkingLines() {
    _parkingLines = {};
    final mainH = {12, 13, 25, 26, 38, 39};
    final mainV = {10, 11, 24, 25, 40, 41};
    final secondaryH = {5, 18, 32, 45};
    final secondaryV = {4, 17, 32, 46};

    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (_tiles[y][x] != TileType.road) continue;
        if (!_hasAdjacentSidewalkOrBuilding(x, y)) continue;

        final key = y * mapWidth + x;
        final isMainRoad = mainH.contains(y) || mainV.contains(x);
        final isSecondary = secondaryH.contains(y) || secondaryV.contains(x);

        // Near intersection (within 2 tiles): always red (no stopping)
        final nearIntersectionH = mainH.any((r) => (y - r).abs() <= 2) && mainV.any((c) => (x - c).abs() <= 2);
        final nearIntersectionS = secondaryH.any((r) => (y - r).abs() <= 1) && secondaryV.any((c) => (x - c).abs() <= 1);
        if (nearIntersectionH || nearIntersectionS) {
          _parkingLines[key] = ParkingLine.red;
          continue;
        }

        // Main roads: red line (no stopping on arterials)
        if (isMainRoad) {
          _parkingLines[key] = ParkingLine.red;
          continue;
        }

        // Zone-specific rules on secondary/minor roads
        if (_inZone(x, y, _zoneNightMarket)) {
          // Night market: yellow (loading zones for vendors)
          _parkingLines[key] = ParkingLine.yellow;
        } else if (_inZone(x, y, _zoneCommercial)) {
          // Commercial: mostly yellow (loading), some white
          _parkingLines[key] = isSecondary ? ParkingLine.yellow : ParkingLine.white;
        } else if (_inZone(x, y, _zoneTemple)) {
          // Temple area: yellow near temples, red on main paths
          _parkingLines[key] = isSecondary ? ParkingLine.red : ParkingLine.yellow;
        } else if (_inZone(x, y, _zoneResidential)) {
          // Residential: mostly white (legal parking), some yellow
          _parkingLines[key] = isSecondary ? ParkingLine.yellow : ParkingLine.white;
        } else if (_inZone(x, y, _zoneApartments)) {
          // Apartments: white (legal parking on side streets)
          _parkingLines[key] = isSecondary ? ParkingLine.yellow : ParkingLine.white;
        } else {
          // Default: secondary = yellow, minor = white
          _parkingLines[key] = isSecondary ? ParkingLine.yellow : ParkingLine.white;
        }
      }
    }
  }

  ParkingLine? getParkingLineAt(int x, int y) {
    if (x < 0 || x >= mapWidth || y < 0 || y >= mapHeight) return null;
    return _parkingLines[y * mapWidth + x];
  }

  void _fillBuildingZone((int, int, int, int) zone) {
    final (x1, y1, x2, y2) = zone;
    for (int y = y1; y <= y2 && y < mapHeight; y++) {
      for (int x = x1; x <= x2 && x < mapWidth; x++) {
        if (_tiles[y][x] != TileType.ground) continue;
        final lx = (x - x1) % 7;
        final ly = (y - y1) % 7;
        if (lx < 5 && ly < 5) {
          _tiles[y][x] = TileType.building;
        } else {
          _tiles[y][x] = TileType.park;
        }
      }
    }
  }

  void _fillNightMarket((int, int, int, int) zone) {
    final (x1, y1, x2, y2) = zone;
    for (int y = y1; y <= y2 && y < mapHeight; y++) {
      for (int x = x1; x <= x2 && x < mapWidth; x++) {
        if (_tiles[y][x] != TileType.ground) continue;
        final ly = (y - y1) % 4;
        final lx = (x - x1) % 8;
        if (ly < 2 && lx < 6) {
          _tiles[y][x] = TileType.nightMarket;
        } else {
          _tiles[y][x] = TileType.sidewalk;
        }
      }
    }
  }

  bool _hasAdjacentRoad(int x, int y) {
    for (final (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 && nx < mapWidth && ny >= 0 && ny < mapHeight) {
        if (_tiles[ny][nx] == TileType.road) return true;
      }
    }
    return false;
  }

  bool _hasAdjacentSidewalkOrBuilding(int x, int y) {
    for (final (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 && nx < mapWidth && ny >= 0 && ny < mapHeight) {
        final t = _tiles[ny][nx];
        if (t == TileType.sidewalk || t == TileType.building ||
            t == TileType.restaurant || t == TileType.customer) return true;
      }
    }
    return false;
  }

  bool _roadAt(int x, int y) {
    if (x < 0 || x >= mapWidth || y < 0 || y >= mapHeight) return false;
    return _tiles[y][x] == TileType.road;
  }

  // ────────────────────── Rendering ──────────────────────

  @override
  void render(Canvas canvas) {
    if (_tiles.isEmpty) return;
    final ts = tileDisplaySize;

    // Fill beyond-map area so camera overshoot shows dark ground, not black
    final mapW = mapWidth * ts;
    final mapH = mapHeight * ts;
    const pad = 800.0;
    canvas.drawRect(
      Rect.fromLTWH(-pad, -pad, mapW + pad * 2, mapH + pad * 2),
      Paint()..color = const Color(0xFF2A2A2A),
    );

    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        final px = x * ts;
        final py = y * ts;
        final tile = _tiles[y][x];

        switch (tile) {
          case TileType.road:
            _drawRoad(canvas, x, y, px, py, ts);
          case TileType.sidewalk:
            _drawSidewalk(canvas, x, y, px, py, ts);
          case TileType.ground:
            _drawGround(canvas, px, py, ts);
          case TileType.building:
            _drawBuilding(canvas, x, y, px, py, ts);
          case TileType.nightMarket:
            _drawNightMarket(canvas, x, y, px, py, ts);
          case TileType.restaurant:
            _drawRestaurant(canvas, px, py, ts);
          case TileType.customer:
            _drawCustomer(canvas, x, y, px, py, ts);
          case TileType.park:
            _drawPark(canvas, x, y, px, py, ts);
        }
      }
    }

    _drawZoneLabels(canvas);
  }

  // ── Road with lane markings & parking lines ──
  void _drawRoad(Canvas canvas, int x, int y, double px, double py, double ts) {
    final rect = Rect.fromLTWH(px, py, ts, ts);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF404040));

    final p = ts / 16;
    final isMainH = _mainRoadsH.contains(y);
    final isMainV = _mainRoadsV.contains(x);
    final hasH = _roadAt(x - 1, y) || _roadAt(x + 1, y);
    final hasV = _roadAt(x, y - 1) || _roadAt(x, y + 1);
    final isIntersection = hasH && hasV;

    // Asphalt texture variation
    final v = _tileVariant[y][x];
    if (v % 7 == 0) {
      canvas.drawRect(
        Rect.fromLTWH(px + (v % 12) * p, py + (v % 10) * p, 3 * p, 2 * p),
        Paint()..color = const Color(0xFF383838),
      );
    }

    if (isIntersection) {
      // Intersection: crosswalk stripes at edges adjacent to sidewalk
      _drawCrosswalkIfNeeded(canvas, x, y, px, py, ts, p);
    } else if (hasH && !hasV) {
      // Horizontal road
      final isTopLane = isMainH && _mainRoadsH.contains(y + 1);
      final isBottomLane = isMainH && _mainRoadsH.contains(y - 1);

      if (isTopLane) {
        // Top lane of 2-lane road: draw dashed yellow center line at bottom edge
        _drawDashedLine(canvas, px, py + 15 * p, ts, 1.5 * p,
            isHorizontal: true, color: const Color(0xDDFFD600), dashLen: 4 * p);
        // White edge line at top
        canvas.drawRect(
          Rect.fromLTWH(px, py, ts, p),
          Paint()..color = const Color(0x88FFFFFF),
        );
      } else if (isBottomLane) {
        // Bottom lane: dashed yellow center at top edge
        _drawDashedLine(canvas, px, py, ts, 1.5 * p,
            isHorizontal: true, color: const Color(0xDDFFD600), dashLen: 4 * p);
        canvas.drawRect(
          Rect.fromLTWH(px, py + 15 * p, ts, p),
          Paint()..color = const Color(0x88FFFFFF),
        );
      } else {
        // Single-lane secondary road: dashed white center
        _drawDashedLine(canvas, px, py + 7 * p, ts, 1.5 * p,
            isHorizontal: true, color: const Color(0x99FFFFFF), dashLen: 3 * p);
        canvas.drawRect(Rect.fromLTWH(px, py, ts, p), Paint()..color = const Color(0x55FFFFFF));
        canvas.drawRect(Rect.fromLTWH(px, py + 15 * p, ts, p), Paint()..color = const Color(0x55FFFFFF));
      }
    } else if (hasV && !hasH) {
      // Vertical road
      final isLeftLane = isMainV && _mainRoadsV.contains(x + 1);
      final isRightLane = isMainV && _mainRoadsV.contains(x - 1);

      if (isLeftLane) {
        _drawDashedLine(canvas, px + 15 * p, py, 1.5 * p, ts,
            isHorizontal: false, color: const Color(0xDDFFD600), dashLen: 4 * p);
        canvas.drawRect(
          Rect.fromLTWH(px, py, p, ts),
          Paint()..color = const Color(0x88FFFFFF),
        );
      } else if (isRightLane) {
        _drawDashedLine(canvas, px, py, 1.5 * p, ts,
            isHorizontal: false, color: const Color(0xDDFFD600), dashLen: 4 * p);
        canvas.drawRect(
          Rect.fromLTWH(px + 15 * p, py, p, ts),
          Paint()..color = const Color(0x88FFFFFF),
        );
      } else {
        _drawDashedLine(canvas, px + 7 * p, py, 1.5 * p, ts,
            isHorizontal: false, color: const Color(0x99FFFFFF), dashLen: 3 * p);
        canvas.drawRect(Rect.fromLTWH(px, py, p, ts), Paint()..color = const Color(0x55FFFFFF));
        canvas.drawRect(Rect.fromLTWH(px + 15 * p, py, p, ts), Paint()..color = const Color(0x55FFFFFF));
      }
    }

    // Parking line stripe on road edge near sidewalk
    final pl = _parkingLines[y * mapWidth + x];
    if (pl != null) {
      final lineColor = switch (pl) {
        ParkingLine.red => const Color(0xFFE53935),
        ParkingLine.yellow => const Color(0xFFFFD600),
        ParkingLine.white => const Color(0xDDFFFFFF),
      };
      final linePaint = Paint()..color = lineColor;
      if (_isSidewalkOrBuilding(x, y - 1)) {
        canvas.drawRect(Rect.fromLTWH(px, py, ts, 1.5 * p), linePaint);
      }
      if (_isSidewalkOrBuilding(x, y + 1)) {
        canvas.drawRect(Rect.fromLTWH(px, py + ts - 1.5 * p, ts, 1.5 * p), linePaint);
      }
      if (_isSidewalkOrBuilding(x - 1, y)) {
        canvas.drawRect(Rect.fromLTWH(px, py, 1.5 * p, ts), linePaint);
      }
      if (_isSidewalkOrBuilding(x + 1, y)) {
        canvas.drawRect(Rect.fromLTWH(px + ts - 1.5 * p, py, 1.5 * p, ts), linePaint);
      }
    }
  }

  static const _mainRoadsH = {12, 13, 25, 26, 38, 39};
  static const _mainRoadsV = {10, 11, 24, 25, 40, 41};

  void _drawDashedLine(Canvas canvas, double x, double y, double w, double h,
      {required bool isHorizontal, required Color color, required double dashLen}) {
    final paint = Paint()..color = color;
    if (isHorizontal) {
      for (double dx = 0; dx < w; dx += dashLen * 2) {
        canvas.drawRect(Rect.fromLTWH(x + dx, y, dashLen.clamp(0, w - dx), h), paint);
      }
    } else {
      for (double dy = 0; dy < h; dy += dashLen * 2) {
        canvas.drawRect(Rect.fromLTWH(x, y + dy, w, dashLen.clamp(0, h - dy)), paint);
      }
    }
  }

  void _drawCrosswalkIfNeeded(Canvas canvas, int x, int y, double px, double py, double ts, double p) {
    final cwPaint = Paint()..color = const Color(0xAAFFFFFF);
    // Draw crosswalk stripes where road meets sidewalk
    if (_isSidewalkOrBuilding(x, y - 1)) {
      for (double sx = 2 * p; sx < ts - 2 * p; sx += 4 * p) {
        canvas.drawRect(Rect.fromLTWH(px + sx, py, 2 * p, 3 * p), cwPaint);
      }
    }
    if (_isSidewalkOrBuilding(x, y + 1)) {
      for (double sx = 2 * p; sx < ts - 2 * p; sx += 4 * p) {
        canvas.drawRect(Rect.fromLTWH(px + sx, py + ts - 3 * p, 2 * p, 3 * p), cwPaint);
      }
    }
    if (_isSidewalkOrBuilding(x - 1, y)) {
      for (double sy = 2 * p; sy < ts - 2 * p; sy += 4 * p) {
        canvas.drawRect(Rect.fromLTWH(px, py + sy, 3 * p, 2 * p), cwPaint);
      }
    }
    if (_isSidewalkOrBuilding(x + 1, y)) {
      for (double sy = 2 * p; sy < ts - 2 * p; sy += 4 * p) {
        canvas.drawRect(Rect.fromLTWH(px + ts - 3 * p, py + sy, 3 * p, 2 * p), cwPaint);
      }
    }

    // Traffic light at major intersections (top-left corner sidewalk)
    if (_mainRoadsH.contains(y) && _mainRoadsV.contains(x)) {
      final isCorner = _isSidewalkOrBuilding(x - 1, y - 1);
      if (isCorner) {
        _drawTrafficLight(canvas, px, py, p);
      }
    }
  }

  void _drawTrafficLight(Canvas canvas, double px, double py, double p) {
    // Pole
    canvas.drawRect(
      Rect.fromLTWH(px + 1 * p, py + 4 * p, 1.5 * p, 12 * p),
      Paint()..color = const Color(0xFF4A4A4A),
    );
    // Horizontal arm
    canvas.drawRect(
      Rect.fromLTWH(px + 1 * p, py + 4 * p, 8 * p, 1 * p),
      Paint()..color = const Color(0xFF4A4A4A),
    );
    // Signal box
    canvas.drawRect(
      Rect.fromLTWH(px + 6 * p, py + 1 * p, 4 * p, 7 * p),
      Paint()..color = const Color(0xFF333333),
    );
    // Red light
    canvas.drawCircle(
      Offset(px + 8 * p, py + 2.5 * p), 1 * p,
      Paint()..color = const Color(0xFFFF1744),
    );
    // Yellow light
    canvas.drawCircle(
      Offset(px + 8 * p, py + 4.5 * p), 1 * p,
      Paint()..color = const Color(0xFF333333),
    );
    // Green light
    canvas.drawCircle(
      Offset(px + 8 * p, py + 6.5 * p), 1 * p,
      Paint()..color = const Color(0xFF333333),
    );
  }

  bool _isSidewalkOrBuilding(int x, int y) {
    if (x < 0 || x >= mapWidth || y < 0 || y >= mapHeight) return false;
    final t = _tiles[y][x];
    return t == TileType.sidewalk || t == TileType.building ||
        t == TileType.restaurant || t == TileType.customer;
  }

  // ── Sidewalk with street furniture ──
  void _drawSidewalk(Canvas canvas, int x, int y, double px, double py, double ts) {
    canvas.drawRect(
      Rect.fromLTWH(px, py, ts, ts),
      Paint()..color = const Color(0xFFB0A898),
    );
    final p = ts / 16;
    final v = _tileVariant[y][x];

    // Paving pattern (brick-like)
    final tileLine = Paint()..color = const Color(0x18000000);
    for (int row = 0; row < 4; row++) {
      final off = row.isOdd ? 4.0 : 0.0;
      for (double bx = off; bx < 16; bx += 8) {
        canvas.drawRect(
          Rect.fromLTWH(px + bx * p, py + row * 4 * p, 8 * p, 0.5 * p), tileLine);
        canvas.drawRect(
          Rect.fromLTWH(px + bx * p, py + row * 4 * p, 0.5 * p, 4 * p), tileLine);
      }
    }

    // Curb edge (darker strip near road)
    final curb = Paint()..color = const Color(0xFF787878);
    if (_roadAt(x, y + 1)) canvas.drawRect(Rect.fromLTWH(px, py + 14 * p, ts, 2 * p), curb);
    if (_roadAt(x, y - 1)) canvas.drawRect(Rect.fromLTWH(px, py, ts, 2 * p), curb);
    if (_roadAt(x + 1, y)) canvas.drawRect(Rect.fromLTWH(px + 14 * p, py, 2 * p, ts), curb);
    if (_roadAt(x - 1, y)) canvas.drawRect(Rect.fromLTWH(px, py, 2 * p, ts), curb);

    // Street furniture (scattered props on some sidewalk tiles)
    if (v % 11 == 0) {
      // Utility pole
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 2 * p, 1.5 * p, 14 * p), Paint()..color = const Color(0xFF5D5D5D));
      canvas.drawRect(Rect.fromLTWH(px, py + 2 * p, 5 * p, 1 * p), Paint()..color = const Color(0xFF4A4A4A));
    } else if (v % 13 == 0) {
      // Parked scooter (side view)
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 10 * p, 8 * p, 4 * p), Paint()..color = const Color(0xFF424242));
      canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 8 * p, 4 * p, 3 * p), Paint()..color = const Color(0xFF616161));
      canvas.drawCircle(Offset(px + 5 * p, py + 14 * p), 1.5 * p, Paint()..color = const Color(0xFF333333));
      canvas.drawCircle(Offset(px + 11 * p, py + 14 * p), 1.5 * p, Paint()..color = const Color(0xFF333333));
    } else if (v % 17 == 0) {
      // Trash can
      canvas.drawRect(Rect.fromLTWH(px + 6 * p, py + 8 * p, 4 * p, 6 * p), Paint()..color = const Color(0xFF2E7D32));
      canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 7 * p, 6 * p, 2 * p), Paint()..color = const Color(0xFF388E3C));
    } else if (v % 19 == 0) {
      // Mailbox (台灣郵筒 green+red)
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 6 * p, 3 * p, 8 * p), Paint()..color = const Color(0xFF2E7D32));
      canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 6 * p, 3 * p, 8 * p), Paint()..color = const Color(0xFFD32F2F));
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 5 * p, 8 * p, 2 * p), Paint()..color = const Color(0xFF424242));
    } else if (v % 23 == 0) {
      // Vending machine (自動販賣機)
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 4 * p, 5 * p, 10 * p), Paint()..color = const Color(0xFFD32F2F));
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 5 * p, 3 * p, 4 * p), Paint()..color = const Color(0xCC90CAF9));
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 10 * p, 3 * p, 1 * p), Paint()..color = const Color(0xFF333333));
      // Light on top
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 3.5 * p, 5 * p, 0.5 * p), Paint()..color = const Color(0xCCFFFFFF));
    } else if (v % 29 == 0) {
      // Bus stop shelter (公車站牌)
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 3 * p, 1.5 * p, 11 * p), Paint()..color = const Color(0xFF616161));
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 3 * p, 8 * p, 1 * p), Paint()..color = const Color(0xFF757575));
      // Route sign
      canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 5 * p, 5 * p, 3 * p), Paint()..color = const Color(0xFF1565C0));
      canvas.drawRect(Rect.fromLTWH(px + 6 * p, py + 6 * p, 3 * p, 1 * p), Paint()..color = const Color(0xCCFFFFFF));
    } else if (v % 31 == 0) {
      // Fire hydrant (消防栓)
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 10 * p, 2 * p, 4 * p), Paint()..color = const Color(0xFFD32F2F));
      canvas.drawRect(Rect.fromLTWH(px + 6 * p, py + 9 * p, 4 * p, 2 * p), Paint()..color = const Color(0xFFE53935));
      canvas.drawCircle(Offset(px + 8 * p, py + 9.5 * p), 1 * p, Paint()..color = const Color(0xFFFFCDD2));
    }
  }

  // ── Ground ──
  void _drawGround(Canvas canvas, double px, double py, double ts) {
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFF2D4A2D));
    final p = ts / 16;
    final v = ((px * 7 + py * 13) % 17).toInt();
    if (v < 5) {
      canvas.drawRect(
        Rect.fromLTWH(px + (v * 2) * p, py + (v * 3 % 14) * p, 2 * p, 2 * p),
        Paint()..color = const Color(0xFF3D5A3D),
      );
    }
  }

  // ── Building: zone-specific distinct pixel art ──
  void _drawBuilding(Canvas canvas, int x, int y, double px, double py, double ts) {
    if (_inZone(x, y, _zoneResidential)) {
      _drawResidential(canvas, x, y, px, py, ts);
    } else if (_inZone(x, y, _zoneCommercial)) {
      _drawCommercial(canvas, x, y, px, py, ts);
    } else if (_inZone(x, y, _zoneTemple)) {
      _drawTemple(canvas, x, y, px, py, ts);
    } else {
      _drawApartment(canvas, x, y, px, py, ts);
    }
  }

  // ── Residential: KAI-style Taiwan townhouses — red brick, detailed 鐵窗, balcony life ──
  void _drawResidential(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];

    // Facade color variants (warm Taiwan brick tones)
    final facades = [
      const Color(0xFFB85C3C), const Color(0xFFC4704A),
      const Color(0xFFAA5030), const Color(0xFFD4896C),
    ];
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = facades[v % facades.length]);

    // Brick pattern — staggered rows
    final brickDark = Paint()..color = facades[v % facades.length].withAlpha(160);
    for (int row = 0; row < 8; row++) {
      final off = row.isOdd ? 3.0 : 0.0;
      for (double bx = off; bx < 16; bx += 6) {
        canvas.drawRect(Rect.fromLTWH(px + bx * p, py + row * 2 * p, 0.5 * p, 2 * p), brickDark);
      }
    }

    // Roof — tiles with ridge detail
    final roofColors = [const Color(0xFF5D3A1A), const Color(0xFF4A2E15), const Color(0xFF6B4423)];
    final rc = roofColors[v % roofColors.length];
    canvas.drawRect(Rect.fromLTWH(px, py, ts, 3 * p), Paint()..color = rc);
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py, 14 * p, 1 * p), Paint()..color = rc.withAlpha(200));
    // Tile rows on roof
    for (double rx = 0; rx < 16; rx += 2) {
      canvas.drawRect(Rect.fromLTWH(px + rx * p, py + 1 * p, 1 * p, 2 * p), Paint()..color = rc.withAlpha(180));
    }
    // Gutter
    canvas.drawRect(Rect.fromLTWH(px, py + 3 * p, ts, 0.5 * p), Paint()..color = const Color(0xFF555555));

    // 2F: Two windows with full 鐵窗 grilles
    final winBg = Paint()..color = const Color(0xAAA8D8F0);
    final winLit = Paint()..color = const Color(0xCCFFE082);
    final winFrame = Paint()..color = const Color(0xFFD5C8B0);
    final grille = Paint()..color = const Color(0xFF4A4A4A);
    final grilleLt = Paint()..color = const Color(0xFF666666);

    // Left window
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 4 * p, 6 * p, 4.5 * p), winFrame);
    canvas.drawRect(Rect.fromLTWH(px + 1.5 * p, py + 4.5 * p, 5 * p, 3.5 * p), v % 2 == 0 ? winLit : winBg);
    // Grille bars
    for (double gx = 1.5; gx < 6.5; gx += 1.2) {
      canvas.drawRect(Rect.fromLTWH(px + gx * p, py + 4 * p, 0.4 * p, 4.5 * p), grille);
    }
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 6 * p, 6 * p, 0.4 * p), grilleLt);

    // Right window
    canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 4 * p, 6 * p, 4.5 * p), winFrame);
    canvas.drawRect(Rect.fromLTWH(px + 9.5 * p, py + 4.5 * p, 5 * p, 3.5 * p), winBg);
    for (double gx = 9.5; gx < 14.5; gx += 1.2) {
      canvas.drawRect(Rect.fromLTWH(px + gx * p, py + 4 * p, 0.4 * p, 4.5 * p), grille);
    }
    canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 6 * p, 6 * p, 0.4 * p), grilleLt);

    // Balcony with railing + potted plants
    canvas.drawRect(Rect.fromLTWH(px, py + 8.5 * p, ts, 0.5 * p), Paint()..color = const Color(0xFF888888));
    for (double rx = 1; rx < 15; rx += 1.5) {
      canvas.drawRect(Rect.fromLTWH(px + rx * p, py + 9 * p, 0.4 * p, 1.5 * p), grille);
    }
    canvas.drawRect(Rect.fromLTWH(px, py + 10.5 * p, ts, 0.4 * p), grille);
    // Balcony plants
    if (v % 3 != 2) {
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 9.5 * p, 1.5 * p, 1 * p), Paint()..color = const Color(0xFF6D4C41));
      canvas.drawCircle(Offset(px + 2.7 * p, py + 9 * p), 1.2 * p, Paint()..color = const Color(0xFF4CAF50));
      canvas.drawRect(Rect.fromLTWH(px + 12 * p, py + 9.5 * p, 1.5 * p, 1 * p), Paint()..color = const Color(0xFF5D4037));
      canvas.drawCircle(Offset(px + 12.7 * p, py + 9 * p), 1 * p, Paint()..color = const Color(0xFF66BB6A));
    }

    // AC unit with drip pipe
    if (v % 3 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 5.5 * p, 2.5 * p, 1.5 * p), Paint()..color = const Color(0xFF888888));
      canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 5.5 * p, 2.5 * p, 0.4 * p), Paint()..color = const Color(0xFFAAAAAA));
      canvas.drawRect(Rect.fromLTWH(px + 15.3 * p, py + 7 * p, 0.4 * p, 9 * p), Paint()..color = const Color(0xFF666666));
    }

    // 1F: 鐵捲門 roller shutter + door
    canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 11 * p, 10 * p, 5 * p), Paint()..color = const Color(0xFF707070));
    // Shutter ridges
    for (double sy = 11; sy < 16; sy += 0.8) {
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + sy * p, 10 * p, 0.3 * p), Paint()..color = const Color(0xFF606060));
    }
    // Door handle
    canvas.drawRect(Rect.fromLTWH(px + 12 * p, py + 13 * p, 0.5 * p, 1.5 * p), Paint()..color = const Color(0xFFBDBDBD));

    // Address plate
    canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 12 * p, 2.5 * p, 1.5 * p), Paint()..color = const Color(0xFF1565C0));
    canvas.drawRect(Rect.fromLTWH(px + 0.8 * p, py + 12.3 * p, 1.9 * p, 0.9 * p), Paint()..color = const Color(0xDDFFFFFF));

    // Street-level potted plants
    if (v % 2 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 14 * p, py + 14 * p, 1.5 * p, 2 * p), Paint()..color = const Color(0xFF8B4513));
      canvas.drawCircle(Offset(px + 14.7 * p, py + 13.5 * p), 1.3 * p, Paint()..color = const Color(0xFF388E3C));
    }

    // Cable bundle on facade
    if (v % 5 == 0) {
      canvas.drawRect(Rect.fromLTWH(px, py + 3.5 * p, ts, 0.3 * p), Paint()..color = const Color(0xFF222222));
    }
  }

  // ── Commercial: KAI-style Taiwan shopfronts — huge 招牌, display windows, merchandise ──
  void _drawCommercial(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];

    // Facade base (light concrete/tile tones)
    final facades = [
      const Color(0xFFD7CCC8), const Color(0xFFCFD8DC),
      const Color(0xFFE8E0D8), const Color(0xFFD5CAB8),
    ];
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = facades[v % facades.length]);

    // BIG colorful 招牌 sign (takes up full width, top 5 units)
    final signColors = [
      const Color(0xFFD32F2F), const Color(0xFF1565C0),
      const Color(0xFF2E7D32), const Color(0xFFF57F17),
      const Color(0xFF6A1B9A), const Color(0xFFE65100),
      const Color(0xFF00838F), const Color(0xFFC62828),
    ];
    final sc = signColors[v % signColors.length];
    // Sign body with border
    canvas.drawRect(Rect.fromLTWH(px, py, ts, 5 * p), Paint()..color = sc);
    canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 0.5 * p, 15 * p, 4 * p), Paint()..color = sc.withAlpha(220));
    // Gold/white border around sign
    final borderC = v % 2 == 0 ? const Color(0xFFDAA520) : const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(px, py, ts, 0.5 * p), Paint()..color = borderC);
    canvas.drawRect(Rect.fromLTWH(px, py + 4.5 * p, ts, 0.5 * p), Paint()..color = borderC);
    canvas.drawRect(Rect.fromLTWH(px, py, 0.5 * p, 5 * p), Paint()..color = borderC);
    canvas.drawRect(Rect.fromLTWH(px + 15.5 * p, py, 0.5 * p, 5 * p), Paint()..color = borderC);
    // Faux text blocks on sign (big characters)
    final textC = Paint()..color = const Color(0xEEFFFFFF);
    canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 1 * p, 3 * p, 3 * p), textC);
    canvas.drawRect(Rect.fromLTWH(px + 6 * p, py + 1 * p, 3 * p, 3 * p), textC);
    if (v % 3 != 2) {
      canvas.drawRect(Rect.fromLTWH(px + 10 * p, py + 1 * p, 3 * p, 3 * p), textC);
    }

    // 2F windows with 鐵窗 grilles
    final glassPaint = Paint()..color = const Color(0xAA90CAF9);
    final grille = Paint()..color = const Color(0xFF555555);
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 5.5 * p, 6 * p, 3 * p), glassPaint);
    canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 5.5 * p, 6 * p, 3 * p), glassPaint);
    for (double gx = 1; gx < 7; gx += 1.2) {
      canvas.drawRect(Rect.fromLTWH(px + gx * p, py + 5.5 * p, 0.3 * p, 3 * p), grille);
    }
    for (double gx = 9; gx < 15; gx += 1.2) {
      canvas.drawRect(Rect.fromLTWH(px + gx * p, py + 5.5 * p, 0.3 * p, 3 * p), grille);
    }

    // 遮雨棚 awning — striped
    final awningColors = [
      const Color(0xFF1B5E20), const Color(0xFF880E4F),
      const Color(0xFF0D47A1), const Color(0xFF4A148C),
    ];
    final ac = awningColors[v % awningColors.length];
    canvas.drawRect(Rect.fromLTWH(px, py + 9 * p, ts, 2 * p), Paint()..color = ac);
    for (double sx = 0; sx < 16; sx += 3) {
      canvas.drawRect(Rect.fromLTWH(px + sx * p, py + 9 * p, 1.5 * p, 2 * p), Paint()..color = ac.withAlpha(140));
    }
    // Scalloped edge
    canvas.drawRect(Rect.fromLTWH(px, py + 11 * p, ts, 0.3 * p), Paint()..color = const Color(0xFF424242));

    // 1F display window with "merchandise"
    canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 11.5 * p, 8 * p, 4.5 * p), Paint()..color = const Color(0xAA80DEEA));
    // Merchandise blobs (colored dots in window)
    final merchColors = [
      const Color(0xFFFF7043), const Color(0xFFFFCA28),
      const Color(0xFF66BB6A), const Color(0xFFAB47BC),
      const Color(0xFF42A5F5), const Color(0xFFEF5350),
    ];
    for (int mi = 0; mi < 4; mi++) {
      final mx = 1.5 + mi * 1.8;
      canvas.drawRect(
        Rect.fromLTWH(px + mx * p, py + 13 * p, 1.2 * p, 1.2 * p),
        Paint()..color = merchColors[(v + mi) % merchColors.length],
      );
    }
    // Shelf line
    canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 14.5 * p, 8 * p, 0.3 * p), Paint()..color = const Color(0xFF795548));

    // Glass door
    canvas.drawRect(Rect.fromLTWH(px + 9.5 * p, py + 11.5 * p, 4 * p, 4.5 * p), Paint()..color = const Color(0xFF37474F));
    canvas.drawRect(Rect.fromLTWH(px + 10 * p, py + 12 * p, 3 * p, 3.5 * p), Paint()..color = const Color(0x8880DEEA));
    canvas.drawRect(Rect.fromLTWH(px + 12.5 * p, py + 13.5 * p, 0.5 * p, 1.5 * p), Paint()..color = const Color(0xFFBDBDBD));

    // 營業中 open sign / LED
    if (v % 3 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 14 * p, py + 12 * p, 1.5 * p, 1 * p), Paint()..color = const Color(0xCCFF1744));
    }

    // Rooftop stuff
    if (v % 4 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 12 * p, py - 1.5 * p, 3.5 * p, 1.5 * p), Paint()..color = const Color(0xFF757575));
    }
  }

  // ── Temple: KAI-style traditional red+gold — ornate roof, lanterns, dragon ridge ──
  void _drawTemple(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];

    // Deep red wall
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFF8B1A1A));

    final gold = Paint()..color = const Color(0xFFDAA520);
    final goldBright = Paint()..color = const Color(0xFFFFD700);
    final roofDark = Paint()..color = const Color(0xFF3D1C00);
    final roofMid = Paint()..color = const Color(0xFF5C3317);

    // Multi-layer curved roof
    canvas.drawRect(Rect.fromLTWH(px - 0.5 * p, py + 1 * p, 17 * p, 3 * p), roofDark);
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 1.5 * p, 14 * p, 2 * p), roofMid);
    // Gold trim layers
    canvas.drawRect(Rect.fromLTWH(px - 0.5 * p, py + 3.5 * p, 17 * p, 0.8 * p), gold);
    canvas.drawRect(Rect.fromLTWH(px, py + 1 * p, ts, 0.4 * p), gold);
    // Upswept eave corners
    canvas.drawRect(Rect.fromLTWH(px - 0.5 * p, py + 0.5 * p, 2 * p, 1 * p), roofDark);
    canvas.drawRect(Rect.fromLTWH(px + 14.5 * p, py + 0.5 * p, 2 * p, 1 * p), roofDark);
    canvas.drawRect(Rect.fromLTWH(px - 0.5 * p, py + 0.5 * p, 1 * p, 0.5 * p), gold);
    canvas.drawRect(Rect.fromLTWH(px + 15.5 * p, py + 0.5 * p, 1 * p, 0.5 * p), gold);
    // Ridge ornament (dragon/pearl)
    canvas.drawRect(Rect.fromLTWH(px + 6.5 * p, py, 3 * p, 1 * p), goldBright);
    canvas.drawRect(Rect.fromLTWH(px + 7.5 * p, py - 0.5 * p, 1 * p, 0.5 * p), goldBright);

    // Red pillars with gold caps
    final pillar = Paint()..color = const Color(0xFFCC2222);
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 4.5 * p, 2 * p, 11.5 * p), pillar);
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 4.5 * p, 2 * p, 11.5 * p), pillar);
    canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 4.5 * p, 3 * p, 0.5 * p), gold);
    canvas.drawRect(Rect.fromLTWH(px + 12.5 * p, py + 4.5 * p, 3 * p, 0.5 * p), gold);

    // Ornate door with gold frame
    canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 6 * p, 8 * p, 10 * p), Paint()..color = const Color(0xFF5D1A1A));
    canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 6 * p, 8 * p, 0.8 * p), gold);
    canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 6 * p, 0.8 * p, 10 * p), gold);
    canvas.drawRect(Rect.fromLTWH(px + 11.2 * p, py + 6 * p, 0.8 * p, 10 * p), gold);
    // Door split + panel details
    canvas.drawRect(Rect.fromLTWH(px + 7.8 * p, py + 7.5 * p, 0.5 * p, 8.5 * p), Paint()..color = const Color(0xFF4A1010));
    // Door panel decoration
    canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 8 * p, 2.5 * p, 3 * p), Paint()..color = const Color(0xFF6B1E1E));
    canvas.drawRect(Rect.fromLTWH(px + 8.5 * p, py + 8 * p, 2.5 * p, 3 * p), Paint()..color = const Color(0xFF6B1E1E));

    // Door knockers
    canvas.drawCircle(Offset(px + 6.5 * p, py + 11.5 * p), 0.8 * p, gold);
    canvas.drawCircle(Offset(px + 9.5 * p, py + 11.5 * p), 0.8 * p, gold);

    // Lanterns (red with gold tassel)
    for (final lx in [2.0, 14.0]) {
      if (v % 2 == 0 || lx == 2.0) {
        canvas.drawRect(Rect.fromLTWH(px + (lx - 0.3) * p, py + 5 * p, 0.6 * p, 0.5 * p), gold);
        canvas.drawCircle(Offset(px + lx * p, py + 6.5 * p), 1.3 * p, Paint()..color = const Color(0xDDFF3333));
        canvas.drawCircle(Offset(px + lx * p, py + 6.5 * p), 0.6 * p, Paint()..color = const Color(0xFFFFCC00));
        canvas.drawRect(Rect.fromLTWH(px + (lx - 0.2) * p, py + 7.8 * p, 0.4 * p, 0.8 * p), gold);
      }
    }

    // Stone threshold
    canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 15.5 * p, 10 * p, 0.5 * p), Paint()..color = const Color(0xFF9E9E9E));

    // Incense smoke
    if (v % 3 == 0) {
      canvas.drawCircle(Offset(px + 8 * p, py + 5.5 * p), 1 * p, Paint()..color = const Color(0x22FFFFFF));
      canvas.drawCircle(Offset(px + 7 * p, py + 4.5 * p), 0.7 * p, Paint()..color = const Color(0x18FFFFFF));
    }
  }

  // ── Apartment: KAI-style Taiwan concrete — balcony life, AC units, laundry, 鐵皮 ──
  void _drawApartment(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];

    // Concrete facade with color variants
    final facades = [
      const Color(0xFF8A8A8A), const Color(0xFF93877A),
      const Color(0xFF7E8B8A), const Color(0xFF9A9080),
    ];
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = facades[v % facades.length]);
    // Slightly lighter center
    canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py, 15 * p, ts), Paint()..color = facades[v % facades.length].withAlpha(230));

    // Floor divider lines (3 visible floors)
    final divider = Paint()..color = const Color(0xFF656565);
    for (final fy in [4.0, 8.5, 13.0]) {
      canvas.drawRect(Rect.fromLTWH(px, py + fy * p, ts, 0.4 * p), divider);
    }

    // Windows grid (3 columns × 3 floors) with 鐵窗
    final winDark = Paint()..color = const Color(0xFF505050);
    final winLit = Paint()..color = const Color(0xCCFFE082);
    final winBlue = Paint()..color = const Color(0x99A8D8F0);
    final winCurtain = Paint()..color = const Color(0xAAE8C8A0);
    final grille = Paint()..color = const Color(0xFF555555);

    for (int wy = 0; wy < 3; wy++) {
      final baseY = 0.5 + wy * 4.5;
      for (int wx = 0; wx < 3; wx++) {
        final winX = px + (1.5 + wx * 5) * p;
        final winY = py + baseY * p;
        final wh = (v + wy * 3 + wx * 7) % 12;
        Paint wp;
        if (wh < 4) { wp = winLit; }
        else if (wh < 7) { wp = winBlue; }
        else if (wh < 9) { wp = winCurtain; }
        else { wp = winDark; }
        canvas.drawRect(Rect.fromLTWH(winX, winY, 3 * p, 3 * p), wp);
        // Grille bars on every window
        for (double gx = 0; gx < 3; gx += 0.8) {
          canvas.drawRect(Rect.fromLTWH(winX + gx * p, winY, 0.3 * p, 3 * p), grille);
        }
        canvas.drawRect(Rect.fromLTWH(winX, winY + 1.5 * p, 3 * p, 0.3 * p), grille);
      }
    }

    // Balcony railings with life details
    final rail = Paint()..color = const Color(0xFF606060);
    for (final ry in [4.0, 8.5]) {
      canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + ry * p, 15 * p, 0.4 * p), rail);
      for (double rx = 1; rx < 15; rx += 1.5) {
        canvas.drawRect(Rect.fromLTWH(px + rx * p, py + (ry + 0.4) * p, 0.3 * p, 1 * p), rail);
      }
    }

    // AC units (random placement)
    if (v % 3 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 14 * p, py + 2 * p, 2 * p, 1.5 * p), Paint()..color = const Color(0xFF888888));
      canvas.drawRect(Rect.fromLTWH(px + 14 * p, py + 2 * p, 2 * p, 0.3 * p), Paint()..color = const Color(0xFFAAAAAA));
    }
    if (v % 4 == 1) {
      canvas.drawRect(Rect.fromLTWH(px + 14 * p, py + 6.5 * p, 2 * p, 1.5 * p), Paint()..color = const Color(0xFF888888));
    }

    // Rooftop water tank
    if (v % 5 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 11 * p, py - 2 * p, 4.5 * p, 2 * p), Paint()..color = const Color(0xFF6D6D6D));
      canvas.drawRect(Rect.fromLTWH(px + 11 * p, py - 2 * p, 4.5 * p, 0.4 * p), Paint()..color = const Color(0xFF8A8A8A));
    }

    // 鐵皮加蓋 (corrugated rooftop addition)
    if (v % 7 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py - 1.5 * p, 10 * p, 1.5 * p), Paint()..color = const Color(0xFF7E7E7E));
      for (double cx = 0.5; cx < 10.5; cx += 1.5) {
        canvas.drawRect(Rect.fromLTWH(px + cx * p, py - 1.5 * p, 0.7 * p, 1.5 * p), Paint()..color = const Color(0xFF8A8A8A));
      }
    }

    // Laundry on balcony
    if (v % 3 == 1) {
      canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 5 * p, 13 * p, 0.2 * p), Paint()..color = const Color(0xFF616161));
      final clothColors = [const Color(0xFFE0E0E0), const Color(0xFF90CAF9), const Color(0xFFFFCDD2), const Color(0xFFC8E6C9), const Color(0xFFFFE0B2)];
      for (int ci = 0; ci < 5; ci++) {
        canvas.drawRect(Rect.fromLTWH(px + (1 + ci * 2.5) * p, py + 5 * p, 1.2 * p, 1.5 + (ci % 2) * 0.5), Paint()..color = clothColors[ci]);
      }
    }

    // 1F: Shop or entrance (many apartments have ground-floor shop)
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 13.5 * p, 6 * p, 2.5 * p), Paint()..color = const Color(0xFF555555));
    // Shutter ridges
    for (double sy = 13.5; sy < 16; sy += 0.6) {
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + sy * p, 6 * p, 0.2 * p), Paint()..color = const Color(0xFF4A4A4A));
    }

    // Water stain
    if (v % 4 == 2) {
      final sx = (v % 10).toDouble();
      canvas.drawRect(Rect.fromLTWH(px + sx * p, py + 3 * p, 0.8 * p, 10 * p), Paint()..color = const Color(0x12000000));
    }

    // Cable bundle
    if (v % 5 == 2) {
      canvas.drawRect(Rect.fromLTWH(px, py + 4.2 * p, ts, 0.3 * p), Paint()..color = const Color(0xFF222222));
    }
  }

  // ── Night market: KAI-style neon stalls — food display, colorful lights, steam ──
  void _drawNightMarket(Canvas canvas, int x, int y, double px, double py, double ts) {
    final v = _tileVariant[y][x];
    final p = ts / 16;

    final neonColors = [
      const Color(0xFFFF2D78), const Color(0xFF00E5FF),
      const Color(0xFFFFD700), const Color(0xFF7B68EE),
      const Color(0xFF00FF88), const Color(0xFFFF4444),
    ];
    final neon = neonColors[v % neonColors.length];

    // Dark base with neon glow bleed
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFF1A0A2E));
    canvas.drawRect(Rect.fromLTWH(px - 1, py - 1, ts + 2, ts + 2), Paint()..color = neon.withAlpha(20));

    // Stall structure — metal frame + canvas roof
    final frame = Paint()..color = const Color(0xFF555555);
    canvas.drawRect(Rect.fromLTWH(px, py, ts, 4 * p), Paint()..color = neon.withAlpha(200));
    // Neon sign border
    canvas.drawRect(Rect.fromLTWH(px, py, ts, 0.4 * p), Paint()..color = neon.withAlpha(255));
    canvas.drawRect(Rect.fromLTWH(px, py + 3.6 * p, ts, 0.4 * p), Paint()..color = neon.withAlpha(255));
    // Faux text on sign
    canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 1 * p, 3 * p, 2 * p), Paint()..color = const Color(0xEEFFFFFF));
    canvas.drawRect(Rect.fromLTWH(px + 6 * p, py + 1 * p, 3 * p, 2 * p), Paint()..color = const Color(0xEEFFFFFF));
    canvas.drawRect(Rect.fromLTWH(px + 10 * p, py + 1 * p, 3 * p, 2 * p), Paint()..color = const Color(0xDDFFFFFF));

    // Stall counter
    canvas.drawRect(Rect.fromLTWH(px, py + 10 * p, ts, 2 * p), Paint()..color = const Color(0xFF444444));
    canvas.drawRect(Rect.fromLTWH(px, py + 10 * p, ts, 0.3 * p), Paint()..color = const Color(0xFF666666));

    // Food display on counter
    final foodColors = [
      const Color(0xFFFF7043), const Color(0xFFFFCA28), const Color(0xFF66BB6A),
      const Color(0xFFEF5350), const Color(0xFFAB47BC), const Color(0xFF8D6E63),
    ];
    for (int fi = 0; fi < 5; fi++) {
      final fx = 1.5 + fi * 2.8;
      canvas.drawCircle(
        Offset(px + fx * p, py + 9 * p),
        1 * p,
        Paint()..color = foodColors[(v + fi) % foodColors.length],
      );
    }

    // Metal frame poles
    canvas.drawRect(Rect.fromLTWH(px, py + 4 * p, 0.5 * p, 12 * p), frame);
    canvas.drawRect(Rect.fromLTWH(px + 15.5 * p, py + 4 * p, 0.5 * p, 12 * p), frame);

    // Hanging lantern (red)
    if (v % 3 == 0) {
      canvas.drawCircle(Offset(px + 3 * p, py + 5.5 * p), 1.3 * p, Paint()..color = const Color(0xCCFF3333));
      canvas.drawCircle(Offset(px + 3 * p, py + 5.5 * p), 0.6 * p, Paint()..color = const Color(0xFFFFCC00));
    }

    // Light string across top
    for (double lx = 2; lx < 15; lx += 2.5) {
      final lc = neonColors[((v + lx.toInt()) % neonColors.length)];
      canvas.drawCircle(Offset(px + lx * p, py + 4.5 * p), 0.5 * p, Paint()..color = lc.withAlpha(200));
    }

    // Steam from cooking
    if (v % 2 == 0) {
      canvas.drawCircle(Offset(px + 8 * p, py + 7 * p), 1.5 * p, Paint()..color = const Color(0x22FFFFFF));
      canvas.drawCircle(Offset(px + 6 * p, py + 6 * p), 1 * p, Paint()..color = const Color(0x18FFFFFF));
    }

    // Floor glow
    canvas.drawRect(Rect.fromLTWH(px, py + 15 * p, ts, p), Paint()..color = neon.withAlpha(80));
  }

  // ── Restaurant: gold-highlighted shop ──
  void _drawRestaurant(Canvas canvas, double px, double py, double ts) {
    final p = ts / 16;
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFF8B7355));
    canvas.drawRect(Rect.fromLTWH(px, py, ts, 4 * p), Paint()..color = const Color(0xFFFFD700));
    canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 6 * p, 6 * p, 10 * p), Paint()..color = const Color(0xFF5C4033));
    canvas.drawRect(Rect.fromLTWH(px + 6 * p, py + 7 * p, 4 * p, 4 * p), Paint()..color = const Color(0xAAB0E0FF));
    canvas.drawCircle(Offset(px + 8 * p, py + 8 * p), 12 * p, Paint()..color = const Color(0x18FFD700));
    final tp = TextPainter(
      text: const TextSpan(text: '🍜', style: TextStyle(fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(px + 2 * p, py + 4 * p));
  }

  // ── Customer ──
  void _drawCustomer(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFF607D8B));
    canvas.drawRect(Rect.fromLTWH(px, py, ts, 4 * p), Paint()..color = const Color(0xFF4ECDC4));
    canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 6 * p, 6 * p, 10 * p), Paint()..color = const Color(0xFF37474F));
    canvas.drawCircle(Offset(px + 9 * p, py + 11 * p), p, Paint()..color = const Color(0xFFFFD700));
    canvas.drawCircle(Offset(px + 8 * p, py + 8 * p), 12 * p, Paint()..color = const Color(0x184ECDC4));
    final tp = TextPainter(
      text: const TextSpan(text: '📦', style: TextStyle(fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(px + 2 * p, py + 4 * p));
  }

  // ── Park ──
  void _drawPark(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFF4CAF50));

    // Grass texture variation
    if (v % 3 == 0) {
      canvas.drawRect(
        Rect.fromLTWH(px + (v % 7) * p, py + (v % 5 + 2) * p, 3 * p, 3 * p),
        Paint()..color = const Color(0xFF388E3C),
      );
    }

    if (v % 8 == 0) {
      // Large tree with shadow
      canvas.drawCircle(Offset(px + 9 * p, py + 10 * p), 3 * p, Paint()..color = const Color(0x22000000));
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 10 * p, 2 * p, 6 * p), Paint()..color = const Color(0xFF5D4037));
      canvas.drawCircle(Offset(px + 8 * p, py + 8 * p), 4 * p, Paint()..color = const Color(0xFF2E7D32));
      canvas.drawCircle(Offset(px + 6 * p, py + 7 * p), 2.5 * p, Paint()..color = const Color(0xFF388E3C));
    } else if (v % 8 == 1) {
      // Flower bed
      for (int i = 0; i < 3; i++) {
        final fx = px + (3 + i * 4) * p;
        final fy = py + (8 + (v * i) % 5) * p;
        canvas.drawCircle(
          Offset(fx, fy), 1.5 * p,
          Paint()..color = Color.lerp(const Color(0xFFFF6B6B), const Color(0xFFFFD700), (v * i % 10) / 10.0)!,
        );
      }
    } else if (v % 8 == 2) {
      // Park bench
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 9 * p, 10 * p, 1 * p), Paint()..color = const Color(0xFF795548));
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 10 * p, 1 * p, 2 * p), Paint()..color = const Color(0xFF5D4037));
      canvas.drawRect(Rect.fromLTWH(px + 12 * p, py + 10 * p, 1 * p, 2 * p), Paint()..color = const Color(0xFF5D4037));
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 7 * p, 10 * p, 1 * p), Paint()..color = const Color(0xFF795548));
    } else if (v % 8 == 3) {
      // Walking path (gravel)
      canvas.drawRect(Rect.fromLTWH(px, py + 7 * p, ts, 2 * p), Paint()..color = const Color(0xFFBCAAA4));
      canvas.drawRect(Rect.fromLTWH(px, py + 7.5 * p, ts, 0.3 * p), Paint()..color = const Color(0xFFA1887F));
    } else if (v % 8 == 4) {
      // Small bush cluster
      canvas.drawCircle(Offset(px + 5 * p, py + 8 * p), 2.5 * p, Paint()..color = const Color(0xFF388E3C));
      canvas.drawCircle(Offset(px + 10 * p, py + 10 * p), 2 * p, Paint()..color = const Color(0xFF2E7D32));
      canvas.drawCircle(Offset(px + 8 * p, py + 6 * p), 1.5 * p, Paint()..color = const Color(0xFF43A047));
    } else if (v % 8 == 5) {
      // Streetlamp in park
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 4 * p, 1.5 * p, 10 * p), Paint()..color = const Color(0xFF616161));
      canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 3 * p, 5 * p, 1.5 * p), Paint()..color = const Color(0xFF757575));
      canvas.drawCircle(Offset(px + 7.5 * p, py + 3 * p), 1.5 * p, Paint()..color = const Color(0x44FFFF00));
    }
  }

  // ── Zone labels ──
  void _drawZoneLabels(Canvas canvas) {
    final labels = [
      (_zoneNightMarket, '🏮 夜市區', const Color(0xDDFF2D78)),
      (_zoneResidential, '🏠 住宅區', const Color(0xDD4ECDC4)),
      (_zoneCommercial, '🏢 商業區', const Color(0xDDFFD700)),
      (_zoneTemple, '⛩️ 廟宇區', const Color(0xDDFF6B6B)),
      (_zoneApartments, '🏬 公寓區', const Color(0xDD00E5FF)),
    ];

    for (final (zone, label, color) in labels) {
      final (x1, y1, x2, y2) = zone;
      final centerX = ((x1 + x2) / 2) * tileDisplaySize;
      final labelY = (y1 + 1) * tileDisplaySize;
      _drawFloatingLabel(canvas, centerX, labelY, label, color, 12);
    }

    _drawRestaurantLabels(canvas);
    _drawLandmarkLabels(canvas);
  }

  void _drawFloatingLabel(Canvas canvas, double cx, double cy, String label, Color bgColor, double fontSize) {
    final textSpan = TextSpan(
      text: label,
      style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: tp.width + 12, height: tp.height + 6),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, Paint()..color = bgColor);
    canvas.drawRRect(bgRect, Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1);
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawRestaurantLabels(Canvas canvas) {
    const names = ['🍜 阿嬤滷肉飯', '🧋 茶之道手搖', '🍗 爆漿雞排王'];
    final positions = [(12, 14), (26, 24), (42, 6)];
    for (int i = 0; i < names.length && i < positions.length; i++) {
      final (rx, ry) = positions[i];
      final cx = (rx + 1) * tileDisplaySize;
      final cy = (ry - 0.3) * tileDisplaySize;
      _drawFloatingLabel(canvas, cx, cy, names[i], const Color(0xDDF5A623), 10);
    }
  }

  void _drawLandmarkLabels(Canvas canvas) {
    final landmarks = [
      (3, 3, '🏪 全家', const Color(0xAA00897B)),
      (7, 3, '🏪 7-11', const Color(0xAA00897B)),
      (33, 3, '🏦 台灣銀行', const Color(0xAA1565C0)),
      (38, 3, '📮 郵局', const Color(0xAA43A047)),
      (44, 3, '🏥 診所', const Color(0xAAC62828)),
      (3, 38, '🛕 媽祖廟', const Color(0xAAC62828)),
      (8, 42, '🛕 土地公', const Color(0xAAC62828)),
      (38, 38, '🏫 補習班', const Color(0xAA6A1B9A)),
      (44, 38, '🧺 自助洗', const Color(0xAA0277BD)),
      (13, 3, '💇 美髮店', const Color(0xAA8E24AA)),
      (33, 10, '🏧 ATM', const Color(0xAA1565C0)),
      (3, 10, '🏪 萊爾富', const Color(0xAA00897B)),
      (44, 10, '🧋 清心', const Color(0xAA00897B)),
      (7, 38, '🍜 牛肉麵', const Color(0xAAE65100)),
      (38, 44, '🎮 網咖', const Color(0xAA6A1B9A)),
      (44, 44, '🧹 洗衣店', const Color(0xAA0277BD)),
    ];
    for (final (lx, ly, name, color) in landmarks) {
      final cx = (lx + 0.5) * tileDisplaySize;
      final cy = (ly - 0.3) * tileDisplaySize;
      _drawFloatingLabel(canvas, cx, cy, name, color, 8);
    }
  }

  bool _inZone(int x, int y, (int, int, int, int) zone) {
    final (x1, y1, x2, y2) = zone;
    return x >= x1 && x <= x2 && y >= y1 && y <= y2;
  }

  TileType getTileAt(int x, int y) {
    if (_tiles.isEmpty) return TileType.ground;
    if (x < 0 || x >= mapWidth || y < 0 || y >= mapHeight) return TileType.ground;
    return _tiles[y][x];
  }

  bool get isLoaded => _tiles.isNotEmpty;

  List<List<TileType>> get tileGrid => _tiles;

  bool isWalkable(int x, int y) {
    final tile = getTileAt(x, y);
    return tile == TileType.road || tile == TileType.sidewalk ||
        tile == TileType.restaurant || tile == TileType.customer ||
        tile == TileType.nightMarket || tile == TileType.park;
  }

  // ── A* Pathfinding ──
  List<Vector2>? findPath(Vector2 startWorld, Vector2 endWorld, {bool preferSidewalks = false}) {
    final sx = (startWorld.x / tileDisplaySize).floor().clamp(0, mapWidth - 1);
    final sy = (startWorld.y / tileDisplaySize).floor().clamp(0, mapHeight - 1);
    final ex = (endWorld.x / tileDisplaySize).floor().clamp(0, mapWidth - 1);
    final ey = (endWorld.y / tileDisplaySize).floor().clamp(0, mapHeight - 1);

    if (!isWalkable(ex, ey)) return null;
    if (sx == ex && sy == ey) return [endWorld];

    final w = mapWidth;
    final open = <int>[];
    final closed = <bool>[for (int i = 0; i < w * mapHeight; i++) false];
    final g = <int, double>{};
    final f = <int, double>{};
    final parent = <int, int>{};

    final sk = sy * w + sx;
    final ek = ey * w + ex;
    open.add(sk);
    g[sk] = 0;
    f[sk] = (ex - sx).abs().toDouble() + (ey - sy).abs().toDouble();

    while (open.isNotEmpty) {
      open.sort((a, b) => (f[a] ?? 1e9).compareTo(f[b] ?? 1e9));
      final cur = open.removeAt(0);
      if (cur == ek) return _buildPath(parent, cur, sk);

      closed[cur] = true;
      final cx = cur % w;
      final cy = cur ~/ w;

      for (final d in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        final nx = cx + d.$1;
        final ny = cy + d.$2;
        if (nx < 0 || nx >= w || ny < 0 || ny >= mapHeight) continue;
        final nk = ny * w + nx;
        if (closed[nk] || !isWalkable(nx, ny)) continue;

        // Riding scooter: roads are natural (cheap), sidewalks penalized
        // Walking: sidewalks are natural (cheap), roads penalized
        final tile = _tiles[ny][nx];
        double tileCost;
        if (preferSidewalks) {
          // Riding: prefer roads, avoid sidewalks
          tileCost = tile == TileType.road ? 0.7
                   : tile == TileType.sidewalk ? 1.5
                   : 1.0;
        } else {
          // Walking: prefer sidewalks, roads are ok
          tileCost = tile == TileType.sidewalk ? 0.8
                   : tile == TileType.road ? 1.1
                   : 1.0;
        }
        final tg = (g[cur] ?? 1e9) + tileCost;
        if (tg < (g[nk] ?? 1e9)) {
          parent[nk] = cur;
          g[nk] = tg;
          f[nk] = tg + (ex - nx).abs().toDouble() + (ey - ny).abs().toDouble();
          if (!open.contains(nk)) open.add(nk);
        }
      }
    }
    return null;
  }

  List<Vector2> _buildPath(Map<int, int> parent, int end, int start) {
    final raw = <Vector2>[];
    var n = end;
    while (n != start) {
      raw.add(Vector2(
        (n % mapWidth + 0.5) * tileDisplaySize,
        (n ~/ mapWidth + 0.5) * tileDisplaySize,
      ));
      n = parent[n]!;
    }
    final path = raw.reversed.toList();
    if (path.length <= 2) return path;

    final simple = <Vector2>[path.first];
    for (int i = 1; i < path.length - 1; i++) {
      final dx1 = (path[i].x - simple.last.x).sign;
      final dy1 = (path[i].y - simple.last.y).sign;
      final dx2 = (path[i + 1].x - path[i].x).sign;
      final dy2 = (path[i + 1].y - path[i].y).sign;
      if (dx1 != dx2 || dy1 != dy2) simple.add(path[i]);
    }
    simple.add(path.last);
    return simple;
  }

  Vector2? findNearestWalkable(Vector2 worldPos) {
    final tileX = (worldPos.x / tileDisplaySize).floor();
    final tileY = (worldPos.y / tileDisplaySize).floor();

    if (isWalkable(tileX, tileY)) return worldPos;

    for (int r = 1; r <= 5; r++) {
      for (int dy = -r; dy <= r; dy++) {
        for (int dx = -r; dx <= r; dx++) {
          if (dx.abs() != r && dy.abs() != r) continue;
          if (isWalkable(tileX + dx, tileY + dy)) {
            return Vector2(
              (tileX + dx + 0.5) * tileDisplaySize,
              (tileY + dy + 0.5) * tileDisplaySize,
            );
          }
        }
      }
    }
    return null;
  }
}

enum TileType {
  road,
  sidewalk,
  ground,
  building,
  nightMarket,
  restaurant,
  customer,
  park,
}
