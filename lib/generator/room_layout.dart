import 'dart:math';

import 'geometry.dart';
import 'room_shape.dart';

abstract final class RoomLayouts {
  static const blockChance = 0.3;

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

  static Set<Door> blockedSides(
      RoomShape shape, GridPos origin, int seed, Set<Door> doors) {
    final rng = Random(seed);
    return {
      for (final d in outerSides(shape, origin))
        if (!doors.contains(d) && rng.nextDouble() < blockChance) d,
    };
  }
}
