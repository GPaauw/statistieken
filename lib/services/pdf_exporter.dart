import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/match_controller.dart';
import '../models/goal.dart';
import '../models/match_event.dart';
import 'team_names.dart';

class PdfExporter {
  static const double _cardHeight = 330.0;

  static final _good = p.PdfColors.green700;
  static final _average = p.PdfColors.orange700;
  static final _bad = p.PdfColors.red700;
  static final _ink = p.PdfColors.grey900;
  static final _muted = p.PdfColors.grey600;
  static final _panel = p.PdfColors.grey100;
  static final _line = p.PdfColors.grey300;

  static Future<Uint8List> buildReport({
    required MatchController c,
    String? homeTeamName,
    String? awayTeamName,
    DateTime? dateTime,
  }) async {
    final now = dateTime ?? DateTime.now();
    final doc = pw.Document();

    final homeName = homeTeamName ?? TeamNames.homeTeamName;
    final awayName = awayTeamName ?? TeamNames.awayTeamName;

    String fmt2(int value) => value.toString().padLeft(2, '0');
    String fmtTime(int seconds) {
      final minutes = seconds ~/ 60;
      final remainder = seconds % 60;
      return '${fmt2(minutes)}:${fmt2(remainder)}';
    }

    String homePlayerName(Goal goal) =>
        c.homePlayers.getName(goal.playerNumber);

    String actionLabel(Goal goal) =>
        goal.team == Team.home ? 'Doelpunt' : 'Tegen';

    final headerStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: _ink,
    );
    final sectionTitle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: _ink,
    );
    final cell = pw.TextStyle(fontSize: 11, color: _ink);

    final totalMissedShots = c.shotMissedByPlayer.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final totalShots = c.homeScore + totalMissedShots;
    final teamEfficiency = totalShots == 0 ? 0.0 : c.homeScore / totalShots;

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (_) => [
          pw.Text('Wedstrijdverslag', style: headerStyle),
          pw.SizedBox(height: 4),
          pw.Text(
            '${fmt2(now.day)}-${fmt2(now.month)}-${now.year} ${fmt2(now.hour)}:${fmt2(now.minute)}',
            style: pw.TextStyle(color: _muted),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('$homeName vs $awayName', style: sectionTitle),
              pw.Text(
                'Score: ${c.homeScore} - ${c.awayScore}',
                style: sectionTitle,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          if (c.goals.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: _panel,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _line),
              ),
              child: pw.Text(
                'Nog geen doelpuntmomenten geregistreerd.',
                style: pw.TextStyle(color: _muted),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: p.PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: _bad),
              cellStyle: cell,
              headers: [
                'Tijd',
                'Team',
                'Thuisspeler',
                'Actie',
                'Type',
                'Stand',
              ],
              data: () {
                final rows = <List<String>>[];
                var homeScore = 0;
                var awayScore = 0;
                for (final goal in c.goals) {
                  if (goal.team == Team.home) {
                    homeScore++;
                  } else {
                    awayScore++;
                  }
                  rows.add([
                    fmtTime(goal.secondStamp),
                    goal.team == Team.home ? homeName : awayName,
                    homePlayerName(goal),
                    actionLabel(goal),
                    goal.type.label,
                    '$homeScore - $awayScore',
                  ]);
                }
                return rows;
              }(),
              border: null,
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(2.2),
                3: const pw.FlexColumnWidth(1.4),
                4: const pw.FlexColumnWidth(1.8),
                5: const pw.FlexColumnWidth(1),
              },
            ),
          pw.SizedBox(height: 16),
          pw.Text('Samenvatting', style: sectionTitle),
          pw.SizedBox(height: 6),
          pw.Bullet(text: 'Totale speeltijd: ${fmtTime(c.elapsedSeconds)}'),
          pw.Bullet(
            text: 'Totaal geregistreerde acties: ${c.totalEventsCount}',
          ),
          pw.Bullet(text: 'Doelpuntmomenten: ${c.goals.length}'),
          pw.Bullet(
            text:
                'Thuisschoten: $totalShots, doelpunten: ${c.homeScore}, rendement: ${_formatPercent(teamEfficiency)}',
          ),
          pw.Bullet(
            text: '$homeName: ${c.homeScore} | $awayName: ${c.awayScore}',
          ),
        ],
      ),
    );

    final playerNumbers = c.homePlayers.names.keys.toList()..sort();
    for (var index = 0; index < playerNumbers.length; index += 2) {
      final pagePlayers = playerNumbers.skip(index).take(2).toList();
      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text('Spelerssamenvatting ($homeName)', style: headerStyle),
              pw.SizedBox(height: 18),
              for (
                var pageIndex = 0;
                pageIndex < pagePlayers.length;
                pageIndex++
              ) ...[
                pw.SizedBox(
                  height: _cardHeight,
                  child: _playerCard(
                    playerNumber: pagePlayers[pageIndex],
                    playerName: c.homePlayers.getName(pagePlayers[pageIndex]),
                    goalsScored: c.goals
                        .where(
                          (goal) =>
                              goal.team == Team.home &&
                              goal.playerNumber == pagePlayers[pageIndex],
                        )
                        .toList(),
                    goalsConceded: c.goals
                        .where(
                          (goal) =>
                              goal.team == Team.away &&
                              goal.playerNumber == pagePlayers[pageIndex],
                        )
                        .toList(),
                    missedShots: c.events
                        .where(
                          (event) =>
                              event.type == PlayerEventType.shotMissed &&
                              event.playerNumber == pagePlayers[pageIndex],
                        )
                        .toList(),
                    reboundsWon:
                        c.reboundWonByPlayer[pagePlayers[pageIndex]] ?? 0,
                    reboundsLost:
                        c.reboundLostByPlayer[pagePlayers[pageIndex]] ?? 0,
                    assists: c.assistByPlayer[pagePlayers[pageIndex]] ?? 0,
                    interceptions:
                        c.interceptionByPlayer[pagePlayers[pageIndex]] ?? 0,
                  ),
                ),
                if (pageIndex != pagePlayers.length - 1)
                  pw.SizedBox(height: 12),
              ],
            ],
          ),
        ),
      );
    }

    return doc.save();
  }

  static Future<void> shareReport({
    required MatchController c,
    String? homeTeamName,
    String? awayTeamName,
    DateTime? dateTime,
  }) async {
    final now = dateTime ?? DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy').format(now);
    final bytes = await buildReport(
      c: c,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'wedstrijdverslag_$formattedDate.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // Player card
  // ---------------------------------------------------------------------------

  static pw.Widget _playerCard({
    required int playerNumber,
    required String playerName,
    required List<Goal> goalsScored,
    required List<Goal> goalsConceded,
    required List<PlayerEvent> missedShots,
    required int reboundsWon,
    required int reboundsLost,
    required int assists,
    required int interceptions,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: p.PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: _panel,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
              border: pw.Border(bottom: pw.BorderSide(color: _line)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '#$playerNumber  ${playerName.toUpperCase()}',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.Text(
                  'Spelerssamenvatting',
                  style: pw.TextStyle(fontSize: 9, color: _muted),
                ),
              ],
            ),
          ),
          // Body: left (shots) + right (rebounds/assists/interceptions)
          pw.Table(
            border: pw.TableBorder(verticalInside: pw.BorderSide(color: _line)),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  _shotSection(goalsScored, goalsConceded, missedShots),
                  _rightSection(
                    reboundsWon: reboundsWon,
                    reboundsLost: reboundsLost,
                    assists: assists,
                    interceptions: interceptions,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Left section: Doelpunten & schoten table
  // ---------------------------------------------------------------------------

  static pw.Widget _shotSection(
    List<Goal> goalsScored,
    List<Goal> goalsConceded,
    List<PlayerEvent> missedShots,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Table(
        border: pw.TableBorder.all(color: _line, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _panel),
            children: [
              _th('Doelpunten & schoten'),
              _th('Voor'),
              _th('Tegen'),
              _th('Gemist'),
            ],
          ),
          // One row per goal type
          for (final type in GoalType.values)
            pw.TableRow(
              children: [
                _labelCell(type.label),
                _valueCell(
                  goalsScored.where((g) => g.type == type).length,
                  _colorForPositiveCount,
                ),
                _valueCell(
                  goalsConceded.where((g) => g.type == type).length,
                  _colorForConceded,
                ),
                _valueCell(
                  missedShots.where((e) => e.goalType == type).length,
                  _colorForNegativeCount,
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Right section: Rebounds / Assists / Onderscheppingen
  // ---------------------------------------------------------------------------

  static pw.Widget _rightSection({
    required int reboundsWon,
    required int reboundsLost,
    required int assists,
    required int interceptions,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionHeader('Rebounds'),
          pw.SizedBox(height: 4),
          _miniStatRow('Gewonnen', reboundsWon, _colorForPositiveCount),
          _miniStatRow('Verloren', reboundsLost, _colorForNegativeCount),
          pw.SizedBox(height: 12),
          _sectionHeader('Assists'),
          pw.SizedBox(height: 4),
          _miniStatRow('Assists', assists, _colorForSupportCount),
          pw.SizedBox(height: 12),
          _sectionHeader('Onderscheppingen'),
          pw.SizedBox(height: 4),
          _miniStatRow(
            'Onderscheppingen',
            interceptions,
            _colorForSupportCount,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cell helpers
  // ---------------------------------------------------------------------------

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  static pw.Widget _labelCell(String text) {
    return pw.Container(
      color: _panel,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, color: _ink)),
    );
  }

  static pw.Widget _valueCell(int value, p.PdfColor Function(int) colorFn) {
    final color = colorFn(value);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        '$value',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _sectionHeader(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    );
  }

  static pw.Widget _miniStatRow(
    String label,
    int value,
    p.PdfColor Function(int) colorFn,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _muted)),
        pw.Text(
          '$value',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: colorFn(value),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  static String _formatPercent(double value) => '${(value * 100).round()}%';

  // ---------------------------------------------------------------------------
  // Color helpers
  // ---------------------------------------------------------------------------

  static p.PdfColor _colorForPositiveCount(int value) {
    if (value >= 2) return _good;
    if (value == 1) return _average;
    return _muted;
  }

  static p.PdfColor _colorForNegativeCount(int value) {
    if (value == 0) return _good;
    if (value == 1) return _average;
    return _bad;
  }

  static p.PdfColor _colorForSupportCount(int value) {
    if (value >= 2) return _good;
    if (value == 1) return _average;
    return _muted;
  }

  static p.PdfColor _colorForConceded(int value) {
    if (value <= 1) return _good;
    if (value <= 3) return _average;
    return _bad;
  }
}
