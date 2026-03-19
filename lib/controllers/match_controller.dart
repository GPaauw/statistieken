// lib/controllers/match_controller.dart

import 'dart:async';
import '../models/goal.dart';
import '../models/players.dart';

class MatchController {
  // Scores
  int homeScore = 0;
  int awayScore = 0;

  // Doelpuntenlijst
  final List<Goal> goals = [];

  // Timer
  bool isRunning = false;
  int elapsedSeconds = 0;
  Timer? _timer;

  // Spelersnamen
  TeamPlayers homePlayers = TeamPlayers.default16();

  // UI callback
  final void Function()? onTick;

  MatchController({this.onTick});

  // Timer
  void start() {
    if (isRunning) return;
    isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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

  void addHomeGoal(int playerNumber, GoalType type) {
    _addGoal(Team.home, playerNumber, type);
  }

  void addConcededGoal(int playerNumber, GoalType type) {
    _addGoal(Team.away, playerNumber, type);
  }

  void _addGoal(Team team, int playerNumber, GoalType type) {
    goals.add(
      Goal(
        secondStamp: elapsedSeconds,
        team: team,
        playerNumber: playerNumber,
        type: type,
      ),
    );

    if (team == Team.home) {
      homeScore++;
    } else {
      awayScore++;
    }
    onTick?.call();
  }

  // Spelers updaten
  void updateHomePlayers(TeamPlayers players) {
    homePlayers = players;
    onTick?.call();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  // Undo support: canUndo == there is at least one goal to remove
  bool get canUndo => goals.isNotEmpty;

  /// Remove the most recent goal and update scores accordingly.
  /// If there is no goal, this is a no-op.
  void undo() {
    if (goals.isEmpty) return;
    final last = goals.removeLast();
    if (last.team == Team.home) {
      homeScore = (homeScore > 0) ? homeScore - 1 : 0;
    } else {
      awayScore = (awayScore > 0) ? awayScore - 1 : 0;
    }
    onTick?.call();
  }
}
