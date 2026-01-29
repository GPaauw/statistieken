// lib/models/goal.dart
import 'package:flutter/foundation.dart';

/// Welke ploeg scoorde.
enum Team { home, away }

/// Een doelpunt met tijdstip (in seconden sinds start), het team en spelersnummer.
@immutable
class Goal {
  final int secondStamp;
  final Team team;
  final int playerNumber; // 🔹 nieuw

  const Goal({
    required this.secondStamp,
    required this.team,
    required this.playerNumber, // 🔹 nieuw
  });

  String get formattedTime {
    final m = (secondStamp ~/ 60).toString().padLeft(2, '0');
    final s = (secondStamp % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get teamLabel => team == Team.home ? 'Thuis' : 'Uit';

  String get playerLabel => '#$playerNumber';
}