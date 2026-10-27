import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../generator/floor_layout.dart';
import '../generator/geometry.dart';
import '../generator/layout_generator.dart';
import '../generator/room_shape.dart';

class StatsStore {
  StatsStore(this._prefs);

  final SharedPreferences _prefs;
  static const _bestKey = 'best_streak';

  int get bestStreak => _prefs.getInt(_bestKey) ?? 0;
  Future<void> saveBestStreak(int value) => _prefs.setInt(_bestKey, value);
}

enum QuizPhase { placingSecret, placingSuperSecret, ready, revealed }

class QuizController extends ChangeNotifier {
  QuizController({required this.store, Random? random})
      : _random = random ?? Random(),
        bestStreak = store.bestStreak {
    newFloor();
  }

  final StatsStore store;
  final Random _random;
  final _generator = LayoutGenerator();

  late FloorLayout layout;
  int level = 1;
  GridPos? secretGuess;
  GridPos? superGuess;
  bool revealed = false;
  bool showHints = false;

  int rounds = 0;
  int correct = 0;
  int streak = 0;
  int bestStreak;

  void newFloor({int? seed, int? level}) {
    if (level != null) this.level = level;
    layout = _generator.generate(
        seed ?? _random.nextInt(LayoutGenerator.maxSeed), this.level);
    secretGuess = null;
    superGuess = null;
    revealed = false;
    notifyListeners();
  }

  void toggleHints() {
    showHints = !showHints;
    notifyListeners();
  }

  QuizPhase get phase {
    if (revealed) return QuizPhase.revealed;
    if (secretGuess == null) return QuizPhase.placingSecret;
    if (superGuess == null) return QuizPhase.placingSuperSecret;
    return QuizPhase.ready;
  }

  RoomSlot get secretRoom => layout.ofType(RoomType.secret);
  RoomSlot get superSecretRoom => layout.ofType(RoomType.superSecret);

  bool get secretCorrect => secretGuess == secretRoom.origin;
  bool get superCorrect => superGuess == superSecretRoom.origin;

  double get accuracy => rounds == 0 ? 0 : correct / (rounds * 2);

  bool isHidden(RoomSlot r) =>
      !revealed && (r.type == RoomType.secret || r.type == RoomType.superSecret);

  RoomSlot? visibleRoomAt(GridPos p) {
    final r = layout.roomAt(p);
    return r == null || isHidden(r) ? null : r;
  }

  int visibleNeighbors(GridPos p) =>
      p.neighbors.where((n) => visibleRoomAt(n) != null).length;

  bool isGuessSpot(GridPos p) =>
      layout.inBounds(p) && visibleRoomAt(p) == null && visibleNeighbors(p) > 0;

  void tapCell(GridPos p) {
    if (revealed || !isGuessSpot(p)) return;
    if (p == secretGuess) {
      secretGuess = null;
    } else if (p == superGuess) {
      superGuess = null;
    } else if (secretGuess == null) {
      secretGuess = p;
    } else if (superGuess == null) {
      superGuess = p;
    } else {
      return;
    }
    notifyListeners();
  }

  bool get canUndo => !revealed && (secretGuess != null || superGuess != null);

  void undo() {
    if (!canUndo) return;
    if (superGuess != null) {
      superGuess = null;
    } else {
      secretGuess = null;
    }
    notifyListeners();
  }

  void reveal() {
    if (phase != QuizPhase.ready) return;
    revealed = true;
    rounds++;
    for (final ok in [secretCorrect, superCorrect]) {
      if (ok) {
        correct++;
        streak++;
      } else {
        streak = 0;
      }
      if (streak > bestStreak) bestStreak = streak;
    }
    store.saveBestStreak(bestStreak);
    notifyListeners();
  }
}
