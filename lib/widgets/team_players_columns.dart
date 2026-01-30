// lib/widgets/team_players_columns.dart
import 'package:flutter/material.dart';
import '../models/goal.dart';     // Team enum
import '../models/players.dart'; // TeamPlayers (bevat namen per nummer)

/// Toont voor één team twee kolommen met spelerknoppen:
/// - Linker kolom: spelers 1..8
/// - Rechter kolom: spelers 9..16
/// De knoptekst gebruikt de spelernaam i.p.v. "Doelpunt #n".
///
/// Gebruik:
/// TeamPlayersColumns(
///   team: Team.home,
///   players: controller.homePlayers,
///   onPick: (n) => _pickTypeAndAdd(Team.home, n),
///   showGoalCount: true,
///   goalCountsByPlayer: { 3: 2, 7: 1 }, // optioneel
/// )
class TeamPlayersColumns extends StatelessWidget {
  final Team team;
  final TeamPlayers players;

  /// Wordt aangeroepen met het gekozen spelersnummer (1..16).
  final void Function(int playerNumber) onPick;

  /// Toon optioneel een teller achter de naam: "Naam (2)".
  final bool showGoalCount;
  final Map<int, int>? goalCountsByPlayer;

  /// Iets compactere knoppen (kleinere padding/tekst).
  final bool compact;

  const TeamPlayersColumns({
    super.key,
    required this.team,
    required this.players,
    required this.onPick,
    this.showGoalCount = false,
    this.goalCountsByPlayer,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHome = team == Team.home;
    final color = isHome ? Colors.blue.shade600 : Colors.red.shade600;
    final bg = color.withOpacity(0.10);
    final border = color.withOpacity(0.30);

    // Bouw één knop voor een specifiek spelersnummer
    Widget buildButton(int number) {
      final name = players.getName(number);
      final countSuffix = showGoalCount
          ? ' (${(goalCountsByPlayer ?? const {})[number] ?? 0})'
          : '';
      final label = '$name$countSuffix';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Tooltip(
          message: label, // volledige naam bij hover (handig bij lange namen)
          waitDuration: const Duration(milliseconds: 400),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: color,
              side: BorderSide(color: border),
              textStyle: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: compact ? 8 : 12,
              ),
              minimumSize: const Size.fromHeight(40),
            ),
            onPressed: () => onPick(number),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    // Linkerkolom 1..8, rechterkolom 9..16
    final leftNumbers = List<int>.generate(8, (i) => i + 1);
    final rightNumbers = List<int>.generate(8, (i) => i + 9);

    // Kolomhelper
    Widget buildColumn(List<int> numbers) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: numbers.map(buildButton).toList(),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: buildColumn(leftNumbers)),
        const SizedBox(width: 12),
        Expanded(child: buildColumn(rightNumbers)),
      ],
    );
  }
}