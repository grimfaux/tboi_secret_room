import 'package:flutter/material.dart';

import 'palette.dart';

class CheckerBackground extends StatelessWidget {
  const CheckerBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CheckerPainter(), child: child);
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.background);
    final paint = Paint()..color = Palette.checker;
    const s = 4.0;
    for (var y = 0.0; y < size.height; y += s * 2) {
      for (var x = 0.0; x < size.width; x += s * 2) {
        canvas.drawRect(Rect.fromLTWH(x, y, s, s), paint);
        canvas.drawRect(Rect.fromLTWH(x + s, y + s, s, s), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter old) => false;
}

class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.fill,
    this.ring = Palette.panelRing,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? fill;
  final Color ring;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    Border b(Color c) => Border.all(color: c, width: 4);
    return DecoratedBox(
      decoration: BoxDecoration(border: b(Palette.ink)),
      child: DecoratedBox(
        decoration: BoxDecoration(border: b(ring)),
        child: DecoratedBox(
          decoration: BoxDecoration(color: fill, border: b(Palette.ink)),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    var fill = widget.primary ? Palette.red : Palette.panelRing;
    var light = widget.primary ? Palette.redHighlight : Palette.panelHighlight;
    if (_hover && enabled) {
      fill = Color.lerp(fill, Colors.white, 0.08)!;
      light = Color.lerp(light, Colors.white, 0.08)!;
    }
    final pressed = _down && enabled;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: Palette.text),
          const SizedBox(width: 8),
        ],
        Text(widget.label,
            style: Palette.font(size: 18, weight: FontWeight.w600, color: Palette.text)),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onPressed,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Padding(
              padding: EdgeInsets.only(top: pressed ? 4 : 0, bottom: pressed ? 0 : 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  border: Border.all(color: Palette.ink, width: 3),
                  boxShadow: pressed
                      ? null
                      : const [BoxShadow(color: Palette.ink, offset: Offset(0, 4))],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: pressed ? fill : light, width: 4),
                      left: BorderSide(color: pressed ? fill : light, width: 4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 16, 10),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PixelIconButton extends StatelessWidget {
  const PixelIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active ? Palette.gold : Palette.panelRing,
              border: Border.all(color: Palette.ink, width: 3),
            ),
            child: Icon(icon, size: 22, color: active ? Palette.ink : Palette.text),
          ),
        ),
      ),
    );
  }
}
