import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generator/floor_layout.dart';
import '../generator/layout_generator.dart';
import '../quiz/quiz_controller.dart';
import 'minimap.dart';
import 'palette.dart';
import 'pixel.dart';
import 'sprites.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key, required this.controller, this.onPeek, this.sprites});

  final QuizController controller;
  final void Function(BuildContext context, RoomSlot room)? onPeek;
  final Sprites? sprites;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: CheckerBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 6 : 16),
                  child: PixelPanel(
                    fill: Palette.panel,
                    padding: EdgeInsets.all(compact ? 10 : 18),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          _header(context),
                          const SizedBox(height: 10),
                          _stats(),
                          const SizedBox(height: 10),
                          _prompt(),
                          const SizedBox(height: 10),
                          Expanded(
                            child: PixelPanel(
                              fill: Palette.mapBackground,
                              ring: Palette.mapRing,
                              padding: const EdgeInsets.all(8),
                              child: Minimap(
                                controller: controller,
                                sprites: sprites,
                                onRoomTap:
                                    onPeek == null ? null : (r) => onPeek!(context, r),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (controller.revealed) _legend(),
                          _actions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final c = controller;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'SECRET ROOM TRAINER',
                  style: Palette.font(size: 30, weight: FontWeight.w700)
                      .copyWith(shadows: const [Shadow(offset: Offset(3, 3))]),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: c.level,
                      isDense: true,
                      dropdownColor: Palette.panel,
                      iconEnabledColor: Palette.textDim,
                      style: Palette.font(size: 16, color: Palette.textDim),
                      items: [
                        for (var l = 1; l <= 8; l++)
                          DropdownMenuItem(value: l, child: Text('Level $l')),
                      ],
                      onChanged: (l) => c.newFloor(level: l),
                    ),
                  ),
                  Text('·', style: Palette.font(color: Palette.textDim)),
                  Tooltip(
                    message: 'Copy seed',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '${c.layout.seed}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Seed copied')));
                        },
                        child: Text('Seed ${c.layout.seed}',
                            style: Palette.font(color: Palette.textDim)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PixelIconButton(
          icon: Icons.lightbulb,
          tooltip: c.showHints ? 'Hide hints' : 'Show hints',
          active: c.showHints,
          onPressed: c.toggleHints,
        ),
        const SizedBox(width: 8),
        PixelIconButton(
          icon: Icons.tag,
          tooltip: 'Play a seed',
          onPressed: () => _seedDialog(context),
        ),
      ],
    );
  }

  Widget _stats() {
    final c = controller;
    Widget stat(String label, String value) => Text.rich(TextSpan(children: [
          TextSpan(text: '$label ', style: Palette.font(size: 18)),
          TextSpan(
              text: value,
              style: Palette.font(size: 18, color: Palette.gold, weight: FontWeight.w700)),
        ]));
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          stat('Score', '${c.correct}'),
          stat('Streak', '${c.streak}'),
          stat('Best', '${c.bestStreak}'),
          stat('Acc', c.rounds == 0 ? '-' : '${(c.accuracy * 100).round()}%'),
        ],
      ),
    );
  }

  Widget _prompt() {
    final c = controller;
    final (String text, Color color) = switch (c.phase) {
      QuizPhase.placingSecret => ('Find the SECRET room', Palette.secret),
      QuizPhase.placingSuperSecret => ('Find the SUPER SECRET room', Palette.superSecret),
      QuizPhase.ready => ('Ready! Reveal the answer', Palette.text),
      QuizPhase.revealed => (
          'Secret: ${c.secretCorrect ? 'correct' : 'wrong'}  |  '
              'Super secret: ${c.superCorrect ? 'correct' : 'wrong'}',
          c.secretCorrect && c.superCorrect ? Palette.correct : Palette.text,
        ),
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Palette.font(size: 22, color: color, weight: FontWeight.w600)
          .copyWith(shadows: Palette.shadow),
    );
  }

  Widget _legend() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Each candidate shows adjacent rooms (n) and its weight range; w is the '
        'rolled weight. Highest weight wins (ties: topmost, then leftmost). '
        'Cells next to the boss or super secret room are never candidates. '
        'Tap a room to peek inside.',
        textAlign: TextAlign.center,
        style: Palette.font(size: 14, color: Palette.textDim),
      ),
    );
  }

  Widget _actions() {
    final c = controller;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (!c.revealed)
          PixelButton(label: 'Undo', onPressed: c.canUndo ? c.undo : null),
        if (!c.revealed)
          PixelButton(
            label: 'Reveal',
            primary: true,
            onPressed: c.phase == QuizPhase.ready ? c.reveal : null,
          )
        else
          PixelButton(label: 'Next floor', primary: true, onPressed: () => c.newFloor()),
      ],
    );
  }

  Future<void> _seedDialog(BuildContext context) async {
    final seedCtrl = TextEditingController(text: '${controller.layout.seed}');
    var level = controller.level;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Play a seed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: seedCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Seed'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: level,
                dropdownColor: Palette.panel,
                decoration: const InputDecoration(labelText: 'Level'),
                items: [
                  for (var l = 1; l <= 8; l++)
                    DropdownMenuItem(value: l, child: Text('Level $l')),
                ],
                onChanged: (l) => setState(() => level = l ?? level),
              ),
            ],
          ),
          actions: [
            PixelButton(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
            PixelButton(
              label: 'Play',
              primary: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    final seed = int.tryParse(seedCtrl.text);
    seedCtrl.dispose();
    if (ok == true && seed != null && seed <= LayoutGenerator.maxSeed) {
      controller.newFloor(seed: seed, level: level);
    }
  }
}
