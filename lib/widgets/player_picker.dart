// lib/widgets/player_picker.dart
import 'package:flutter/material.dart';
import '../models/goal.dart';

/// Toont een modal waarin je een spelersnummer kiest voor het gegeven team.
Future<void> showTeamPlayerPicker({
  required BuildContext context,
  required Team team,
  required void Function(int playerNumber) onPick,
}) async {
  final isHome = team == Team.home;
  final color = isHome ? Colors.blue.shade600 : Colors.red.shade600;

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHome ? 'Kies scorer (Thuis)' : 'Kies scorer (Uit)',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
            const SizedBox(height: 12),
            // Grid met knoppen #1..#8
            GridView.builder(
              shrinkWrap: true,
              itemCount: 8,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (_, index) {
                final number = index + 1;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.12),
                    foregroundColor: color,
                    side: BorderSide(color: color.withOpacity(0.3)),
                    textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onPick(number);
                  },
                  child: Text('#$number'),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}