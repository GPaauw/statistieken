// lib/widgets/goal_type_picker.dart
import 'package:flutter/material.dart';
import '../models/goal.dart';

Future<GoalType?> showGoalTypePicker(
  BuildContext context, {
  String title = 'Kies schottype',
}) async {
  final types = GoalType.values;

  return showModalBottomSheet<GoalType>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: types
                    .map(
                      (t) => ListTile(
                        title: Text(t.label),
                        onTap: () => Navigator.pop(ctx, t),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
