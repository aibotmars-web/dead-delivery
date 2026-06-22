import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/constants.dart';

enum ParkingLine { white, red, yellow }

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

class MapComponent extends PositionComponent {
  late List<List<TileType>> _tiles;
  final int mapWidth = GameConfig.mapWidth;
  final int mapHeight = GameConfig.mapHeight;
  final double tileDisplaySize = GameConfig.displayTileSize;

  final List<Vector2> restaurantPositions = [];
  final List<Vector2> customerPositions = [];

  ui.Image? _sceneImage;
  final _paint = Paint()..filterQuality = FilterQuality.low;

  bool get isLoaded => _sceneImage != null && _tiles.isNotEmpty;
  List<List<TileType>> get tileGrid => _tiles;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final worldW = GameConfig.sceneWidth * GameConfig.sceneScale;
    final worldH = GameConfig.sceneHeight * GameConfig.sceneScale;
    size = Vector2(worldW, worldH);

    _buildTileGrid();
    _placeLocations();

    try {
      final data = await rootBundle.load('assets/tiles/scene_main.png');
      final codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _sceneImage = frame.image;
    } catch (e) {
      debugPrint('Failed to load scene image: $e');
    }
  }

  // ── Build walkability grid from image layout ──
  void _buildTileGrid() {
    _tiles = List.generate(
      mapHeight,
      (_) => List.filled(mapWidth, TileType.building),
    );

    // Horizontal main road: image y ~430-590 → grid rows 27-36
    _fillRect(0, 27, 85, 36, TileType.road);

    // Vertical road toward 台中州廳: image x ~470-700 → grid cols 29-43
    _fillRect(29, 5, 43, 27, TileType.road);

    // Wider intersection area
    _fillRect(25, 25, 47, 38, TileType.road);

    // Bottom road near TRA entrance: image y ~640-740
    _fillRect(24, 40, 40, 46, TileType.road);
    // Connect to main road
    _fillRect(28, 37, 42, 40, TileType.road);

    // Sidewalks — top of horizontal road
    _fillRect(0, 25, 28, 26, TileType.sidewalk);
    _fillRect(44, 25, 85, 26, TileType.sidewalk);

    // Sidewalks — bottom of horizontal road
    _fillRect(0, 37, 23, 39, TileType.sidewalk);
    _fillRect(43, 37, 85, 39, TileType.sidewalk);

    // Sidewalks — left of vertical road
    _fillRect(27, 5, 28, 24, TileType.sidewalk);

    // Sidewalks — right of vertical road
    _fillRect(44, 5, 45, 24, TileType.sidewalk);

    // Sidewalk around 台中州廳
    _fillRect(29, 3, 43, 5, TileType.sidewalk);

    // Left shop area sidewalk
    _fillRect(0, 23, 26, 24, TileType.sidewalk);
    _fillRect(0, 40, 23, 41, TileType.sidewalk);

    // Right modern building sidewalk
    _fillRect(46, 23, 85, 24, TileType.sidewalk);
    _fillRect(46, 40, 85, 41, TileType.sidewalk);

    // Night market area (left shops with neon signs)
    _fillRect(2, 15, 25, 22, TileType.nightMarket);

    // Park area (near 台中州廳 front)
    _fillRect(30, 6, 42, 10, TileType.park);
  }

  void _fillRect(int x1, int y1, int x2, int y2, TileType type) {
    for (int y = y1; y <= y2 && y < mapHeight; y++) {
      for (int x = x1; x <= x2 && x < mapWidth; x++) {
        if (x >= 0 && x < mapWidth) {
          _tiles[y][x] = type;
        }
      }
    }
  }

  void _placeLocations() {
    final ts = tileDisplaySize;
    final ty = GameConfig.displayTileY;

    // Restaurants — at building entrances visible in the image
    final rList = [
      (12, 26, '阿嬤滷肉飯'),   // left shop row, on sidewalk
      (50, 26, '便利商店'),       // right modern building
      (34, 41, 'TRA 臺鐵站'),   // TRA station area
    ];
    for (final (rx, ry, _) in rList) {
      _tiles[ry][rx] = TileType.restaurant;
      _tiles[ry][rx + 1] = TileType.restaurant;
      restaurantPositions.add(Vector2(
        (rx + 1) * ts,
        (ry + 0.5) * ty,
      ));
    }

    // Customer delivery points — at various building entrances
    final cList = [
      (6, 37),   // left side bottom
      (36, 5),   // near 台中州廳
      (70, 30),  // right side road
      (78, 37),  // far right bottom
      (18, 26),  // mid-left shops
    ];
    for (final (cx, cy) in cList) {
      _tiles[cy][cx] = TileType.customer;
      customerPositions.add(Vector2(
        (cx + 0.5) * ts,
        (cy + 0.5) * ty,
      ));
    }
  }

  // ── Rendering: draw the scene image ──
  @override
  void render(Canvas canvas) {
    if (_sceneImage == null) return;

    final dst = Rect.fromLTWH(0, 0, size.x, size.y);
    final src = Rect.fromLTWH(
      0,
      0,
      _sceneImage!.width.toDouble(),
      _sceneImage!.height.toDouble(),
    );
    canvas.drawImageRect(_sceneImage!, src, dst, _paint);

    // Draw location markers
    _drawMarkers(canvas);
  }

  void _drawMarkers(Canvas canvas) {
    // Restaurant markers
    for (final pos in restaurantPositions) {
      final r = Rect.fromCenter(
        center: Offset(pos.x, pos.y - 12),
        width: 24,
        height: 24,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()..color = const Color(0xCCFF6600),
      );
      final icon = TextPainter(
        text: const TextSpan(
          text: '🍜',
          style: TextStyle(fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      icon.paint(canvas, Offset(r.center.dx - 7, r.center.dy - 8));
    }

    // Customer markers
    for (final pos in customerPositions) {
      final r = Rect.fromCenter(
        center: Offset(pos.x, pos.y - 12),
        width: 24,
        height: 24,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()..color = const Color(0xCC4ECDC4),
      );
      final icon = TextPainter(
        text: const TextSpan(
          text: '📍',
          style: TextStyle(fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      icon.paint(canvas, Offset(r.center.dx - 7, r.center.dy - 8));
    }
  }

  // ── Tile queries ──
  TileType getTileAt(int x, int y) {
    if (_tiles.isEmpty) return TileType.ground;
    if (x < 0 || x >= mapWidth || y < 0 || y >= mapHeight) {
      return TileType.ground;
    }
    return _tiles[y][x];
  }

  bool isWalkable(int x, int y) {
    final tile = getTileAt(x, y);
    return tile == TileType.road ||
        tile == TileType.sidewalk ||
        tile == TileType.restaurant ||
        tile == TileType.customer ||
        tile == TileType.nightMarket ||
        tile == TileType.park;
  }

  ParkingLine? getParkingLineAt(int x, int y) {
    if (x < 0 || x >= mapWidth || y < 0 || y >= mapHeight) return null;
    final tile = _tiles[y][x];
    if (tile != TileType.road) return null;

    // Red lines at intersections, yellow elsewhere
    final atIntersection = x >= 29 && x <= 43 && y >= 25 && y <= 38;
    if (atIntersection) return ParkingLine.red;
    return (x + y) % 5 < 2 ? ParkingLine.yellow : ParkingLine.red;
  }

  // ── A* Pathfinding ──
  List<Vector2>? findPath(Vector2 startWorld, Vector2 endWorld,
      {bool preferSidewalks = false}) {
    final ts = tileDisplaySize;
    final ty = GameConfig.displayTileY;
    final sx = (startWorld.x / ts).floor().clamp(0, mapWidth - 1);
    final sy = (startWorld.y / ty).floor().clamp(0, mapHeight - 1);
    final ex = (endWorld.x / ts).floor().clamp(0, mapWidth - 1);
    final ey = (endWorld.y / ty).floor().clamp(0, mapHeight - 1);

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

        final tile = _tiles[ny][nx];
        double tileCost;
        if (preferSidewalks) {
          tileCost = tile == TileType.road
              ? 0.7
              : tile == TileType.sidewalk
                  ? 1.5
                  : 1.0;
        } else {
          tileCost = tile == TileType.sidewalk
              ? 0.8
              : tile == TileType.road
                  ? 1.1
                  : 1.0;
        }
        final tg = (g[cur] ?? 1e9) + tileCost;
        if (tg < (g[nk] ?? 1e9)) {
          parent[nk] = cur;
          g[nk] = tg;
          f[nk] =
              tg + (ex - nx).abs().toDouble() + (ey - ny).abs().toDouble();
          if (!open.contains(nk)) open.add(nk);
        }
      }
    }
    return null;
  }

  List<Vector2> _buildPath(Map<int, int> parent, int end, int start) {
    final ts = tileDisplaySize;
    final ty = GameConfig.displayTileY;
    final raw = <Vector2>[];
    var n = end;
    while (n != start) {
      raw.add(Vector2(
        (n % mapWidth + 0.5) * ts,
        (n ~/ mapWidth + 0.5) * ty,
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
    final ts = tileDisplaySize;
    final ty = GameConfig.displayTileY;
    final tileX = (worldPos.x / ts).floor();
    final tileY = (worldPos.y / ty).floor();

    if (isWalkable(tileX, tileY)) return worldPos;

    for (int r = 1; r <= 8; r++) {
      for (int dy = -r; dy <= r; dy++) {
        for (int dx = -r; dx <= r; dx++) {
          if (dx.abs() != r && dy.abs() != r) continue;
          if (isWalkable(tileX + dx, tileY + dy)) {
            return Vector2(
              (tileX + dx + 0.5) * ts,
              (tileY + dy + 0.5) * ty,
            );
          }
        }
      }
    }
    return null;
  }
}
