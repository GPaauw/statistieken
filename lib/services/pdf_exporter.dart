import 'dart:math' show pi;
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
  static const double _cardHeight = 380.0;
  static const _shotGoalTypes = [
    GoalType.turnaround,
    GoalType.throughBall,
    GoalType.freeThrow,
    GoalType.penalty,
  ];
  static const _distanceGoalTypes = [
    GoalType.smallChance2m,
    GoalType.midRange5m,
    GoalType.longRange7m,
  ];

  static final _good = p.PdfColors.green700;
  static final _average = p.PdfColors.orange700;
  static final _bad = p.PdfColors.red700;
  static final _shot = p.PdfColors.blue700;
  static final _rebound = p.PdfColors.orange700;
  static final _assist = p.PdfColors.teal700;
  static final _interception = p.PdfColors.green700;
  static final _ink = p.PdfColors.grey900;
  static final _muted = p.PdfColors.grey600;
  static final _panel = p.PdfColors.grey100;
  static final _line = p.PdfColors.grey300;
  static final _zoneOuter = const p.PdfColor.fromInt(0xff09ba51);
  static final _zoneMiddle = const p.PdfColor.fromInt(0xff98d548);

  static Future<Uint8List> buildReport({
    required MatchController c,
    String? homeTeamName,
    String? awayTeamName,
    DateTime? dateTime,
  }) async {
    final now = dateTime ?? DateTime.now();
    final doc = pw.Document();
    const pageTheme = pw.PageTheme(margin: pw.EdgeInsets.all(24));

    final homeName = _pdfSafe(homeTeamName ?? TeamNames.homeTeamName);
    final awayName = _pdfSafe(awayTeamName ?? TeamNames.awayTeamName);

    String fmt2(int value) => value.toString().padLeft(2, '0');
    String fmtTime(int seconds) {
      final minutes = seconds ~/ 60;
      final remainder = seconds % 60;
      return '${fmt2(minutes)}:${fmt2(remainder)}';
    }

    String homePlayerName(Goal goal) =>
        _pdfSafe(c.homePlayers.getName(goal.playerNumber));

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
        pageTheme: pageTheme,
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

    pw.Widget buildCard(int playerNumber) {
      return pw.SizedBox(
        height: _cardHeight,
        child: _playerCard(
          playerNumber: playerNumber,
          playerName: _pdfSafe(c.homePlayers.getName(playerNumber)),
          goalsScored: c.goals
              .where(
                (goal) =>
                    goal.team == Team.home &&
                    goal.playerNumber == playerNumber,
              )
              .toList(),
          goalsConceded: c.goals
              .where(
                (goal) =>
                    goal.team == Team.away &&
                    goal.playerNumber == playerNumber,
              )
              .toList(),
          missedShots: c.events
              .where(
                (event) =>
                    event.type == PlayerEventType.shotMissed &&
                    event.playerNumber == playerNumber,
              )
              .toList(),
          reboundsWon: c.reboundWonByPlayer[playerNumber] ?? 0,
          reboundsLost: c.reboundLostByPlayer[playerNumber] ?? 0,
          assists: c.assistByPlayer[playerNumber] ?? 0,
          interceptions: c.interceptionByPlayer[playerNumber] ?? 0,
        ),
      );
    }

    for (var i = 0; i < playerNumbers.length; i += 2) {
      final p1 = playerNumbers[i];
      final p2 = i + 1 < playerNumbers.length ? playerNumbers[i + 1] : null;
      doc.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (_) => pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              buildCard(p1),
              if (p2 != null) ...[pw.SizedBox(height: 8), buildCard(p2)],
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
    final filename = 'wedstrijdverslag_$formattedDate.pdf';
    final bytes = await buildReport(
      c: c,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
    );
    final shared = await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    );
    if (!shared) {
      await Printing.layoutPdf(
        name: filename,
        dynamicLayout: false,
        onLayout: (_) async => bytes,
      );
    }
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
    final shotStats = _buildShotStats(
      goalsScored: goalsScored,
      goalsConceded: goalsConceded,
      missedShots: missedShots,
    );
    final distanceStats = _buildDistanceStats(
      goalsScored: goalsScored,
      goalsConceded: goalsConceded,
      missedShots: missedShots,
    );

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
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: _shotSection(shotStats),
                      ),
                      pw.Container(width: 1, color: _line),
                      pw.Expanded(
                        flex: 3,
                        child: _rightSection(
                          reboundsWon: reboundsWon,
                          reboundsLost: reboundsLost,
                          assists: assists,
                          interceptions: interceptions,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(height: 1, color: _line),
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: _distanceBreakdown(distanceStats),
                      ),
                      pw.Container(width: 1, color: _line),
                      pw.Expanded(
                        flex: 3,
                        child: _distanceChart(distanceStats),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Left section: Doelpunten & schoten table
  // ---------------------------------------------------------------------------

  static pw.Widget _shotSection(List<_ShotTypeStats> shotStats) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Table(
            border: pw.TableBorder.all(color: _line, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3.1),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(0.9),
              3: const pw.FlexColumnWidth(0.9),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _panel),
                children: [
                  _headerTitleCell('Doelpunten & schoten', color: _shot),
                  _headerSpacerCell(),
                  _headerSpacerCell(),
                  _headerSpacerCell(),
                  _headerSpacerCell(),
                ],
              ),
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _panel),
                children: [
                  _th('Type'),
                  _th('%'),
                  _th('Voor'),
                  _th('Tegen'),
                  _th('Gemist'),
                ],
              ),
              for (final stat in shotStats)
                pw.TableRow(
                  children: [
                    _labelCell(stat.type.label),
                    _valueTextCell(
                      _formatPercent(stat.accuracy),
                      _colorForAccuracy(stat.accuracy, stat.attempts),
                    ),
                    _valueCell(stat.made, _colorForPositiveCount),
                    _valueCell(stat.against, _colorForConceded),
                    _valueCell(stat.missed, _colorForNegativeCount),
                  ],
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
    final reboundTotal = reboundsWon + reboundsLost;
    final reboundPercent = _ratio(reboundsWon, reboundTotal);

    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionHeader('Rebounds', color: _rebound),
          pw.SizedBox(height: 4),
          _miniStatRow(
            'Gewonnen',
            reboundsWon,
            _colorForPositiveCount,
            suffix: _formatPercent(reboundPercent),
          ),
          _miniStatRow('Verloren', reboundsLost, _colorForNegativeCount),
          pw.SizedBox(height: 12),
          _sectionHeader('Assists', color: _assist),
          pw.SizedBox(height: 4),
          _miniStatRow('Assists', assists, _colorForSupportCount),
          pw.SizedBox(height: 12),
          _sectionHeader('Onderscheppingen', color: _interception),
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
  // Bottom section: distance breakdown + ring chart
  // ---------------------------------------------------------------------------

  static pw.Widget _distanceBreakdown(List<_DistanceStats> distanceStats) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Table(
        border: pw.TableBorder.all(color: _line, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(2.4),
          1: const pw.FlexColumnWidth(1.6),
        },
        children: [
          for (final stat in distanceStats)
            pw.TableRow(
              children: [_labelCell(stat.type.label), _distanceValueCell(stat)],
            ),
        ],
      ),
    );
  }

  static pw.Widget _distanceChart(List<_DistanceStats> distanceStats) {
    final outer = distanceStats.firstWhere(
      (s) => s.type == GoalType.longRange7m,
    );
    final middle = distanceStats.firstWhere(
      (s) => s.type == GoalType.midRange5m,
    );
    final inner = distanceStats.firstWhere(
      (s) => s.type == GoalType.smallChance2m,
    );

    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints!.maxWidth;
        final double h = constraints.maxHeight;
        final double r = ((h * 0.85).clamp(10.0, w * 0.46)).toDouble();
        final lbl = pw.TextStyle(fontSize: 6, color: p.PdfColors.white);
        final cnt = pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: p.PdfColors.white,
        );
        return pw.Stack(
          children: [
            pw.CustomPaint(
              painter: _QChartPainter(r: r, w: w).paint,
              size: p.PdfPoint(w, h),
            ),
            // Left axis labels (7m / 5m / 2m)
            pw.Positioned(left: 1, bottom: r - 9, child: pw.Text('7m', style: lbl)),
            pw.Positioned(left: 1, bottom: r * 0.65 - 9, child: pw.Text('5m', style: lbl)),
            pw.Positioned(left: 1, bottom: r * 0.35 - 9, child: pw.Text('2m', style: lbl)),
            // Left count values inside zones
            pw.Positioned(left: r * 0.70, bottom: r * 0.30, child: pw.Transform.rotate(angle: -pi / 4, child: pw.Text('${outer.made}', style: cnt))),
            pw.Positioned(left: r * 0.41, bottom: r * 0.20, child: pw.Transform.rotate(angle: -pi / 4, child: pw.Text('${middle.made}', style: cnt))),
            pw.Positioned(left: r * 0.13, bottom: r * 0.09, child: pw.Transform.rotate(angle: -pi / 4, child: pw.Text('${inner.made}', style: cnt))),
            // Right axis labels
            pw.Positioned(right: 1, bottom: r - 9, child: pw.Text('7m', style: lbl)),
            pw.Positioned(right: 1, bottom: r * 0.65 - 9, child: pw.Text('5m', style: lbl)),
            pw.Positioned(right: 1, bottom: r * 0.35 - 9, child: pw.Text('2m', style: lbl)),
            // Right count values inside zones
            pw.Positioned(right: r * 0.70, bottom: r * 0.30, child: pw.Transform.rotate(angle: pi / 4, child: pw.Text('${outer.against}', style: cnt))),
            pw.Positioned(right: r * 0.41, bottom: r * 0.20, child: pw.Transform.rotate(angle: pi / 4, child: pw.Text('${middle.against}', style: cnt))),
            pw.Positioned(right: r * 0.13, bottom: r * 0.09, child: pw.Transform.rotate(angle: pi / 4, child: pw.Text('${inner.against}', style: cnt))),
          ],
        );
      },
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

  static pw.Widget _headerTitleCell(
    String text, {
    required p.PdfColor color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Row(
        children: [
          _sectionMarker(color: color, size: 10),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _headerSpacerCell() {
    return pw.SizedBox();
  }

  static pw.Widget _labelCell(String text) {
    return pw.Container(
      color: _panel,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, color: _ink)),
    );
  }

  static pw.Widget _valueCell(int value, p.PdfColor Function(int) colorFn) {
    return _valueTextCell('$value', colorFn(value));
  }

  static pw.Widget _valueTextCell(String text, p.PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _distanceValueCell(_DistanceStats stat) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        '${stat.made} / ${stat.attempts} (${_formatPercent(stat.accuracy)})',
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: _colorForAccuracy(stat.accuracy, stat.attempts),
        ),
      ),
    );
  }

  static pw.Widget _sectionHeader(
    String text, {
    required p.PdfColor color,
  }) {
    return pw.Row(
      children: [
        _sectionMarker(color: color, size: 11),
        pw.SizedBox(width: 4),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    );
  }

  static pw.Widget _sectionMarker({
    required p.PdfColor color,
    required double size,
  }) {
    return pw.Container(
      width: size - 2,
      height: size - 2,
      decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
    );
  }

  static pw.Widget _miniStatRow(
    String label,
    int value,
    p.PdfColor Function(int) colorFn, {
    String? suffix,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _muted)),
        pw.Text(
          suffix == null ? '$value' : '$value ($suffix)',
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

  static double _ratio(int numerator, int denominator) {
    if (denominator == 0) {
      return 0;
    }
    return numerator / denominator;
  }

  static List<_ShotTypeStats> _buildShotStats({
    required List<Goal> goalsScored,
    required List<Goal> goalsConceded,
    required List<PlayerEvent> missedShots,
  }) {
    return _shotGoalTypes
        .map(
          (type) => _ShotTypeStats(
            type: type,
            made: goalsScored.where((goal) => goal.type == type).length,
            against: goalsConceded.where((goal) => goal.type == type).length,
            missed: missedShots.where((event) => event.goalType == type).length,
          ),
        )
        .toList();
  }

  static List<_DistanceStats> _buildDistanceStats({
    required List<Goal> goalsScored,
    required List<Goal> goalsConceded,
    required List<PlayerEvent> missedShots,
  }) {
    return _distanceGoalTypes
        .map(
          (type) => _DistanceStats(
            type: type,
            made: goalsScored.where((goal) => goal.type == type).length,
            against: goalsConceded.where((goal) => goal.type == type).length,
            missed: missedShots.where((event) => event.goalType == type).length,
          ),
        )
        .toList();
  }

  /// Strips characters outside the Latin-1 range (codepoints > 0xFF) so that
  /// the default PDF font (Helvetica) never receives unsupported glyphs like emoji.
  static String _pdfSafe(String text) {
    return String.fromCharCodes(
      text.runes.where((r) => r >= 0x20 && r <= 0xFF),
    );
  }

  // ---------------------------------------------------------------------------
  // Color helpers
  // ---------------------------------------------------------------------------

  static p.PdfColor _colorForAccuracy(double value, int attempts) {
    if (attempts == 0) {
      return _muted;
    }
    if (value >= 0.6) return _good;
    if (value >= 0.35) return _average;
    return _bad;
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

  static p.PdfColor _colorForConceded(int value) {
    if (value <= 1) return _good;
    if (value <= 3) return _average;
    return _bad;
  }
}

class _QChartPainter {
  const _QChartPainter({required this.r, required this.w});

  final double r;
  final double w;

  // Cubic bezier approximation constant for a quarter circle.
  static const _k = 0.5522847498;

  // Green shades: lightest (7m outer) → darkest (2m inner)
  static const _g1 = p.PdfColor.fromInt(0xff99d44d);
  static const _g2 = p.PdfColor.fromInt(0xff4ca800);
  static const _g3 = p.PdfColor.fromInt(0xff1a6200);

  // Red shades: lightest (7m outer) → darkest (2m inner)
  static const _r1 = p.PdfColor.fromInt(0xffffb3b3);
  static const _r2 = p.PdfColor.fromInt(0xffee5533);
  static const _r3 = p.PdfColor.fromInt(0xffbb0000);

  // Quarter circle with centre at bottom-left corner (PDF origin 0,0).
  void _bl(p.PdfGraphics c, p.PdfColor color, double radius) {
    c
      ..setFillColor(color)
      ..moveTo(0, 0)
      ..lineTo(radius, 0)
      ..curveTo(radius, _k * radius, _k * radius, radius, 0, radius)
      ..closePath()
      ..fillPath();
  }

  // Quarter circle with centre at bottom-right corner (PDF x = w, y = 0).
  void _br(p.PdfGraphics c, p.PdfColor color, double radius) {
    c
      ..setFillColor(color)
      ..moveTo(w, 0)
      ..lineTo(w, radius)
      ..curveTo(w - _k * radius, radius, w - radius, _k * radius, w - radius, 0)
      ..closePath()
      ..fillPath();
  }

  void paint(p.PdfGraphics canvas, p.PdfPoint size) {
    // Draw largest sector first so smaller ones paint on top.
    _bl(canvas, _g1, r);
    _bl(canvas, _g2, r * 0.65);
    _bl(canvas, _g3, r * 0.35);
    _br(canvas, _r1, r);
    _br(canvas, _r2, r * 0.65);
    _br(canvas, _r3, r * 0.35);
  }

}

class _ShotTypeStats {
  const _ShotTypeStats({
    required this.type,
    required this.made,
    required this.against,
    required this.missed,
  });

  final GoalType type;
  final int made;
  final int against;
  final int missed;

  int get attempts => made + missed;

  double get accuracy => attempts == 0 ? 0 : made / attempts;
}

class _DistanceStats {
  const _DistanceStats({
    required this.type,
    required this.made,
    required this.against,
    required this.missed,
  });

  final GoalType type;
  final int made;
  final int against;
  final int missed;

  int get attempts => made + missed;

  double get accuracy => attempts == 0 ? 0 : made / attempts;
}
