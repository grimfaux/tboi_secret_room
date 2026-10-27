import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_room_trainer/generator/floor_layout.dart';
import 'package:secret_room_trainer/generator/layout_generator.dart';
import 'package:secret_room_trainer/generator/room_shape.dart';

final gen = LayoutGenerator();

Iterable<FloorLayout> samples({int count = 300}) sync* {
  for (var i = 0; i < count; i++) {
    yield gen.generate(i * 7919 + 13, i % 8 + 1);
  }
}

List<RoomSlot> treeRooms(FloorLayout l) =>
    l.rooms.where((r) => r.type != RoomType.secret).toList();

Set<RoomSlot> treeNeighbors(FloorLayout l, RoomSlot r) => {
      for (final c in r.cells)
        for (final n in c.neighbors)
          if (l.roomAt(n) case final o? when o != r && o.type != RoomType.secret) o,
    };

void main() {
  test('room count matches target', () {
    for (final l in samples()) {
      final expected =
          LayoutGenerator.targetRoomCount(l.level, Random(l.seed * 16 + l.level));
      expect(l.targetRoomCount, expected);
      expect(treeRooms(l).length, l.targetRoomCount);
      expect(l.rooms.where((r) => r.type == RoomType.secret).length, 1);
    }
  });

  test('rooms never overlap and stay in bounds', () {
    for (final l in samples()) {
      final cells = [for (final r in l.rooms) ...r.cells];
      expect(cells.toSet().length, cells.length);
      expect(cells.every(l.inBounds), isTrue);
    }
  });

  test('special shapes appear', () {
    final shapes = {
      for (final l in samples(count: 500))
        for (final r in l.rooms) r.shape,
    };
    expect(shapes, containsAll(RoomShape.values));
  });

  test('layout is a tree', () {
    for (final l in samples()) {
      final rooms = treeRooms(l);
      final cells = {for (final r in rooms) ...r.cells};
      var contacts = 0;
      for (final r in rooms) {
        for (final c in r.cells) {
          contacts += c.neighbors
              .where((n) => cells.contains(n) && !r.cells.contains(n))
              .length;
        }
      }
      expect(contacts ~/ 2, rooms.length - 1);

      final seen = {l.roomAt(LayoutGenerator.start)!};
      final stack = [...seen];
      while (stack.isNotEmpty) {
        for (final n in treeNeighbors(l, stack.removeLast())) {
          if (seen.add(n)) stack.add(n);
        }
      }
      expect(seen.length, rooms.length);
    }
  });

  test('doors only use open sides and are symmetric', () {
    for (final l in samples()) {
      for (final r in l.rooms) {
        for (final d in r.doors) {
          expect(r.cells, contains(d.cell));
          expect(r.isOpen(d.side), isTrue);
          final other = l.roomAt(d.cell.step(d.side))!;
          expect(other.doors,
              contains((cell: d.cell.step(d.side), side: d.side.opposite)));
        }
      }
      for (final r in treeRooms(l)) {
        expect(
          r.doors.where((d) => l.roomAt(d.cell.step(d.side))!.type != RoomType.secret).length,
          treeNeighbors(l, r).length,
        );
      }
    }
  });

  test('boss is farthest dead end, super secret second farthest', () {
    for (final l in samples()) {
      final deadEnds = treeRooms(l)
          .where((r) =>
              r.type != RoomType.start &&
              r.shape == RoomShape.oneByOne &&
              treeNeighbors(l, r).length == 1)
          .toList();
      expect(deadEnds.length, greaterThanOrEqualTo(4));
      final boss = l.ofType(RoomType.boss);
      final ssr = l.ofType(RoomType.superSecret);
      expect(deadEnds, containsAll([boss, ssr]));
      for (final d in deadEnds) {
        expect(boss.distance, greaterThanOrEqualTo(d.distance));
        if (d != boss) expect(ssr.distance, greaterThanOrEqualTo(d.distance));
      }
      for (final t in [RoomType.treasure, RoomType.shop]) {
        expect(deadEnds, contains(l.ofType(t)));
      }
    }
  });

  test('secret room is valid and max weight', () {
    for (final l in samples()) {
      final secret = l.ofType(RoomType.secret);
      final forbidden = {
        l.ofType(RoomType.boss).origin,
        l.ofType(RoomType.superSecret).origin,
      };
      expect(secret.origin.neighbors.any(forbidden.contains), isFalse);
      expect(secret.doors, isNotEmpty);

      final best = l.secretCandidates.map((c) => c.weight).reduce(max);
      final chosen = l.secretCandidates.firstWhere((c) => c.pos == secret.origin);
      expect(chosen.weight, best);
      expect(chosen.neighbors, secret.doors.length);
      for (final c in l.secretCandidates) {
        expect(c.roll, inInclusiveRange(10, 14));
        expect(c.pos.neighbors.any(forbidden.contains), isFalse);
      }
    }
  });

  test('same seed and level give identical floor', () {
    for (final l in samples(count: 50)) {
      final again = gen.generate(l.seed, l.level);
      expect(again.rooms.length, l.rooms.length);
      for (var i = 0; i < l.rooms.length; i++) {
        final a = l.rooms[i], b = again.rooms[i];
        expect(b.origin, a.origin);
        expect(b.shape, a.shape);
        expect(b.type, a.type);
        expect(b.doors, a.doors);
        expect(b.seed, a.seed);
        expect(b.distance, a.distance);
      }
    }
  });

  test('10,000 generations never hang or throw', () {
    final rng = Random(42);
    for (var i = 0; i < 10000; i++) {
      final l = gen.generate(rng.nextInt(LayoutGenerator.maxSeed), i % 8 + 1);
      expect(l.attempts, lessThan(100000));
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
