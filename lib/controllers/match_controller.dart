// lib/controllers/match_controller.dart
import 'dart:async';
import '../models/goal.dart';

/// Stuurt de wedstrijdlogica aan: timer, scores en goals.
class MatchController {
  // Score
  int homeScore = 0;
  int awayScore = 0;

  // Doelpunten-lijst
  final List<Goal> goals = [];

  // Timer
  bool isRunning = false;
  int elapsedSeconds = 0;
  Timer? _timer;

  /// Wordt aangeroepen bij elke tick of state change (zodat de UI kan updaten).
  final void Function()? onTick;

  MatchController({this.onTick});

  void start() {
    if (isRunning) return;
    isRunning = true;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds++;
      onTick?.call();
    });
    onTick?.call();
  }

  void stop() {
    isRunning = false;
    _timer?.cancel();
    _timer = null;
    onTick?.call();
  }

  void reset() {
    stop();
    elapsedSeconds = 0;
    homeScore = 0;
    awayScore = 0;
    goals.clear();
    onTick?.call();
  }

  /// 🔹 Nieuw: doelpunt toevoegen incl. spelersnummer (1..8)
  void addGoal(Team team, int playerNumber) {
    goals.add(Goal(
      secondStamp: elapsedSeconds,
      team: team,
      playerNumber: playerNumber,
    ));
    if (team == Team.home) {
      homeScore++;
    } else {
      awayScore++;
    }
    onTick?.call();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}