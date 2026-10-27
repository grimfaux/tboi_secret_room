import 'geometry.dart';

enum RoomShape {
  oneByOne([GridPos(0, 0)]);

  const RoomShape(this.offsets);

  final List<GridPos> offsets;

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
