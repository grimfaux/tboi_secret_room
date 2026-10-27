import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generator/room_filler.dart';
import 'generator/room_template.dart';
import 'quiz/quiz_controller.dart';
import 'ui/palette.dart';
import 'ui/quiz_page.dart';
import 'ui/room_preview.dart';
import 'ui/sprites.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  try {
    await GoogleFonts.pendingFonts([
      for (final w in [FontWeight.w400, FontWeight.w600, FontWeight.w700])
        GoogleFonts.pixelifySans(fontWeight: w),
    ]);
  } catch (_) {}
  final pool = RoomTemplate.parsePool(
      await rootBundle.loadString('assets/rooms/templates.json'));
  runApp(SecretRoomApp(
    controller: QuizController(store: StatsStore(prefs)),
    filler: RoomFiller(pool),
    sprites: await Sprites.load(rootBundle),
  ));
}

class SecretRoomApp extends StatelessWidget {
  const SecretRoomApp({
    super.key,
    required this.controller,
    required this.filler,
    this.sprites,
  });

  final QuizController controller;
  final RoomFiller filler;
  final Sprites? sprites;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secret Room Trainer',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: QuizPage(
        controller: controller,
        sprites: sprites,
        onPeek: (context, room) => showRoomPreview(context, filler.fill(room)),
      ),
    );
  }
}

ThemeData _theme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: Palette.gold,
    scaffoldBackgroundColor: Palette.background,
  );
  const square = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
    side: BorderSide(color: Palette.ink, width: 4),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.pixelifySans().fontFamily,
      bodyColor: Palette.text,
      displayColor: Palette.text,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.panel,
      shape: square,
      titleTextStyle: Palette.font(size: 24, weight: FontWeight.w700)
          .copyWith(shadows: Palette.shadow),
      contentTextStyle: Palette.font(),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.panelRing,
      contentTextStyle: Palette.font(),
      shape: square,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Palette.ink,
        border: Border.all(color: Palette.panelRing, width: 2),
      ),
      textStyle: Palette.font(size: 14),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Palette.textDim),
      floatingLabelStyle: TextStyle(color: Palette.gold),
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Palette.panelHighlight, width: 3)),
      focusedBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: Palette.gold, width: 3)),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Palette.gold),
  );
}
