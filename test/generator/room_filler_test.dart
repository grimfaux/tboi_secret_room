import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_room_trainer/generator/layout_generator.dart';
import 'package:secret_room_trainer/generator/room_filler.dart';
import 'package:secret_room_trainer/generator/room_shape.dart';
import 'package:secret_room_trainer/generator/room_template.dart';

void main() {
  final pool = RoomTemplate.parsePool(
      File('assets/rooms/templates.json').readAsStringSync());
  final filler = RoomFiller(pool);
  final gen = LayoutGenerator();

  test('template pool is well formed', () {
    expect(pool.map((t) => t.id).toSet().length, pool.length);
    for (final type in RoomType.values) {
      expect(pool.where((t) => t.type == type).length, greaterThanOrEqualTo(5));
    }
    for (final t in pool) {
      expect(t.tiles.length, t.shape.tileHeight);
      expect(t.tiles.every((r) => r.length == t.shape.tileWidth), isTrue);
      expect(t.weight, greaterThan(0));
    }
  });

  test('every pick matches its slot', () {
    for (var i = 0; i < 500; i++) {
      final layout = gen.generate(i * 104729 + 1, i % 8 + 1);
      for (final filled in filler.fillFloor(layout).values) {
        final t = filled.template;
        expect(t.shape, filled.slot.shape);
        expect(t.type, filled.slot.type);
        expect(t.doors.containsAll(filled.slot.relativeDoors), isTrue);
        if (!filled.isFallback) expect(pool, contains(t));
      }
    }
  });

  test('same seed and level give identical picks', () {
    for (var i = 0; i < 100; i++) {
      final a = filler.fillFloor(gen.generate(i * 31 + 5, i % 8 + 1));
      final b = filler.fillFloor(gen.generate(i * 31 + 5, i % 8 + 1));
      expect(b.keys, a.keys);
      for (final id in a.keys) {
        expect(b[id]!.template.id, a[id]!.template.id);
        expect(b[id]!.slot.seed, a[id]!.slot.seed);
      }
    }
  });

  test('falls back to an empty room when nothing matches', () {
    final layout = gen.generate(1, 1);
    final filled = RoomFiller(const []).fill(layout.rooms.first);
    expect(filled.isFallback, isTrue);
    expect(filled.template.tiles.join().replaceAll('.', ''), isEmpty);
  });

  test('empty fallback fits every shape', () {
    for (final shape in RoomShape.values) {
      final t = RoomTemplate.empty(shape, RoomType.normal);
      expect(t.tiles.length, shape.tileHeight);
      expect(t.tiles.every((r) => r.length == shape.tileWidth), isTrue);
      for (final d in t.doors) {
        expect(shape.openSides, contains(d.side));
        expect(shape.offsets, contains(d.cell));
      }
    }
  });
}
