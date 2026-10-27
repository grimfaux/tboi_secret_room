import 'geometry.dart';
import 'room_shape.dart';

class RoomSlot {
  const RoomSlot({
    required this.id,
    required this.origin,
    required this.shape,
    required this.type,
    required this.doors,
    required this.distance,
    required this.seed,
  });

  final int id;
  final GridPos origin;
  final RoomShape shape;
  final RoomType type;
  final Set<Door> doors;
  final int distance;
  final int seed;

  List<GridPos> get cells => shape.cellsAt(origin);

  Set<Door> get relativeDoors =>
      {for (final d in doors) (cell: d.cell - origin, side: d.side)};

  bool isOpen(Side side) => shape.openSides.contains(side);
}

class SecretCandidate {
  const SecretCandidate({
    required this.pos,
    required this.neighbors,
    required this.roll,
  });

  final GridPos pos;
  final int neighbors;
  final int roll;

  static int penaltyFor(int neighbors) => switch (neighbors) {
        1 => 6,
        2 => 3,
        _ => 0,
      };

  int get penalty => penaltyFor(neighbors);
  int get weight => roll - penalty;
  int get minWeight => 10 - penalty;
  int get maxWeight => 14 - penalty;
}

class FloorLayout {
  FloorLayout({
    required this.seed,
    required this.level,
    required this.width,
    required this.height,
    required this.targetRoomCount,
    required this.rooms,
    required this.deadEnds,
    required this.secretCandidates,
    required this.attempts,
  }) : _byCell = {
          for (final r in rooms)
            for (final c in r.cells) c: r,
        };

  final int seed;
  final int level;
  final int width;
  final int height;
  final int targetRoomCount;
  final List<RoomSlot> rooms;
  final List<GridPos> deadEnds;
  final List<SecretCandidate> secretCandidates;
  final int attempts;
  final Map<GridPos, RoomSlot> _byCell;

  RoomSlot? roomAt(GridPos p) => _byCell[p];

  RoomSlot ofType(RoomType type) => rooms.firstWhere((r) => r.type == type);

  bool inBounds(GridPos p) => p.x >= 0 && p.y >= 0 && p.x < width && p.y < height;
}
