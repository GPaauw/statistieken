// lib/widgets/conceded_player_picker.dart
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/players.dart';

/// Kies uit het verdedigende team wie de goal tegen kreeg.
/// Returnt het spelersnummer (1..16) of null bij annuleren.
Future<int?> showConcededPlayerPicker({
  required BuildContext context,
  required Team defendingTeam,
  required TeamPlayers players,
}) async {
  final isHome = defendingTeam == Team.home;
  final color = isHome ? Colors.blue.shade600 : Colors.red.shade600;

  final numbers = List.generate(16, (i) => i + 1);

  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Wie kreeg het doelpunt tegen?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          for (final n in numbers)
            ListTile(
              leading: Icon(Icons.person, color: color),
              title: Text(players.getName(n)),
              onTap: () => Navigator.pop(ctx, n),
            ),
        ],
      );
    },
  );
}