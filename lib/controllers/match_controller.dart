// lib/controllers/match_controller.dart

import 'dart:async';

import '../models/goal.dart';
import '../models/match_event.dart';
import '../models/players.dart';

class MatchController {
  // Scores
  int homeScore = 0;
  int awayScore = 0;

  // Doelpuntenlijst
  final List<Goal> goals = [];
  final List<PlayerEvent> events = [];

  final Map<int, int> _reboundWonByPlayer = {};
  final Map<int, int> _reboundLostByPlayer = {};
  final Map<int, int> _shotMissedByPlayer = {};
  final Map<int, int> _assistByPlayer = {};
  final Map<int, int> _interceptionByPlayer = {};

  // Timer
  bool isRunning = false;
  int elapsedSeconds = 0;
  Timer? _timer;

  // Spelersnamen
  TeamPlayers homePlayers = TeamPlayers.default8();

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
    events.clear();
    _reboundWonByPlayer.clear();
    _reboundLostByPlayer.clear();
    _shotMissedByPlayer.clear();
    _assistByPlayer.clear();
    _interceptionByPlayer.clear();
    onTick?.call();
  }

  void addHomeGoal(int playerNumber, GoalType type) {
    _addGoal(GoalSide.home, playerNumber, type);
  }

  void addConcededGoal(int playerNumber, GoalType type) {
    _addGoal(GoalSide.away, playerNumber, type);
  }

  void addReboundWon(int playerNumber) {
    _addCountEvent(
      playerNumber,
      PlayerEventType.reboundWon,
      _reboundWonByPlayer,
    );
  }

  void addReboundLost(int playerNumber) {
    _addCountEvent(
      playerNumber,
      PlayerEventType.reboundLost,
      _reboundLostByPlayer,
    );
  }

  void addAssist(int playerNumber) {
    _addCountEvent(playerNumber, PlayerEventType.assist, _assistByPlayer);
  }

  void addMissedShot(int playerNumber, GoalType type) {
    _addCountEvent(
      playerNumber,
      PlayerEventType.shotMissed,
      _shotMissedByPlayer,
      goalType: type,
    );
  }

  void addInterception(int playerNumber) {
    _addCountEvent(
      playerNumber,
      PlayerEventType.interception,
      _interceptionByPlayer,
    );
  }

  void _addGoal(GoalSide team, int playerNumber, GoalType type) {
    goals.add(
      Goal(
        secondStamp: elapsedSeconds,
        team: team,
        playerNumber: playerNumber,
        type: type,
      ),
    );

    events.add(
      PlayerEvent(
        secondStamp: elapsedSeconds,
        playerNumber: playerNumber,
        type: team == GoalSide.home
            ? PlayerEventType.goalFor
            : PlayerEventType.goalAgainst,
        goalType: type,
      ),
    );

    if (team == GoalSide.home) {
      homeScore++;
    } else {
      awayScore++;
    }
    onTick?.call();
  }

  void _addCountEvent(
    int playerNumber,
    PlayerEventType type,
    Map<int, int> store, {
    GoalType? goalType,
  }) {
    store[playerNumber] = (store[playerNumber] ?? 0) + 1;
    events.add(
      PlayerEvent(
        secondStamp: elapsedSeconds,
        playerNumber: playerNumber,
        type: type,
        goalType: goalType,
      ),
    );
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

  // Undo support over alle geregistreerde events.
  bool get canUndo => events.isNotEmpty;

  Map<int, int> get reboundWonByPlayer => Map.unmodifiable(_reboundWonByPlayer);

  Map<int, int> get reboundLostByPlayer =>
      Map.unmodifiable(_reboundLostByPlayer);

  Map<int, int> get shotMissedByPlayer => Map.unmodifiable(_shotMissedByPlayer);

  Map<int, int> get assistByPlayer => Map.unmodifiable(_assistByPlayer);

  Map<int, int> get interceptionByPlayer =>
      Map.unmodifiable(_interceptionByPlayer);

  int get totalEventsCount => events.length;

  /// Remove the most recent event and update counters accordingly.
  /// If there is no event, this is a no-op.
  void undo() {
    if (events.isEmpty) return;

    final last = events.removeLast();
    switch (last.type) {
      case PlayerEventType.goalFor:
        if (goals.isNotEmpty) {
          goals.removeLast();
        }
        homeScore = (homeScore > 0) ? homeScore - 1 : 0;
        break;
      case PlayerEventType.goalAgainst:
        if (goals.isNotEmpty) {
          goals.removeLast();
        }
        awayScore = (awayScore > 0) ? awayScore - 1 : 0;
        break;
      case PlayerEventType.reboundWon:
        _decrement(_reboundWonByPlayer, last.playerNumber);
        break;
      case PlayerEventType.reboundLost:
        _decrement(_reboundLostByPlayer, last.playerNumber);
        break;
      case PlayerEventType.shotMissed:
        _decrement(_shotMissedByPlayer, last.playerNumber);
        break;
      case PlayerEventType.assist:
        _decrement(_assistByPlayer, last.playerNumber);
        break;
      case PlayerEventType.interception:
        _decrement(_interceptionByPlayer, last.playerNumber);
        break;
    }
    onTick?.call();
  }

  void _decrement(Map<int, int> store, int playerNumber) {
    final current = store[playerNumber] ?? 0;
    if (current <= 1) {
      store.remove(playerNumber);
      return;
    }
    store[playerNumber] = current - 1;
  }
}
