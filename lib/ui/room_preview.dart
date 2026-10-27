import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../generator/floor_layout.dart';
import '../generator/geometry.dart';
import '../generator/room_shape.dart';
import 'palette.dart';
import 'pixel.dart';
import 'sprites.dart';

const _bases = {
  '1_side': {Side.up},
  '2_sides_parallel': {Side.up, Side.down},
  '2_sides_perpendicular': {Side.up, Side.left},
  '3_sides': {Side.up, Side.left, Side.right},
};

(String, int) layoutTile(RoomShape shape, Set<Side> blocked) {
  bool same(Set<Side> a, Set<Side> b) => a.length == b.length && a.containsAll(b);
  if (shape.openSides.length == 2) {
    final turn = shape.openSides.contains(Side.up) ? 1 : 0;
    if (blocked.isEmpty) return ('open_narrow', turn);
    for (final k in [turn, turn + 2]) {
      if (same({Side.right.rotated(k)}, blocked)) return ('1_side_narrow', k);
    }
  } else {
    if (blocked.isEmpty) return ('open', 0);
    for (final MapEntry(key: name, value: base) in _bases.entries) {
      for (var k = 0; k < 4; k++) {
        if (same({for (final s in base) s.rotated(k)}, blocked)) return (name, k);
      }
    }
  }
  throw StateError('No layout image for ${shape.name} blocked $blocked');
}

Future<void> showRoomPreview(BuildContext context, RoomSlot slot, Sprites? sprites,
    Set<Door> visibleDoors) {
  final wide = slot.shape.cellsWide, tall = slot.shape.cellsTall;
  final avail = min(360.0, MediaQuery.sizeOf(context).width - 150);
  var cell = min(min(avail / wide, 280 / tall), 192.0);
  cell = max(48.0, (cell / 16).floorToDouble() * 16);
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(_typeName(slot.type)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: PixelPanel(
                padding: const EdgeInsets.all(8),
                fill: Palette.mapBackground,
                ring: Palette.mapRing,
                child: CustomPaint(
                  size: Size(cell * wide, cell * tall),
                  painter: _RoomPainter(slot, sprites, visibleDoors, cell),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Shape: ${slot.shape.name}\n'
              'Doors: ${visibleDoors.length}  |  Blocked sides: ${slot.blocked.length}\n'
              'Blue is walkable, red is blocked. Secret rooms can only attach '
              'to walkable sides.',
              style: Palette.font(color: Palette.textDim).copyWith(height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        PixelButton(label: 'Close', onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}

String _typeName(RoomType type) => switch (type) {
      RoomType.start => 'Start room',
      RoomType.normal => 'Normal room',
      RoomType.boss => 'Boss room',
      RoomType.treasure => 'Treasure room',
      RoomType.shop => 'Shop',
      RoomType.secret => 'Secret room',
      RoomType.superSecret => 'Super secret room',
    };

class _RoomPainter extends CustomPainter {
  _RoomPainter(this.slot, this.sprites, this.doors, this.cell);

  final RoomSlot slot;
  final Sprites? sprites;
  final Set<Door> doors;
  final double cell;

  static const _walk = Color(0xFF49538D);
  static const _block = Color(0xFF772525);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in slot.cells) {
      final rel = p - slot.origin;
      final rect = Rect.fromLTWH(rel.x * cell, rel.y * cell, cell, cell)
          .inflate(0.5);
      final blocked = {
        for (final d in slot.blocked)
          if (d.cell == p) d.side,
      };
      final (name, turns) = layoutTile(slot.shape, blocked);
      final image = sprites?.layout(name);
      if (image != null) {
        _rotated(canvas, image, rect, turns);
      } else {
        canvas.drawRect(rect, Paint()..color = _walk);
        for (final s in blocked) {
          canvas.drawRect(_band(rect, s), Paint()..color = _block);
        }
      }
    }
    final door = sprites?.layout('door');
    for (final d in doors) {
      final rel = d.cell - slot.origin;
      final rect = Rect.fromLTWH(rel.x * cell, rel.y * cell, cell, cell);
      if (door != null) {
        _rotated(canvas, door, rect, d.side.quarterTurns);
      } else {
        canvas.drawRect(_band(rect, d.side).deflate(cell * 0.03),
            Paint()..color = Palette.gold);
      }
    }
  }

  Rect _band(Rect r, Side s) {
    final t = r.width / 8;
    return switch (s) {
      Side.up => Rect.fromLTWH(r.left, r.top, r.width, t),
      Side.down => Rect.fromLTWH(r.left, r.bottom - t, r.width, t),
      Side.left => Rect.fromLTWH(r.left, r.top, t, r.height),
      Side.right => Rect.fromLTWH(r.right - t, r.top, t, r.height),
    };
  }

  void _rotated(Canvas canvas, ui.Image image, Rect rect, int turns) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(turns * pi / 2);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: rect.width, height: rect.height),
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoomPainter old) => old.slot != slot || old.cell != cell;
}
