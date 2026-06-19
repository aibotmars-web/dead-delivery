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
    final p = ts / 16;
    final v = _tileVariant[y][x];

    // Dark asphalt base
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFF353535));

    // Subtle aggregate texture
    final ag = v % 4;
    if (ag == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 3 * p, 4 * p, 3 * p), Paint()..color = const Color(0xFF3A3A3A));
      canvas.drawRect(Rect.fromLTWH(px + 10 * p, py + 9 * p, 3 * p, 2 * p), Paint()..color = const Color(0xFF323232));
    } else if (ag == 1) {
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 1 * p, 5 * p, 4 * p), Paint()..color = const Color(0xFF393939));
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 10 * p, 4 * p, 3 * p), Paint()..color = const Color(0xFF313131));
    }

    final isMainH = _mainRoadsH.contains(y);
    final isMainV = _mainRoadsV.contains(x);
    final hasH = _roadAt(x - 1, y) || _roadAt(x + 1, y);
    final hasV = _roadAt(x, y - 1) || _roadAt(x, y + 1);
    final isIntersection = hasH && hasV;

    // Road surface wear
    if (v % 11 == 0 && !isIntersection) {
      // Tar repair strip
      canvas.drawRect(Rect.fromLTWH(px + (v % 6) * p, py + (v % 5 + 2) * p, 8 * p, 0.4 * p), Paint()..color = const Color(0xFF2D2D2D));
    }
    if (v % 17 == 0) {
      // Oil stain
      canvas.drawCircle(Offset(px + 8 * p, py + 10 * p), 2 * p, Paint()..color = const Color(0x0A000000));
      canvas.drawCircle(Offset(px + 7 * p, py + 9 * p), 1.5 * p, Paint()..color = const Color(0x08141420));
    }
    if (v % 29 == 0 && !isIntersection) {
      // Pothole patch
      canvas.drawCircle(Offset(px + 6 * p, py + 7 * p), 2.5 * p, Paint()..color = const Color(0xFF2A2A2A));
      canvas.drawCircle(Offset(px + 6 * p, py + 7 * p), 2 * p, Paint()..color = const Color(0xFF303030));
    }
    // Manhole cover
    if (v % 37 == 0 && !isIntersection) {
      final mx = px + 4 * p;
      final my = py + 4 * p;
      canvas.drawCircle(Offset(mx + 4 * p, my + 4 * p), 3.5 * p, Paint()..color = const Color(0xFF454545));
      canvas.drawCircle(Offset(mx + 4 * p, my + 4 * p), 3 * p, Paint()..color = const Color(0xFF3D3D3D));
      // Diamond grid pattern
      for (double gd = -2; gd <= 2; gd += 1) {
        canvas.drawRect(Rect.fromLTWH(mx + (4 + gd) * p - 0.1 * p, my + 1.5 * p, 0.3 * p, 5 * p),
          Paint()..color = const Color(0xFF494949));
      }
      canvas.drawRect(Rect.fromLTWH(mx + 1.5 * p, my + 3.8 * p, 5 * p, 0.3 * p), Paint()..color = const Color(0xFF494949));
      // Rim
      canvas.drawCircle(Offset(mx + 4 * p, my + 4 * p), 3.5 * p,
        Paint()..color = const Color(0xFF4A4A4A)..style = PaintingStyle.stroke..strokeWidth = 0.4 * p);
    }
    // Road drain grate
    if (v % 31 == 0 && !isIntersection) {
      if (_isSidewalkOrBuilding(x, y + 1)) {
        canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 13 * p, 5 * p, 2.5 * p), Paint()..color = const Color(0xFF252525));
        for (double gy = 13.3; gy < 15.5; gy += 0.7) {
          canvas.drawRect(Rect.fromLTWH(px + 5.3 * p, py + gy * p, 4.4 * p, 0.25 * p), Paint()..color = const Color(0xFF383838));
        }
      }
    }

    if (isIntersection) {
      _drawCrosswalkIfNeeded(canvas, x, y, px, py, ts, p);
    } else if (hasH && !hasV) {
      final isTopLane = isMainH && _mainRoadsH.contains(y + 1);
      final isBottomLane = isMainH && _mainRoadsH.contains(y - 1);
      if (isTopLane) {
        _drawDashedLine(canvas, px, py + 15 * p, ts, 1.2 * p,
            isHorizontal: true, color: const Color(0xDDFFD600), dashLen: 4 * p);
        canvas.drawRect(Rect.fromLTWH(px, py, ts, 0.8 * p), Paint()..color = const Color(0x77FFFFFF));
      } else if (isBottomLane) {
        _drawDashedLine(canvas, px, py, ts, 1.2 * p,
            isHorizontal: true, color: const Color(0xDDFFD600), dashLen: 4 * p);
        canvas.drawRect(Rect.fromLTWH(px, py + 15.2 * p, ts, 0.8 * p), Paint()..color = const Color(0x77FFFFFF));
      } else {
        _drawDashedLine(canvas, px, py + 7.3 * p, ts, 1.2 * p,
            isHorizontal: true, color: const Color(0x88FFFFFF), dashLen: 3 * p);
        canvas.drawRect(Rect.fromLTWH(px, py, ts, 0.6 * p), Paint()..color = const Color(0x44FFFFFF));
        canvas.drawRect(Rect.fromLTWH(px, py + 15.4 * p, ts, 0.6 * p), Paint()..color = const Color(0x44FFFFFF));
      }
    } else if (hasV && !hasH) {
      final isLeftLane = isMainV && _mainRoadsV.contains(x + 1);
      final isRightLane = isMainV && _mainRoadsV.contains(x - 1);
      if (isLeftLane) {
        _drawDashedLine(canvas, px + 15 * p, py, 1.2 * p, ts,
            isHorizontal: false, color: const Color(0xDDFFD600), dashLen: 4 * p);
        canvas.drawRect(Rect.fromLTWH(px, py, 0.8 * p, ts), Paint()..color = const Color(0x77FFFFFF));
      } else if (isRightLane) {
        _drawDashedLine(canvas, px, py, 1.2 * p, ts,
            isHorizontal: false, color: const Color(0xDDFFD600), dashLen: 4 * p);
        canvas.drawRect(Rect.fromLTWH(px + 15.2 * p, py, 0.8 * p, ts), Paint()..color = const Color(0x77FFFFFF));
      } else {
        _drawDashedLine(canvas, px + 7.3 * p, py, 1.2 * p, ts,
            isHorizontal: false, color: const Color(0x88FFFFFF), dashLen: 3 * p);
        canvas.drawRect(Rect.fromLTWH(px, py, 0.6 * p, ts), Paint()..color = const Color(0x44FFFFFF));
        canvas.drawRect(Rect.fromLTWH(px + 15.4 * p, py, 0.6 * p, ts), Paint()..color = const Color(0x44FFFFFF));
      }
    }

    // Parking line stripes
    final pl = _parkingLines[y * mapWidth + x];
    if (pl != null) {
      final lineColor = switch (pl) {
        ParkingLine.red => const Color(0xFFE53935),
        ParkingLine.yellow => const Color(0xFFFFD600),
        ParkingLine.white => const Color(0xCCFFFFFF),
      };
      final linePaint = Paint()..color = lineColor;
      if (_isSidewalkOrBuilding(x, y - 1)) {
        canvas.drawRect(Rect.fromLTWH(px, py, ts, 1.2 * p), linePaint);
      }
      if (_isSidewalkOrBuilding(x, y + 1)) {
        canvas.drawRect(Rect.fromLTWH(px, py + ts - 1.2 * p, ts, 1.2 * p), linePaint);
      }
      if (_isSidewalkOrBuilding(x - 1, y)) {
        canvas.drawRect(Rect.fromLTWH(px, py, 1.2 * p, ts), linePaint);
      }
      if (_isSidewalkOrBuilding(x + 1, y)) {
        canvas.drawRect(Rect.fromLTWH(px + ts - 1.2 * p, py, 1.2 * p, ts), linePaint);
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
    final cwPaint = Paint()..color = const Color(0xBBFFFFFF);
    if (_isSidewalkOrBuilding(x, y - 1)) {
      for (double sx = 1.5 * p; sx < ts - 1.5 * p; sx += 3.5 * p) {
        canvas.drawRect(Rect.fromLTWH(px + sx, py, 2 * p, 3.5 * p), cwPaint);
      }
    }
    if (_isSidewalkOrBuilding(x, y + 1)) {
      for (double sx = 1.5 * p; sx < ts - 1.5 * p; sx += 3.5 * p) {
        canvas.drawRect(Rect.fromLTWH(px + sx, py + ts - 3.5 * p, 2 * p, 3.5 * p), cwPaint);
      }
    }
    if (_isSidewalkOrBuilding(x - 1, y)) {
      for (double sy = 1.5 * p; sy < ts - 1.5 * p; sy += 3.5 * p) {
        canvas.drawRect(Rect.fromLTWH(px, py + sy, 3.5 * p, 2 * p), cwPaint);
      }
    }
    if (_isSidewalkOrBuilding(x + 1, y)) {
      for (double sy = 1.5 * p; sy < ts - 1.5 * p; sy += 3.5 * p) {
        canvas.drawRect(Rect.fromLTWH(px + ts - 3.5 * p, py + sy, 3.5 * p, 2 * p), cwPaint);
      }
    }
    // Traffic light at major intersections
    if (_mainRoadsH.contains(y) && _mainRoadsV.contains(x)) {
      final isCorner = _isSidewalkOrBuilding(x - 1, y - 1);
      if (isCorner) {
        _drawTrafficLight(canvas, px, py, p);
      }
    }
  }

  void _drawTrafficLight(Canvas canvas, double px, double py, double p) {
    // Pole with isometric shadow
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 5 * p, 1.5 * p, 11 * p), Paint()..color = const Color(0xFF3A3A3A));
    canvas.drawRect(Rect.fromLTWH(px + 2.5 * p, py + 5 * p, 0.3 * p, 11 * p), Paint()..color = const Color(0xFF2A2A2A));
    // Horizontal arm
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 4.5 * p, 9 * p, 1 * p), Paint()..color = const Color(0xFF3A3A3A));
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 5.5 * p, 9 * p, 0.3 * p), Paint()..color = const Color(0xFF2A2A2A));
    // Signal housing (3D box)
    canvas.drawRect(Rect.fromLTWH(px + 6 * p, py + 1 * p, 4.5 * p, 7.5 * p), Paint()..color = const Color(0xFF2A2A2A));
    canvas.drawRect(Rect.fromLTWH(px + 10.5 * p, py + 1 * p, 0.5 * p, 7.5 * p), Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawRect(Rect.fromLTWH(px + 6 * p, py + 0.5 * p, 4.5 * p, 0.5 * p), Paint()..color = const Color(0xFF444444));
    // Red
    canvas.drawCircle(Offset(px + 8.2 * p, py + 2.5 * p), 1.1 * p, Paint()..color = const Color(0xFFFF1744));
    canvas.drawCircle(Offset(px + 8.2 * p, py + 2.5 * p), 0.5 * p, Paint()..color = const Color(0x44FFFFFF));
    // Yellow (dim)
    canvas.drawCircle(Offset(px + 8.2 * p, py + 4.8 * p), 1.1 * p, Paint()..color = const Color(0xFF2D2D2D));
    // Green (dim)
    canvas.drawCircle(Offset(px + 8.2 * p, py + 7 * p), 1.1 * p, Paint()..color = const Color(0xFF2D2D2D));
    // Visor hoods
    for (final ly in [2.5, 4.8, 7.0]) {
      canvas.drawRect(Rect.fromLTWH(px + 5.5 * p, py + (ly - 1) * p, 0.5 * p, 2.2 * p), Paint()..color = const Color(0xFF333333));
    }
  }

  bool _isSidewalkOrBuilding(int x, int y) {
    if (x < 0 || x >= mapWidth || y < 0 || y >= mapHeight) return false;
    final t = _tiles[y][x];
    return t == TileType.sidewalk || t == TileType.building ||
        t == TileType.restaurant || t == TileType.customer;
  }

  // ── Sidewalk with street furniture ──
  void _drawSidewalk(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];

    // Warm clay tile base
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFFC4B5A0));

    // Herringbone paving pattern
    final tileLine = Paint()..color = const Color(0x15000000);
    for (int row = 0; row < 8; row++) {
      final off = row.isOdd ? 2.0 : 0.0;
      for (double bx = off; bx < 16; bx += 4) {
        canvas.drawRect(Rect.fromLTWH(px + bx * p, py + row * 2 * p, 4 * p, 0.3 * p), tileLine);
        canvas.drawRect(Rect.fromLTWH(px + bx * p, py + row * 2 * p, 0.3 * p, 2 * p), tileLine);
      }
    }
    // Tile color variation
    if (v % 5 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + (v % 8) * p, py + (v % 6) * p, 4 * p, 4 * p), Paint()..color = const Color(0xFFBAAC96));
    }

    // Curb edge (raised concrete, 3D look)
    final curb = Paint()..color = const Color(0xFF888888);
    final curbTop = Paint()..color = const Color(0xFF9A9A9A);
    if (_roadAt(x, y + 1)) {
      canvas.drawRect(Rect.fromLTWH(px, py + 14 * p, ts, 2 * p), curb);
      canvas.drawRect(Rect.fromLTWH(px, py + 14 * p, ts, 0.4 * p), curbTop);
    }
    if (_roadAt(x, y - 1)) {
      canvas.drawRect(Rect.fromLTWH(px, py, ts, 2 * p), curb);
      canvas.drawRect(Rect.fromLTWH(px, py + 1.6 * p, ts, 0.4 * p), curbTop);
    }
    if (_roadAt(x + 1, y)) {
      canvas.drawRect(Rect.fromLTWH(px + 14 * p, py, 2 * p, ts), curb);
      canvas.drawRect(Rect.fromLTWH(px + 14 * p, py, 0.4 * p, ts), curbTop);
    }
    if (_roadAt(x - 1, y)) {
      canvas.drawRect(Rect.fromLTWH(px, py, 2 * p, ts), curb);
      canvas.drawRect(Rect.fromLTWH(px + 1.6 * p, py, 0.4 * p, ts), curbTop);
    }

    // Street furniture (Taiwan props, variant-based)
    final propSeed = v * 3 + x * 7 + y * 13;
    if (v % 7 == 0) {
      // ─ 電線桿 Utility pole with transformer (isometric) ─
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 1 * p, 1.8 * p, 15 * p), Paint()..color = const Color(0xFF4A4A4A));
      canvas.drawRect(Rect.fromLTWH(px + 3.8 * p, py + 1 * p, 0.3 * p, 15 * p), Paint()..color = const Color(0xFF333333));
      // Cross arm
      canvas.drawRect(Rect.fromLTWH(px, py + 2.5 * p, 6 * p, 0.6 * p), Paint()..color = const Color(0xFF555555));
      // Transformer (isometric box)
      canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 4 * p, 3.5 * p, 3 * p), Paint()..color = const Color(0xFF606060));
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 4 * p, 0.5 * p, 3 * p), Paint()..color = const Color(0xFF444444));
      canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 4 * p, 3.5 * p, 0.4 * p), Paint()..color = const Color(0xFF777777));
      // Wires
      canvas.drawRect(Rect.fromLTWH(px, py + 2.7 * p, ts, 0.2 * p), Paint()..color = const Color(0xFF1A1A1A));
      canvas.drawRect(Rect.fromLTWH(px, py + 3.2 * p, ts, 0.2 * p), Paint()..color = const Color(0xFF1A1A1A));
      // Base plate
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 15 * p, 3 * p, 1 * p), Paint()..color = const Color(0xFF555555));
    } else if (v % 9 == 0) {
      // ─ 機車停車排 Parked scooters (isometric, 2 bikes) ─
      for (int si = 0; si < 2; si++) {
        final sx = 1.0 + si * 7;
        final bodyC = si == 0 ? const Color(0xFF1565C0) : const Color(0xFFD32F2F);
        // Body (isometric box shape)
        canvas.drawRect(Rect.fromLTWH(px + sx * p, py + 6 * p, 3.5 * p, 7 * p), Paint()..color = bodyC);
        canvas.drawRect(Rect.fromLTWH(px + (sx + 3.5) * p, py + 6 * p, 0.5 * p, 7 * p), Paint()..color = bodyC.withAlpha(160));
        // Handlebar
        canvas.drawRect(Rect.fromLTWH(px + (sx + 0.2) * p, py + 5 * p, 3 * p, 1.5 * p), Paint()..color = const Color(0xFF222222));
        // Seat
        canvas.drawRect(Rect.fromLTWH(px + (sx + 0.5) * p, py + 8 * p, 2.5 * p, 3 * p), Paint()..color = const Color(0xFF333333));
        // Rear
        canvas.drawRect(Rect.fromLTWH(px + (sx + 0.5) * p, py + 12 * p, 2.5 * p, 2 * p), Paint()..color = const Color(0xFF444444));
        // Wheels
        canvas.drawCircle(Offset(px + (sx + 1.7) * p, py + 4.5 * p), 0.8 * p, Paint()..color = const Color(0xFF111111));
        canvas.drawCircle(Offset(px + (sx + 1.7) * p, py + 14.5 * p), 0.8 * p, Paint()..color = const Color(0xFF111111));
        // Mirror
        canvas.drawRect(Rect.fromLTWH(px + sx * p, py + 5.2 * p, 0.5 * p, 0.5 * p), Paint()..color = const Color(0xFFBBBBBB));
        canvas.drawRect(Rect.fromLTWH(px + (sx + 3) * p, py + 5.2 * p, 0.5 * p, 0.5 * p), Paint()..color = const Color(0xFFBBBBBB));
      }
    } else if (v % 11 == 0) {
      // ─ 騎樓 Arcade pillar (isometric column) ─
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 2 * p, 3.5 * p, 3.5 * p), Paint()..color = const Color(0xFF909090));
      canvas.drawRect(Rect.fromLTWH(px + 5.5 * p, py + 2 * p, 0.5 * p, 3.5 * p), Paint()..color = const Color(0xFF707070));
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 2 * p, 3.5 * p, 0.5 * p), Paint()..color = const Color(0xFFAAAAAA));
      // Ceiling shadow
      canvas.drawRect(Rect.fromLTWH(px, py, ts, 1.5 * p), Paint()..color = const Color(0x28000000));
      // Floor tiles (smoother under arcade)
      for (double ax = 0; ax < 16; ax += 4) {
        for (double ay = 7; ay < 16; ay += 4) {
          canvas.drawRect(Rect.fromLTWH(px + ax * p, py + ay * p, 4 * p, 0.2 * p), Paint()..color = const Color(0x0D000000));
          canvas.drawRect(Rect.fromLTWH(px + ax * p, py + ay * p, 0.2 * p, 4 * p), Paint()..color = const Color(0x0D000000));
        }
      }
    } else if (v % 13 == 0) {
      // ─ 檳榔攤 Betel nut stand (isometric booth) ─
      // Main box
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 4 * p, 7 * p, 10 * p), Paint()..color = const Color(0xFF1B5E20));
      canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 4 * p, 1 * p, 10 * p), Paint()..color = const Color(0xFF0D3810));
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 4 * p, 7 * p, 0.5 * p), Paint()..color = const Color(0xFF2E7D32));
      // Neon green display window
      canvas.drawRect(Rect.fromLTWH(px + 1.5 * p, py + 5 * p, 6 * p, 4.5 * p), Paint()..color = const Color(0xCC00E676));
      // Neon edge glow
      canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 3.5 * p, 8.5 * p, 0.5 * p), Paint()..color = const Color(0xFF00FF88));
      canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 14 * p, 8.5 * p, 0.5 * p), Paint()..color = const Color(0xFF00FF88));
      // Products
      canvas.drawCircle(Offset(px + 3 * p, py + 12 * p), 0.8 * p, Paint()..color = const Color(0xFF4CAF50));
      canvas.drawCircle(Offset(px + 5 * p, py + 12 * p), 0.8 * p, Paint()..color = const Color(0xFF66BB6A));
      canvas.drawCircle(Offset(px + 7 * p, py + 12 * p), 0.8 * p, Paint()..color = const Color(0xFF81C784));
      // Glow effect
      canvas.drawRect(Rect.fromLTWH(px, py + 3 * p, 10 * p, 12 * p), Paint()..color = const Color(0x0800FF88));
    } else if (v % 17 == 0) {
      // ─ 垃圾桶 Trash can pair ─
      // Green recycling (isometric)
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 8 * p, 4.5 * p, 6 * p), Paint()..color = const Color(0xFF2E7D32));
      canvas.drawRect(Rect.fromLTWH(px + 6.5 * p, py + 8 * p, 0.5 * p, 6 * p), Paint()..color = const Color(0xFF1B5E20));
      canvas.drawRect(Rect.fromLTWH(px + 1.5 * p, py + 7 * p, 5.5 * p, 1.5 * p), Paint()..color = const Color(0xFF388E3C));
      canvas.drawCircle(Offset(px + 4.5 * p, py + 11 * p), 1 * p, Paint()..color = const Color(0x99FFFFFF));
      // Gray general waste (isometric)
      canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 9 * p, 4 * p, 5 * p), Paint()..color = const Color(0xFF555555));
      canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 9 * p, 0.5 * p, 5 * p), Paint()..color = const Color(0xFF3A3A3A));
      canvas.drawRect(Rect.fromLTWH(px + 8.5 * p, py + 8 * p, 5 * p, 1.5 * p), Paint()..color = const Color(0xFF666666));
    } else if (v % 19 == 0) {
      // ─ 台灣郵筒 Green+Red pair (isometric) ─
      // Green box
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 5 * p, 4.5 * p, 9 * p), Paint()..color = const Color(0xFF2E7D32));
      canvas.drawRect(Rect.fromLTWH(px + 6.5 * p, py + 5 * p, 0.5 * p, 9 * p), Paint()..color = const Color(0xFF1B5E20));
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 4 * p, 5 * p, 1.5 * p), Paint()..color = const Color(0xFF1B5E20));
      canvas.drawRect(Rect.fromLTWH(px + 2.5 * p, py + 6.5 * p, 3.5 * p, 0.5 * p), Paint()..color = const Color(0xFF111111));
      // Red box
      canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 5 * p, 4.5 * p, 9 * p), Paint()..color = const Color(0xFFD32F2F));
      canvas.drawRect(Rect.fromLTWH(px + 13.5 * p, py + 5 * p, 0.5 * p, 9 * p), Paint()..color = const Color(0xFFA12222));
      canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 4 * p, 5 * p, 1.5 * p), Paint()..color = const Color(0xFFC62828));
      canvas.drawRect(Rect.fromLTWH(px + 9.5 * p, py + 6.5 * p, 3.5 * p, 0.5 * p), Paint()..color = const Color(0xFF111111));
      // Base
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 14 * p, 14 * p, 2 * p), Paint()..color = const Color(0xFF555555));
    } else if (v % 23 == 0) {
      // ─ 自動販賣機 Vending machine (isometric box) ─
      final vmC = propSeed % 2 == 0 ? const Color(0xFFD32F2F) : const Color(0xFF1565C0);
      // Main body
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 2 * p, 7 * p, 12 * p), Paint()..color = vmC);
      canvas.drawRect(Rect.fromLTWH(px + 10 * p, py + 2 * p, 1 * p, 12 * p), Paint()..color = vmC.withAlpha(140));
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 2 * p, 7 * p, 0.5 * p), Paint()..color = vmC.withAlpha(200));
      // Display window
      canvas.drawRect(Rect.fromLTWH(px + 3.5 * p, py + 3 * p, 6 * p, 5 * p), Paint()..color = const Color(0xBB90CAF9));
      // Product rows
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          canvas.drawRect(
            Rect.fromLTWH(px + (4 + col * 1.7) * p, py + (3.5 + row * 1.5) * p, 1.2 * p, 1 * p),
            Paint()..color = Color(0xFF000000 | ((propSeed + row * 3 + col) * 0x2468AC & 0xFFFFFF)));
        }
      }
      // Coin slot + dispenser
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 9 * p, 2 * p, 1 * p), Paint()..color = const Color(0xFF222222));
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 11 * p, 5 * p, 2.5 * p), Paint()..color = const Color(0xFF1A1A1A));
      // Light strip
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 1.5 * p, 7 * p, 0.5 * p), Paint()..color = const Color(0xCCFFFFFF));
    } else if (v % 29 == 0) {
      // ─ 公車站牌 Bus stop shelter (isometric) ─
      // Post
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 2 * p, 1.5 * p, 13 * p), Paint()..color = const Color(0xFF555555));
      canvas.drawRect(Rect.fromLTWH(px + 8.5 * p, py + 2 * p, 0.3 * p, 13 * p), Paint()..color = const Color(0xFF3A3A3A));
      // Roof panel
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 2 * p, 12 * p, 1.2 * p), Paint()..color = const Color(0xFF777777));
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 3.2 * p, 12 * p, 0.3 * p), Paint()..color = const Color(0xFF555555));
      // Route info panel
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 4.5 * p, 7 * p, 4.5 * p), Paint()..color = const Color(0xFFEEEEEE));
      canvas.drawRect(Rect.fromLTWH(px + 4.5 * p, py + 5 * p, 6 * p, 1.2 * p), Paint()..color = const Color(0xFF1565C0));
      canvas.drawRect(Rect.fromLTWH(px + 4.5 * p, py + 6.5 * p, 5 * p, 0.5 * p), Paint()..color = const Color(0xFF333333));
      canvas.drawRect(Rect.fromLTWH(px + 4.5 * p, py + 7.5 * p, 4 * p, 0.5 * p), Paint()..color = const Color(0xFF333333));
      // Bench (isometric)
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 12 * p, 10 * p, 1 * p), Paint()..color = const Color(0xFF795548));
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 13 * p, 1 * p, 1.5 * p), Paint()..color = const Color(0xFF5D4037));
      canvas.drawRect(Rect.fromLTWH(px + 12 * p, py + 13 * p, 1 * p, 1.5 * p), Paint()..color = const Color(0xFF5D4037));
    } else if (v % 31 == 0) {
      // ─ 消防栓 Fire hydrant ─
      canvas.drawRect(Rect.fromLTWH(px + 6.5 * p, py + 9 * p, 3 * p, 5 * p), Paint()..color = const Color(0xFFD32F2F));
      canvas.drawRect(Rect.fromLTWH(px + 9.5 * p, py + 9 * p, 0.4 * p, 5 * p), Paint()..color = const Color(0xFFB71C1C));
      canvas.drawRect(Rect.fromLTWH(px + 5.5 * p, py + 8 * p, 5 * p, 1.5 * p), Paint()..color = const Color(0xFFE53935));
      canvas.drawCircle(Offset(px + 8 * p, py + 8.5 * p), 1.2 * p, Paint()..color = const Color(0xFFFFCDD2));
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 7.5 * p, 2.5 * p, 1 * p), Paint()..color = const Color(0xFFB71C1C));
    } else if (v % 37 == 0) {
      // ─ 行道樹 Street tree (top-down canopy with shadow) ─
      canvas.drawRect(Rect.fromLTWH(px + 6.5 * p, py + 7 * p, 2.5 * p, 3 * p), Paint()..color = const Color(0xFF5D4037));
      canvas.drawCircle(Offset(px + 9 * p, py + 10 * p), 3.5 * p, Paint()..color = const Color(0x1A000000));
      canvas.drawCircle(Offset(px + 8 * p, py + 7 * p), 5 * p, Paint()..color = const Color(0xFF2E7D32));
      canvas.drawCircle(Offset(px + 5.5 * p, py + 6 * p), 3 * p, Paint()..color = const Color(0xFF388E3C));
      canvas.drawCircle(Offset(px + 10.5 * p, py + 8 * p), 2.5 * p, Paint()..color = const Color(0xFF43A047));
      // Tree pit border
      canvas.drawRect(Rect.fromLTWH(px + 4.5 * p, py + 5 * p, 7 * p, 0.3 * p), Paint()..color = const Color(0xFF888888));
      canvas.drawRect(Rect.fromLTWH(px + 4.5 * p, py + 11 * p, 7 * p, 0.3 * p), Paint()..color = const Color(0xFF888888));
      canvas.drawRect(Rect.fromLTWH(px + 4.5 * p, py + 5 * p, 0.3 * p, 6 * p), Paint()..color = const Color(0xFF888888));
      canvas.drawRect(Rect.fromLTWH(px + 11.5 * p, py + 5 * p, 0.3 * p, 6 * p), Paint()..color = const Color(0xFF888888));
    } else if (v % 41 == 0) {
      // ─ 盆栽牆 Potted plants (4 pots with greenery) ─
      for (int pi = 0; pi < 4; pi++) {
        final ppx = 0.5 + pi * 3.8;
        canvas.drawRect(Rect.fromLTWH(px + ppx * p, py + 12 * p, 3 * p, 3.5 * p), Paint()..color = const Color(0xFF6D4C41));
        canvas.drawRect(Rect.fromLTWH(px + (ppx + 3) * p, py + 12 * p, 0.4 * p, 3.5 * p), Paint()..color = const Color(0xFF5D3F33));
        canvas.drawCircle(Offset(px + (ppx + 1.5) * p, py + 11 * p), 1.8 * p,
          Paint()..color = Color.lerp(const Color(0xFF388E3C), const Color(0xFF66BB6A), (propSeed + pi) % 3 / 2.0)!);
      }
    } else if (v % 43 == 0) {
      // ─ 報攤 Newspaper stand (isometric) ─
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 6 * p, 9 * p, 8 * p), Paint()..color = const Color(0xFF795548));
      canvas.drawRect(Rect.fromLTWH(px + 12 * p, py + 6 * p, 1 * p, 8 * p), Paint()..color = const Color(0xFF5D4037));
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 6 * p, 9 * p, 0.5 * p), Paint()..color = const Color(0xFF8D6E63));
      // Papers/magazines
      canvas.drawRect(Rect.fromLTWH(px + 3.5 * p, py + 7 * p, 4 * p, 3 * p), Paint()..color = const Color(0xFFE0E0E0));
      canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 7 * p, 3.5 * p, 3 * p), Paint()..color = const Color(0xFFFFCDD2));
      canvas.drawRect(Rect.fromLTWH(px + 3.5 * p, py + 10.5 * p, 8 * p, 3 * p), Paint()..color = const Color(0xFFBBDEFB));
    } else if (v % 47 == 0) {
      // ─ 路牌 Street sign (isometric) ─
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 5 * p, 1.2 * p, 11 * p), Paint()..color = const Color(0xFF555555));
      canvas.drawRect(Rect.fromLTWH(px + 8.2 * p, py + 5 * p, 0.3 * p, 11 * p), Paint()..color = const Color(0xFF3A3A3A));
      // Green sign plate
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 3 * p, 13 * p, 3 * p), Paint()..color = const Color(0xFF2E7D32));
      canvas.drawRect(Rect.fromLTWH(px + 14 * p, py + 3 * p, 0.5 * p, 3 * p), Paint()..color = const Color(0xFF1B5E20));
      // White border
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 3 * p, 13 * p, 0.3 * p), Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 5.7 * p, 13 * p, 0.3 * p), Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 3 * p, 0.3 * p, 3 * p), Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawRect(Rect.fromLTWH(px + 13.7 * p, py + 3 * p, 0.3 * p, 3 * p), Paint()..color = const Color(0xFFFFFFFF));
      // Faux text
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 3.8 * p, 4.5 * p, 1.5 * p), Paint()..color = const Color(0xDDFFFFFF));
      canvas.drawRect(Rect.fromLTWH(px + 7.5 * p, py + 3.8 * p, 5.5 * p, 0.8 * p), Paint()..color = const Color(0x88FFFFFF));
    }
    // Drain cover on all tiles
    if ((x + y) % 8 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 12 * p, py + 12 * p, 3 * p, 3 * p), Paint()..color = const Color(0xFF7A7A6A));
      for (double dg = 12.3; dg < 15; dg += 0.8) {
        canvas.drawRect(Rect.fromLTWH(px + 12.2 * p, py + dg * p, 2.6 * p, 0.3 * p), Paint()..color = const Color(0xFF5A5A4A));
      }
    }
  }

  // ── Ground ──
  void _drawGround(Canvas canvas, double px, double py, double ts) {
    final p = ts / 16;
    final v = ((px * 7 + py * 13) % 17).toInt();
    // Rich grass with texture variation
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFF2D5A2D));
    // Grass clumps
    if (v < 5) {
      canvas.drawRect(Rect.fromLTWH(px + (v * 2) * p, py + (v * 3 % 14) * p, 3 * p, 3 * p), Paint()..color = const Color(0xFF3D6A3D));
    }
    if (v > 10) {
      canvas.drawRect(Rect.fromLTWH(px + (v % 8) * p, py + (v % 6 + 4) * p, 2 * p, 2 * p), Paint()..color = const Color(0xFF255A25));
    }
    // Small stones
    if (v == 3 || v == 11) {
      canvas.drawCircle(Offset(px + 10 * p, py + 12 * p), 1 * p, Paint()..color = const Color(0xFF8B8B7A));
    }
    // Dirt patch
    if (v == 7) {
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 5 * p, 5 * p, 4 * p), Paint()..color = const Color(0xFF5D4E37));
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

  // ── Residential: Isometric 透天厝 — corrugated roof, brick facade, 鐵窗 ──
  void _drawResidential(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];

    // ─ EAST SHADOW WALL (right 3 cols, full height) ─
    final eastC = [const Color(0xFF7A4422), const Color(0xFF8B5533), const Color(0xFF6B3818)];
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = eastC[v % 3]);
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = const Color(0x33000000));
    // Small window on east
    canvas.drawRect(Rect.fromLTWH(px + 13.5 * p, py + 5 * p, 2 * p, 2 * p), Paint()..color = const Color(0x8890CAF9));
    // Cable on east wall
    canvas.drawRect(Rect.fromLTWH(px + 15 * p, py + 1 * p, 0.4 * p, 15 * p), Paint()..color = const Color(0xFF333333));

    // ─ ROOF (top 10 rows, left 13 cols) — corrugated metal ─
    final roofC = [const Color(0xFF7D8D90), const Color(0xFF8B9898), const Color(0xFF6E7D80)];
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 10 * p), Paint()..color = roofC[v % 3]);
    // Corrugated ridges
    for (double ry = 0; ry < 10; ry += 1.3) {
      canvas.drawRect(Rect.fromLTWH(px, py + ry * p, 13 * p, 0.3 * p), Paint()..color = roofC[v % 3].withAlpha(160));
    }
    // NW highlight (light from top-left)
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 0.5 * p), Paint()..color = const Color(0x22FFFFFF));
    canvas.drawRect(Rect.fromLTWH(px, py, 0.5 * p, 10 * p), Paint()..color = const Color(0x15FFFFFF));
    // Roof edge shadow
    canvas.drawRect(Rect.fromLTWH(px, py + 9.5 * p, 13 * p, 0.5 * p), Paint()..color = const Color(0x44000000));

    // Roof details (variant)
    if (v % 3 == 0) {
      // 不鏽鋼水塔 water tank
      canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 1 * p, 4 * p, 3.5 * p), Paint()..color = const Color(0xFF888888));
      canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 1 * p, 4 * p, 0.5 * p), Paint()..color = const Color(0xFFAAAAAA));
      canvas.drawRect(Rect.fromLTWH(px + 8.5 * p, py + 4.5 * p, 0.5 * p, 1 * p), Paint()..color = const Color(0xFF555555));
      canvas.drawRect(Rect.fromLTWH(px + 11 * p, py + 4.5 * p, 0.5 * p, 1 * p), Paint()..color = const Color(0xFF555555));
    }
    if (v % 4 != 0) {
      // AC outdoor unit
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 6 * p, 3 * p, 2.5 * p), Paint()..color = const Color(0xFF777777));
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 6 * p, 3 * p, 0.3 * p), Paint()..color = const Color(0xFF999999));
      canvas.drawCircle(Offset(px + 2.5 * p, py + 7.5 * p), 0.8 * p, Paint()..color = const Color(0xFF666666));
    }
    if (v % 5 == 2) {
      // Satellite dish
      canvas.drawCircle(Offset(px + 10 * p, py + 7 * p), 1.5 * p, Paint()..color = const Color(0xFFE0E0E0));
      canvas.drawRect(Rect.fromLTWH(px + 9.8 * p, py + 7 * p, 0.4 * p, 2 * p), Paint()..color = const Color(0xFF888888));
    }
    if (v % 6 == 3) {
      // Laundry rack
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 3 * p, 8 * p, 0.3 * p), Paint()..color = const Color(0xFF666666));
      final clothC = [const Color(0xFFE0E0E0), const Color(0xFF90CAF9), const Color(0xFFFFCDD2), const Color(0xFFC8E6C9)];
      for (int ci = 0; ci < 4; ci++) {
        canvas.drawRect(Rect.fromLTWH(px + (4.5 + ci * 1.8) * p, py + 3 * p, 1 * p, 1.5 * p), Paint()..color = clothC[ci]);
      }
    }
    if (v % 7 == 1) {
      canvas.drawRect(Rect.fromLTWH(px + 6 * p, py, 0.3 * p, 3 * p), Paint()..color = const Color(0xFF555555));
    }

    // ─ SOUTH FACADE (bottom 6 rows, left 13 cols) ─
    final brickC = [const Color(0xFFB85C3C), const Color(0xFFC4704A), const Color(0xFFAA5030), const Color(0xFFD4896C)];
    canvas.drawRect(Rect.fromLTWH(px, py + 10 * p, 13 * p, 6 * p), Paint()..color = brickC[v % 4]);
    // Brick mortar
    for (double by = 10.5; by < 16; by += 1.2) {
      canvas.drawRect(Rect.fromLTWH(px, py + by * p, 13 * p, 0.2 * p), Paint()..color = const Color(0x22000000));
    }

    // 2F windows with 鐵窗
    for (int wi = 0; wi < 2; wi++) {
      final wx = 1.0 + wi * 6.0;
      canvas.drawRect(Rect.fromLTWH(px + wx * p, py + 10.5 * p, 4.5 * p, 2.5 * p),
        Paint()..color = (v + wi) % 3 == 0 ? const Color(0xBBFFE082) : const Color(0xAA90CAF9));
      for (double gx = wx; gx <= wx + 4.5; gx += 0.9) {
        canvas.drawRect(Rect.fromLTWH(px + gx * p, py + 10.3 * p, 0.3 * p, 2.8 * p), Paint()..color = const Color(0xFF444444));
      }
      canvas.drawRect(Rect.fromLTWH(px + wx * p, py + 11.5 * p, 4.5 * p, 0.3 * p), Paint()..color = const Color(0xFF555555));
    }

    // 1F 鐵捲門
    canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 13.5 * p, 8 * p, 2.5 * p), Paint()..color = const Color(0xFF6A6A6A));
    for (double sy = 13.5; sy < 16; sy += 0.5) {
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + sy * p, 8 * p, 0.2 * p), Paint()..color = const Color(0xFF5A5A5A));
    }
    canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 14.5 * p, 0.5 * p, 1 * p), Paint()..color = const Color(0xFFBDBDBD));

    // Address plate
    canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 14 * p, 1.5 * p, 1 * p), Paint()..color = const Color(0xFF1565C0));
    canvas.drawRect(Rect.fromLTWH(px + 0.6 * p, py + 14.2 * p, 1.3 * p, 0.6 * p), Paint()..color = const Color(0xCCFFFFFF));

    // Corner shadow
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 10 * p, 3 * p, 6 * p), Paint()..color = const Color(0x22000000));
  }

  // ── Commercial: Isometric 商店 — huge 招牌, awning, merchandise ──
  void _drawCommercial(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];

    // ─ EAST SHADOW WALL ─
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = const Color(0xFFA09888));
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = const Color(0x33000000));
    canvas.drawRect(Rect.fromLTWH(px + 14.5 * p, py + 2 * p, 0.4 * p, 14 * p), Paint()..color = const Color(0xFF777777));

    // ─ ROOF (top 5 rows) — flat concrete ─
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 5 * p), Paint()..color = const Color(0xFFBBB5AA));
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 0.4 * p), Paint()..color = const Color(0x22FFFFFF));
    canvas.drawRect(Rect.fromLTWH(px, py, 0.4 * p, 5 * p), Paint()..color = const Color(0x15FFFFFF));
    canvas.drawRect(Rect.fromLTWH(px, py + 4.5 * p, 13 * p, 0.5 * p), Paint()..color = const Color(0x44000000));
    // AC on roof
    canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 1 * p, 4 * p, 2.5 * p), Paint()..color = const Color(0xFF888888));
    canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 1 * p, 4 * p, 0.3 * p), Paint()..color = const Color(0xFFAAAAAA));
    if (v % 3 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 1 * p, 3 * p, 3 * p), Paint()..color = const Color(0xFF999999));
      canvas.drawRect(Rect.fromLTWH(px + 1.5 * p, py + 1.5 * p, 2 * p, 2 * p), Paint()..color = const Color(0xFF666666));
    }

    // ─ BIG 招牌 (rows 5-8) ─
    final signC = [
      const Color(0xFFD32F2F), const Color(0xFF1565C0), const Color(0xFF2E7D32),
      const Color(0xFFF57F17), const Color(0xFF6A1B9A), const Color(0xFFE65100),
    ];
    final sc = signC[v % signC.length];
    canvas.drawRect(Rect.fromLTWH(px, py + 5 * p, 13 * p, 4 * p), Paint()..color = sc);
    final borderC = v % 2 == 0 ? const Color(0xFFDAA520) : const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(px, py + 5 * p, 13 * p, 0.4 * p), Paint()..color = borderC);
    canvas.drawRect(Rect.fromLTWH(px, py + 8.6 * p, 13 * p, 0.4 * p), Paint()..color = borderC);
    canvas.drawRect(Rect.fromLTWH(px, py + 5 * p, 0.4 * p, 4 * p), Paint()..color = borderC);
    canvas.drawRect(Rect.fromLTWH(px + 12.6 * p, py + 5 * p, 0.4 * p, 4 * p), Paint()..color = borderC);
    // Faux text
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 6 * p, 3 * p, 2 * p), Paint()..color = const Color(0xEEFFFFFF));
    canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 6 * p, 3 * p, 2 * p), Paint()..color = const Color(0xEEFFFFFF));
    if (v % 3 != 2) canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 6 * p, 3 * p, 2 * p), Paint()..color = const Color(0xDDFFFFFF));

    // ─ AWNING (rows 9-10) ─
    final awningC = [const Color(0xFF1B5E20), const Color(0xFF880E4F), const Color(0xFF0D47A1)];
    final ac = awningC[v % awningC.length];
    canvas.drawRect(Rect.fromLTWH(px - 0.5 * p, py + 9 * p, 14 * p, 1.5 * p), Paint()..color = ac);
    for (double sx = 0; sx < 13.5; sx += 2.5) {
      canvas.drawRect(Rect.fromLTWH(px + sx * p, py + 9 * p, 1.2 * p, 1.5 * p), Paint()..color = ac.withAlpha(150));
    }
    canvas.drawRect(Rect.fromLTWH(px - 0.5 * p, py + 10.3 * p, 14 * p, 0.3 * p), Paint()..color = const Color(0xFF333333));

    // ─ GROUND FLOOR (rows 10.5-16) ─
    final facadeC = [const Color(0xFFD7CCC8), const Color(0xFFCFD8DC), const Color(0xFFE8E0D8)];
    canvas.drawRect(Rect.fromLTWH(px, py + 10.5 * p, 13 * p, 5.5 * p), Paint()..color = facadeC[v % 3]);
    // Display window + merchandise
    canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 11 * p, 7 * p, 4.5 * p), Paint()..color = const Color(0xAA80DEEA));
    final merchC = [const Color(0xFFFF7043), const Color(0xFFFFCA28), const Color(0xFF66BB6A), const Color(0xFFAB47BC)];
    for (int mi = 0; mi < 4; mi++) {
      canvas.drawRect(Rect.fromLTWH(px + (1 + mi * 1.6) * p, py + 13 * p, 1 * p, 1.2 * p), Paint()..color = merchC[(v + mi) % 4]);
    }
    canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 14.5 * p, 7 * p, 0.3 * p), Paint()..color = const Color(0xFF795548));
    // Glass door
    canvas.drawRect(Rect.fromLTWH(px + 8.5 * p, py + 11 * p, 4 * p, 5 * p), Paint()..color = const Color(0xFF37474F));
    canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 11.5 * p, 3 * p, 4 * p), Paint()..color = const Color(0x8880DEEA));
    canvas.drawRect(Rect.fromLTWH(px + 11.5 * p, py + 13 * p, 0.4 * p, 1.5 * p), Paint()..color = const Color(0xFFBDBDBD));
    // 營業中
    if (v % 3 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 9.5 * p, py + 11.5 * p, 2 * p, 0.8 * p), Paint()..color = const Color(0xCCFF1744));
    }
    // Corner shadow
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 5 * p, 3 * p, 11 * p), Paint()..color = const Color(0x18000000));
  }

  // ── Temple: Isometric 廟宇 — ornate curved roof, dragon ridge, red+gold ──
  void _drawTemple(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];
    final gold = Paint()..color = const Color(0xFFDAA520);
    final goldBright = Paint()..color = const Color(0xFFFFD700);

    // ─ EAST SHADOW WALL (deep red) ─
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = const Color(0xFF6B1111));
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 8 * p, 3 * p, 0.4 * p), gold);

    // ─ ORNATE ROOF (top 9 rows, left 13 cols) ─
    canvas.drawRect(Rect.fromLTWH(px - 0.5 * p, py + 1 * p, 14 * p, 8 * p), Paint()..color = const Color(0xFF3D1C00));
    // Tile rows (curved look)
    for (int tr = 0; tr < 4; tr++) {
      canvas.drawRect(Rect.fromLTWH(px, py + (1.5 + tr * 1.8) * p, 13 * p, 1.2 * p),
        Paint()..color = Color(0xFF4A2E15 + tr * 6));
    }
    // Fish-scale tile pattern
    for (double rx = 0; rx < 13; rx += 2) {
      for (double ry = 2; ry < 8; ry += 2) {
        canvas.drawCircle(Offset(px + (rx + 1) * p, py + (ry + 1) * p), 0.8 * p,
          Paint()..color = const Color(0xFF5C3317)..style = PaintingStyle.stroke..strokeWidth = 0.3 * p);
      }
    }
    // Gold trim
    canvas.drawRect(Rect.fromLTWH(px - 0.5 * p, py + 0.5 * p, 14 * p, 0.5 * p), gold);
    canvas.drawRect(Rect.fromLTWH(px - 0.5 * p, py + 8.5 * p, 14 * p, 0.6 * p), goldBright);
    // Upswept eave corners
    canvas.drawRect(Rect.fromLTWH(px - 1 * p, py, 2 * p, 1 * p), Paint()..color = const Color(0xFF3D1C00));
    canvas.drawRect(Rect.fromLTWH(px + 12 * p, py, 2 * p, 1 * p), Paint()..color = const Color(0xFF3D1C00));
    canvas.drawRect(Rect.fromLTWH(px - 1 * p, py, 1 * p, 0.5 * p), goldBright);
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 1 * p, 0.5 * p), goldBright);
    // Dragon ridge ornament
    canvas.drawRect(Rect.fromLTWH(px + 5 * p, py, 4 * p, 1 * p), goldBright);
    canvas.drawRect(Rect.fromLTWH(px + 6 * p, py - 0.5 * p, 2 * p, 1 * p), goldBright);
    canvas.drawRect(Rect.fromLTWH(px + 6.5 * p, py - 1 * p, 1 * p, 0.5 * p), Paint()..color = const Color(0xFFFF6D00));
    // Highlight
    canvas.drawRect(Rect.fromLTWH(px, py + 1 * p, 0.4 * p, 8 * p), Paint()..color = const Color(0x15FFFFFF));

    // ─ SOUTH FACADE (bottom 7 rows) ─
    canvas.drawRect(Rect.fromLTWH(px, py + 9 * p, 13 * p, 7 * p), Paint()..color = const Color(0xFF8B1A1A));
    // Pillars with gold capitals
    for (final pxOff in [0.5, 10.5]) {
      canvas.drawRect(Rect.fromLTWH(px + pxOff * p, py + 9.5 * p, 2 * p, 6.5 * p), Paint()..color = const Color(0xFFCC2222));
      canvas.drawRect(Rect.fromLTWH(px + (pxOff - 0.2) * p, py + 9.2 * p, 2.4 * p, 0.5 * p), gold);
    }
    // Ornate door
    canvas.drawRect(Rect.fromLTWH(px + 3.5 * p, py + 10 * p, 6 * p, 6 * p), Paint()..color = const Color(0xFF5D1A1A));
    canvas.drawRect(Rect.fromLTWH(px + 3.5 * p, py + 10 * p, 6 * p, 0.5 * p), gold);
    canvas.drawRect(Rect.fromLTWH(px + 3.5 * p, py + 10 * p, 0.5 * p, 6 * p), gold);
    canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 10 * p, 0.5 * p, 6 * p), gold);
    canvas.drawRect(Rect.fromLTWH(px + 6.2 * p, py + 11 * p, 0.4 * p, 5 * p), Paint()..color = const Color(0xFF3A0A0A));
    // Door panels
    canvas.drawRect(Rect.fromLTWH(px + 4.2 * p, py + 11.5 * p, 1.8 * p, 2 * p), Paint()..color = const Color(0xFF6B1E1E));
    canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 11.5 * p, 1.8 * p, 2 * p), Paint()..color = const Color(0xFF6B1E1E));
    // Door knockers
    canvas.drawCircle(Offset(px + 5 * p, py + 14 * p), 0.6 * p, gold);
    canvas.drawCircle(Offset(px + 8 * p, py + 14 * p), 0.6 * p, gold);
    // Lanterns
    canvas.drawCircle(Offset(px + 1.5 * p, py + 11 * p), 1.2 * p, Paint()..color = const Color(0xDDFF3333));
    canvas.drawCircle(Offset(px + 1.5 * p, py + 11 * p), 0.5 * p, Paint()..color = const Color(0xFFFFCC00));
    canvas.drawCircle(Offset(px + 11.5 * p, py + 11 * p), 1.2 * p, Paint()..color = const Color(0xDDFF3333));
    canvas.drawCircle(Offset(px + 11.5 * p, py + 11 * p), 0.5 * p, Paint()..color = const Color(0xFFFFCC00));
    canvas.drawRect(Rect.fromLTWH(px + 1.3 * p, py + 12.2 * p, 0.4 * p, 0.6 * p), gold);
    canvas.drawRect(Rect.fromLTWH(px + 11.3 * p, py + 12.2 * p, 0.4 * p, 0.6 * p), gold);
    // Stone threshold
    canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 15.5 * p, 7 * p, 0.5 * p), Paint()..color = const Color(0xFF9E9E9E));
    // Incense smoke
    if (v % 2 == 0) {
      canvas.drawCircle(Offset(px + 7 * p, py + 9 * p), 1.2 * p, Paint()..color = const Color(0x22FFFFFF));
      canvas.drawCircle(Offset(px + 5 * p, py + 8 * p), 0.8 * p, Paint()..color = const Color(0x15FFFFFF));
    }
    // Corner shadow
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 9 * p, 3 * p, 7 * p), Paint()..color = const Color(0x22000000));
  }

  // ── Apartment: Isometric 台灣公寓 — concrete, 鐵窗 grid, water tanks, 鐵皮 ──
  void _drawApartment(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];

    // ─ EAST SHADOW WALL ─
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = const Color(0xFF686868));
    canvas.drawRect(Rect.fromLTWH(px + 13.5 * p, py + 6 * p, 2 * p, 2 * p), Paint()..color = const Color(0x7790CAF9));
    canvas.drawRect(Rect.fromLTWH(px + 13.5 * p, py + 12 * p, 2 * p, 2 * p), Paint()..color = const Color(0x77FFE082));
    if (v % 3 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 13.5 * p, py + 9 * p, 2 * p, 1.5 * p), Paint()..color = const Color(0xFF888888));
    }

    // ─ ROOF (top 5 rows, left 13 cols) ─
    final roofC = [const Color(0xFF9A9A9A), const Color(0xFF8E8E8E), const Color(0xFFA0A0A0)];
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 5 * p), Paint()..color = roofC[v % 3]);
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 0.4 * p), Paint()..color = const Color(0x22FFFFFF));
    canvas.drawRect(Rect.fromLTWH(px, py, 0.4 * p, 5 * p), Paint()..color = const Color(0x15FFFFFF));
    canvas.drawRect(Rect.fromLTWH(px, py + 4.5 * p, 13 * p, 0.5 * p), Paint()..color = const Color(0x44000000));
    // Water tank
    if (v % 3 != 2) {
      canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 0.5 * p, 4 * p, 2.5 * p), Paint()..color = const Color(0xFF757575));
      canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 0.5 * p, 4 * p, 0.4 * p), Paint()..color = const Color(0xFF8A8A8A));
    }
    // 鐵皮加蓋
    if (v % 5 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 0.5 * p, py + 0.5 * p, 6 * p, 3 * p), Paint()..color = const Color(0xFF7E7E7E));
      for (double cx = 0.5; cx < 6.5; cx += 1) {
        canvas.drawRect(Rect.fromLTWH(px + cx * p, py + 0.5 * p, 0.4 * p, 3 * p), Paint()..color = const Color(0xFF8A8A8A));
      }
    }
    // Laundry poles
    if (v % 4 == 1) {
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 2 * p, 9 * p, 0.2 * p), Paint()..color = const Color(0xFF555555));
      final clothC = [const Color(0xFFE0E0E0), const Color(0xFF90CAF9), const Color(0xFFFFCDD2)];
      for (int ci = 0; ci < 3; ci++) {
        canvas.drawRect(Rect.fromLTWH(px + (2.5 + ci * 3) * p, py + 2 * p, 1.2 * p, 1.5 * p), Paint()..color = clothC[ci]);
      }
    }
    if (v % 7 == 3) {
      canvas.drawCircle(Offset(px + 2 * p, py + 1.5 * p), 1 * p, Paint()..color = const Color(0xFFE0E0E0));
    }

    // ─ SOUTH FACADE (bottom 11 rows, left 13 cols) ─
    final facadeC = [const Color(0xFF8A8A8A), const Color(0xFF93877A), const Color(0xFF7E8B8A)];
    canvas.drawRect(Rect.fromLTWH(px, py + 5 * p, 13 * p, 11 * p), Paint()..color = facadeC[v % 3]);
    // Floor dividers
    for (final fy in [7.5, 10.0, 12.5]) {
      canvas.drawRect(Rect.fromLTWH(px, py + fy * p, 13 * p, 0.3 * p), Paint()..color = const Color(0xFF656565));
    }

    // Window grid (3×4) with 鐵窗
    for (int wy = 0; wy < 4; wy++) {
      final baseY = 5.5 + wy * 2.5;
      for (int wx = 0; wx < 3; wx++) {
        final winX = px + (1 + wx * 4) * p;
        final winY = py + baseY * p;
        final wh = (v + wy * 3 + wx * 7) % 10;
        final wp = Paint()..color = wh < 3 ? const Color(0xBBFFE082)
                 : wh < 6 ? const Color(0x99A8D8F0)
                 : wh < 8 ? const Color(0xAAE8C8A0)
                 : const Color(0xFF505050);
        canvas.drawRect(Rect.fromLTWH(winX, winY, 2.5 * p, 2 * p), wp);
        for (double gx = 0; gx < 2.5; gx += 0.7) {
          canvas.drawRect(Rect.fromLTWH(winX + gx * p, winY, 0.2 * p, 2 * p), Paint()..color = const Color(0xFF555555));
        }
        canvas.drawRect(Rect.fromLTWH(winX, winY + 1 * p, 2.5 * p, 0.2 * p), Paint()..color = const Color(0xFF555555));
      }
    }

    // AC on facade
    if (v % 2 == 0) canvas.drawRect(Rect.fromLTWH(px + 11 * p, py + 6 * p, 1.5 * p, 1 * p), Paint()..color = const Color(0xFF888888));
    if (v % 3 == 1) canvas.drawRect(Rect.fromLTWH(px + 11 * p, py + 11 * p, 1.5 * p, 1 * p), Paint()..color = const Color(0xFF888888));
    // Balcony railings
    for (final ry in [7.5, 10.0]) {
      for (double rx = 0.5; rx < 12.5; rx += 1.2) {
        canvas.drawRect(Rect.fromLTWH(px + rx * p, py + (ry + 0.3) * p, 0.2 * p, 0.8 * p), Paint()..color = const Color(0xFF555555));
      }
    }
    // Water stain
    if (v % 4 == 2) {
      canvas.drawRect(Rect.fromLTWH(px + (v % 8) * p, py + 6 * p, 0.6 * p, 10 * p), Paint()..color = const Color(0x0F000000));
    }
    // Cable bundle
    canvas.drawRect(Rect.fromLTWH(px, py + 5.3 * p, 13 * p, 0.2 * p), Paint()..color = const Color(0xFF333333));
    // Corner shadow
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 5 * p, 3 * p, 11 * p), Paint()..color = const Color(0x22000000));
  }

  // ── Night market: Isometric 夜市攤販 — neon canvas, food stalls, steam ──
  void _drawNightMarket(Canvas canvas, int x, int y, double px, double py, double ts) {
    final v = _tileVariant[y][x];
    final p = ts / 16;
    final neonC = [
      const Color(0xFFFF2D78), const Color(0xFF00E5FF), const Color(0xFFFFD700),
      const Color(0xFF7B68EE), const Color(0xFF00FF88), const Color(0xFFFF4444),
    ];
    final neon = neonC[v % neonC.length];

    // Dark base + neon ambient
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFF1A0A2E));
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = neon.withAlpha(15));

    // ─ EAST FRAME ─
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = const Color(0xFF222222));
    canvas.drawRect(Rect.fromLTWH(px + 14 * p, py + 2 * p, 1 * p, 14 * p), Paint()..color = const Color(0xFF444444));

    // ─ CANVAS ROOF (top 6 rows, left 13 cols) ─
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 6 * p), Paint()..color = neon.withAlpha(180));
    // Neon sign border
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 0.5 * p), Paint()..color = neon);
    canvas.drawRect(Rect.fromLTWH(px, py + 5.5 * p, 13 * p, 0.5 * p), Paint()..color = neon);
    canvas.drawRect(Rect.fromLTWH(px, py, 0.5 * p, 6 * p), Paint()..color = neon);
    // Faux text
    canvas.drawRect(Rect.fromLTWH(px + 1.5 * p, py + 1.5 * p, 3 * p, 2.5 * p), Paint()..color = const Color(0xEEFFFFFF));
    canvas.drawRect(Rect.fromLTWH(px + 5.5 * p, py + 1.5 * p, 3 * p, 2.5 * p), Paint()..color = const Color(0xEEFFFFFF));
    canvas.drawRect(Rect.fromLTWH(px + 9.5 * p, py + 1.5 * p, 2.5 * p, 2.5 * p), Paint()..color = const Color(0xDDFFFFFF));

    // String lights
    for (double lx = 1; lx < 13; lx += 2) {
      final lc = neonC[((v + lx.toInt()) % neonC.length)];
      canvas.drawCircle(Offset(px + lx * p, py + 6.5 * p), 0.5 * p, Paint()..color = lc.withAlpha(220));
    }

    // ─ STALL AREA ─
    canvas.drawRect(Rect.fromLTWH(px, py + 7 * p, 13 * p, 3 * p), Paint()..color = const Color(0xFF333333));
    // Grill
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 7.5 * p, 5 * p, 2 * p), Paint()..color = const Color(0xFF555555));
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 7.5 * p, 5 * p, 0.3 * p), Paint()..color = const Color(0xFF888888));
    // Food on grill
    final foodC = [const Color(0xFFFF7043), const Color(0xFFFFCA28), const Color(0xFF66BB6A), const Color(0xFFEF5350)];
    for (int fi = 0; fi < 4; fi++) {
      canvas.drawCircle(Offset(px + (1.8 + fi * 1.2) * p, py + 8.5 * p), 0.5 * p, Paint()..color = foodC[fi % 4]);
    }
    // Counter
    canvas.drawRect(Rect.fromLTWH(px, py + 10 * p, 13 * p, 2 * p), Paint()..color = const Color(0xFF444444));
    canvas.drawRect(Rect.fromLTWH(px, py + 10 * p, 13 * p, 0.3 * p), Paint()..color = const Color(0xFF666666));
    // Drinks on counter
    for (int di = 0; di < 3; di++) {
      canvas.drawRect(Rect.fromLTWH(px + (7.5 + di * 1.5) * p, py + 8 * p, 0.8 * p, 2 * p), Paint()..color = const Color(0xFF00BCD4));
    }
    // Steam
    if (v % 2 == 0) {
      canvas.drawCircle(Offset(px + 4 * p, py + 6.5 * p), 1.5 * p, Paint()..color = const Color(0x22FFFFFF));
      canvas.drawCircle(Offset(px + 3 * p, py + 5.5 * p), 1 * p, Paint()..color = const Color(0x18FFFFFF));
    }
    // Frame poles
    canvas.drawRect(Rect.fromLTWH(px, py + 6 * p, 0.5 * p, 10 * p), Paint()..color = const Color(0xFF555555));
    canvas.drawRect(Rect.fromLTWH(px + 12.5 * p, py + 6 * p, 0.5 * p, 10 * p), Paint()..color = const Color(0xFF555555));
    // Floor
    canvas.drawRect(Rect.fromLTWH(px, py + 12 * p, 13 * p, 4 * p), Paint()..color = const Color(0xFF2A1A3E));
    // Hanging lantern
    if (v % 3 == 0) {
      canvas.drawCircle(Offset(px + 2 * p, py + 7 * p), 1 * p, Paint()..color = const Color(0xCCFF3333));
      canvas.drawCircle(Offset(px + 2 * p, py + 7 * p), 0.4 * p, Paint()..color = const Color(0xFFFFCC00));
    }
    // Floor glow
    canvas.drawRect(Rect.fromLTWH(px, py + 14 * p, 13 * p, 2 * p), Paint()..color = neon.withAlpha(30));
  }

  // ── Restaurant: Isometric eatery — gold sign, warm interior ──
  void _drawRestaurant(Canvas canvas, double px, double py, double ts) {
    final p = ts / 16;
    // East shadow
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = const Color(0xFF6B5535));
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = const Color(0x33000000));
    // Roof
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 4 * p), Paint()..color = const Color(0xFFBBB5AA));
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 0.4 * p), Paint()..color = const Color(0x22FFFFFF));
    canvas.drawRect(Rect.fromLTWH(px, py + 3.5 * p, 13 * p, 0.5 * p), Paint()..color = const Color(0x44000000));
    // Gold 招牌
    canvas.drawRect(Rect.fromLTWH(px, py + 4 * p, 13 * p, 3 * p), Paint()..color = const Color(0xFFFFD700));
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 4.5 * p, 3 * p, 2 * p), Paint()..color = const Color(0xDDFFFFFF));
    canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 4.5 * p, 3 * p, 2 * p), Paint()..color = const Color(0xDDFFFFFF));
    canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 4.5 * p, 3 * p, 2 * p), Paint()..color = const Color(0xDDFFFFFF));
    // Facade
    canvas.drawRect(Rect.fromLTWH(px, py + 7 * p, 13 * p, 9 * p), Paint()..color = const Color(0xFF8B7355));
    // Big window showing kitchen
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 8 * p, 5 * p, 5 * p), Paint()..color = const Color(0xBBFFE0B2));
    // Door
    canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 8 * p, 4 * p, 8 * p), Paint()..color = const Color(0xFF5C4033));
    canvas.drawRect(Rect.fromLTWH(px + 8.5 * p, py + 8.5 * p, 3 * p, 3 * p), Paint()..color = const Color(0xAAB0E0FF));
    // Warm glow
    canvas.drawCircle(Offset(px + 6 * p, py + 10 * p), 8 * p, Paint()..color = const Color(0x0CFFD700));
    // Emoji
    final tp = TextPainter(text: const TextSpan(text: '\u{1F35C}', style: TextStyle(fontSize: 10)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(px + 2 * p, py + 1 * p));
    // Corner shadow
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 4 * p, 3 * p, 12 * p), Paint()..color = const Color(0x22000000));
  }

  // ── Customer: Isometric delivery destination ──
  void _drawCustomer(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    // East shadow
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = const Color(0xFF3D5D6D));
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py, 3 * p, ts), Paint()..color = const Color(0x33000000));
    // Roof
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 4 * p), Paint()..color = const Color(0xFFBBB5AA));
    canvas.drawRect(Rect.fromLTWH(px, py, 13 * p, 0.4 * p), Paint()..color = const Color(0x22FFFFFF));
    canvas.drawRect(Rect.fromLTWH(px, py + 3.5 * p, 13 * p, 0.5 * p), Paint()..color = const Color(0x44000000));
    // Teal 招牌
    canvas.drawRect(Rect.fromLTWH(px, py + 4 * p, 13 * p, 3 * p), Paint()..color = const Color(0xFF4ECDC4));
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 4.5 * p, 5 * p, 2 * p), Paint()..color = const Color(0xDDFFFFFF));
    canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 4.5 * p, 5 * p, 2 * p), Paint()..color = const Color(0xDDFFFFFF));
    // Facade
    canvas.drawRect(Rect.fromLTWH(px, py + 7 * p, 13 * p, 9 * p), Paint()..color = const Color(0xFF607D8B));
    // Door
    canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 8 * p, 5 * p, 8 * p), Paint()..color = const Color(0xFF37474F));
    canvas.drawRect(Rect.fromLTWH(px + 4.5 * p, py + 8.5 * p, 4 * p, 3 * p), Paint()..color = const Color(0xAAB0E0FF));
    // Doorbell
    canvas.drawCircle(Offset(px + 9 * p, py + 12 * p), 0.5 * p, Paint()..color = const Color(0xFFFFD700));
    // Teal glow
    canvas.drawCircle(Offset(px + 6 * p, py + 10 * p), 8 * p, Paint()..color = const Color(0x0C4ECDC4));
    // Emoji
    final tp = TextPainter(text: const TextSpan(text: '\u{1F4E6}', style: TextStyle(fontSize: 10)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(px + 2 * p, py + 1 * p));
    // Corner shadow
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 4 * p, 3 * p, 12 * p), Paint()..color = const Color(0x22000000));
  }

  // ── Park: Top-down green space with trees, benches, paths ──
  void _drawPark(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];
    // Lush grass base
    canvas.drawRect(Rect.fromLTWH(px, py, ts, ts), Paint()..color = const Color(0xFF4CAF50));
    // Grass variation
    if (v % 3 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + (v % 7) * p, py + (v % 5 + 2) * p, 4 * p, 4 * p), Paint()..color = const Color(0xFF388E3C));
    }
    if (v % 4 == 1) {
      canvas.drawRect(Rect.fromLTWH(px + (v % 5 + 5) * p, py + (v % 4 + 8) * p, 3 * p, 3 * p), Paint()..color = const Color(0xFF43A047));
    }

    if (v % 8 == 0) {
      // Large tree (top-down canopy)
      canvas.drawCircle(Offset(px + 9 * p, py + 10 * p), 3 * p, Paint()..color = const Color(0x22000000));
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 7 * p, 2 * p, 3 * p), Paint()..color = const Color(0xFF5D4037));
      canvas.drawCircle(Offset(px + 8 * p, py + 6 * p), 5 * p, Paint()..color = const Color(0xFF2E7D32));
      canvas.drawCircle(Offset(px + 6 * p, py + 5 * p), 3 * p, Paint()..color = const Color(0xFF388E3C));
      canvas.drawCircle(Offset(px + 10 * p, py + 7 * p), 2.5 * p, Paint()..color = const Color(0xFF43A047));
    } else if (v % 8 == 1) {
      // Flower bed with border
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 5 * p, 12 * p, 6 * p), Paint()..color = const Color(0xFF6D4C41));
      canvas.drawRect(Rect.fromLTWH(px + 2.5 * p, py + 5.5 * p, 11 * p, 5 * p), Paint()..color = const Color(0xFF388E3C));
      for (int i = 0; i < 4; i++) {
        final fx = 3.5 + i * 2.5;
        canvas.drawCircle(Offset(px + fx * p, py + 8 * p), 1 * p,
          Paint()..color = Color.lerp(const Color(0xFFFF6B6B), const Color(0xFFFFD700), (v * i % 10) / 10.0)!);
      }
    } else if (v % 8 == 2) {
      // Park bench with path
      canvas.drawRect(Rect.fromLTWH(px, py + 11 * p, ts, 2 * p), Paint()..color = const Color(0xFFBCAAA4));
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 8 * p, 10 * p, 1.5 * p), Paint()..color = const Color(0xFF795548));
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 6 * p, 10 * p, 1 * p), Paint()..color = const Color(0xFF795548));
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 9.5 * p, 1 * p, 1.5 * p), Paint()..color = const Color(0xFF5D4037));
      canvas.drawRect(Rect.fromLTWH(px + 12 * p, py + 9.5 * p, 1 * p, 1.5 * p), Paint()..color = const Color(0xFF5D4037));
    } else if (v % 8 == 3) {
      // Gravel walking path
      canvas.drawRect(Rect.fromLTWH(px, py + 6 * p, ts, 3 * p), Paint()..color = const Color(0xFFBCAAA4));
      canvas.drawRect(Rect.fromLTWH(px, py + 7 * p, ts, 0.3 * p), Paint()..color = const Color(0xFFA1887F));
    } else if (v % 8 == 4) {
      // Bush cluster
      canvas.drawCircle(Offset(px + 5 * p, py + 8 * p), 3 * p, Paint()..color = const Color(0xFF388E3C));
      canvas.drawCircle(Offset(px + 10 * p, py + 10 * p), 2.5 * p, Paint()..color = const Color(0xFF2E7D32));
      canvas.drawCircle(Offset(px + 8 * p, py + 5 * p), 2 * p, Paint()..color = const Color(0xFF43A047));
    } else if (v % 8 == 5) {
      // Park lamp
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 3 * p, 1.5 * p, 11 * p), Paint()..color = const Color(0xFF616161));
      canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 2 * p, 5 * p, 2 * p), Paint()..color = const Color(0xFF757575));
      canvas.drawCircle(Offset(px + 7.5 * p, py + 2 * p), 2 * p, Paint()..color = const Color(0x33FFFF00));
    } else if (v % 8 == 6) {
      // Small pond
      canvas.drawCircle(Offset(px + 8 * p, py + 9 * p), 4 * p, Paint()..color = const Color(0xFF1565C0));
      canvas.drawCircle(Offset(px + 8 * p, py + 9 * p), 3 * p, Paint()..color = const Color(0xFF42A5F5));
      canvas.drawCircle(Offset(px + 7 * p, py + 8 * p), 1 * p, Paint()..color = const Color(0x44FFFFFF));
    } else {
      // Playground equipment
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 5 * p, 10 * p, 8 * p), Paint()..color = const Color(0xFFBCAAA4));
      canvas.drawCircle(Offset(px + 6 * p, py + 9 * p), 2 * p, Paint()..color = const Color(0xFFFF7043));
      canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 7 * p, 3 * p, 4 * p), Paint()..color = const Color(0xFF42A5F5));
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
