enum Side {
  left(-1, 0),
  up(0, -1),
  right(1, 0),
  down(0, 1);

  const Side(this.dx, this.dy);

  final int dx;
  final int dy;

  Side get opposite => switch (this) {
        Side.left => Side.right,
        Side.right => Side.left,
        Side.up => Side.down,
        Side.down => Side.up,
      };
}

class GridPos {
  const GridPos(this.x, this.y);

  final int x;
  final int y;

  GridPos step(Side side) => GridPos(x + side.dx, y + side.dy);

  GridPos operator +(GridPos o) => GridPos(x + o.x, y + o.y);

  Iterable<GridPos> get neighbors => Side.values.map(step);

  @override
  bool operator ==(Object other) =>
      other is GridPos && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}
