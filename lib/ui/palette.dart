import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../generator/room_shape.dart';

abstract final class Palette {
  static const background = Color(0xFF1C1411);
  static const checker = Color(0xFF211814);
  static const panel = Color(0xFF2B1F1A);
  static const panelRing = Color(0xFF3B2A22);
  static const panelHighlight = Color(0xFF5A4234);
  static const ink = Color(0xFF000000);
  static const mapBackground = Color(0xFF0E0A09);
  static const mapRing = Color(0xFF2A1E19);
  static const text = Color(0xFFE9DCC4);
  static const textDim = Color(0xFFA8957C);
  static const gold = Color(0xFFF4C542);
  static const red = Color(0xFF8A2A1F);
  static const redHighlight = Color(0xFFB4442F);

  static const room = Color(0xFF9A918A);
  static const roomBorder = Color(0xFF3A302D);
  static const secretRoom = Color(0xFFA9C8E6);
  static const superSecretRoom = Color(0xFFD2B8F0);
  static const spotHover = Color(0x40F4C542);
  static const hint = Color(0xFFB9B2A8);
  static const secret = gold;
  static const superSecret = Color(0xFFC79BFF);
  static const correct = Color(0xFF6BCB77);
  static const wrong = Color(0xFFE5534B);
  static const candidate = Color(0xFFD8CCB8);
  static const candidateBest = gold;

  static TextStyle font({double size = 16, Color color = text, FontWeight? weight}) =>
      GoogleFonts.pixelifySans(fontSize: size, color: color, fontWeight: weight);

  static const shadow = [Shadow(offset: Offset(2, 2), color: ink)];

  static const icons = <RoomType, (IconData, Color)>{
    RoomType.start: (Icons.home_rounded, Color(0xFF6B5E58)),
    RoomType.boss: (Icons.dangerous_rounded, Color(0xFFB3261E)),
    RoomType.treasure: (Icons.emoji_events_rounded, Color(0xFFF2B705)),
    RoomType.shop: (Icons.monetization_on_rounded, Color(0xFF2E7D32)),
    RoomType.secret: (Icons.question_mark_rounded, Color(0xFFE8F1F8)),
    RoomType.superSecret: (Icons.auto_awesome_rounded, Color(0xFFF3E8FF)),
  };
}
