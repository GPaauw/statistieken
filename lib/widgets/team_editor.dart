// lib/widgets/team_editor.dart
import 'package:flutter/material.dart';

import '../models/team.dart';
import '../models/players.dart';
import 'player_name_editor.dart';

Future<Team?> showTeamEditor(BuildContext context, {Team? team}) async {
  final nameCtrl = TextEditingController(text: team?.name ?? '');
  TeamPlayers players = team?.players ?? TeamPlayers.default8();
  int playerCount = players.names.length;

  return showDialog<Team>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(team == null ? 'Nieuw team' : 'Bewerk team'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Naam team', border: OutlineInputBorder()),
                  autofocus: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Spelers: '),
                      DropdownButton<int>(
                        value: playerCount,
                        items: [for (var i = 8; i <= 16; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            playerCount = v;
                            players = _resizePlayers(players, playerCount);
                          });
                        },
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final updated = await showPlayerNameEditor(context, players);
                      if (updated != null) {
                        setState(() {
                          players = updated;
                          playerCount = players.names.length;
                        });
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Bewerk spelers'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuleer')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final abbr = _abbrevFromName(name);

              final updated = team == null
                ? Team.create(name: name, abbreviation: abbr, players: players)
                : Team(id: team.id, name: name, abbreviation: abbr, players: players);

              Navigator.pop(ctx, updated);
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    ),
  );
}

String _abbrevFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
}

TeamPlayers _resizePlayers(TeamPlayers old, int newCount) {
  final updated = <int, String>{};
  for (var i = 1; i <= newCount; i++) {
    if (old.names.containsKey(i)) {
      updated[i] = old.names[i]!;
    } else {
      updated[i] = 'Speler $i';
    }
  }
  return TeamPlayers(names: updated);
}
