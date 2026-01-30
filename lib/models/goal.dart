// lib/models/goal.dart
import 'package:flutter/foundation.dart';

/// Team
enum Team { home, away }

/// Type doelpunt
enum GoalType {
  smallChance2m, // Klein kansje 2m
  midRange5m,    // Mid range 5m
  longRange7m,   // Afstander 7m
  turnaround,    // Omdraaibal
  throughBall,   // Doorloopbal
  freeThrow,     // Vrije bal
  penalty,       // Strafworp
}

extension GoalTypeX on GoalType {
  String get label {
    switch (this) {
      case GoalType.smallChance2m: return 'Klein kansje 2m';
      case GoalType.midRange5m:    return 'Mid range 5m';
      case GoalType.longRange7m:   return 'Afstander 7m';
      case GoalType.turnaround:    return 'Omdraaibal';
      case GoalType.throughBall:   return 'Doorloopbal';
      case GoalType.freeThrow:     return 'Vrije bal';
      case GoalType.penalty:       return 'Strafworp';
    }
  }
}

/// Een doelpunt met tijdstip, team, speler en type.
@immutable
class Goal {
  final int secondStamp;
  final Team team;
  final int playerNumber;
  final GoalType type; // 🔹 nieuw

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

  String get teamLabel => team == Team.home ? 'Thuis' : 'Uit';
  String get playerLabel => '#$playerNumber';
}