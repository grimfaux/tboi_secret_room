import 'dart:collection';
import 'dart:math';

import 'floor_layout.dart';
import 'geometry.dart';
import 'room_layout.dart';
import 'room_shape.dart';

class LayoutGenerator {
  static const width = 9;
  static const height = 8;
  static const start = GridPos(4, 3);
  static const maxSeed = 0x7fffffff;
  static const specialShapeChance = 0.25;

  static final specialShapes =
      RoomShape.values.where((s) => s != RoomShape.oneByOne).toList();

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
    final origins = <GridPos>[start];
    final shapes = <RoomShape>[RoomShape.oneByOne];
    final dist = <int>[0];
    final owner = <GridPos, int>{start: 0};
    final queue = Queue<int>()..add(0);
    final deadEnds = <int>[];

    List<GridPos>? place(RoomShape shape, GridPos origin, Side fromParent) {
      final cells = shape.cellsAt(origin);
      if (!cells.every((c) => _inBounds(c) && !owner.containsKey(c))) return null;
      if (!shape.openSides.contains(fromParent.opposite)) return null;
      var contacts = 0;
      for (final c in cells) {
        for (final n in c.neighbors) {
          if (!cells.contains(n) && owner.containsKey(n)) contacts++;
        }
      }
      return contacts == 1 ? cells : null;
    }

    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      var added = false;
      for (final cell in shapes[cur].cellsAt(origins[cur])) {
        for (final side in Side.values) {
          if (!shapes[cur].openSides.contains(side)) continue;
          final n = cell.step(side);
          if (!_inBounds(n) || owner.containsKey(n)) continue;
          if (origins.length >= target) continue;
          if (rng.nextBool()) continue;

          var shape = RoomShape.oneByOne;
          var origin = n;
          var cells = place(shape, origin, side);
          if (rng.nextDouble() < specialShapeChance) {
            final s = specialShapes[rng.nextInt(specialShapes.length)];
            final fits = [
              for (final o in s.offsets)
                if (place(s, n - o, side) != null) n - o,
            ];
            if (fits.isNotEmpty) {
              shape = s;
              origin = fits[rng.nextInt(fits.length)];
              cells = place(s, origin, side);
            }
          }
          if (cells == null) continue;

          final id = origins.length;
          origins.add(origin);
          shapes.add(shape);
          dist.add(dist[cur] + 1);
          for (final c in cells) {
            owner[c] = id;
          }
          queue.add(id);
          added = true;
        }
      }
      if (!added && cur != 0 && shapes[cur] == RoomShape.oneByOne) {
        deadEnds.add(cur);
      }
    }

    if (origins.length != target || deadEnds.length < 4) return null;

    deadEnds.sort((a, b) {
      final d = dist[b].compareTo(dist[a]);
      return d != 0 ? d : a.compareTo(b);
    });
    final types = List.filled(origins.length, RoomType.normal, growable: true);
    types[0] = RoomType.start;
    types[deadEnds[0]] = RoomType.boss;
    types[deadEnds[1]] = RoomType.superSecret;
    final rest = deadEnds.sublist(2);
    types[rest.removeAt(rng.nextInt(rest.length))] = RoomType.treasure;
    types[rest.removeAt(rng.nextInt(rest.length))] = RoomType.shop;

    final seeds = [for (var i = 0; i < origins.length; i++) rng.nextInt(maxSeed)];
    Set<Door> contactsOf(int id) => {
          for (final d in RoomLayouts.outerSides(shapes[id], origins[id]))
            if (owner[d.cell.step(d.side)] != null) d,
        };
    final blockedSides = [
      for (var i = 0; i < origins.length; i++)
        RoomLayouts.blockedSides(shapes[i], origins[i], seeds[i], contactsOf(i)),
    ];

    bool reachable(GridPos from, Side side) {
      final n = from.step(side);
      final id = owner[n];
      return id != null &&
          shapes[id].openSides.contains(side.opposite) &&
          !blockedSides[id].contains((cell: n, side: side.opposite));
    }

    final nearSpecial = {origins[deadEnds[0]], origins[deadEnds[1]]};
    final candidates = <SecretCandidate>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final p = GridPos(x, y);
        if (owner.containsKey(p)) continue;
        final contacts = Side.values.where((s) => reachable(p, s)).length;
        if (contacts == 0 || p.neighbors.any(nearSpecial.contains)) continue;
        candidates.add(SecretCandidate(
            pos: p, neighbors: contacts, roll: 10 + rng.nextInt(5)));
      }
    }
    if (candidates.isEmpty) return null;
    final secret = candidates.reduce((a, b) => b.weight > a.weight ? b : a).pos;
    final secretDoors = {
      for (final s in Side.clockwise)
        if (reachable(secret, s)) (cell: secret, side: s),
    };
    dist.add(secretDoors
            .map((d) => dist[owner[secret.step(d.side)]!])
            .reduce(min) +
        1);
    owner[secret] = origins.length;
    origins.add(secret);
    shapes.add(RoomShape.oneByOne);
    types.add(RoomType.secret);
    seeds.add(rng.nextInt(maxSeed));
    blockedSides.add(RoomLayouts.blockedSides(
        RoomShape.oneByOne, secret, seeds.last, secretDoors));

    // Extension point: ultra secret room placement goes here.

    Set<Door> doorsOf(int id) => {
          for (final d in contactsOf(id))
            if (!blockedSides[id].contains(d) && reachable(d.cell, d.side)) d,
        };

    final rooms = <RoomSlot>[
      for (var i = 0; i < origins.length; i++)
        RoomSlot(
          id: i,
          origin: origins[i],
          shape: shapes[i],
          type: types[i],
          doors: doorsOf(i),
          blocked: blockedSides[i],
          distance: dist[i],
          seed: seeds[i],
        ),
    ];

    return FloorLayout(
      seed: seed,
      level: level,
      width: width,
      height: height,
      targetRoomCount: target,
      rooms: rooms,
      deadEnds: [for (final d in deadEnds) origins[d]],
      secretCandidates: List.unmodifiable(candidates),
      attempts: attempt,
    );
  }
}
