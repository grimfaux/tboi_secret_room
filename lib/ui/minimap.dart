import 'package:flutter/material.dart';

import '../generator/floor_layout.dart';
import '../generator/geometry.dart';
import '../generator/room_shape.dart';
import '../quiz/quiz_controller.dart';
import 'palette.dart';

class Minimap extends StatefulWidget {
  const Minimap({super.key, required this.controller, this.onRoomTap});

  final QuizController controller;
  final void Function(RoomSlot room)? onRoomTap;

  @override
  State<Minimap> createState() => _MinimapState();
}

class _MinimapState extends State<Minimap> {
  GridPos? _hover;

  GridPos _cellAt(Offset local, double cell) =>
      GridPos((local.dx / cell).floor(), (local.dy / cell).floor());

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
    final layout = widget.controller.layout;
    return LayoutBuilder(builder: (context, box) {
      final cell = (box.maxWidth / layout.width)
          .clamp(0.0, box.maxHeight / layout.height)
          .toDouble();
      final size = Size(cell * layout.width, cell * layout.height);
      final hover = _hover;
      return Center(
        child: MouseRegion(
          cursor: hover != null && _tappable(hover)
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onHover: (e) => setState(() => _hover = _cellAt(e.localPosition, cell)),
          onExit: (_) => setState(() => _hover = null),
          child: GestureDetector(
            onTapUp: (d) => _tap(_cellAt(d.localPosition, cell)),
            child: CustomPaint(
              size: size,
              painter: _MinimapPainter(
                widget.controller,
                hover != null && _tappable(hover) ? hover : null,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter(this.c, this.hover);

  final QuizController c;
  final GridPos? hover;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = c.layout;
    final s = size.width / layout.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.2)),
      Paint()..color = Palette.mapBackground,
    );

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
      _guess(canvas, c.secretGuess!, s, 'S', Palette.secret,
          c.revealed ? c.secretCorrect : null);
    }
    if (c.superGuess != null) {
      _guess(canvas, c.superGuess!, s, 'SS', Palette.superSecret,
          c.revealed ? c.superCorrect : null);
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
    final rect = _cellRect(r.origin, s, s * 0.08);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.14));
    final fill = switch (r.type) {
      RoomType.start => Palette.startRoom,
      RoomType.secret => Palette.secretRoom,
      RoomType.superSecret => Palette.superSecretRoom,
      _ => Palette.room,
    };
    if (c.revealed && r.origin == hover) {
      canvas.drawRRect(rr.inflate(s * 0.04), Paint()..color = Palette.spotHover);
    }
    canvas.drawRRect(rr, Paint()..color = fill);
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Palette.roomBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.05,
    );
    final icon = Palette.icons[r.type];
    if (icon != null) {
      final small = r.type == RoomType.secret;
      _icon(canvas, icon.$1, _center(r.origin, s), s * (small ? 0.34 : 0.5), icon.$2);
    }
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

  void _guess(Canvas canvas, GridPos p, double s, String label, Color color,
      bool? correct) {
    final center = _center(p, s);
    final radius = s * (correct == null ? 0.3 : 0.22);
    final ringColor = switch (correct) {
      true => Palette.correct,
      false => Palette.wrong,
      null => color,
    };
    if (correct == null) {
      canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: 0.85));
      _text(canvas, label, center, s * 0.22, Palette.mapBackground, bold: true);
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
      if (c.layout.roomAt(p) == null) {
        _text(canvas, label, center, s * 0.16, color, bold: true);
      }
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
