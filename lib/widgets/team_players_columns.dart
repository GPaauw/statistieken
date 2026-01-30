// lib/widgets/team_players_columns.dart

import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/players.dart';

class TeamPlayersColumns extends StatelessWidget {
  final Team team;
  final TeamPlayers players;
  final void Function(int) onPick;
  final bool showGoalCount;
  final Map<int, int>? goalCountsByPlayer;

  const TeamPlayersColumns({
    super.key,
    required this.team,
    required this.players,
    required this.onPick,
    this.showGoalCount = false,
    this.goalCountsByPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final color = team == Team.home ? Colors.blue : Colors.red;

    Widget button(int n) {
      final name = players.getName(n);
      final count =
          showGoalCount ? " (${goalCountsByPlayer?[n] ?? 0})" : "";

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(.15),
            foregroundColor: color,
          ),
          onPressed: () => onPick(n),
          child: Text("$name$count"),
        ),
      );
    }

    final left = List.generate(8, (i) => i + 1);
    final right = List.generate(8, (i) => i + 9);

    return Row(
      children: [
        Expanded(child: Column(children: left.map(button).toList())),
        const SizedBox(width: 16),
        Expanded(child: Column(children: right.map(button).toList())),
      ],
    );
  }
}