import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generator/floor_layout.dart';
import '../generator/layout_generator.dart';
import '../quiz/quiz_controller.dart';
import 'minimap.dart';
import 'palette.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key, required this.controller, this.onPeek});

  final QuizController controller;
  final void Function(BuildContext context, RoomSlot room)? onPeek;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
          backgroundColor: Palette.background,
          title: const Text('Secret Room Trainer'),
          actions: [
            IconButton(
              tooltip: controller.showHints ? 'Hide hints' : 'Show hints',
              isSelected: controller.showHints,
              icon: const Icon(Icons.lightbulb_outline),
              selectedIcon: const Icon(Icons.lightbulb, color: Palette.secret),
              onPressed: controller.toggleHints,
            ),
            IconButton(
              tooltip: 'Play a seed',
              icon: const Icon(Icons.tag),
              onPressed: () => _seedDialog(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _statsBar(context),
                    const SizedBox(height: 8),
                    _prompt(context),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Minimap(
                        controller: controller,
                        onRoomTap: onPeek == null ? null : (r) => onPeek!(context, r),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (controller.revealed) _legend(context),
                    _actions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsBar(BuildContext context) {
    final c = controller;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<int>(
          value: c.level,
          isDense: true,
          items: [
            for (var l = 1; l <= 8; l++)
              DropdownMenuItem(value: l, child: Text('Level $l')),
          ],
          onChanged: (l) => c.newFloor(level: l),
        ),
        _chip('Seed', '${c.layout.seed}', onTap: () {
          Clipboard.setData(ClipboardData(text: '${c.layout.seed}'));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Seed copied')));
        }),
        _chip('Score', '${c.correct}'),
        _chip('Streak', '${c.streak}'),
        _chip('Best', '${c.bestStreak}'),
        _chip('Accuracy', c.rounds == 0 ? '-' : '${(c.accuracy * 100).round()}%'),
      ],
    );
  }

  Widget _chip(String label, String value, {VoidCallback? onTap}) {
    final text = Text.rich(TextSpan(children: [
      TextSpan(text: '$label ', style: const TextStyle(color: Colors.white54)),
      TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]));
    if (onTap == null) {
      return Chip(
          label: text, backgroundColor: Palette.mapBackground, side: BorderSide.none);
    }
    return ActionChip(
      onPressed: onTap,
      tooltip: 'Copy seed',
      backgroundColor: Palette.mapBackground,
      side: BorderSide.none,
      label: text,
    );
  }

  Widget _prompt(BuildContext context) {
    final c = controller;
    final (String text, Color color) = switch (c.phase) {
      QuizPhase.placingSecret => ('Tap where the SECRET room is', Palette.secret),
      QuizPhase.placingSuperSecret => (
          'Tap where the SUPER SECRET room is',
          Palette.superSecret
        ),
      QuizPhase.ready => ('Ready - reveal the answer', Colors.white),
      QuizPhase.revealed => (
          'Secret: ${c.secretCorrect ? 'correct' : 'wrong'}  |  '
              'Super secret: ${c.superCorrect ? 'correct' : 'wrong'}',
          c.secretCorrect && c.superCorrect ? Palette.correct : Colors.white,
        ),
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _legend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Each candidate shows adjacent rooms (n) and its weight range; w is the '
        'rolled weight. Highest weight wins. Cells next to the boss or super '
        'secret room are never candidates. Tap a room to peek inside.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
          OutlinedButton.icon(
            onPressed: c.canUndo ? c.undo : null,
            icon: const Icon(Icons.undo),
            label: const Text('Undo'),
          ),
        if (!c.revealed)
          FilledButton.icon(
            onPressed: c.phase == QuizPhase.ready ? c.reveal : null,
            icon: const Icon(Icons.visibility),
            label: const Text('Reveal'),
          )
        else
          FilledButton.icon(
            onPressed: () => c.newFloor(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next floor'),
          ),
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
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Play'),
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
