import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_room_trainer/generator/room_shape.dart';
import 'package:secret_room_trainer/quiz/quiz_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<QuizController> make() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return QuizController(store: StatsStore(prefs), random: Random(1));
}

void main() {
  test('hidden rooms do not leak before reveal', () async {
    final c = await make();
    for (var seed = 0; seed < 200; seed++) {
      c.newFloor(seed: seed, level: seed % 8 + 1);
      final ssr = c.superSecretRoom.origin;
      final secret = c.secretRoom.origin;
      expect(c.visibleRoomAt(ssr), isNull);
      expect(c.visibleRoomAt(secret), isNull);
      expect(c.isGuessSpot(ssr), isTrue);
      expect(c.isGuessSpot(secret), isTrue);
      for (final n in ssr.neighbors.where(c.layout.inBounds)) {
        final hint = c.visibleNeighbors(n);
        final actual = n.neighbors
            .map(c.layout.roomAt)
            .where((r) => r != null && r.type != RoomType.secret && r.type != RoomType.superSecret)
            .length;
        expect(hint, actual);
      }
    }
  });

  test('scoring, streak and best streak', () async {
    final c = await make();
    c.newFloor(seed: 7, level: 3);
    c.tapCell(c.secretRoom.origin);
    c.tapCell(c.superSecretRoom.origin);
    c.reveal();
    expect(c.correct, 2);
    expect(c.streak, 2);
    expect(c.bestStreak, 2);

    c.newFloor(seed: 8, level: 3);
    final wrong = c.layout.secretCandidates
        .map((s) => s.pos)
        .firstWhere((p) => p != c.secretRoom.origin && c.isGuessSpot(p));
    c.tapCell(wrong);
    c.tapCell(c.superSecretRoom.origin);
    c.undo();
    expect(c.phase, QuizPhase.placingSuperSecret);
    c.tapCell(c.superSecretRoom.origin);
    c.reveal();
    expect(c.correct, 3);
    expect(c.streak, 1);
    expect(c.bestStreak, 2);
    expect(c.accuracy, 0.75);
    expect(c.store.bestStreak, 2);
  });
}
