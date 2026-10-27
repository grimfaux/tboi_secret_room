import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generator/room_filler.dart';
import 'generator/room_template.dart';
import 'quiz/quiz_controller.dart';
import 'ui/palette.dart';
import 'ui/quiz_page.dart';
import 'ui/room_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final pool = RoomTemplate.parsePool(
      await rootBundle.loadString('assets/rooms/templates.json'));
  runApp(SecretRoomApp(
    controller: QuizController(store: StatsStore(prefs)),
    filler: RoomFiller(pool),
  ));
}

class SecretRoomApp extends StatelessWidget {
  const SecretRoomApp({super.key, required this.controller, required this.filler});

  final QuizController controller;
  final RoomFiller filler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secret Room Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Palette.secret,
        scaffoldBackgroundColor: Palette.background,
      ),
      home: QuizPage(
        controller: controller,
        onPeek: (context, room) => showRoomPreview(context, filler.fill(room)),
      ),
    );
  }
}
