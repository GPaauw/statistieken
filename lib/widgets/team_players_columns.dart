// lib/widgets/team_players_columns.dart
import 'package:flutter/material.dart';
import '../models/players.dart';

/// Twee kolommen met thuisspelers en acties voor doelpunten en tegendoelpunten.
class TeamPlayersColumns extends StatelessWidget {
  final TeamPlayers players;
  final void Function(int) onScoredPick;
  final void Function(int) onConcededPick;
  final Map<int, int>? scoredCountsByPlayer;
  final Map<int, int>? concededCountsByPlayer;

  const TeamPlayersColumns({
    super.key,
    required this.players,
    required this.onScoredPick,
    required this.onConcededPick,
    this.scoredCountsByPlayer,
    this.concededCountsByPlayer,
  });

  @override
  Widget build(BuildContext context) {
    Widget playerCard(int n) {
      final name = players.getName(n);
      final scored = scoredCountsByPlayer?[n] ?? 0;
      final conceded = concededCountsByPlayer?[n] ?? 0;

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
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => onScoredPick(n),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text('Doelpunt $scored'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => onConcededPick(n),
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: Text('Tegen $conceded'),
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
