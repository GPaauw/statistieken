// lib/widgets/goal_type_picker.dart
import 'package:flutter/material.dart';
import '../models/goal.dart';

Future<GoalType?> showGoalTypePicker(BuildContext context) async {
  final types = GoalType.values;

  return showModalBottomSheet<GoalType>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => ListView(
      children: types
          .map((t) => ListTile(
                title: Text(t.label),
                onTap: () => Navigator.pop(ctx, t),
              ))
          .toList(),
    ),
  );
}