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

  factory RoomTemplate.empty(RoomShape shape, RoomType type) => RoomTemplate(
        id: 'empty_${shape.name}',
        shape: shape,
        type: type,
        doors: Side.values.toSet(),
        weight: 1,
        difficulty: 0,
        tiles: List.filled(shape.tileHeight, '.' * shape.tileWidth),
      );

  factory RoomTemplate.fromJson(Map<String, dynamic> json) => RoomTemplate(
        id: json['id'] as String,
        shape: RoomShape.values.byName(json['shape'] as String),
        type: RoomType.values.byName(json['type'] as String),
        doors: {for (final d in json['doors'] as List) Side.values.byName(d as String)},
        weight: (json['weight'] as num).toDouble(),
        difficulty: json['difficulty'] as int,
        tiles: [for (final row in json['tiles'] as List) row as String],
      );

  final String id;
  final RoomShape shape;
  final RoomType type;
  final Set<Side> doors;
  final double weight;
  final int difficulty;
  final List<String> tiles;

  static List<RoomTemplate> parsePool(String source) => [
        for (final t in (jsonDecode(source) as Map<String, dynamic>)['templates'] as List)
          RoomTemplate.fromJson(t as Map<String, dynamic>),
      ];
}
