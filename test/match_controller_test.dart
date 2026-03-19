import 'package:flutter_test/flutter_test.dart';

import 'package:Statistieken/controllers/match_controller.dart';
import 'package:Statistieken/models/goal.dart';

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
  });
}
