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

  // Timeouts en wissels
  int timeoutsUsed = 0;
  int substitutionsUsed = 0;

  // Spelersnamen
  TeamPlayers homePlayers = TeamPlayers.default8();
  // Welke spelers staan momenteel op het veld (spelernummers)
  final Set<int> _onCourt = {};

  // UI callback
  final void Function()? onTick;

  MatchController({this.onTick}) {
    // init onCourt met de eerste spelers uit de lijst (bijv. 5 spelers of minder)
    final nums = homePlayers.players.map((p) => p.number).toList()..sort();
    final takeCount = nums.length >= 5 ? 5 : nums.length;
    _onCourt.addAll(nums.take(takeCount));
  }

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
    timeoutsUsed = 0;
    substitutionsUsed = 0;
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
    // Zorg dat onCourt consistent blijft met nieuwe spelerslijst.
    final nums = homePlayers.players.map((p) => p.number).toSet();
    _onCourt.retainAll(nums);
    if (_onCourt.isEmpty) {
      final ordered = nums.toList()..sort();
      final takeCount = ordered.length >= 5 ? 5 : ordered.length;
      _onCourt.addAll(ordered.take(takeCount));
    }
    onTick?.call();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  // Timeouts en wissels beheren
  void useTimeout() {
    timeoutsUsed++;
    events.add(
      PlayerEvent(
        secondStamp: elapsedSeconds,
        playerNumber: 0,
        type: PlayerEventType.timeoutAdded,
      ),
    );
    onTick?.call();
  }

  void unuseTimeout() {
    if (timeoutsUsed > 0) {
      // Reduce counter and remove the most recent timeoutAdded event from the timeline
      timeoutsUsed--;
      for (var i = events.length - 1; i >= 0; i--) {
        if (events[i].type == PlayerEventType.timeoutAdded) {
          events.removeAt(i);
          break;
        }
      }
      onTick?.call();
    }
  }

  void addSubstitution(int outPlayerNumber, int inPlayerNumber) {
    substitutionsUsed++;
    events.add(
      PlayerEvent(
        secondStamp: elapsedSeconds,
        playerNumber: outPlayerNumber,
        relatedPlayerNumber: inPlayerNumber,
        type: PlayerEventType.substitutionAdded,
      ),
    );
    // Werk onCourt bij: haal eruit, voeg erin toe
    if (_onCourt.contains(outPlayerNumber)) {
      _onCourt.remove(outPlayerNumber);
    }
    _onCourt.add(inPlayerNumber);
    onTick?.call();
  }

  /// Check of een speler momenteel op het veld staat
  bool isOnCourt(int playerNumber) => _onCourt.contains(playerNumber);

  /// Geef een onveranderlijke lijst van spelernummers die op het veld staan
  List<int> get onCourtPlayers => List.unmodifiable(_onCourt.toList()..sort());

  void removeSubstitution() {
    if (substitutionsUsed > 0) {
      // Reduce counter and remove the most recent substitutionAdded event from the timeline
      substitutionsUsed--;
      for (var i = events.length - 1; i >= 0; i--) {
        if (events[i].type == PlayerEventType.substitutionAdded) {
          events.removeAt(i);
          break;
        }
      }
      onTick?.call();
    }
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
      case PlayerEventType.timeoutAdded:
        timeoutsUsed = (timeoutsUsed > 0) ? timeoutsUsed - 1 : 0;
        break;
      case PlayerEventType.timeoutRemoved:
        timeoutsUsed++;
        break;
      case PlayerEventType.substitutionAdded:
        substitutionsUsed = (substitutionsUsed > 0) ? substitutionsUsed - 1 : 0;
        break;
      case PlayerEventType.substitutionRemoved:
        substitutionsUsed++;
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
