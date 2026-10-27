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

  void _fontsChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_fontsChanged);
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_fontsChanged);
    super.dispose();
  }

  void _setHover(GridPos? p) {
    if (p != _hover) setState(() => _hover = p);
  }

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
    if (widget.onRoomTap != null && c.visibleRoomAt(p) != null) return true;
    return !c.revealed && c.isGuessSpot(p);
  }

  void _tap(GridPos p) {
    final c = widget.controller;
    final room = c.visibleRoomAt(p);
    if (room != null) {
      widget.onRoomTap?.call(room);
    } else {
      c.tapCell(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _view();
    return LayoutBuilder(builder: (context, box) {
      var cell = [box.maxWidth / view.cols, box.maxHeight / view.rows, 96.0]
          .reduce((a, b) => a < b ? a : b);
      cell = cell >= 32 ? (cell / 8).floorToDouble() * 8 : cell.floorToDouble();
      final size = Size(cell * view.cols, cell * view.rows);
      final hover = _hover;
      return Center(
        child: MouseRegion(
          cursor: hover != null && _tappable(hover)
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onHover: (e) => _setHover(_cellAt(e.localPosition, cell, view.origin)),
          onExit: (_) => _setHover(null),
          child: GestureDetector(
            onTapUp: (d) => _tap(_cellAt(d.localPosition, cell, view.origin)),
            child: RepaintBoundary(
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
        ),
      );
    });
  }
}

const _checkGlyph = [
  '.......',
  '......#',
  '.....##',
  '#...##.',
  '##.##..',
  '.###...',
  '..#....',
];

const _crossGlyph = [
  '#.....#',
  '##...##',
  '.##.##.',
  '..###..',
  '.##.##.',
  '##...##',
  '#.....#',
];

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
    canvas.clipRect(Offset.zero & size);
    canvas.translate(-origin.x * s, -origin.y * s);

    for (var y = 0; y < layout.height; y++) {
      for (var x = 0; x < layout.width; x++) {
        final p = GridPos(x, y);
        if (c.isGuessSpot(p)) _spot(canvas, p);
      }
    }

    for (final r in layout.rooms) {
      if (!c.isHidden(r)) _room(canvas, r);
    }

    if (c.revealed) {
      for (final cand in layout.secretCandidates) {
        _candidate(canvas, cand);
      }
    } else if (c.showHints) {
      for (var y = 0; y < layout.height; y++) {
        for (var x = 0; x < layout.width; x++) {
          final p = GridPos(x, y);
          if (!c.isGuessSpot(p) || p == c.secretGuess || p == c.superGuess) continue;
          _text(canvas, '${c.visibleNeighbors(p)}', _center(p), s * 0.4, Palette.hint);
        }
      }
    }

    if (c.secretGuess != null) {
      _guess(canvas, c.secretGuess!, RoomType.secret, 'S', Palette.secret,
          c.revealed ? c.secretCorrect : null);
    }
    if (c.superGuess != null) {
      _guess(canvas, c.superGuess!, RoomType.superSecret, 'SS', Palette.superSecret,
          c.revealed ? c.superCorrect : null);
    }
  }

  Offset _center(GridPos p) => Offset((p.x + 0.5) * s, (p.y + 0.5) * s);

  Rect _cellRect(GridPos p) => Rect.fromLTWH(p.x * s, p.y * s, s, s);

  void _spot(Canvas canvas, GridPos p) {
    final rect = _cellRect(p);
    final empty = sprites?.empty;
    if (empty != null) {
      _image(canvas, empty, rect);
    } else {
      canvas.drawRect(rect, Paint()..color = Palette.ink);
      canvas.drawRect(rect.deflate(s * 0.06), Paint()..color = const Color(0xFF353331));
    }
    if (p == hover) canvas.drawRect(rect, Paint()..color = Palette.spotHover);
  }

  void _room(Canvas canvas, RoomSlot r) {
    final tint = switch (r.type) {
      RoomType.secret => Palette.secretRoom,
      RoomType.superSecret => Palette.superSecretRoom,
      _ => null,
    };
    final cells = r.cells;
    for (final (i, p) in cells.indexed) {
      final rect = _cellRect(p);
      final tile = sprites?.tile(r.shape.tiles[i]);
      if (tile != null) {
        bool joined(Side side) => cells.contains(p.step(side));
        const overlap = 1.0;
        final dst = Rect.fromLTRB(
          rect.left - (joined(Side.left) ? overlap : 0),
          rect.top - (joined(Side.up) ? overlap : 0),
          rect.right + (joined(Side.right) ? overlap : 0),
          rect.bottom + (joined(Side.down) ? overlap : 0),
        );
        _image(canvas, tile, dst, tint: tint);
      } else {
        canvas.drawRect(rect, Paint()..color = Palette.ink);
        canvas.drawRect(rect.deflate(s * 0.06), Paint()..color = tint ?? Palette.room);
      }
      if (cells.contains(hover)) {
        canvas.drawRect(rect, Paint()..color = Palette.spotHover);
      }
    }

    final bounds = cells.map(_cellRect).reduce((a, b) => a.expandToInclude(b));
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
      ..isAntiAlias = false
      ..color = Color.fromRGBO(0, 0, 0, opacity);
    if (tint != null) paint.colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      paint,
    );
  }

  void _candidate(Canvas canvas, SecretCandidate cand) {
    final isSecret = cand.pos == c.secretRoom.origin;
    final top = Offset((cand.pos.x + 0.5) * s, cand.pos.y * s + s * 0.22);
    final bottom = Offset((cand.pos.x + 0.5) * s, (cand.pos.y + 1) * s - s * 0.22);
    final color = isSecret ? Palette.candidateBest : Palette.candidate;
    _text(canvas, '${cand.neighbors}n ${cand.minWeight}-${cand.maxWeight}', top,
        s * 0.19, color);
    _text(canvas, 'w${cand.weight}', bottom, s * 0.22, color, bold: isSecret);
  }

  void _frame(Canvas canvas, Rect rect, Color color, double width) {
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, width), paint);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.bottom - width, rect.width, width), paint);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, width, rect.height), paint);
    canvas.drawRect(Rect.fromLTWH(rect.right - width, rect.top, width, rect.height), paint);
  }

  void _glyph(Canvas canvas, List<String> rows, Rect rect, Color color) {
    final px = rect.width / rows.length;
    final paint = Paint()..color = color;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] == '#') {
          canvas.drawRect(Rect.fromLTWH(rect.left + x * px, rect.top + y * px, px, px), paint);
        }
      }
    }
  }

  void _guess(Canvas canvas, GridPos p, RoomType type, String label, Color color,
      bool? correct) {
    final cell = _cellRect(p);
    final unit = (s / 16).roundToDouble().clamp(2.0, 8.0);
    final sprite = sprites?.icon(type);
    if (correct == null) {
      final box = cell.deflate(unit * 2);
      canvas.drawRect(box, Paint()..color = color.withValues(alpha: 0.75));
      _frame(canvas, box, Palette.ink, unit);
      if (sprite != null) {
        _image(canvas, sprite, cell);
      } else {
        _text(canvas, label, cell.center, s * 0.3, Palette.ink, bold: true);
      }
      return;
    }
    final ring = correct ? Palette.correct : Palette.wrong;
    _frame(canvas, cell.deflate(unit), Palette.ink, unit * 3);
    _frame(canvas, cell.deflate(unit * 2), ring, unit);
    if (c.layout.roomAt(p) == null && sprite != null) {
      _image(canvas, sprite, cell.deflate(s * 0.15), opacity: 0.5);
    }
    final b = (s * 0.34).roundToDouble();
    final badge = Rect.fromLTWH(cell.right - b - unit * 2, cell.top + unit * 2, b, b);
    canvas.drawRect(badge, Paint()..color = Palette.ink);
    canvas.drawRect(badge.deflate(unit), Paint()..color = ring);
    _glyph(canvas, correct ? _checkGlyph : _crossGlyph, badge.deflate(b * 0.2), Palette.ink);
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
    final style = Palette.font(
      size: size,
      color: color,
      weight: bold ? FontWeight.w700 : FontWeight.w400,
    ).copyWith(shadows: [Shadow(offset: Offset(size / 10, size / 10), color: Palette.ink)]);
    _paintCentered(canvas, TextSpan(text: text, style: style), center);
  }

  void _paintCentered(Canvas canvas, TextSpan span, Offset center) {
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_MinimapPainter old) => true;
}
