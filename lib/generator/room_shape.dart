import 'geometry.dart';

const _horizontal = {Side.left, Side.right};
const _vertical = {Side.up, Side.down};

enum RoomShape {
  oneByOne([GridPos(0, 0)]),
  narrowH([GridPos(0, 0)], _horizontal),
  narrowV([GridPos(0, 0)], _vertical),
  longH([GridPos(0, 0), GridPos(1, 0)]),
  longV([GridPos(0, 0), GridPos(0, 1)]),
  longNarrowH([GridPos(0, 0), GridPos(1, 0)], _horizontal),
  longNarrowV([GridPos(0, 0), GridPos(0, 1)], _vertical),
  twoByTwo([GridPos(0, 0), GridPos(1, 0), GridPos(0, 1), GridPos(1, 1)]),
  lNoTopRight([GridPos(0, 0), GridPos(0, 1), GridPos(1, 1)]),
  lNoTopLeft([GridPos(1, 0), GridPos(1, 1), GridPos(0, 1)]),
  lNoBottomRight([GridPos(0, 1), GridPos(0, 0), GridPos(1, 0)]),
  lNoBottomLeft([GridPos(1, 1), GridPos(1, 0), GridPos(0, 0)]);

  const RoomShape(this.offsets, [this.openSides = const {...Side.values}]);

  final List<GridPos> offsets;
  final Set<Side> openSides;

  static const tilesPerCellX = 13;
  static const tilesPerCellY = 7;

  List<GridPos> cellsAt(GridPos origin) =>
      [for (final o in offsets) origin + o];

  int get cellsWide => offsets.map((o) => o.x).reduce((a, b) => a > b ? a : b) + 1;
  int get cellsTall => offsets.map((o) => o.y).reduce((a, b) => a > b ? a : b) + 1;

  int get tileWidth => cellsWide * tilesPerCellX;
  int get tileHeight => cellsTall * tilesPerCellY;

  List<String> get tiles => [for (final o in offsets) tileFor(o)];

  String tileFor(GridPos cell) {
    final inner = {
      for (final s in Side.values)
        if (offsets.contains(cell.step(s))) s,
    };
    final narrow = openSides.length == 4
        ? ''
        : openSides.contains(Side.left)
            ? 'n_h'
            : 'n_v';
    bool only(Set<Side> s) => inner.length == s.length && inner.containsAll(s);
    if (inner.isEmpty) return narrow.isEmpty ? '1x1' : '1x1_$narrow';
    if (inner.length == 1) {
      final end = switch (inner.single) {
        Side.down => 'v_t',
        Side.up => 'v_b',
        Side.right => 'h_l',
        Side.left => 'h_r',
      };
      return narrow.isEmpty ? '1x2_$end' : '1x2_n_$end';
    }
    if (only({Side.up, Side.right})) return 'L';
    if (only({Side.right, Side.down})) return 'RL';
    if (only({Side.up, Side.left})) return 'ML';
    if (only({Side.left, Side.down})) return 'RML';
    throw StateError('No tile for $name at $cell');
  }
}

enum RoomType { start, normal, boss, treasure, shop, secret, superSecret }
