// lib/widgets/team_players_columns.dart
import 'package:flutter/material.dart';
import '../models/players.dart';

/// Twee kolommen met thuisspelers en vier actieknoppen per speler.
class TeamPlayersColumns extends StatelessWidget {
  final TeamPlayers players;
  final void Function(int) onShotPick;
  final void Function(int) onReboundPick;
  final void Function(int) onAssistPick;
  final void Function(int) onInterceptionPick;
  final void Function(TeamPlayers)? onPlayersChanged;

  const TeamPlayersColumns({
    super.key,
    required this.players,
    required this.onShotPick,
    required this.onReboundPick,
    required this.onAssistPick,
    required this.onInterceptionPick,
    this.onPlayersChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget playerCard(int n) {
      final name = players.getName(n);

      Future<void> removePlayer() async {
        if (onPlayersChanged == null) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Verwijderen bevestigen'),
            content: Text(
              'Weet je zeker dat je "${players.getName(n)}" wilt verwijderen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(d).pop(false),
                child: const Text('Nee'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(d).pop(true),
                child: const Text('Ja'),
              ),
            ],
          ),
        );
        if (ok != true) return;

        final ordered = players.names.keys.toList()..sort();
        final namesList = ordered.map((k) => players.names[k]!).toList();
        final idx = n - 1;
        if (idx < 0 || idx >= namesList.length) return;
        namesList.removeAt(idx);
        final updated = <int, String>{};
        for (var i = 0; i < namesList.length; i++) {
          updated[i + 1] = namesList[i];
        }
        onPlayersChanged!(TeamPlayers(names: updated));
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onPlayersChanged != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: removePlayer,
                      tooltip: 'Speler verwijderen',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 140,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => onShotPick(n),
                      icon: const Icon(Icons.sports_soccer, size: 18),
                      label: const Text('Schot'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => onReboundPick(n),
                      icon: const Icon(Icons.sports_basketball, size: 18),
                      label: const Text('Rebound'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => onAssistPick(n),
                      icon: const Icon(Icons.handshake_outlined, size: 18),
                      label: const Text('Assist'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => onInterceptionPick(n),
                      icon: const Icon(Icons.front_hand_outlined, size: 18),
                      label: const Text('Onderschepping'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final total = players.names.length;
    const cols = 2;
    final rows = (total + cols - 1) ~/ cols;

    List<int> rowNumbers(int row) {
      final first = row * cols + 1;
      final second = first + 1;
      final list = <int>[];
      if (first <= total) list.add(first);
      if (second <= total) list.add(second);
      return list;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          final all = List.generate(total, (i) => i + 1);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: all.map(playerCard).toList(),
          );
        }

        final rowWidgets = List<Widget>.generate(rows, (r) {
          final nums = rowNumbers(r);
          return Row(
            children: [
              Expanded(
                child: nums.isNotEmpty
                    ? playerCard(nums[0])
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: nums.length > 1
                    ? playerCard(nums[1])
                    : const SizedBox.shrink(),
              ),
            ],
          );
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rowWidgets,
        );
      },
    );
  }
}
