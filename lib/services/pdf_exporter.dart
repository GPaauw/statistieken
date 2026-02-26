// lib/services/pdf_exporter.dart
// Quarter-circles pinned to bottom, container 1.5x scaled (width & height),
// heatmap unchanged in scale, and label gutter so 7m/5m/2m can sit outside the arcs.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as p;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../controllers/match_controller.dart';
import '../models/goal.dart';

class PdfExporter {
  // Container scaling (frame 1.5x larger, content keeps size)
  static const double _containerScale = 1.5;
  static const double _cardBaseWidth = 360.0;

  static Future<Uint8List> buildReport({
    required MatchController c,
    String homeTeamName = "KV Flamingo's",
    String awayTeamName = 'Tegenstanders',
    DateTime? dateTime,
  }) async {
    final now = dateTime ?? DateTime.now();
    final doc = pw.Document();

    String fmt2(int v) => v.toString().padLeft(2, '0');
    String fmtTime(int seconds) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${fmt2(m)}:${fmt2(s)}';
    }

    String scorerName(Goal g) {
      return g.team == Team.home
          ? c.homePlayers.getName(g.playerNumber)
          : c.awayPlayers.getName(g.playerNumber);
    }

    String? concededName(Goal g) {
      final n = g.concededPlayerNumber;
      if (n == null) return null;
      return g.team == Team.home ? c.awayPlayers.getName(n) : c.homePlayers.getName(n);
    }

    final headerStyle = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
    final h2 = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final cell = pw.TextStyle(fontSize: 11);

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (_) => [
          pw.Text('Wedstrijdverslag', style: headerStyle),
          pw.SizedBox(height: 4),
          pw.Text(
            '${fmt2(now.day)}-${fmt2(now.month)}-${now.year} ${fmt2(now.hour)}:${fmt2(now.minute)}',
            style: pw.TextStyle(color: p.PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('$homeTeamName vs $awayTeamName', style: h2),
              pw.Text('Score: ${c.homeScore} - ${c.awayScore}', style: h2),
            ],
          ),
          pw.SizedBox(height: 12),

          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            headerDecoration: pw.BoxDecoration(color: p.PdfColors.grey300),
            cellStyle: cell,
            headers: ['Tijd', 'Team', 'Speler', 'Type', 'Tegen', 'Stand'],
            data: () {
              final rows = <List<String>>[];
              int home = 0, away = 0;
              for (final g in c.goals) {
                if (g.team == Team.home) home++; else away++;
                rows.add([
                  fmtTime(g.secondStamp),
                  g.team == Team.home ? homeTeamName : awayTeamName,
                  scorerName(g),
                  g.type.label,
                  concededName(g) ?? '',
                  '$home - $away',
                ]);
              }
              return rows;
            }(),
            border: null,
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2.4),
              2: const pw.FlexColumnWidth(2.2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.4),
              5: const pw.FlexColumnWidth(1),
            },
          ),

          pw.SizedBox(height: 16),
          pw.Text('Samenvatting', style: h2),
          pw.SizedBox(height: 6),
          pw.Bullet(text: 'Totale speeltijd: ${fmtTime(c.elapsedSeconds)}'),
          pw.Bullet(text: 'Totaal doelpunten: ${c.goals.length}'),
          pw.Bullet(text: "KV Flamingo's: ${c.homeScore} | Tegenstanders: ${c.awayScore}"),

          pw.SizedBox(height: 12),
          pw.Text("Spelerssamenvatting (KV Flamingo's)", style: h2),
          pw.SizedBox(height: 6),

          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final n in (c.homePlayers.names.keys.toList()..sort()))
                _playerCard(
                  playerNumber: n,
                  playerName: c.homePlayers.getName(n),
                  goalsScored: c.goals.where((g) => g.team == Team.home && g.playerNumber == n).toList(),
                  goalsConceded: c.goals.where((g) => g.concededPlayerNumber == n).toList(),
                  cardWidth: _cardBaseWidth * _containerScale,
                  containerScale: _containerScale,
                ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> shareReport({
    required MatchController c,
    String homeTeamName = "KV Flamingo's",
    String awayTeamName = 'Tegenstanders',
    DateTime? dateTime,
  }) async {
    final now = dateTime ?? DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy').format(now);
    final bytes = await buildReport(c: c, homeTeamName: homeTeamName, awayTeamName: awayTeamName);
    await Printing.sharePdf(bytes: bytes, filename: 'wedstrijdverslag_$formattedDate.pdf');
  }

  // ------------- Bars, labels, and counts -------------
  static const _barHeight = 16.0;
  static const _barRadius = 4.0;
  static const _barGap = 8.0;

  static final _green = p.PdfColors.green600;
  static final _greenBack = p.PdfColors.green300;
  static final _red = p.PdfColors.red600;
  static final _redBack = p.PdfColors.red300;

  static bool _isDistanceType(GoalType t) {
    final lbl = t.label.toLowerCase();
    return lbl.contains('7m') || lbl.contains('5m') || lbl.contains('2m');
  }

  static List<GoalType> _nonDistanceTypes() {
    final list = <GoalType>[];
    for (final t in GoalType.values) if (!_isDistanceType(t)) list.add(t);
    list.sort((a, b) => a.label.compareTo(b.label));
    return list;
  }

  static Map<GoalType, int> _countByType(Iterable<Goal> goals) {
    final map = <GoalType, int>{};
    for (final t in GoalType.values) map[t] = 0;
    for (final g in goals) map[g.type] = (map[g.type] ?? 0) + 1;
    return map;
  }

  static pw.Widget _barRow({
    required int value,
    required int maxValue,
    required double maxWidth,
    required p.PdfColor fill,
    required p.PdfColor fillBack,
  }) {
    final frac = maxValue <= 0 ? 0 : value / maxValue;
    final barW = (frac * maxWidth).clamp(0.0, maxWidth);

    return pw.Container(
      height: _barHeight,
      decoration: pw.BoxDecoration(color: fillBack, borderRadius: pw.BorderRadius.circular(_barRadius)),
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: barW,
                decoration: pw.BoxDecoration(color: fill, borderRadius: pw.BorderRadius.circular(_barRadius)),
              ),
            ),
          ),
          pw.Center(
            child: pw.Text(
              value.toString(),
              style: pw.TextStyle(color: p.PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _barList({
    required Map<GoalType, int> counts,
    required List<GoalType> typesOrder,
    required p.PdfColor fill,
    required p.PdfColor fillBack,
    required double maxWidth,
  }) {
    final values = [for (final t in typesOrder) counts[t] ?? 0];
    final maxValue = values.isEmpty ? 0 : values.reduce(math.max);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < typesOrder.length; i++) ...[
          _barRow(value: values[i], maxValue: maxValue, maxWidth: maxWidth, fill: fill, fillBack: fillBack),
          if (i != typesOrder.length - 1) pw.SizedBox(height: _barGap),
        ],
      ],
    );
  }

  static pw.Widget _labelList({required List<GoalType> typesOrder}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < typesOrder.length; i++) ...[
          pw.Text(typesOrder[i].label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (i != typesOrder.length - 1) pw.SizedBox(height: _barGap),
        ],
      ],
    );
  }

  // ------------- Distances and heatmap helpers -------------
  static Map<String, int> _distanceCounts(List<Goal> goals) {
    int c2 = 0, c5 = 0, c7 = 0;
    for (final g in goals) {
      final lbl = g.type.label.toLowerCase();
      if (lbl.contains('2m')) c2++;
      if (lbl.contains('5m')) c5++;
      if (lbl.contains('7m')) c7++;
    }
    return {'7m': c7, '5m': c5, '2m': c2};
  }

  static p.PdfColor _lerpColor(p.PdfColor a, p.PdfColor b, double t) {
    t = t.clamp(0, 1);
    return p.PdfColor(
      a.red + (b.red - a.red) * t,
      a.green + (b.green - a.green) * t,
      a.blue + (b.blue - a.blue) * t,
    );
  }

  // Ring overlay numbers (with optional dx offset when drawing area is shifted)
  static pw.Widget _ringNumberOverlayQuarter({
    required bool rightSide,
    required double width,
    required double height,
    required int ringIndex,
    required int value,
    double dx = 0, // horizontal shift of drawing origin
  }) {
    const ringGap = 4.0;
    const ringCount = 3;
    final outerR = height;
    final ringWidth = (height - (ringGap * (ringCount - 1))) / ringCount;
    final rOuter = outerR - ringIndex * (ringWidth + ringGap);
    final rMid = rOuter - ringWidth / 2;

    final cx = rightSide ? width : 0.0;
    final cy = 0.0;
    final angle = rightSide ? (3 * math.pi / 4) : (math.pi / 4);
    final tx = cx + rMid * math.cos(angle);
    final ty = cy + rMid * math.sin(angle);

    final left = dx + tx - 7; // apply dx so numbers align after shifting draw area
    final top = height - ty - 7;

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Container(
        width: 14,
        height: 14,
        alignment: pw.Alignment.center,
        child: pw.Text(
          value.toString(),
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: p.PdfColors.white),
        ),
      ),
    );
  }

  static pw.Widget _distanceQuarterSection({
    required List<Goal> goalsScored,
    required List<Goal> goalsConceded,
    required double height,
    required double leftWidth,
    required double middleGapWidth,
    required double rightWidth,
  }) {
    final left = _distanceCounts(goalsScored);
    final right = _distanceCounts(goalsConceded);

    final maxLeft = math.max(left['2m']!, math.max(left['5m']!, left['7m']!));
    final maxRight = math.max(right['2m']!, math.max(right['5m']!, right['7m']!));

    const double labelGutter = 18.0; // reserved space for labels outside the arc

    pw.Widget quarter({
      required bool rightSide,
      required Map<String, int> values,
      required p.PdfColor baseColor,
      required int maxValue,
      required double width,
    }) {
      final shades = [
        _lerpColor(baseColor, p.PdfColors.white, 0.55),
        _lerpColor(baseColor, p.PdfColors.white, 0.35),
        baseColor,
      ];
      final seq = [values['7m']!, values['5m']!, values['2m']!];

      final double drawDx = rightSide ? 0.0 : labelGutter; // shift left quarter rightwards
      final double drawW = width - labelGutter;            // effective drawing width

      return pw.Container(
        width: width,
        height: height,
        child: pw.Stack(
          children: [
            // Drawing area (shifted when left quarter)
            pw.Positioned(
              left: drawDx,
              right: rightSide ? labelGutter : 0,
              top: 0,
              bottom: 0,
              child: pw.ClipRect(
                child: pw.CustomPaint(
                  size: p.PdfPoint(drawW, height),
                  painter: (p.PdfGraphics canvas, p.PdfPoint size) {
                    final cx = rightSide ? size.x : 0.0;
                    const ringGap = 4.0;
                    final outerR = size.y;
                    final ringWidth = (size.y - (ringGap * 2)) / 3;

                    for (int i = 0; i < 3; i++) {
                      final rOuter = outerR - i * (ringWidth + ringGap);
                      final rInner = rOuter - ringWidth;
                      final t = maxValue == 0 ? 0 : seq[i] / maxValue;
                      final col = _lerpColor(shades[i], baseColor, t * 0.6);

                      canvas
                        ..setFillColor(col)
                        ..drawEllipse(cx, 0, rOuter, rOuter)
                        ..fillPath();

                      canvas
                        ..setFillColor(p.PdfColors.white)
                        ..drawEllipse(cx, 0, rInner, rInner)
                        ..fillPath();
                    }

                    // Baseline across effective drawing area
                    canvas
                      ..setLineWidth(0.5)
                      ..setStrokeColor(p.PdfColors.black)
                      ..moveTo(0, 0)
                      ..lineTo(size.x, 0)
                      ..strokePath();
                  },
                ),
              ),
            ),

            // Numbers on rings (respect drawDx)
            _ringNumberOverlayQuarter(rightSide: rightSide, width: drawW, height: height, ringIndex: 0, value: seq[0], dx: drawDx),
            _ringNumberOverlayQuarter(rightSide: rightSide, width: drawW, height: height, ringIndex: 1, value: seq[1], dx: drawDx),
            _ringNumberOverlayQuarter(rightSide: rightSide, width: drawW, height: height, ringIndex: 2, value: seq[2], dx: drawDx),

            // Labels in the gutter (outside the arc)
            if (!rightSide) ...[
              pw.Positioned(left: 0, bottom: height * .20, child: pw.Text('2m', style: const pw.TextStyle(fontSize: 9))),
              pw.Positioned(left: 0, bottom: height * .40, child: pw.Text('5m', style: const pw.TextStyle(fontSize: 9))),
              pw.Positioned(left: 0, bottom: height * .80, child: pw.Text('7m', style: const pw.TextStyle(fontSize: 9))),
            ] else ...[
              pw.Positioned(right: 0, bottom: height * .20, child: pw.Text('2m', style: const pw.TextStyle(fontSize: 9))),
              pw.Positioned(right: 0, bottom: height * .40, child: pw.Text('5m', style: const pw.TextStyle(fontSize: 9))),
              pw.Positioned(right: 0, bottom: height * .80, child: pw.Text('7m', style: const pw.TextStyle(fontSize: 9))),
            ],
          ],
        ),
      );
    }

    return pw.SizedBox(
      height: height,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.SizedBox(
            width: leftWidth,
            child: quarter(rightSide: false, values: left, baseColor: _green, maxValue: maxLeft, width: leftWidth),
          ),
          pw.SizedBox(width: middleGapWidth),
          pw.SizedBox(
            width: rightWidth,
            child: quarter(rightSide: true, values: right, baseColor: _red, maxValue: maxRight, width: rightWidth),
          ),
        ],
      ),
    );
  }

  static double _barsBlockHeight(int itemCount) =>
      itemCount <= 0 ? _barHeight : itemCount * _barHeight + (itemCount - 1) * _barGap;

  // Player card (container scaled; heatmap not scaled; quarter-circles pinned to bottom)
  static pw.Widget _playerCard({
    required int playerNumber,
    required String playerName,
    required List<Goal> goalsScored,
    required List<Goal> goalsConceded,
    double cardWidth = _cardBaseWidth,
    double containerScale = 1.0,
  }) {
    final typesOrder = _nonDistanceTypes();
    final scoredCounts = _countByType(goalsScored);
    final concededCounts = _countByType(goalsConceded);

    const horizontalPad = 10.0;
    const verticalPad = 8.0;
    const colGap = 12.0;

    final innerWidth = cardWidth - 2 * horizontalPad;
    final availableWidth = innerWidth - 2 * colGap;
    final colLeftWidth = availableWidth * 0.37;
    final colCenterWidth = availableWidth * 0.26;
    final colRightWidth = availableWidth * 0.37;

    final barsHeight = _barsBlockHeight(typesOrder.length);
    final heatmapHeight = math.max(125.0, barsHeight); // enlarge a bit; not scaled with container

    const double titleRowEstimate = 22.0;
    final double baseHeight = (2 * verticalPad) + titleRowEstimate + 6 + barsHeight + 10 + heatmapHeight;
    final double containerHeight = baseHeight * containerScale;

    return pw.Container(
      width: cardWidth,
      height: containerHeight,
      padding: const pw.EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: p.PdfColors.grey600, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.max,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Doelpunten', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _green)),
              pw.Text(playerName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Tegendoelpunten', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _red)),
            ],
          ),
          pw.SizedBox(height: 6),

          pw.Row(
            children: [
              pw.Container(width: colLeftWidth, child: _barList(counts: scoredCounts, typesOrder: typesOrder, fill: _green, fillBack: _greenBack, maxWidth: colLeftWidth)),
              pw.SizedBox(width: colGap),
              pw.Container(width: colCenterWidth, child: _labelList(typesOrder: typesOrder)),
              pw.SizedBox(width: colGap),
              pw.Container(width: colRightWidth, child: _barList(counts: concededCounts, typesOrder: typesOrder, fill: _red, fillBack: _redBack, maxWidth: colRightWidth)),
            ],
          ),

          // push quarter-circles to the bottom of the card
          pw.Spacer(),

          _distanceQuarterSection(
            goalsScored: goalsScored,
            goalsConceded: goalsConceded,
            height: heatmapHeight,
            leftWidth: colLeftWidth,
            middleGapWidth: colCenterWidth + 2 * colGap,
            rightWidth: colRightWidth,
          ),
        ],
      ),
    );
  }
}
