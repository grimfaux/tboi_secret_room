import 'dart:math';

import 'floor_layout.dart';
import 'room_template.dart';

class FilledRoom {
  const FilledRoom(this.slot, this.template, {this.isFallback = false});

  final RoomSlot slot;
  final RoomTemplate template;
  final bool isFallback;
}

class RoomFiller {
  RoomFiller(this.pool);

  final List<RoomTemplate> pool;

  List<RoomTemplate> matches(RoomSlot slot) => pool
      .where((t) =>
          t.shape == slot.shape &&
          t.type == slot.type &&
          t.weight > 0 &&
          t.doors.containsAll(slot.relativeDoors))
      .toList();

  FilledRoom fill(RoomSlot slot) {
    final options = matches(slot);
    if (options.isEmpty) {
      return FilledRoom(slot, RoomTemplate.empty(slot.shape, slot.type),
          isFallback: true);
    }
    final total = options.fold<double>(0, (sum, t) => sum + t.weight);
    var roll = Random(slot.seed).nextDouble() * total;
    for (final t in options) {
      roll -= t.weight;
      if (roll < 0) return FilledRoom(slot, t);
    }
    return FilledRoom(slot, options.last);
  }

  Map<int, FilledRoom> fillFloor(FloorLayout layout) =>
      {for (final r in layout.rooms) r.id: fill(r)};
}
