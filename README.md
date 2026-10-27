# Secret Room Trainer

A quiz game: every round generates a random Binding of Isaac–style floor and you guess where the secret room and super secret room are.

This is a simplified fan-made approximation of the floor generation, not the original code. It uses no game assets.

## Running

```bash
flutter pub get
flutter run -d chrome
```

Build for web (output in `build/web`):

```bash
flutter build web
```

It also runs on Android/iOS with `flutter run`.

Tests:

```bash
flutter test
```

## How to play

- Tap an empty cell next to a room to place your **secret room** guess, then a second one for the **super secret room**. Tap a guess again or use Undo to remove it.
- **Reveal** shows the real rooms. Every secret room candidate shows its adjacent room count (`n`), its weight range, and the weight it rolled (`w`).
- After revealing, tap any room to peek at its filled layout.
- The lightbulb toggles hints (adjacent visible room count on every empty cell). The `#` button replays a floor from a seed and level; tap the seed chip to copy it.
- Score is +1 per correct room. The streak counts consecutive correct rooms; the best streak is saved locally.

## Generation

All generation code is pure Dart in `lib/generator/` and is fully reproducible from `(seed, level)`.

**Phase 1: layout** (`layout_generator.dart`) builds the floor as abstract boxes (`RoomSlot`s) on a 9×8 grid, starting at (4,3):

1. Target room count = `min(20, rand(0..1) + 5 + floor(level * 10 / 3))`.
2. Breadth-first growth from the start room, room by room. For every cell and open side of a dequeued room, the neighboring cell is skipped if it is already taken, the target is reached, or a 50% roll fails. Otherwise a new room grows there: 1×1 by default, or with a 25% chance a random other shape (narrow, long, long narrow, 2×2 or L), placed so that it covers that cell. A room is only placed if it touches the existing rooms at exactly one spot, so the layout stays a tree. A dequeued 1×1 room that adds nothing is a dead end.
3. The floor is discarded and regenerated unless it hits the target exactly and has at least 4 dead ends.
4. Dead ends sorted by distance: farthest is the boss, second farthest the super secret room, then two random others become treasure and shop. Special rooms are always 1×1.
5. Secret room: every empty cell that touches a room through an open side, and is not next to the boss or super secret room, is a candidate with weight `rand(10..14)`, minus 3 with exactly 2 such contacts, minus 6 with exactly 1. The highest weight wins (ties go to the first cell in row order).

Doors are stored per cell. Narrow rooms only open on their long sides, so nothing connects through their closed sides. Each slot gets its own seed from the floor RNG. Ultra secret room placement has a marked extension point.

The minimap tile for each cell of a shape is picked from which of its neighbors belong to the same room (`RoomShape.tileFor`), using the images in `assets/tiles/`.

**Phase 2: fill** (`room_filler.dart`) picks a pre-made layout for each slot from `assets/rooms/templates.json`: same shape and room type, with openings on all of the slot's doors, weighted random using the room's own seed. If nothing matches, it uses an empty room of that shape. Only 1×1 templates exist so far, so other shapes always use the empty room. Template doors are side names (`"left"`) for 1×1 rooms, or `"x,y,side"` for a door on a specific cell. Tile legend: `.` floor, `#` wall, `r` rock, `p` pit, `i` item, `$` shop item, `b` boss.

## State management

A single `ChangeNotifier` (`QuizController`) with `ListenableBuilder`, no extra packages. Best streak is stored with `shared_preferences`.
