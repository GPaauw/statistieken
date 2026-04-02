import 'package:flutter_test/flutter_test.dart';

import 'package:Statistieken/controllers/match_controller.dart';
import 'package:Statistieken/models/goal.dart';
import 'package:Statistieken/services/pdf_exporter.dart';

void main() {
  test('bouwt pdf met meerdere spelerssamenvattingen zonder fouten', () async {
    final controller = MatchController();

    controller.addHomeGoal(1, GoalType.smallChance2m);
    controller.addHomeGoal(1, GoalType.midRange5m);
    controller.addConcededGoal(1, GoalType.longRange7m);
    controller.addMissedShot(1, GoalType.penalty);
    controller.addReboundWon(1);
    controller.addReboundLost(1);
    controller.addAssist(1);
    controller.addInterception(1);

    controller.addHomeGoal(2, GoalType.penalty);
    controller.addMissedShot(2, GoalType.longRange7m);
    controller.addReboundWon(2);
    controller.addAssist(2);

    final bytes = await PdfExporter.buildReport(
      c: controller,
      homeTeamName: 'KV Flamingo\'s',
      awayTeamName: 'Tegenstander',
      dateTime: DateTime(2026, 4, 2, 19, 30),
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1000));
  });
}
