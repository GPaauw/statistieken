// lib/widgets/player_name_editor.dart
import 'package:flutter/material.dart';
import '../models/players.dart';

Future<TeamPlayers?> showPlayerNameEditor(
  BuildContext context,
  TeamPlayers players,
) async {
  final controllers = {
    for (final entry in players.names.entries)
      entry.key: TextEditingController(text: entry.value)
  };

  return showDialog<TeamPlayers>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Spelersnamen aanpassen"),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: players.names.keys.map((k) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: controllers[k],
                  decoration: InputDecoration(
                    labelText: 'Speler $k',
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuleren"),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = {
                for (final entry in controllers.entries)
                  entry.key: entry.value.text.trim().isEmpty
                      ? "Speler ${entry.key}"
                      : entry.value.text.trim()
              };
              Navigator.pop(context, TeamPlayers(names: updated));
            },
            child: const Text("Opslaan"),
          ),
        ],
      );
    },
  );
}