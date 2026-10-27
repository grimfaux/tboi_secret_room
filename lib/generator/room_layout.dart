import 'dart:math';

import 'geometry.dart';
import 'room_shape.dart';

abstract final class RoomLayouts {
  static const blockChance = 0.3;
  static const treasureBlockChance = 0.15;

  static Iterable<Door> outerSides(RoomShape shape, GridPos origin) sync* {
    final cells = shape.cellsAt(origin);
    for (final c in cells) {
      for (final s in Side.clockwise) {
        if (shape.openSides.contains(s) && !cells.contains(c.step(s))) {
          yield (cell: c, side: s);
        }
      }
    }
  }

  static Set<Door> blockedSides(RoomShape shape, GridPos origin, RoomType type,
      int seed, Set<Door> doors) {
    final rng = Random(seed);
    final free = [
      for (final d in outerSides(shape, origin))
        if (!doors.contains(d)) d,
    ];
    return switch (type) {
      RoomType.start || RoomType.shop => {},
      RoomType.treasure => free.isNotEmpty && rng.nextDouble() < treasureBlockChance
          ? {free[rng.nextInt(free.length)]}
          : {},
      _ => {
          for (final d in free)
            if (rng.nextDouble() < blockChance) d,
        },
    };
  }
}
