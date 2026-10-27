import 'dart:collection';
import 'dart:math';

import 'floor_layout.dart';
import 'geometry.dart';
import 'room_shape.dart';

class LayoutGenerator {
  static const width = 9;
  static const height = 8;
  static const start = GridPos(4, 3);
  static const maxSeed = 0x7fffffff;

  static int targetRoomCount(int level, Random rng) =>
      min(20, rng.nextInt(2) + 5 + (level * 10 / 3).floor());

  FloorLayout generate(int seed, int level) {
    final rng = Random(seed * 16 + level);
    final target = targetRoomCount(level, rng);
    for (var attempt = 1;; attempt++) {
      final layout = _attempt(rng, seed, level, target, attempt);
      if (layout != null) return layout;
    }
  }

  static bool _inBounds(GridPos p) =>
      p.x >= 0 && p.y >= 0 && p.x < width && p.y < height;

  FloorLayout? _attempt(
      Random rng, int seed, int level, int target, int attempt) {
    final dist = <GridPos, int>{start: 0};
    final order = <GridPos>[start];
    final queue = Queue<GridPos>()..add(start);
    final deadEnds = <GridPos>[];

    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      var added = false;
      for (final n in cur.neighbors) {
        if (!_inBounds(n) || dist.containsKey(n)) continue;
        if (n.neighbors.where(dist.containsKey).length > 1) continue;
        if (dist.length >= target) continue;
        if (rng.nextBool()) continue;
        dist[n] = dist[cur]! + 1;
        order.add(n);
        queue.add(n);
        added = true;
      }
      if (!added && cur != start) deadEnds.add(cur);
    }

    if (dist.length != target || deadEnds.length < 4) return null;

    deadEnds.sort((a, b) {
      final d = dist[b]!.compareTo(dist[a]!);
      return d != 0 ? d : order.indexOf(a).compareTo(order.indexOf(b));
    });
    final types = <GridPos, RoomType>{
      for (final p in order) p: RoomType.normal,
      start: RoomType.start,
      deadEnds[0]: RoomType.boss,
      deadEnds[1]: RoomType.superSecret,
    };
    final rest = deadEnds.sublist(2);
    types[rest.removeAt(rng.nextInt(rest.length))] = RoomType.treasure;
    types[rest.removeAt(rng.nextInt(rest.length))] = RoomType.shop;

    final blocked = {deadEnds[0], deadEnds[1]};
    final candidates = <SecretCandidate>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final p = GridPos(x, y);
        if (dist.containsKey(p)) continue;
        final adj = p.neighbors.where(dist.containsKey).toList();
        if (adj.isEmpty || adj.any(blocked.contains)) continue;
        candidates.add(SecretCandidate(
            pos: p, neighbors: adj.length, roll: 10 + rng.nextInt(5)));
      }
    }
    if (candidates.isEmpty) return null;
    final secret =
        candidates.reduce((a, b) => b.weight > a.weight ? b : a).pos;
    types[secret] = RoomType.secret;
    dist[secret] =
        secret.neighbors.where(dist.containsKey).map((p) => dist[p]!).reduce(min) + 1;
    order.add(secret);

    // Extension point: ultra secret room placement goes here.

    final rooms = <RoomSlot>[
      for (final (i, p) in order.indexed)
        RoomSlot(
          id: i,
          origin: p,
          shape: RoomShape.oneByOne,
          type: types[p]!,
          doors: {
            for (final s in Side.values)
              if (dist.containsKey(p.step(s))) s,
          },
          distance: dist[p]!,
          seed: rng.nextInt(maxSeed),
        ),
    ];

    return FloorLayout(
      seed: seed,
      level: level,
      width: width,
      height: height,
      targetRoomCount: target,
      rooms: rooms,
      deadEnds: List.unmodifiable(deadEnds),
      secretCandidates: List.unmodifiable(candidates),
      attempts: attempt,
    );
  }
}
