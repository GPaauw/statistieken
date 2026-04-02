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
    for (var index = 0; index < playerNumbers.length; index += 1) {
      final pagePlayers = playerNumbers.skip(index).take(1).toList();
      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text('Spelerssamenvatting ($homeName)', style: headerStyle),
              pw.SizedBox(height: 4),
              pw.Text(
                'Sportief profiel met aantallen, rendement en statuskleur.',
                style: pw.TextStyle(color: _muted, fontSize: 10),
              ),
              pw.SizedBox(height: 14),
              for (
                var pageIndex = 0;
                pageIndex < pagePlayers.length;
                pageIndex++
              ) ...[
                _playerCard(
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

    final buckets = _buildShotBuckets(goalsScored, missedShots);

    return pw.Container(
      width: cardWidth,
      decoration: pw.BoxDecoration(
        color: p.PdfColors.white,
        borderRadius: pw.BorderRadius.circular(16),
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
                topLeft: pw.Radius.circular(16),
                topRight: pw.Radius.circular(16),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _softFill(statusColor),
                        borderRadius: pw.BorderRadius.circular(999),
                      ),
                      child: pw.Text(
                        '#$playerNumber',
                        style: pw.TextStyle(
                          color: statusColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            playerName.toUpperCase(),
                            maxLines: 1,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: _ink,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Spelerskaart',
                            style: pw.TextStyle(fontSize: 10, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        borderRadius: pw.BorderRadius.circular(999),
                      ),
                      child: pw.Text(
                        statusLabel,
                        style: pw.TextStyle(
                          color: p.PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _metricTile(
                        label: 'Schoten',
                        value: '$totalShots',
                        detail:
                            '${goalsScored.length} doelpunt / ${missedShots.length} gemist',
                        accent: totalShots == 0 ? _muted : _average,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _metricTile(
                        label: 'Rendement',
                        value: _formatPercent(efficiency),
                        detail: totalShots == 0
                            ? 'Geen schoten'
                            : '${goalsScored.length}/$totalShots raak',
                        accent: _colorForScore(finishingScore),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _metricTile(
                        label: 'Netto',
                        value: _signed(netScore),
                        detail:
                            '${goalsScored.length} voor / ${goalsConceded.length} tegen',
                        accent: _colorForNet(netScore),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _sectionCard(
                        title: 'Aanval',
                        accent: _colorForScore(finishingScore),
                        rows: [
                          _statLine(
                            label: 'Doelpunt voor',
                            value: '${goalsScored.length}',
                            accent: _good,
                          ),
                          _statLine(
                            label: 'Schot gemist',
                            value: '${missedShots.length}',
                            accent: _average,
                          ),
                          _statLine(
                            label: 'Doelpunt tegen',
                            value: '${goalsConceded.length}',
                            accent: _colorForConceded(goalsConceded.length),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _sectionCard(
                        title: 'Teamplay',
                        accent: _colorForScore(teamPlayScore),
                        rows: [
                          _statLine(
                            label: 'Rebounds',
                            value: '$reboundsWon/$reboundsLost',
                            detail: 'saldo ${_signed(reboundBalance)}',
                            accent: _colorForNet(reboundBalance),
                          ),
                          _statLine(
                            label: 'Assist',
                            value: '$assists',
                            accent: assists >= 2
                                ? _good
                                : assists == 1
                                ? _average
                                : _muted,
                          ),
                          _statLine(
                            label: 'Onderschepping',
                            value: '$interceptions',
                            accent: interceptions >= 2
                                ? _good
                                : interceptions == 1
                                ? _average
                                : _muted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Schotzones',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 8),
                for (
                  var bucketIndex = 0;
                  bucketIndex < buckets.length;
                  bucketIndex++
                ) ...[
                  _zoneRow(buckets[bucketIndex]),
                  if (bucketIndex != buckets.length - 1) pw.SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metricTile({
    required String label,
    required String value,
    required String detail,
    required p.PdfColor accent,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _softFill(accent),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              color: accent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 22,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(detail, style: pw.TextStyle(fontSize: 9, color: _muted)),
        ],
      ),
    );
  }

  static pw.Widget _sectionCard({
    required String title,
    required p.PdfColor accent,
    required List<pw.Widget> rows,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.SizedBox(height: 10),
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
            rows[rowIndex],
            if (rowIndex != rows.length - 1) pw.SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  static pw.Widget _statLine({
    required String label,
    required String value,
    String? detail,
    required p.PdfColor accent,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _ink)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: _softFill(accent),
                borderRadius: pw.BorderRadius.circular(999),
              ),
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: accent,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (detail != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(detail, style: pw.TextStyle(fontSize: 8, color: _muted)),
        ],
      ],
    );
  }

  static pw.Widget _zoneRow(_ShotBucketStats bucket) {
    final efficiency = bucket.attempts == 0
        ? 0.0
        : bucket.goals / bucket.attempts;
    final accent = bucket.attempts == 0
        ? _muted
        : _colorForScore(_scoreForEfficiency(efficiency));

    return pw.Row(
      children: [
        pw.SizedBox(
          width: 46,
          child: pw.Text(
            bucket.label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ),
        pw.SizedBox(
          width: 56,
          child: pw.Text(
            '${bucket.goals}/${bucket.attempts}',
            style: pw.TextStyle(fontSize: 10, color: _ink),
          ),
        ),
        pw.SizedBox(
          width: 40,
          child: pw.Text(
            bucket.attempts == 0 ? '-' : _formatPercent(efficiency),
            style: pw.TextStyle(
              fontSize: 10,
              color: accent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _miniBar(bucket.attempts == 0 ? 0.0 : efficiency, accent),
        ),
      ],
    );
  }

  static pw.Widget _miniBar(double progress, p.PdfColor accent) {
    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints?.maxWidth ?? 0.0;
        return pw.Container(
          height: 10,
          decoration: pw.BoxDecoration(
            color: _panel,
            borderRadius: pw.BorderRadius.circular(999),
          ),
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Container(
              width: barWidth * progress.clamp(0.0, 1.0).toDouble(),
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(999),
              ),
            ),
          ),
        );
      },
    );
  }

  static List<_ShotBucketStats> _buildShotBuckets(
    List<Goal> goalsScored,
    List<PlayerEvent> missedShots,
  ) {
    final buckets = {
      '2m': _ShotBucketStats(label: '2m'),
      '5m': _ShotBucketStats(label: '5m'),
      '7m': _ShotBucketStats(label: '7m'),
      'Overig': _ShotBucketStats(label: 'Overig'),
    };

    for (final goal in goalsScored) {
      final bucket = buckets[_bucketForType(goal.type)]!;
      bucket.goals++;
      bucket.attempts++;
    }

    for (final missedShot in missedShots) {
      final type = missedShot.goalType;
      if (type == null) continue;
      final bucket = buckets[_bucketForType(type)]!;
      bucket.attempts++;
    }

    return [buckets['2m']!, buckets['5m']!, buckets['7m']!, buckets['Overig']!];
  }

  static String _bucketForType(GoalType type) {
    final label = type.label.toLowerCase();
    if (label.contains('2m')) return '2m';
    if (label.contains('5m')) return '5m';
    if (label.contains('7m')) return '7m';
    return 'Overig';
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

class _ShotBucketStats {
  _ShotBucketStats({required this.label});

  final String label;
  int goals = 0;
  int attempts = 0;
}
