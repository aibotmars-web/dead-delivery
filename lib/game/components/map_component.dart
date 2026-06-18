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
    final mainRoadsH = {12, 13, 25, 26, 38, 39};
    final mainRoadsV = {10, 11, 24, 25, 40, 41};

    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        if (_tiles[y][x] != TileType.road) continue;
        if (!_hasAdjacentSidewalkOrBuilding(x, y)) continue;

        // No parking at intersections
        if (mainRoadsH.contains(y) && mainRoadsV.contains(x)) continue;

        final key = y * mapWidth + x;
        final hash = (x * 31 + y * 17) % 100;

        if (_inZone(x, y, _zoneTemple)) {
          _parkingLines[key] = hash < 60 ? ParkingLine.red : ParkingLine.yellow;
        } else if (_inZone(x, y, _zoneCommercial)) {
          _parkingLines[key] = hash < 30 ? ParkingLine.red : (hash < 60 ? ParkingLine.yellow : ParkingLine.white);
        } else if (_inZone(x, y, _zoneNightMarket)) {
          _parkingLines[key] = hash < 40 ? ParkingLine.red : ParkingLine.yellow;
        } else if (_inZone(x, y, _zoneResidential)) {
          _parkingLines[key] = hash < 15 ? ParkingLine.red : ParkingLine.white;
        } else if (_inZone(x, y, _zoneApartments)) {
          _parkingLines[key] = hash < 20 ? ParkingLine.red : ParkingLine.white;
        } else {
          _parkingLines[key] = hash < 25 ? ParkingLine.red : (hash < 50 ? ParkingLine.yellow : ParkingLine.white);
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

  // ── Residential: Taiwan brick houses with balconies, AC units, plants ──
  void _drawResidential(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];
    final dst = Rect.fromLTWH(px, py, ts, ts);

    // Brick wall base
    canvas.drawRect(dst, Paint()..color = const Color(0xFFB85C3C));

    // Darker brick pattern
    final brickDark = Paint()..color = const Color(0xFF9E4A2E);
    for (int row = 0; row < 8; row++) {
      final offset = row.isOdd ? 4.0 : 0.0;
      for (double bx = offset; bx < 16; bx += 8) {
        canvas.drawRect(
          Rect.fromLTWH(px + bx * p, py + row * 2 * p, 1 * p, 2 * p),
          brickDark,
        );
      }
    }

    // Roof (brown tiles, sloped appearance)
    canvas.drawRect(Rect.fromLTWH(px, py, ts, 3 * p), Paint()..color = const Color(0xFF5D3A1A));
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py, 14 * p, 1 * p), Paint()..color = const Color(0xFF7A4E2A));
    // Roof ridge
    canvas.drawRect(Rect.fromLTWH(px + 3 * p, py, 10 * p, 1 * p), Paint()..color = const Color(0xFF8B6340));

    // Windows with frames
    final winBg = Paint()..color = const Color(0xAAA8D8F0);
    final winFrame = Paint()..color = const Color(0xFFE0D5C0);
    final winLit = Paint()..color = const Color(0xCCFFE082);

    if (v % 3 == 0) {
      // Two windows
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 4 * p, 5 * p, 4 * p), winFrame);
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 5 * p, 3 * p, 2 * p), v % 2 == 0 ? winLit : winBg);
      canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 4 * p, 5 * p, 4 * p), winFrame);
      canvas.drawRect(Rect.fromLTWH(px + 10 * p, py + 5 * p, 3 * p, 2 * p), winBg);
    } else {
      // Single large window
      canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 4 * p, 10 * p, 4 * p), winFrame);
      canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 5 * p, 8 * p, 2 * p), winBg);
      // Window divider
      canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 5 * p, 1 * p, 2 * p), winFrame);
    }

    // 鐵窗 Iron window grilles (iconic Taiwan element)
    final grillePaint = Paint()..color = const Color(0xFF4A4A4A);
    if (v % 3 == 0) {
      // Grille on windows
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 4 * p, 5 * p, 0.5 * p), grillePaint);
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 7 * p, 5 * p, 0.5 * p), grillePaint);
      for (double gx = 2; gx < 7; gx += 1.5) {
        canvas.drawRect(Rect.fromLTWH(px + gx * p, py + 4 * p, 0.5 * p, 4 * p), grillePaint);
      }
    }

    // Balcony railing (iron) with laundry poles
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 9 * p, 14 * p, 0.5 * p), grillePaint);
    for (double rx = 2; rx < 15; rx += 2) {
      canvas.drawRect(Rect.fromLTWH(px + rx * p, py + 9 * p, 0.5 * p, 2 * p), grillePaint);
    }

    // AC unit (some houses) — with drip pipe
    if (v % 4 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 12 * p, py + 5 * p, 3 * p, 2 * p), Paint()..color = const Color(0xFF888888));
      canvas.drawRect(Rect.fromLTWH(px + 12 * p, py + 5 * p, 3 * p, 0.5 * p), Paint()..color = const Color(0xFFAAAAAA));
      // Drip pipe
      canvas.drawRect(Rect.fromLTWH(px + 15 * p, py + 7 * p, 0.5 * p, 9 * p), Paint()..color = const Color(0xFF666666));
    }

    // Door with awning
    canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 10 * p, 6 * p, 6 * p), Paint()..color = const Color(0xFF5D3A1A));
    canvas.drawRect(Rect.fromLTWH(px + 6 * p, py + 11 * p, 4 * p, 4 * p), Paint()..color = const Color(0xFF7A4E2A));
    canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 13 * p, 1 * p, 1 * p), Paint()..color = const Color(0xFFDAA520));
    // Metal roller shutter above door (鐵捲門)
    canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 10 * p, 6 * p, 1 * p), Paint()..color = const Color(0xFF666666));

    // Street-level number plate
    if (v % 5 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 11 * p, 3 * p, 2 * p), Paint()..color = const Color(0xFF1565C0));
      canvas.drawRect(Rect.fromLTWH(px + 1.5 * p, py + 11.5 * p, 2 * p, 1 * p), Paint()..color = const Color(0xCCFFFFFF));
    }

    // Potted plants (very common in Taiwan streets)
    if (v % 3 == 1) {
      canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 14 * p, 2 * p, 2 * p), Paint()..color = const Color(0xFF8B4513));
      canvas.drawCircle(Offset(px + 14 * p, py + 13 * p), 1.5 * p, Paint()..color = const Color(0xFF4CAF50));
    }
    if (v % 7 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 14 * p, 2 * p, 2 * p), Paint()..color = const Color(0xFF6D4C41));
      canvas.drawCircle(Offset(px + 2 * p, py + 13.5 * p), 1.2 * p, Paint()..color = const Color(0xFF66BB6A));
    }
  }

  // ── Commercial: Taiwan street shops with awnings & LED signs ──
  void _drawCommercial(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];
    final dst = Rect.fromLTWH(px, py, ts, ts);

    // Concrete facade
    final facadeColors = [
      const Color(0xFFD7CCC8), const Color(0xFFCFD8DC),
      const Color(0xFFE8E0D8), const Color(0xFFBCAAA4),
    ];
    canvas.drawRect(dst, Paint()..color = facadeColors[v % facadeColors.length]);

    // Floor divider (horizontal line)
    canvas.drawRect(
      Rect.fromLTWH(px, py + 7 * p, ts, 0.5 * p),
      Paint()..color = const Color(0xFF9E9E9E),
    );

    // Big colorful shop sign (招牌) — THE most Taiwan commercial feature
    final signColors = [
      const Color(0xFFD32F2F), const Color(0xFF1565C0),
      const Color(0xFF2E7D32), const Color(0xFFF57F17),
      const Color(0xFF6A1B9A), const Color(0xFFE65100),
    ];
    final signColor = signColors[v % signColors.length];
    canvas.drawRect(Rect.fromLTWH(px, py, ts, 4 * p), Paint()..color = signColor);
    // Sign border
    canvas.drawRect(Rect.fromLTWH(px, py + 3.5 * p, ts, 0.5 * p), Paint()..color = signColor.withAlpha(180));
    // White text area on sign
    canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 0.5 * p, 12 * p, 2.5 * p), Paint()..color = const Color(0xDDFFFFFF));
    // Faux text lines
    canvas.drawRect(Rect.fromLTWH(px + 3 * p, py + 1 * p, 4 * p, 1 * p), Paint()..color = signColor.withAlpha(200));
    canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 1 * p, 5 * p, 1 * p), Paint()..color = signColor.withAlpha(150));

    // Awning (遮雨棚) over ground floor — striped fabric
    final awningColor = v % 2 == 0 ? const Color(0xFF1B5E20) : const Color(0xFF880E4F);
    canvas.drawRect(Rect.fromLTWH(px, py + 8 * p, ts, 2 * p), Paint()..color = awningColor);
    // Stripe pattern on awning
    for (double sx = 0; sx < 16; sx += 4) {
      canvas.drawRect(
        Rect.fromLTWH(px + sx * p, py + 8 * p, 2 * p, 2 * p),
        Paint()..color = awningColor.withAlpha(150),
      );
    }
    // Awning drip edge
    canvas.drawRect(Rect.fromLTWH(px, py + 10 * p, ts, 0.5 * p), Paint()..color = const Color(0xFF424242));

    // Second floor windows with iron grilles
    final glassPaint = Paint()..color = const Color(0xAA90CAF9);
    canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 4.5 * p, 5 * p, 2.5 * p), glassPaint);
    canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 4.5 * p, 5 * p, 2.5 * p), glassPaint);
    // Iron grilles
    final grille = Paint()..color = const Color(0xFF555555);
    for (double gx = 2; gx < 7; gx += 1.5) {
      canvas.drawRect(Rect.fromLTWH(px + gx * p, py + 4.5 * p, 0.4 * p, 2.5 * p), grille);
    }
    for (double gx = 9; gx < 14; gx += 1.5) {
      canvas.drawRect(Rect.fromLTWH(px + gx * p, py + 4.5 * p, 0.4 * p, 2.5 * p), grille);
    }

    // Ground floor: glass door + display window
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 10.5 * p, 6 * p, 5.5 * p), Paint()..color = const Color(0xAA80DEEA));
    canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 10.5 * p, 4 * p, 5.5 * p), Paint()..color = const Color(0xFF37474F));
    canvas.drawRect(Rect.fromLTWH(px + 9 * p, py + 11 * p, 2 * p, 4 * p), Paint()..color = const Color(0x8880DEEA));
    // Door handle
    canvas.drawRect(Rect.fromLTWH(px + 11 * p, py + 13 * p, 0.5 * p, 1.5 * p), Paint()..color = const Color(0xFFBDBDBD));

    // LED open sign (some shops)
    if (v % 3 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 11 * p, 2 * p, 1.5 * p), Paint()..color = const Color(0xCCFF1744));
    }

    // Rooftop AC / water tank
    if (v % 5 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 12 * p, py - 1.5 * p, 3 * p, 1.5 * p), Paint()..color = const Color(0xFF757575));
    }
  }

  // ── Temple: traditional red+gold architecture ──
  void _drawTemple(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];
    final dst = Rect.fromLTWH(px, py, ts, ts);

    // Red wall base
    canvas.drawRect(dst, Paint()..color = const Color(0xFF8B1A1A));

    // Curved roof (distinctive upswept shape)
    final roofGold = Paint()..color = const Color(0xFFDAA520);
    final roofDark = Paint()..color = const Color(0xFF3D1C00);
    // Main roof body
    canvas.drawRect(Rect.fromLTWH(px, py + 1 * p, ts, 3 * p), roofDark);
    // Gold trim along roof
    canvas.drawRect(Rect.fromLTWH(px, py + 3 * p, ts, 1 * p), roofGold);
    // Upswept corners
    canvas.drawRect(Rect.fromLTWH(px, py, 2 * p, 1 * p), roofDark);
    canvas.drawRect(Rect.fromLTWH(px + 14 * p, py, 2 * p, 1 * p), roofDark);
    // Ridge ornament
    canvas.drawRect(Rect.fromLTWH(px + 7 * p, py, 2 * p, 1 * p), roofGold);

    // Red pillars on sides
    final pillarPaint = Paint()..color = const Color(0xFFCC2222);
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 4 * p, 2 * p, 10 * p), pillarPaint);
    canvas.drawRect(Rect.fromLTWH(px + 13 * p, py + 4 * p, 2 * p, 10 * p), pillarPaint);

    // Ornate door (gold frame)
    canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 6 * p, 8 * p, 10 * p), Paint()..color = const Color(0xFF5D1A1A));
    canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 6 * p, 8 * p, 1 * p), roofGold);
    canvas.drawRect(Rect.fromLTWH(px + 4 * p, py + 6 * p, 1 * p, 10 * p), roofGold);
    canvas.drawRect(Rect.fromLTWH(px + 11 * p, py + 6 * p, 1 * p, 10 * p), roofGold);
    // Door split
    canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 8 * p, 1 * p, 8 * p), Paint()..color = const Color(0xFF4A1010));

    // Door knockers (gold dots)
    canvas.drawCircle(Offset(px + 6 * p, py + 11 * p), 1 * p, roofGold);
    canvas.drawCircle(Offset(px + 10 * p, py + 11 * p), 1 * p, roofGold);

    // Lantern
    if (v % 2 == 0) {
      canvas.drawCircle(Offset(px + 3 * p, py + 6 * p), 1.5 * p, Paint()..color = const Color(0xCCFF3333));
      canvas.drawCircle(Offset(px + 3 * p, py + 6 * p), 0.8 * p, Paint()..color = const Color(0xFFFFCC00));
    }
    if (v % 3 == 0) {
      canvas.drawCircle(Offset(px + 13 * p, py + 6 * p), 1.5 * p, Paint()..color = const Color(0xCCFF3333));
      canvas.drawCircle(Offset(px + 13 * p, py + 6 * p), 0.8 * p, Paint()..color = const Color(0xFFFFCC00));
    }

    // Incense smoke (subtle)
    if (v % 4 == 0) {
      canvas.drawCircle(Offset(px + 8 * p, py + 5 * p), 1 * p, Paint()..color = const Color(0x33FFFFFF));
    }
  }

  // ── Apartment: Taiwan-style concrete apartments with lit windows ──
  void _drawApartment(Canvas canvas, int x, int y, double px, double py, double ts) {
    final p = ts / 16;
    final v = _tileVariant[y][x];
    final dst = Rect.fromLTWH(px, py, ts, ts);

    // Concrete base
    canvas.drawRect(dst, Paint()..color = const Color(0xFF8A8A8A));

    // Slightly lighter facade
    canvas.drawRect(Rect.fromLTWH(px + 1 * p, py, 14 * p, ts), Paint()..color = const Color(0xFF959595));

    // Floor divider lines
    for (double fy = 3; fy < 16; fy += 4) {
      canvas.drawRect(
        Rect.fromLTWH(px, py + fy * p, ts, 0.5 * p),
        Paint()..color = const Color(0xFF707070),
      );
    }

    // Grid of windows (some lit warm yellow, some dark)
    final winDark = Paint()..color = const Color(0xFF505050);
    final winLit = Paint()..color = const Color(0xCCFFE082);
    final winBlue = Paint()..color = const Color(0x88A8D8F0);

    for (int wy = 0; wy < 4; wy++) {
      for (int wx = 0; wx < 3; wx++) {
        final winX = px + (2 + wx * 5) * p;
        final winY = py + (0.5 + wy * 4) * p;
        final winHash = (v + wy * 3 + wx * 7) % 10;
        Paint winPaint;
        if (winHash < 4) {
          winPaint = winLit;
        } else if (winHash < 7) {
          winPaint = winBlue;
        } else {
          winPaint = winDark;
        }
        canvas.drawRect(Rect.fromLTWH(winX, winY, 3 * p, 2.5 * p), winPaint);
      }
    }

    // Balcony railings (horizontal dark lines between floors)
    final railPaint = Paint()..color = const Color(0xFF606060);
    for (double ry = 3; ry < 15; ry += 4) {
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + ry * p, 14 * p, 0.5 * p), railPaint);
    }

    // Rooftop water tank (very Taiwan)
    if (v % 5 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 11 * p, py - 2 * p, 4 * p, 2 * p), Paint()..color = const Color(0xFF6D6D6D));
      canvas.drawRect(Rect.fromLTWH(px + 11 * p, py - 2 * p, 4 * p, 0.5 * p), Paint()..color = const Color(0xFF8A8A8A));
    }

    // Rooftop illegal addition (鐵皮加蓋 — corrugated metal)
    if (v % 7 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py - 1.5 * p, 10 * p, 1.5 * p), Paint()..color = const Color(0xFF7E7E7E));
      // Corrugation lines
      for (double cx = 1; cx < 11; cx += 2) {
        canvas.drawRect(
          Rect.fromLTWH(px + cx * p, py - 1.5 * p, 1 * p, 1.5 * p),
          Paint()..color = const Color(0xFF8A8A8A),
        );
      }
    }

    // Laundry on balcony (clothes hanging — very common)
    if (v % 3 == 1) {
      // Laundry pole line
      canvas.drawRect(Rect.fromLTWH(px + 1 * p, py + 7 * p, 14 * p, 0.3 * p), Paint()..color = const Color(0xFF616161));
      // Hanging clothes
      canvas.drawRect(Rect.fromLTWH(px + 2 * p, py + 7 * p, 1.5 * p, 2.5 * p), Paint()..color = const Color(0xFFE0E0E0));
      canvas.drawRect(Rect.fromLTWH(px + 5 * p, py + 7 * p, 1.5 * p, 2 * p), Paint()..color = const Color(0xFF90CAF9));
      canvas.drawRect(Rect.fromLTWH(px + 8 * p, py + 7 * p, 1.5 * p, 2.5 * p), Paint()..color = const Color(0xFFFFCDD2));
      canvas.drawRect(Rect.fromLTWH(px + 11 * p, py + 7 * p, 1.5 * p, 2 * p), Paint()..color = const Color(0xFFC8E6C9));
    }

    // Water stain streaks (aging concrete — very Taiwan)
    if (v % 4 == 2) {
      canvas.drawRect(
        Rect.fromLTWH(px + (v % 10) * p, py + 4 * p, 1 * p, 8 * p),
        Paint()..color = const Color(0x15000000),
      );
    }

    // Cable bundle on facade
    if (v % 6 == 0) {
      canvas.drawRect(Rect.fromLTWH(px, py + 3 * p, ts, 0.5 * p), Paint()..color = const Color(0xFF333333));
    }
  }

  // ── Night market: neon-lit stalls ──
  void _drawNightMarket(Canvas canvas, int x, int y, double px, double py, double ts) {
    final dst = Rect.fromLTWH(px, py, ts, ts);
    final v = _tileVariant[y][x];
    final p = ts / 16;

    final neonColors = [
      const Color(0xFFFF2D78), const Color(0xFF00E5FF),
      const Color(0xFFFFD700), const Color(0xFF7B68EE),
      const Color(0xFF00FF88),
    ];
    final neon = neonColors[v % neonColors.length];

    canvas.drawRect(dst, Paint()..color = const Color(0xFF1A0A2E));
    canvas.drawRect(
      Rect.fromLTWH(px - 1, py - 1, ts + 2, ts + 2),
      Paint()..color = neon.withAlpha(25),
    );

    if (_sheet != null) {
      const sprites = [
        (31, 4), (32, 4), (33, 4), (34, 4),
        (31, 5), (32, 5), (33, 5), (34, 5),
      ];
      final s = sprites[v % sprites.length];
      canvas.drawImageRect(_sheet!, _spr(s.$1, s.$2), dst, _paint);
    }

    canvas.drawRect(Rect.fromLTWH(px, py, ts, 3 * p), Paint()..color = neon.withAlpha(180));

    if (v % 3 == 0) {
      canvas.drawCircle(Offset(px + 8 * p, py + 5 * p), 2 * p, Paint()..color = const Color(0xCCFF4444));
      canvas.drawCircle(Offset(px + 8 * p, py + 5 * p), 1 * p, Paint()..color = const Color(0xFFFFCC00));
    }

    canvas.drawRect(Rect.fromLTWH(px, py + 15 * p, ts, p), Paint()..color = neon.withAlpha(120));
    canvas.drawRect(Rect.fromLTWH(px, py + 3 * p, p, 12 * p), Paint()..color = neon.withAlpha(60));
    canvas.drawRect(Rect.fromLTWH(px + 15 * p, py + 3 * p, p, 12 * p), Paint()..color = neon.withAlpha(60));
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
    if (v % 5 < 2) {
      canvas.drawRect(
        Rect.fromLTWH(px + (v % 7) * p, py + (v % 5 + 2) * p, 3 * p, 3 * p),
        Paint()..color = const Color(0xFF388E3C),
      );
    }
    if (v % 4 == 0) {
      canvas.drawRect(Rect.fromLTWH(px + 7 * p, py + 10 * p, 2 * p, 6 * p), Paint()..color = const Color(0xFF5D4037));
      canvas.drawCircle(Offset(px + 8 * p, py + 8 * p), 4 * p, Paint()..color = const Color(0xFF2E7D32));
    }
    if (v % 4 == 1) {
      for (int i = 0; i < 3; i++) {
        final fx = px + (3 + i * 4) * p;
        final fy = py + (8 + (v * i) % 5) * p;
        canvas.drawCircle(
          Offset(fx, fy), 1.5 * p,
          Paint()..color = Color.lerp(const Color(0xFFFF6B6B), const Color(0xFFFFD700), (v * i % 10) / 10.0)!,
        );
      }
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
