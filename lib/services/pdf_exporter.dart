import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/match_controller.dart';
import '../models/goal.dart';
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
  static const double _cardBaseWidth = 520.0;
  static const double _cardHeight = 286.0;

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
              pw.SizedBox(height: 4),
              pw.Text(
                'Kleuren per statistiek op basis van de waarde.',
                style: pw.TextStyle(color: _muted, fontSize: 10),
              ),
              pw.SizedBox(height: 14),
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
                    cardWidth: _cardBaseWidth,
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
    required double cardWidth,
  }) {
    final totalShots = goalsScored.length + missedShots.length;
    final efficiency = totalShots == 0 ? 0.0 : goalsScored.length / totalShots;
    final netScore = goalsScored.length - goalsConceded.length;
    final reboundBalance = reboundsWon - reboundsLost;
    final teamPlay = assists + interceptions + reboundsWon;

    final finishingScore = _scoreForEfficiency(efficiency);
    final defenseScore = _scoreForConceded(goalsConceded.length);
    final teamPlayScore = _scoreForTeamPlay(teamPlay);
    final overallScore = (finishingScore + defenseScore + teamPlayScore) / 3;
    final statusColor = _colorForScore(overallScore);
    final statusLabel = _labelForScore(overallScore);

    return pw.Container(
      width: cardWidth,
      height: _cardHeight,
      decoration: pw.BoxDecoration(
        color: p.PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            height: 8,
            decoration: pw.BoxDecoration(
              color: statusColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(12),
                topRight: pw.Radius.circular(12),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '#$playerNumber  ${playerName.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Spelerskaart',
                          style: pw.TextStyle(fontSize: 8, color: _muted),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _softFill(statusColor),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        statusLabel,
                        style: pw.TextStyle(
                          color: statusColor,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                _statsTable([
                  _PlayerStatRow(
                    leftLabel: 'Doelpunt voor',
                    leftValue: '${goalsScored.length}',
                    leftAccent: _colorForPositiveCount(goalsScored.length),
                    rightLabel: 'Schot gemist',
                    rightValue: '${missedShots.length}',
                    rightAccent: _colorForNegativeCount(missedShots.length),
                  ),
                  _PlayerStatRow(
                    leftLabel: 'Doelpunt tegen',
                    leftValue: '${goalsConceded.length}',
                    leftAccent: _colorForConceded(goalsConceded.length),
                    rightLabel: 'Rendement',
                    rightValue: _formatPercent(efficiency),
                    rightAccent: _colorForScore(finishingScore),
                  ),
                  _PlayerStatRow(
                    leftLabel: 'Rebounds',
                    leftValue: '$reboundsWon / $reboundsLost',
                    leftAccent: _colorForNet(reboundBalance),
                    rightLabel: 'Assist',
                    rightValue: '$assists',
                    rightAccent: _colorForSupportCount(assists),
                  ),
                  _PlayerStatRow(
                    leftLabel: 'Onderschepping',
                    leftValue: '$interceptions',
                    leftAccent: _colorForSupportCount(interceptions),
                    rightLabel: 'Netto',
                    rightValue: _signed(netScore),
                    rightAccent: _colorForNet(netScore),
                  ),
                ]),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Afwerking: ${_labelForScore(finishingScore)} | Verdediging: ${_labelForScore(defenseScore)} | Teamplay: ${_labelForScore(teamPlayScore)}',
                  style: pw.TextStyle(fontSize: 8, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _statsTable(List<_PlayerStatRow> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.0),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(2.0),
        3: const pw.FlexColumnWidth(1.2),
      },
      children: rows
          .map(
            (row) => pw.TableRow(
              children: [
                _statsCell(row.leftLabel, accent: row.leftAccent, shaded: true),
                _statsCell(row.leftValue, accent: row.leftAccent),
                _statsCell(
                  row.rightLabel,
                  accent: row.rightAccent,
                  shaded: true,
                ),
                _statsCell(row.rightValue, accent: row.rightAccent),
              ],
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _statsCell(
    String text, {
    required p.PdfColor accent,
    bool shaded = false,
  }) {
    return pw.Container(
      color: shaded ? _softFill(accent) : p.PdfColors.white,
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          color: shaded ? accent : _ink,
          fontWeight: shaded ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _formatPercent(double value) => '${(value * 100).round()}%';

  static String _signed(int value) => value > 0 ? '+$value' : '$value';

  static double _scoreForEfficiency(double value) {
    if (value >= 0.60) return 1.0;
    if (value >= 0.35) return 0.55;
    return 0.15;
  }

  static double _scoreForConceded(int value) {
    if (value <= 1) return 1.0;
    if (value <= 3) return 0.55;
    return 0.15;
  }

  static double _scoreForTeamPlay(int value) {
    if (value >= 5) return 1.0;
    if (value >= 2) return 0.55;
    return 0.15;
  }

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

  static p.PdfColor _colorForScore(double score) {
    if (score >= 0.67) return _good;
    if (score >= 0.34) return _average;
    return _bad;
  }

  static p.PdfColor _colorForNet(int value) {
    if (value > 0) return _good;
    if (value == 0) return _average;
    return _bad;
  }

  static p.PdfColor _colorForConceded(int value) {
    if (value <= 1) return _good;
    if (value <= 3) return _average;
    return _bad;
  }

  static String _labelForScore(double score) {
    if (score >= 0.67) return 'GOED';
    if (score >= 0.34) return 'GEMIDDELD';
    return 'AANDACHT';
  }

  static p.PdfColor _softFill(p.PdfColor color) {
    return p.PdfColor(
      color.red + (1 - color.red) * 0.86,
      color.green + (1 - color.green) * 0.86,
      color.blue + (1 - color.blue) * 0.86,
    );
  }
}

class _PlayerStatRow {
  const _PlayerStatRow({
    required this.leftLabel,
    required this.leftValue,
    required this.leftAccent,
    required this.rightLabel,
    required this.rightValue,
    required this.rightAccent,
  });

  final String leftLabel;
  final String leftValue;
  final p.PdfColor leftAccent;
  final String rightLabel;
  final String rightValue;
  final p.PdfColor rightAccent;
}
