// lib/widgets/team_players_columns.dart
import 'package:flutter/material.dart';
import '../models/players.dart';

/// Twee kolommen met thuisspelers en vier actieknoppen per speler.
class TeamPlayersColumns extends StatelessWidget {
  final TeamPlayers players;
  final void Function(int) onGoalPick;
  final void Function(int) onReboundPick;
  final void Function(int) onAssistPick;
  final void Function(int) onInterceptionPick;

  const TeamPlayersColumns({
    super.key,
    required this.players,
    required this.onGoalPick,
    required this.onReboundPick,
    required this.onAssistPick,
    required this.onInterceptionPick,
  });

  @override
  Widget build(BuildContext context) {
    Widget playerCard(int n) {
      final name = players.getName(n);

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
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                      onPressed: () => onGoalPick(n),
                      icon: const Icon(Icons.sports_soccer, size: 18),
                      label: const Text('Doelpunt'),
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

    final left = List.generate(8, (i) => i + 1);
    final right = List.generate(8, (i) => i + 9);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          final all = List.generate(16, (i) => i + 1);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: all.map(playerCard).toList(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: left.map(playerCard).toList())),
            const SizedBox(width: 12),
            Expanded(child: Column(children: right.map(playerCard).toList())),
          ],
        );
      },
    );
  }
}
