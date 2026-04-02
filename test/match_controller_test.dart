import 'package:flutter_test/flutter_test.dart';

import 'package:Statistieken/controllers/match_controller.dart';
import 'package:Statistieken/models/goal.dart';
import 'package:Statistieken/models/match_event.dart';

void main() {
  group('MatchController', () {
    test('registreert thuisdoelpunt en tegendoelpunt per thuisspeler', () {
      final controller = MatchController();

      controller.addHomeGoal(4, GoalType.penalty);
      controller.addConcededGoal(7, GoalType.freeThrow);

      expect(controller.homeScore, 1);
      expect(controller.awayScore, 1);
      expect(controller.goals, hasLength(2));

      expect(controller.goals.first.team, Team.home);
      expect(controller.goals.first.playerNumber, 4);
      expect(controller.goals.first.type, GoalType.penalty);

      expect(controller.goals.last.team, Team.away);
      expect(controller.goals.last.playerNumber, 7);
      expect(controller.goals.last.type, GoalType.freeThrow);
    });

    test('undo draait laatste geregistreerde moment terug', () {
      final controller = MatchController();

      controller.addHomeGoal(5, GoalType.turnaround);
      controller.addConcededGoal(9, GoalType.longRange7m);

      controller.undo();

      expect(controller.homeScore, 1);
      expect(controller.awayScore, 0);
      expect(controller.goals, hasLength(1));
      expect(controller.goals.single.playerNumber, 5);
    });

    test('registreert extra statistieken en undo werkt voor alle events', () {
      final controller = MatchController();

      controller.addAssist(3);
      controller.addInterception(3);
      controller.addReboundWon(3);
      controller.addReboundLost(3);

      expect(controller.totalEventsCount, 4);
      expect(controller.assistByPlayer[3], 1);
      expect(controller.interceptionByPlayer[3], 1);
      expect(controller.reboundWonByPlayer[3], 1);
      expect(controller.reboundLostByPlayer[3], 1);

      controller.undo();
      controller.undo();

      expect(controller.totalEventsCount, 2);
      expect(controller.assistByPlayer[3], 1);
      expect(controller.interceptionByPlayer[3], 1);
      expect(controller.reboundWonByPlayer[3], isNull);
      expect(controller.reboundLostByPlayer[3], isNull);
    });

    test('registreert gemist schot met type en undo werkt', () {
      final controller = MatchController();

      controller.addMissedShot(6, GoalType.midRange5m);

      expect(controller.totalEventsCount, 1);
      expect(controller.shotMissedByPlayer[6], 1);
      expect(controller.events.single.type, PlayerEventType.shotMissed);
      expect(controller.events.single.goalType, GoalType.midRange5m);

      controller.undo();

      expect(controller.totalEventsCount, 0);
      expect(controller.shotMissedByPlayer[6], isNull);
      expect(controller.events, isEmpty);
    });

    test('tijdlijn-events blijven in invoervolgorde staan', () {
      final controller = MatchController();

      controller.addHomeGoal(4, GoalType.penalty);
      controller.addAssist(4);

      expect(controller.events, hasLength(2));
      expect(controller.events.first.type, PlayerEventType.goalFor);
      expect(controller.events.last.type, PlayerEventType.assist);
      expect(controller.events.first.goalType, GoalType.penalty);
    });
  });
}
