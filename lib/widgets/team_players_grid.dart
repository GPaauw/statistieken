// lib/widgets/team_players_grid.dart
import 'package:flutter/material.dart';
import '../models/goal.dart';

/// Grid met spelerknoppen voor één team.
/// - playerCount: aantal spelers (standaard 26)
/// - columns: aantal kolommen (standaard 8)
/// - visibleRows: aantal zichtbare rijen (scrollt voor de rest; standaard 2)
class TeamPlayersGrid extends StatelessWidget {
  final Team team;
  final int playerCount;
  final int columns;
  final int visibleRows;
  final void Function(int playerNumber) onPick;
  final bool showGoalCount;
  final Map<int, int>? goalCountsByPlayer; // optioneel teller per speler

  const TeamPlayersGrid({
    super.key,
    required this.team,
    required this.onPick,
    this.playerCount = 26,
    this.columns = 8,
    this.visibleRows = 2,
    this.showGoalCount = false,
    this.goalCountsByPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final isHome = team == Team.home;
    final color = isHome ? Colors.blue.shade600 : Colors.red.shade600;

    // Esthetisch: verhouding voor brede, niet te hoge knoppen.
    const childAspectRatio = 2.4; // hoger = platter; pas naar smaak aan
    // Hoogte per rij (schatting): maak zichtbare hoogte voor 'visibleRows'.
    final rowHeight = 52.0; // ongeveer; afhankelijk van text/padding
    final gridHeight = visibleRows * (rowHeight + 12); // + spacing marge

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grid in fixed height met scroll voor de overige rijen.
        SizedBox(
          height: gridHeight,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: playerCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
            ),
            physics: const ClampingScrollPhysics(),
            itemBuilder: (context, index) {
              final number = index + 1;
              final labelCount = showGoalCount
                  ? ' (${(goalCountsByPlayer ?? const {})[number] ?? 0})'
                  : '';
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withOpacity(0.10),
                  foregroundColor: color,
                  side: BorderSide(color: color.withOpacity(0.30)),
                  textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                onPressed: () => onPick(number),
                child: Text('Doelpunt #$number$labelCount'),
              );
            },
          ),
        ),
      ],
    );
  }
}