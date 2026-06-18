import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../game/components/map_component.dart';

class MinimapWidget extends StatelessWidget {
  final List<List<TileType>> tiles;
  final double playerTileX;
  final double playerTileY;
  final double? targetTileX;
  final double? targetTileY;
  final bool isPickup;

  const MinimapWidget({
    super.key,
    required this.tiles,
    required this.playerTileX,
    required this.playerTileY,
    this.targetTileX,
    this.targetTileY,
    this.isPickup = true,
  });

  @override
  Widget build(BuildContext context) {
    const size = 90.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CustomPaint(
          size: const Size(size, size),
          painter: _MinimapPainter(
            tiles: tiles,
            playerTileX: playerTileX,
            playerTileY: playerTileY,
            targetTileX: targetTileX,
            targetTileY: targetTileY,
            isPickup: isPickup,
          ),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final List<List<TileType>> tiles;
  final double playerTileX;
  final double playerTileY;
  final double? targetTileX;
  final double? targetTileY;
  final bool isPickup;

  _MinimapPainter({
    required this.tiles,
    required this.playerTileX,
    required this.playerTileY,
    this.targetTileX,
    this.targetTileY,
    this.isPickup = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tiles.isEmpty) return;

    final mapW = GameConfig.mapWidth;
    final mapH = GameConfig.mapHeight;
    final px = size.width / mapW;
    final py = size.height / mapH;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF2A2A2A),
    );

    // Draw tiles
    for (int y = 0; y < mapH && y < tiles.length; y++) {
      for (int x = 0; x < mapW && x < tiles[y].length; x++) {
        final color = switch (tiles[y][x]) {
          TileType.road => const Color(0xFF505050),
          TileType.sidewalk => const Color(0xFF808080),
          TileType.building => const Color(0xFF8B4513),
          TileType.nightMarket => const Color(0xFFFF6600),
          TileType.restaurant => const Color(0xFFFFD700),
          TileType.customer => const Color(0xFF4ECDC4),
          TileType.park => const Color(0xFF2D5A2D),
          TileType.ground => const Color(0xFF3A3A3A),
        };
        canvas.drawRect(
          Rect.fromLTWH(x * px, y * py, px + 0.5, py + 0.5),
          Paint()..color = color,
        );
      }
    }

    // Target marker (pulsing would need animation, use static for now)
    if (targetTileX != null && targetTileY != null) {
      final tx = targetTileX! * px;
      final ty = targetTileY! * py;
      final markerColor = isPickup
          ? const Color(0xFFFFD700)
          : const Color(0xFF4ECDC4);
      canvas.drawCircle(
        Offset(tx, ty),
        3,
        Paint()..color = markerColor,
      );
      canvas.drawCircle(
        Offset(tx, ty),
        3,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Player dot
    final plx = playerTileX * px;
    final ply = playerTileY * py;
    canvas.drawCircle(
      Offset(plx, ply),
      2.5,
      Paint()..color = Color(AppColors.orangeMain),
    );
    canvas.drawCircle(
      Offset(plx, ply),
      2.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(_MinimapPainter old) =>
      old.playerTileX != playerTileX ||
      old.playerTileY != playerTileY ||
      old.targetTileX != targetTileX ||
      old.targetTileY != targetTileY;
}
