import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../generator/room_shape.dart';

class Sprites {
  Sprites(this._tiles, this._icons, this._layouts);

  final Map<String, ui.Image> _tiles;
  final Map<String, ui.Image> _icons;
  final Map<String, ui.Image> _layouts;

  static const iconNames = {
    RoomType.start: 'spawn',
    RoomType.boss: 'boss',
    RoomType.treasure: 'treasure',
    RoomType.shop: 'shop',
    RoomType.secret: 'secret',
    RoomType.superSecret: 'super_secret',
  };

  static const layoutNames = [
    '1_side',
    '1_side_narrow',
    '2_sides_parallel',
    '2_sides_perpendicular',
    '3_sides',
    'door',
  ];

  ui.Image? tile(String name) => _tiles[name];
  ui.Image? get empty => _tiles['empty'];
  ui.Image? icon(RoomType type) => _icons[iconNames[type]];
  ui.Image? layout(String name) => _layouts[name];

  static Future<Sprites> load(AssetBundle bundle) async {
    final tileNames = {'empty', for (final s in RoomShape.values) ...s.tiles};
    final (tiles, icons, layouts) = await (
      _loadAll(bundle, 'tiles', tileNames),
      _loadAll(bundle, 'icons', iconNames.values),
      _loadAll(bundle, 'room_layouts', layoutNames),
    ).wait;
    final side = layouts['1_side'];
    if (side != null) {
      layouts['open'] = await _patch(side, const ui.Rect.fromLTWH(0, 8, 64, 8),
          const ui.Rect.fromLTWH(0, 0, 64, 8));
    }
    final narrow = layouts['1_side_narrow'];
    if (narrow != null) {
      layouts['open_narrow'] = await _patch(narrow,
          const ui.Rect.fromLTWH(48, 0, 8, 64), const ui.Rect.fromLTWH(56, 0, 8, 64));
    }
    return Sprites(tiles, icons, layouts);
  }

  static Future<ui.Image> _patch(ui.Image base, ui.Rect from, ui.Rect to) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()..filterQuality = ui.FilterQuality.none;
    canvas.drawImage(base, ui.Offset.zero, paint);
    canvas.drawImageRect(base, from, to, paint);
    return recorder.endRecording().toImage(base.width, base.height);
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
