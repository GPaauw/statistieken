// lib/widgets/goal_type_picker.dart
import 'package:flutter/material.dart';
import '../models/goal.dart';

/// Toont een bottom sheet om het type doelpunt te kiezen.
/// Returned de gekozen GoalType of null bij annuleren.
Future<GoalType?> showGoalTypePicker(BuildContext context) async {
  final entries = <(GoalType, IconData, Color)>[
    (GoalType.smallChance2m, Icons.sports_handball, Colors.blueGrey),
    (GoalType.midRange5m,    Icons.timeline,        Colors.indigo),
    (GoalType.longRange7m,   Icons.stacked_line_chart, Colors.deepPurple),
    (GoalType.turnaround,    Icons.sync,            Colors.teal),
    (GoalType.throughBall,   Icons.directions_run,  Colors.green),
    (GoalType.freeThrow,     Icons.flag,            Colors.orange),
    (GoalType.penalty,       Icons.sports,          Colors.red),
  ];

  return showModalBottomSheet<GoalType>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final (type, icon, color) = entries[i];
            return ListTile(
              leading: Icon(icon, color: color),
              title: Text(type.label),
              onTap: () => Navigator.of(ctx).pop(type),
            );
          },
        ),
      );
    },
  );
}