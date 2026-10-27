import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_room_trainer/generator/floor_layout.dart';
import 'package:secret_room_trainer/generator/geometry.dart';
import 'package:secret_room_trainer/generator/layout_generator.dart';
import 'package:secret_room_trainer/generator/room_shape.dart';

final gen = LayoutGenerator();

Iterable<FloorLayout> samples({int count = 200}) sync* {
  for (var i = 0; i < count; i++) {
    yield gen.generate(i * 7919 + 13, i % 8 + 1);
  }
}

List<RoomSlot> treeRooms(FloorLayout l) =>
    l.rooms.where((r) => r.type != RoomType.secret).toList();

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

  test('layout is a tree', () {
    for (final l in samples()) {
      final rooms = treeRooms(l);
      final cells = {for (final r in rooms) r.origin};
      var edges = 0;
      for (final r in rooms) {
        edges += r.origin.neighbors.where(cells.contains).length;
      }
      expect(edges ~/ 2, rooms.length - 1);

      final seen = {LayoutGenerator.start};
      final stack = [LayoutGenerator.start];
      while (stack.isNotEmpty) {
        for (final n in stack.removeLast().neighbors) {
          if (cells.contains(n) && seen.add(n)) stack.add(n);
        }
      }
      expect(seen.length, rooms.length);
    }
  });

  test('boss is farthest dead end, super secret second farthest', () {
    for (final l in samples()) {
      final cells = {for (final r in treeRooms(l)) r.origin};
      final deadEnds = treeRooms(l)
          .where((r) =>
              r.type != RoomType.start &&
              r.origin.neighbors.where(cells.contains).length == 1)
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
      final secret = l.ofType(RoomType.secret).origin;
      final forbidden = {
        l.ofType(RoomType.boss).origin,
        l.ofType(RoomType.superSecret).origin,
      };
      expect(secret.neighbors.any(forbidden.contains), isFalse);
      expect(secret.neighbors.any((n) => l.roomAt(n) != null), isTrue);

      final best = l.secretCandidates.map((c) => c.weight).reduce(max);
      final chosen = l.secretCandidates.firstWhere((c) => c.pos == secret);
      expect(chosen.weight, best);
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
        expect(b.type, a.type);
        expect(b.doors, a.doors);
        expect(b.seed, a.seed);
        expect(b.distance, a.distance);
      }
    }
  });

  test('doors are symmetric', () {
    for (final l in samples()) {
      for (final r in l.rooms) {
        for (final s in r.doors) {
          expect(l.roomAt(r.origin.step(s))!.doors, contains(s.opposite));
        }
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
