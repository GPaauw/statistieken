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
  final Map<int, int> _assistByPlayer = {};
  final Map<int, int> _interceptionByPlayer = {};

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
    events.clear();
    _reboundWonByPlayer.clear();
    _reboundLostByPlayer.clear();
    _assistByPlayer.clear();
    _interceptionByPlayer.clear();
    onTick?.call();
  }

  void addHomeGoal(int playerNumber, GoalType type) {
    _addGoal(Team.home, playerNumber, type);
  }

  void addConcededGoal(int playerNumber, GoalType type) {
    _addGoal(Team.away, playerNumber, type);
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

  void addInterception(int playerNumber) {
    _addCountEvent(
      playerNumber,
      PlayerEventType.interception,
      _interceptionByPlayer,
    );
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

    events.add(
      PlayerEvent(
        secondStamp: elapsedSeconds,
        playerNumber: playerNumber,
        type: team == Team.home
            ? PlayerEventType.goalFor
            : PlayerEventType.goalAgainst,
        goalType: type,
      ),
    );

    if (team == Team.home) {
      homeScore++;
    } else {
      awayScore++;
    }
    onTick?.call();
  }

  void _addCountEvent(
    int playerNumber,
    PlayerEventType type,
    Map<int, int> store,
  ) {
    store[playerNumber] = (store[playerNumber] ?? 0) + 1;
    events.add(
      PlayerEvent(
        secondStamp: elapsedSeconds,
        playerNumber: playerNumber,
        type: type,
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
      case PlayerEventType.goalAgainst:
        if (goals.isNotEmpty) {
          goals.removeLast();
        }
        awayScore = (awayScore > 0) ? awayScore - 1 : 0;
      case PlayerEventType.reboundWon:
        _decrement(_reboundWonByPlayer, last.playerNumber);
      case PlayerEventType.reboundLost:
        _decrement(_reboundLostByPlayer, last.playerNumber);
      case PlayerEventType.assist:
        _decrement(_assistByPlayer, last.playerNumber);
      case PlayerEventType.interception:
        _decrement(_interceptionByPlayer, last.playerNumber);
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
