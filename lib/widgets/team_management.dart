// lib/widgets/team_management.dart
import 'package:flutter/material.dart';

import '../services/team_names.dart';
import 'team_editor.dart';

Future<void> showManageTeamsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx2, setStateDialog) {
        final teams = TeamNames.teams;

        return AlertDialog(
          title: const Text('Beheer teams'),
          content: SizedBox(
            width: 420,
            child: teams.isEmpty
                ? const Text('Geen teams gevonden')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: teams.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx3, index) {
                      final t = teams[index];
                      return ListTile(
                        leading: CircleAvatar(child: Icon(Icons.checkroom, size: 18)),
                        title: Text(t.name),
                        subtitle: Text('${t.players.names.length} spelers'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final updated = await showTeamEditor(context, team: t);
                                if (updated != null) {
                                  await TeamNames.updateTeam(updated);
                                  setStateDialog(() {});
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final sure = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Verwijderen'),
                                    content: Text('Weet je zeker dat je "${t.name}" wilt verwijderen?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Nee')),
                                      ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ja')),
                                    ],
                                  ),
                                );

                                if (sure == true) {
                                  await TeamNames.deleteTeam(t.id);
                                  setStateDialog(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Sluiten')),
            ElevatedButton(
              onPressed: () async {
                final created = await showTeamEditor(context);
                if (created != null) {
                  await TeamNames.addTeam(created);
                  setStateDialog(() {});
                }
              },
              child: const Text('Nieuw team'),
            ),
          ],
        );
      });
    },
  );
}
