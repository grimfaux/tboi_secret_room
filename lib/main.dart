import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quiz/quiz_controller.dart';
import 'ui/palette.dart';
import 'ui/quiz_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(SecretRoomApp(controller: QuizController(store: StatsStore(prefs))));
}

class SecretRoomApp extends StatelessWidget {
  const SecretRoomApp({super.key, required this.controller});

  final QuizController controller;

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
      home: QuizPage(controller: controller),
    );
  }
}
