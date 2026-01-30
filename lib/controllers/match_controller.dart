// lib/controllers/match_controller.dart

import 'dart:async';
import '../models/goal.dart';
import '../models/players.dart';

class MatchController {
  int homeScore = 0;
  int awayScore = 0;

  final List<Goal> goals = [];

  bool isRunning = false;
  int elapsedSeconds = 0;
  Timer? _timer;

  TeamPlayers homePlayers = TeamPlayers.default16();
  TeamPlayers awayPlayers = TeamPlayers.default16();

  final void Function()? onTick;

  MatchController({this.onTick});

  void start() {
    if (isRunning) return;
    isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds++;
      onTick?.call();
    });
  }

  void stop() {
    isRunning = false;
    _timer?.cancel();
  }

  void reset() {
    stop();
    homeScore = 0;
    awayScore = 0;
    elapsedSeconds = 0;
    goals.clear();
    onTick?.call();
  }

  void addGoal(Team team, int number, GoalType type) {
    goals.add(Goal(
      secondStamp: elapsedSeconds,
      team: team,
      playerNumber: number,
      type: type,
    ));

    if (team == Team.home) {
      homeScore++;
    } else {
      awayScore++;
    }

    onTick?.call();
  }

  void updateHomePlayers(TeamPlayers players) {
    homePlayers = players;
    onTick?.call();
  }

  void updateAwayPlayers(TeamPlayers players) {
    awayPlayers = players;
    onTick?.call();
  }

  void dispose() {
    _timer?.cancel();
  }
}