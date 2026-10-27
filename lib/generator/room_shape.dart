import 'geometry.dart';

enum RoomShape {
  oneByOne([GridPos(0, 0)], ['1x1']),
  narrowH([GridPos(0, 0)], ['1x1_n_h'], {Side.left, Side.right}),
  narrowV([GridPos(0, 0)], ['1x1_n_v'], {Side.up, Side.down}),
  longH([GridPos(0, 0), GridPos(1, 0)], ['1x2_h_l', '1x2_h_r']),
  longV([GridPos(0, 0), GridPos(0, 1)], ['1x2_v_t', '1x2_v_b']),
  longNarrowH([GridPos(0, 0), GridPos(1, 0)], ['1x2_n_h_l', '1x2_n_h_r'],
      {Side.left, Side.right}),
  longNarrowV([GridPos(0, 0), GridPos(0, 1)], ['1x2_n_v_t', '1x2_n_v_b'],
      {Side.up, Side.down}),
  twoByTwo(
    [GridPos(0, 0), GridPos(1, 0), GridPos(0, 1), GridPos(1, 1)],
    ['ML', 'RML', 'L', 'RL'],
  ),
  lShape([GridPos(0, 0), GridPos(0, 1), GridPos(1, 1)], ['1x2_v_t', 'L', '1x2_h_r']),
  lReversed([GridPos(1, 0), GridPos(1, 1), GridPos(0, 1)], ['1x2_v_t', 'RL', '1x2_h_l']),
  lMirrored([GridPos(0, 1), GridPos(0, 0), GridPos(1, 0)], ['1x2_v_b', 'ML', '1x2_h_r']),
  lReversedMirrored(
    [GridPos(1, 1), GridPos(1, 0), GridPos(0, 0)],
    ['1x2_v_b', 'RML', '1x2_h_l'],
  );

  const RoomShape(this.offsets, this.tiles, [this.openSides = const {...Side.values}]);

  final List<GridPos> offsets;
  final List<String> tiles;
  final Set<Side> openSides;

  static const tilesPerCellX = 13;
  static const tilesPerCellY = 7;

  List<GridPos> cellsAt(GridPos origin) =>
      [for (final o in offsets) origin + o];

  int get cellsWide => offsets.map((o) => o.x).reduce((a, b) => a > b ? a : b) + 1;
  int get cellsTall => offsets.map((o) => o.y).reduce((a, b) => a > b ? a : b) + 1;

  int get tileWidth => cellsWide * tilesPerCellX;
  int get tileHeight => cellsTall * tilesPerCellY;
}

enum RoomType { start, normal, boss, treasure, shop, secret, superSecret }
