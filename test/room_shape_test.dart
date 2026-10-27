import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_room_trainer/generator/room_shape.dart';
import 'package:secret_room_trainer/ui/sprites.dart';

void main() {
  test('every shape cell has an existing tile', () {
    for (final shape in RoomShape.values) {
      expect(shape.tiles.length, shape.offsets.length, reason: shape.name);
      expect(shape.offsets.toSet().length, shape.offsets.length, reason: shape.name);
      for (final t in shape.tiles) {
        expect(File('assets/tiles/$t.png').existsSync(), isTrue, reason: t);
      }
    }
  });

  test('every room icon exists', () {
    for (final name in Sprites.iconNames.values) {
      expect(File('assets/icons/$name.png').existsSync(), isTrue, reason: name);
    }
  });
}
