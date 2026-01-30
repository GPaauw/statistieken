// lib/widgets/player_name_editor.dart

import 'package:flutter/material.dart';
import '../models/players.dart';

Future<TeamPlayers?> showPlayerNameEditor(
  BuildContext context,
  TeamPlayers players,
) async {
  final ctrls = {
    for (final e in players.names.entries)
      e.key: TextEditingController(text: e.value),
  };

  return showDialog<TeamPlayers>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Spelersnames aanpassen"),
      content: SizedBox(
        width: 400,
        child: ListView(
          shrinkWrap: true,
          children: players.names.keys
              .map((k) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextField(
                      controller: ctrls[k],
                      decoration: InputDecoration(
                        labelText: "Speler $k",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ))
              .toList(),
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
              for (final e in ctrls.entries)
                e.key: e.value.text.trim().isEmpty
                    ? "Speler ${e.key}"
                    : e.value.text.trim()
            };
            Navigator.pop(context, TeamPlayers(names: updated));
          },
          child: const Text("Opslaan"),
        ),
      ],
    ),
  );
}