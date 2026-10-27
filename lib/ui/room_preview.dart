import 'package:flutter/material.dart';

import '../generator/geometry.dart';
import '../generator/room_filler.dart';
import '../generator/room_shape.dart';
import 'palette.dart';

Future<void> showRoomPreview(BuildContext context, FilledRoom room) {
  final t = room.template;
  final slot = room.slot;
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Palette.mapBackground,
      title: Text(_typeName(slot.type)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: (t.shape.tileWidth + 2) / (t.shape.tileHeight + 2),
              child: CustomPaint(painter: _RoomPainter(room)),
            ),
            const SizedBox(height: 12),
            Text(
              'Template: ${room.isFallback ? 'none matched (empty fallback)' : t.id}\n'
              'Doors: ${slot.doors.map((d) => d.name).join(', ')}\n'
              'Distance from start: ${slot.distance}  |  Difficulty: ${t.difficulty}\n'
              'Room seed: ${slot.seed}',
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
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
  _RoomPainter(this.room);

  final FilledRoom room;

  static const _floor = Color(0xFF4A3B33);
  static const _wall = Color(0xFF2A211D);
  static const _rock = Color(0xFF8A8079);
  static const _pit = Color(0xFF0B0908);
  static const _door = Color(0xFF7A5A3A);

  @override
  void paint(Canvas canvas, Size size) {
    final t = room.template;
    final w = t.shape.tileWidth;
    final h = t.shape.tileHeight;
    final tile = size.width / (w + 2);
    canvas.drawRect(Offset.zero & size, Paint()..color = _wall);
    canvas.drawRect(
        Rect.fromLTWH(tile, tile, w * tile, h * tile), Paint()..color = _floor);

    for (final side in room.slot.doors) {
      final x = switch (side) {
        Side.left => 0,
        Side.right => w + 1,
        _ => w ~/ 2 + 1,
      };
      final y = switch (side) {
        Side.up => 0,
        Side.down => h + 1,
        _ => h ~/ 2 + 1,
      };
      canvas.drawRect(
          Rect.fromLTWH(x * tile, y * tile, tile, tile), Paint()..color = _door);
    }

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final rect = Rect.fromLTWH((x + 1) * tile, (y + 1) * tile, tile, tile);
        switch (t.tiles[y][x]) {
          case 'r':
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect.deflate(tile * 0.08), Radius.circular(tile * 0.25)),
              Paint()..color = _rock,
            );
          case 'p':
            canvas.drawRect(rect, Paint()..color = _pit);
          case 'i':
            _glyph(canvas, rect, Icons.emoji_events_rounded, Palette.secret);
          case r'$':
            _glyph(canvas, rect, Icons.monetization_on_rounded, Palette.correct);
          case 'b':
            _glyph(canvas, rect.inflate(tile * 0.6), Icons.dangerous_rounded,
                Palette.wrong);
        }
      }
    }
  }

  void _glyph(Canvas canvas, Rect rect, IconData icon, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: rect.height * 0.9,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_RoomPainter old) => old.room != room;
}
