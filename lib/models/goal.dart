// lib/models/goal.dart
import 'package:flutter/foundation.dart';

enum Team { home, away }

enum GoalType {
  smallChance2m,
  midRange5m,
  longRange7m,
  turnaround,
  throughBall,
  freeThrow,
  penalty,
}

extension GoalTypeLabel on GoalType {
  String get label {
    switch (this) {
      case GoalType.smallChance2m: return "Klein kansje 2m";
      case GoalType.midRange5m:    return "Mid range 5m";
      case GoalType.longRange7m:   return "Afstander 7m";
      case GoalType.turnaround:    return "Omdraaibal";
      case GoalType.throughBall:   return "Doorloopbal";
      case GoalType.freeThrow:     return "Vrije bal";
      case GoalType.penalty:       return "Strafworp";
    }
  }
}

@immutable
class Goal {
  final int secondStamp;
  final Team team;
  final int playerNumber;
  final GoalType type;

  const Goal({
    required this.secondStamp,
    required this.team,
    required this.playerNumber,
    required this.type,
  });

  String get formattedTime {
    final m = (secondStamp ~/ 60).toString().padLeft(2, '0');
    final s = (secondStamp % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get teamLabel => team == Team.home ? "Thuis" : "Uit";
}