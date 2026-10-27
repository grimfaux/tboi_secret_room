import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../generator/room_shape.dart';

class Sprites {
  Sprites(this._tiles, this._icons);

  final Map<String, ui.Image> _tiles;
  final Map<String, ui.Image> _icons;

  static const iconNames = {
    RoomType.start: 'spawn',
    RoomType.boss: 'boss',
    RoomType.treasure: 'treasure',
    RoomType.shop: 'shop',
    RoomType.secret: 'secret',
    RoomType.superSecret: 'super_secret',
  };

  ui.Image? tile(String name) => _tiles[name];
  ui.Image? icon(RoomType type) => _icons[iconNames[type]];

  static Future<Sprites> load(AssetBundle bundle) async {
    final tileNames = {for (final s in RoomShape.values) ...s.tiles};
    return Sprites(
      await _loadAll(bundle, 'tiles', tileNames),
      await _loadAll(bundle, 'icons', iconNames.values),
    );
  }

  static Future<Map<String, ui.Image>> _loadAll(
      AssetBundle bundle, String folder, Iterable<String> names) async {
    final entries = await Future.wait(names.map((name) async {
      try {
        final data = await bundle.load('assets/$folder/$name.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        return MapEntry(name, (await codec.getNextFrame()).image);
      } catch (_) {
        return null;
      }
    }));
    return Map.fromEntries(entries.nonNulls);
  }
}
