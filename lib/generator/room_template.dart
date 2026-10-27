import 'dart:convert';

import 'geometry.dart';
import 'room_shape.dart';

class RoomTemplate {
  const RoomTemplate({
    required this.id,
    required this.shape,
    required this.type,
    required this.doors,
    required this.weight,
    required this.difficulty,
    required this.tiles,
  });

  factory RoomTemplate.empty(RoomShape shape, RoomType type) {
    const cx = RoomShape.tilesPerCellX, cy = RoomShape.tilesPerCellY;
    final open = shape.openSides;
    final narrowH = !open.contains(Side.up);
    final narrowV = !open.contains(Side.left);
    bool floor(int x, int y) {
      if (!shape.offsets.contains(GridPos(x ~/ cx, y ~/ cy))) return false;
      if (narrowH && (y % cy < 2 || y % cy > 4)) return false;
      if (narrowV && (x % cx < 4 || x % cx > 8)) return false;
      return true;
    }

    return RoomTemplate(
      id: 'empty_${shape.name}',
      shape: shape,
      type: type,
      doors: {
        for (final o in shape.offsets)
          for (final s in open)
            if (!shape.offsets.contains(o.step(s))) (cell: o, side: s),
      },
      weight: 1,
      difficulty: 0,
      tiles: [
        for (var y = 0; y < shape.tileHeight; y++)
          [for (var x = 0; x < shape.tileWidth; x++) floor(x, y) ? '.' : '#'].join(),
      ],
    );
  }

  factory RoomTemplate.fromJson(Map<String, dynamic> json) => RoomTemplate(
        id: json['id'] as String,
        shape: RoomShape.values.byName(json['shape'] as String),
        type: RoomType.values.byName(json['type'] as String),
        doors: {for (final d in json['doors'] as List) _parseDoor(d as String)},
        weight: (json['weight'] as num).toDouble(),
        difficulty: json['difficulty'] as int,
        tiles: [for (final row in json['tiles'] as List) row as String],
      );

  static Door _parseDoor(String s) {
    final parts = s.split(',');
    if (parts.length == 1) return (cell: const GridPos(0, 0), side: Side.values.byName(s));
    return (
      cell: GridPos(int.parse(parts[0]), int.parse(parts[1])),
      side: Side.values.byName(parts[2]),
    );
  }

  final String id;
  final RoomShape shape;
  final RoomType type;
  final Set<Door> doors;
  final double weight;
  final int difficulty;
  final List<String> tiles;

  static List<RoomTemplate> parsePool(String source) => [
        for (final t in (jsonDecode(source) as Map<String, dynamic>)['templates'] as List)
          RoomTemplate.fromJson(t as Map<String, dynamic>),
      ];
}
