// lib/models/goal.dart
import 'package:flutter/foundation.dart';

/// Team aanduiding
enum Team { home, away }

/// Type doelpunt
enum GoalType {
  smallChance2m, // Klein kansje 2m
  midRange5m, // Mid range 5m
  longRange7m, // Afstander 7m
  turnaround, // Omdraaibal
  throughBall, // Doorloopbal
  freeThrow, // Vrije bal
  penalty, // Strafworp
}

extension GoalTypeLabel on GoalType {
  String get label {
    switch (this) {
      case GoalType.smallChance2m:
        return "Klein kansje 2m";
      case GoalType.midRange5m:
        return "Mid range 5m";
      case GoalType.longRange7m:
        return "Afstander 7m";
      case GoalType.turnaround:
        return "Omdraaibal";
      case GoalType.throughBall:
        return "Doorloopbal";
      case GoalType.freeThrow:
        return "Vrije bal";
      case GoalType.penalty:
        return "Strafworp";
    }
  }
}

/// Geregistreerd doelpuntmoment met tijd, scorend team, thuisspeler en type.
@immutable
class Goal {
  final int secondStamp;
  final Team team;

  /// Het thuisspelersnummer dat bij dit moment hoort.
  ///
  /// - Bij [Team.home] is dit de speler die scoorde.
  /// - Bij [Team.away] is dit de thuisspeler die het doelpunt tegen kreeg.
  final int playerNumber;
  final GoalType type;

  const Goal({
    required this.secondStamp,
    required this.team,
    required this.playerNumber,
    required this.type,
  });

  bool get isHomeGoal => team == Team.home;

  bool get isAwayGoal => team == Team.away;

  String get formattedTime {
    final m = (secondStamp ~/ 60).toString().padLeft(2, '0');
    final s = (secondStamp % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get teamLabel => isHomeGoal ? "KV Flamingo's" : 'Tegenstanders';
}
