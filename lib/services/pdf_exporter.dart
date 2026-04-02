import 'dart:typed_data';

import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/match_controller.dart';
import '../models/goal.dart';
import '../models/match_event.dart';
import 'team_names.dart';

class PdfExporter {
  static const double _cardHeight = 370.0;
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
  static final _zoneInner = const p.PdfColor.fromInt(0xffd4efac);

  static Future<Uint8List> buildReport({
    required MatchController c,
    String? homeTeamName,
    String? awayTeamName,
    DateTime? dateTime,
  }) async {
    final now = dateTime ?? DateTime.now();
    final doc = pw.Document();
    final materialIcons = await _tryLoadMaterialIconsFont();
    final showIcons = materialIcons != null;
    final pageTheme = materialIcons == null
        ? const pw.PageTheme(margin: pw.EdgeInsets.all(24))
        : pw.PageTheme(
            margin: const pw.EdgeInsets.all(24),
            theme: pw.ThemeData.withFont(icons: materialIcons),
          );

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
    for (final playerNumber in playerNumbers) {
      doc.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (_) => pw.SizedBox(
            height: _cardHeight,
            child: _playerCard(
              playerNumber: playerNumber,
              playerName: _pdfSafe(c.homePlayers.getName(playerNumber)),
              showIcons: showIcons,
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
    required bool showIcons,
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
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: _shotSection(shotStats, showIcons: showIcons),
                      ),
                      pw.Container(width: 1, color: _line),
                      pw.Expanded(
                        flex: 3,
                        child: _rightSection(
                          showIcons: showIcons,
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
                  flex: 2,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: _distanceBreakdown(distanceStats),
                      ),
                      pw.Expanded(
                        flex: 4,
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

  static pw.Widget _shotSection(
    List<_ShotTypeStats> shotStats, {
    required bool showIcons,
  }) {
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
                  _headerTitleCell(
                    'Doelpunten & schoten',
                    color: _shot,
                    icon: showIcons ? _shotIcon : null,
                  ),
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
    required bool showIcons,
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
          _sectionHeader(
            'Rebounds',
            color: _rebound,
            icon: showIcons ? _reboundIcon : null,
          ),
          pw.SizedBox(height: 4),
          _miniStatRow(
            'Gewonnen',
            reboundsWon,
            _colorForPositiveCount,
            suffix: _formatPercent(reboundPercent),
          ),
          _miniStatRow('Verloren', reboundsLost, _colorForNegativeCount),
          pw.SizedBox(height: 12),
          _sectionHeader(
            'Assists',
            color: _assist,
            icon: showIcons ? _assistIcon : null,
          ),
          pw.SizedBox(height: 4),
          _miniStatRow('Assists', assists, _colorForSupportCount),
          pw.SizedBox(height: 12),
          _sectionHeader(
            'Onderscheppingen',
            color: _interception,
            icon: showIcons ? _interceptionIcon : null,
          ),
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
      (stat) => stat.type == GoalType.longRange7m,
    );
    final middle = distanceStats.firstWhere(
      (stat) => stat.type == GoalType.midRange5m,
    );
    final inner = distanceStats.firstWhere(
      (stat) => stat.type == GoalType.smallChance2m,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        left: 8,
        right: 12,
        top: 10,
        bottom: 10,
      ),
      child: pw.Center(
        child: pw.SizedBox(
          width: 190,
          height: 135,
          child: pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              _ringCircle(132, _zoneOuter),
              _ringCircle(92, _zoneMiddle),
              _ringCircle(48, _zoneInner),
              pw.Positioned(
                left: 18,
                top: 57,
                child: _chartPercent(_formatPercent(outer.accuracy)),
              ),
              pw.Positioned(
                left: 73,
                top: 57,
                child: _chartPercent(_formatPercent(middle.accuracy)),
              ),
              pw.Positioned(
                left: 111,
                top: 55,
                child: _chartPercent(_formatPercent(inner.accuracy)),
              ),
            ],
          ),
        ),
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

  static pw.Widget _headerTitleCell(
    String text, {
    required p.PdfColor color,
    pw.IconData? icon,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Row(
        children: [
          _sectionMarker(color: color, size: 10, icon: icon),
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

  static pw.Widget _ringCircle(double size, p.PdfColor color) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
    );
  }

  static pw.Widget _chartPercent(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    );
  }

  static pw.Widget _sectionHeader(
    String text, {
    required p.PdfColor color,
    pw.IconData? icon,
  }) {
    return pw.Row(
      children: [
        _sectionMarker(color: color, size: 11, icon: icon),
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
    pw.IconData? icon,
  }) {
    if (icon != null) {
      return pw.Icon(icon, size: size, color: color);
    }

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
    required List<PlayerEvent> missedShots,
  }) {
    return _distanceGoalTypes
        .map(
          (type) => _DistanceStats(
            type: type,
            made: goalsScored.where((goal) => goal.type == type).length,
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

  static Future<pw.Font?> _tryLoadMaterialIconsFont() async {
    // Load from the bundled project asset — always works, no network needed.
    try {
      final data = await rootBundle.load(
        'assets/fonts/MaterialIcons-Regular.otf',
      );
      return pw.Font.ttf(data.buffer.asByteData());
    } catch (_) {
      return null;
    }
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

  static pw.IconData get _shotIcon => _toPdfIcon(m.Icons.sports_soccer);

  static pw.IconData get _reboundIcon => _toPdfIcon(m.Icons.sports_basketball);

  static pw.IconData get _assistIcon => _toPdfIcon(m.Icons.handshake_outlined);

  static pw.IconData get _interceptionIcon =>
      _toPdfIcon(m.Icons.front_hand_outlined);

  static pw.IconData _toPdfIcon(m.IconData icon) {
    return pw.IconData(
      icon.codePoint,
      matchTextDirection: icon.matchTextDirection,
    );
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
    required this.missed,
  });

  final GoalType type;
  final int made;
  final int missed;

  int get attempts => made + missed;

  double get accuracy => attempts == 0 ? 0 : made / attempts;
}
