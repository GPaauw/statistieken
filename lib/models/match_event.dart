import 'package:flutter/foundation.dart';

import 'goal.dart';

enum PlayerEventType {
  goalFor,
  goalAgainst,
  shotMissed,
  reboundWon,
  reboundLost,
  assist,
  interception,
  timeoutAdded,
  timeoutRemoved,
  substitutionAdded,
  substitutionRemoved,
}

@immutable
class PlayerEvent {
  final int secondStamp;
  final int playerNumber;
  final PlayerEventType type;
  final int? relatedPlayerNumber;
  final GoalType? goalType;

  const PlayerEvent({
    required this.secondStamp,
    required this.playerNumber,
    required this.type,
    this.relatedPlayerNumber,
    this.goalType,
  });

  bool get isGoal =>
      type == PlayerEventType.goalFor || type == PlayerEventType.goalAgainst;

  bool get isShot =>
      type == PlayerEventType.goalFor || type == PlayerEventType.shotMissed;

  String get formattedTime {
    final m = (secondStamp ~/ 60).toString().padLeft(2, '0');
    final s = (secondStamp % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
