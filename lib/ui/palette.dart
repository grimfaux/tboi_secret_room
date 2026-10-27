import 'package:flutter/material.dart';

import '../generator/room_shape.dart';

abstract final class Palette {
  static const background = Color(0xFF120E0D);
  static const mapBackground = Color(0xFF1E1716);
  static const room = Color(0xFF9A918A);
  static const startRoom = Color(0xFFE6DFD8);
  static const roomBorder = Color(0xFF3A302D);
  static const secretRoom = Color(0xFF5E7F9C);
  static const superSecretRoom = Color(0xFF8C6BB0);
  static const secretDoor = Color(0xFF6F6577);
  static const spot = Color(0x40FFFFFF);
  static const spotFaint = Color(0x18FFFFFF);
  static const spotHover = Color(0x33FFE082);
  static const hint = Color(0x99FFFFFF);
  static const secret = Color(0xFFFFC857);
  static const superSecret = Color(0xFFC79BFF);
  static const correct = Color(0xFF6BCB77);
  static const wrong = Color(0xFFE5534B);
  static const candidate = Color(0xB3FFFFFF);
  static const candidateBest = Color(0xFFFFC857);

  static const icons = <RoomType, (IconData, Color)>{
    RoomType.start: (Icons.home_rounded, Color(0xFF6B5E58)),
    RoomType.boss: (Icons.dangerous_rounded, Color(0xFFB3261E)),
    RoomType.treasure: (Icons.emoji_events_rounded, Color(0xFFF2B705)),
    RoomType.shop: (Icons.monetization_on_rounded, Color(0xFF2E7D32)),
    RoomType.secret: (Icons.question_mark_rounded, Color(0xFFE8F1F8)),
    RoomType.superSecret: (Icons.auto_awesome_rounded, Color(0xFFF3E8FF)),
  };
}
