import 'package:flutter_test/flutter_test.dart';
import 'package:secret_room_trainer/generator/floor_layout.dart';
import 'package:secret_room_trainer/generator/geometry.dart';
import 'package:secret_room_trainer/generator/layout_generator.dart';
import 'package:secret_room_trainer/generator/room_layout.dart';
import 'package:secret_room_trainer/generator/room_shape.dart';
import 'package:secret_room_trainer/ui/room_preview.dart';

final gen = LayoutGenerator();

Iterable<FloorLayout> samples({int count = 300}) sync* {
  for (var i = 0; i < count; i++) {
    yield gen.generate(i * 104729 + 1, i % 8 + 1);
  }
}

void main() {
  test('blocked sides are outer, open and never doors', () {
    for (final l in samples()) {
      for (final r in l.rooms) {
        final outer = RoomLayouts.outerSides(r.shape, r.origin).toSet();
        expect(outer.containsAll(r.blocked), isTrue);
        expect(r.blocked.intersection(r.doors), isEmpty);
      }
    }
  });

  test('every door is reachable from both sides', () {
    for (final l in samples()) {
      for (final r in l.rooms) {
        for (final d in r.doors) {
          expect(r.isAccessible(d.cell, d.side), isTrue);
          final n = d.cell.step(d.side);
          expect(l.roomAt(n)!.isAccessible(n, d.side.opposite), isTrue);
        }
      }
    }
  });

  test('secret candidates only count reachable sides', () {
    for (final l in samples()) {
      for (final c in l.secretCandidates) {
        final reachable = Side.values.where((s) {
          final n = c.pos.step(s);
          final r = l.roomAt(n);
          return r != null && r.type != RoomType.secret && r.isAccessible(n, s.opposite);
        }).length;
        expect(c.neighbors, reachable);
      }
    }
  });

  test('some but not all free sides get blocked', () {
    var free = 0, blocked = 0;
    for (final l in samples()) {
      for (final r in l.rooms) {
        final outer = RoomLayouts.outerSides(r.shape, r.origin).toSet();
        free += outer.difference(r.doors).length;
        blocked += r.blocked.length;
      }
    }
    expect(blocked / free, inInclusiveRange(0.2, 0.4));
  });

  test('blocked sides are reproducible', () {
    for (final l in samples(count: 50)) {
      final again = gen.generate(l.seed, l.level);
      for (var i = 0; i < l.rooms.length; i++) {
        expect(again.rooms[i].blocked, l.rooms[i].blocked);
      }
    }
  });

  test('every cell has a layout image', () {
    for (final l in samples()) {
      for (final r in l.rooms) {
        for (final p in r.cells) {
          final blocked = {
            for (final d in r.blocked)
              if (d.cell == p) d.side,
          };
          expect(() => layoutTile(r.shape, blocked), returnsNormally);
        }
      }
    }
  });

  test('layout images rotate to the blocked sides', () {
    expect(layoutTile(RoomShape.oneByOne, {}), ('open', 0));
    expect(layoutTile(RoomShape.oneByOne, {Side.left}), ('1_side', 3));
    expect(layoutTile(RoomShape.oneByOne, {Side.left, Side.right}),
        ('2_sides_parallel', 1));
    expect(layoutTile(RoomShape.oneByOne, {Side.up, Side.right}),
        ('2_sides_perpendicular', 1));
    expect(layoutTile(RoomShape.oneByOne, {Side.up, Side.right, Side.down}),
        ('3_sides', 1));
    expect(layoutTile(RoomShape.narrowH, {Side.left}), ('1_side_narrow', 2));
    expect(layoutTile(RoomShape.narrowV, {Side.up}), ('1_side_narrow', 3));
    expect(layoutTile(RoomShape.longNarrowV, {}), ('open_narrow', 1));
  });
}
