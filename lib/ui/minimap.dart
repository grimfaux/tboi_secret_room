import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../generator/floor_layout.dart';
import '../generator/geometry.dart';
import '../generator/room_shape.dart';
import '../quiz/quiz_controller.dart';
import 'palette.dart';
import 'sprites.dart';

class Minimap extends StatefulWidget {
  const Minimap({super.key, required this.controller, this.onRoomTap, this.sprites});

  final QuizController controller;
  final Sprites? sprites;
  final void Function(RoomSlot room)? onRoomTap;

  @override
  State<Minimap> createState() => _MinimapState();
}

class _MinimapState extends State<Minimap> {
  GridPos? _hover;

  ({GridPos origin, int cols, int rows}) _view() {
    final layout = widget.controller.layout;
    final cells = [
      for (final r in layout.rooms)
        if (r.type != RoomType.secret && r.type != RoomType.superSecret) ...r.cells,
    ];
    int lo(Iterable<int> v) => v.reduce((a, b) => a < b ? a : b);
    int hi(Iterable<int> v) => v.reduce((a, b) => a > b ? a : b);
    final x0 = (lo(cells.map((p) => p.x)) - 1).clamp(0, layout.width - 1);
    final y0 = (lo(cells.map((p) => p.y)) - 1).clamp(0, layout.height - 1);
    final x1 = (hi(cells.map((p) => p.x)) + 1).clamp(0, layout.width - 1);
    final y1 = (hi(cells.map((p) => p.y)) + 1).clamp(0, layout.height - 1);
    return (origin: GridPos(x0, y0), cols: x1 - x0 + 1, rows: y1 - y0 + 1);
  }

  GridPos _cellAt(Offset local, double cell, GridPos origin) =>
      origin + GridPos((local.dx / cell).floor(), (local.dy / cell).floor());

  bool _tappable(GridPos p) {
    final c = widget.controller;
    if (!c.layout.inBounds(p)) return false;
    if (c.revealed) return widget.onRoomTap != null && c.layout.roomAt(p) != null;
    return c.isGuessSpot(p);
  }

  void _tap(GridPos p) {
    final c = widget.controller;
    if (c.revealed) {
      final room = c.layout.roomAt(p);
      if (room != null) widget.onRoomTap?.call(room);
    } else {
      c.tapCell(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _view();
    return LayoutBuilder(builder: (context, box) {
      final cell = [box.maxWidth / view.cols, box.maxHeight / view.rows, 110.0]
          .reduce((a, b) => a < b ? a : b);
      final size = Size(cell * view.cols, cell * view.rows);
      final hover = _hover;
      return Center(
        child: MouseRegion(
          cursor: hover != null && _tappable(hover)
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onHover: (e) =>
              setState(() => _hover = _cellAt(e.localPosition, cell, view.origin)),
          onExit: (_) => setState(() => _hover = null),
          child: GestureDetector(
            onTapUp: (d) => _tap(_cellAt(d.localPosition, cell, view.origin)),
            child: CustomPaint(
              size: size,
              painter: _MinimapPainter(
                widget.controller,
                hover != null && _tappable(hover) ? hover : null,
                view.origin,
                cell,
                widget.sprites,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter(this.c, this.hover, this.origin, this.s, this.sprites);

  final QuizController c;
  final Sprites? sprites;
  final GridPos? hover;
  final GridPos origin;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = c.layout;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.2)),
      Paint()..color = Palette.mapBackground,
    );
    canvas.clipRect(Offset.zero & size);
    canvas.translate(-origin.x * s, -origin.y * s);

    for (var y = 0; y < layout.height; y++) {
      for (var x = 0; x < layout.width; x++) {
        final p = GridPos(x, y);
        if (c.isGuessSpot(p)) {
          _spot(canvas, p, s);
        }
      }
    }

    for (final r in layout.rooms) {
      if (c.isHidden(r)) continue;
      for (final side in r.doors) {
        final other = layout.roomAt(r.origin.step(side));
        if (other == null || c.isHidden(other)) continue;
        _door(canvas, r.origin, side, s, _isSecretType(r) || _isSecretType(other));
      }
    }

    for (final r in layout.rooms) {
      if (!c.isHidden(r)) _room(canvas, r, s);
    }

    if (c.revealed) {
      for (final cand in layout.secretCandidates) {
        _candidate(canvas, cand, s);
      }
    } else if (c.showHints) {
      for (var y = 0; y < layout.height; y++) {
        for (var x = 0; x < layout.width; x++) {
          final p = GridPos(x, y);
          if (!c.isGuessSpot(p) || p == c.secretGuess || p == c.superGuess) continue;
          _text(canvas, '${c.visibleNeighbors(p)}', _center(p, s), s * 0.32,
              Palette.hint);
        }
      }
    }

    if (c.secretGuess != null) {
      _guess(canvas, c.secretGuess!, s, RoomType.secret, 'S', Palette.secret,
          c.revealed ? c.secretCorrect : null);
    }
    if (c.superGuess != null) {
      _guess(canvas, c.superGuess!, s, RoomType.superSecret, 'SS',
          Palette.superSecret, c.revealed ? c.superCorrect : null);
    }
  }

  bool _isSecretType(RoomSlot r) =>
      r.type == RoomType.secret || r.type == RoomType.superSecret;

  Offset _center(GridPos p, double s) => Offset((p.x + 0.5) * s, (p.y + 0.5) * s);

  Rect _cellRect(GridPos p, double s, double inset) =>
      Rect.fromLTWH(p.x * s + inset, p.y * s + inset, s - 2 * inset, s - 2 * inset);

  void _spot(Canvas canvas, GridPos p, double s) {
    final rect = _cellRect(p, s, s * 0.14);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.12));
    if (p == hover) {
      canvas.drawRRect(rr, Paint()..color = Palette.spotHover);
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..color = c.revealed ? Palette.spotFaint : Palette.spot
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02,
    );
  }

  void _door(Canvas canvas, GridPos a, Side side, double s, bool secret) {
    final center = _center(a, s) + Offset(side.dx * s * 0.5, side.dy * s * 0.5);
    final horizontal = side.dx != 0;
    final rect = Rect.fromCenter(
      center: center,
      width: horizontal ? s * 0.3 : s * 0.22,
      height: horizontal ? s * 0.22 : s * 0.3,
    );
    canvas.drawRect(
        rect, Paint()..color = secret ? Palette.secretDoor : Palette.roomBorder);
  }

  void _room(Canvas canvas, RoomSlot r, double s) {
    final cells = r.cells;
    final gap = s * 0.06;
    final tint = switch (r.type) {
      RoomType.secret => Palette.secretRoom,
      RoomType.superSecret => Palette.superSecretRoom,
      _ => null,
    };
    if (c.revealed && cells.contains(hover)) {
      for (final p in cells) {
        canvas.drawRect(_cellRect(p, s, 0), Paint()..color = Palette.spotHover);
      }
    }
    for (final (i, p) in cells.indexed) {
      Rect rect = _cellRect(p, s, 0);
      bool open(Side side) => !cells.contains(p.step(side));
      rect = Rect.fromLTRB(
        rect.left + (open(Side.left) ? gap : 0),
        rect.top + (open(Side.up) ? gap : 0),
        rect.right - (open(Side.right) ? gap : 0),
        rect.bottom - (open(Side.down) ? gap : 0),
      );
      final tile = sprites?.tile(r.shape.tiles[i]);
      if (tile != null) {
        _image(canvas, tile, rect, tint: tint);
      } else {
        canvas.drawRect(rect, Paint()..color = tint ?? Palette.room);
        canvas.drawRect(
          rect.deflate(s * 0.025),
          Paint()
            ..color = Palette.roomBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.05,
        );
      }
    }

    final bounds = cells.map((p) => _cellRect(p, s, 0)).reduce((a, b) => a.expandToInclude(b));
    final sprite = sprites?.icon(r.type);
    if (sprite != null) {
      _image(canvas, sprite, Rect.fromCenter(center: bounds.center, width: s, height: s));
    } else {
      final icon = Palette.icons[r.type];
      if (icon != null) _icon(canvas, icon.$1, bounds.center, s * 0.5, icon.$2);
    }
  }

  void _image(Canvas canvas, ui.Image image, Rect dst, {Color? tint, double opacity = 1}) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..color = Color.fromRGBO(0, 0, 0, opacity);
    if (tint != null) paint.colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      paint,
    );
  }

  void _candidate(Canvas canvas, SecretCandidate cand, double s) {
    final isSecret = cand.pos == c.secretRoom.origin;
    final top = Offset((cand.pos.x + 0.5) * s, cand.pos.y * s + s * 0.2);
    final bottom = Offset((cand.pos.x + 0.5) * s, (cand.pos.y + 1) * s - s * 0.2);
    final color = isSecret ? Palette.candidateBest : Palette.candidate;
    _text(canvas, '${cand.neighbors}n ${cand.minWeight}-${cand.maxWeight}', top,
        s * 0.16, color, bold: isSecret);
    _text(canvas, 'w${cand.weight}', bottom, s * 0.18, color, bold: isSecret);
  }

  void _guess(Canvas canvas, GridPos p, double s, RoomType type, String label,
      Color color, bool? correct) {
    final center = _center(p, s);
    final sprite = sprites?.icon(type);
    void mark(double size, double opacity) {
      if (sprite != null) {
        _image(canvas, sprite, Rect.fromCenter(center: center, width: s, height: s),
            opacity: opacity);
      } else {
        _text(canvas, label, center, size,
            correct == null ? Palette.mapBackground : color, bold: true);
      }
    }
    final radius = s * (correct == null ? 0.3 : 0.22);
    final ringColor = switch (correct) {
      true => Palette.correct,
      false => Palette.wrong,
      null => color,
    };
    if (correct == null) {
      canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: 0.85));
      mark(s * 0.22, 1);
    } else {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.06,
      );
      final badge = center + Offset(radius, -radius * 0.6);
      canvas.drawCircle(badge, s * 0.11, Paint()..color = ringColor);
      _icon(canvas, correct ? Icons.check : Icons.close, badge, s * 0.16,
          Palette.mapBackground);
      if (c.layout.roomAt(p) == null) mark(s * 0.16, 0.6);
    }
  }

  void _icon(Canvas canvas, IconData icon, Offset center, double size, Color color) {
    _paintCentered(
      canvas,
      TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      center,
    );
  }

  void _text(Canvas canvas, String text, Offset center, double size, Color color,
      {bool bold = false}) {
    _paintCentered(
      canvas,
      TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          shadows: color == Palette.mapBackground
              ? null
              : const [Shadow(blurRadius: 3, color: Colors.black)],
        ),
      ),
      center,
    );
  }

  void _paintCentered(Canvas canvas, TextSpan span, Offset center) {
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_MinimapPainter old) => true;
}
