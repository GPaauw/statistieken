// lib/services/pdf_exporter.dart
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;    // voor Text, Row, Column, etc.
import 'package:pdf/pdf.dart' as p;         // voor PdfColors, PdfGraphics, PdfPoint
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../controllers/match_controller.dart';
import '../models/goal.dart';

class PdfExporter {
  static Future<Uint8List> buildReport({
    required MatchController c,
    String homeTeamName = "KV Flamingo's",
    String awayTeamName = 'Tegenstanders',
    DateTime? dateTime,
  }) async {
    final now = dateTime ?? DateTime.now();
    final doc = pw.Document();

    // Helpers
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
      // concededPlayerNumber verwijst naar speler van het verdedigende team
      return g.team == Team.home ? c.awayPlayers.getName(n) : c.homePlayers.getName(n);
    }

    final headerStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
    );

    final h2 = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );

    final cell = pw.TextStyle(fontSize: 11);

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(24),
        ),
        build: (context) => [
          // Titel
          pw.Text('Wedstrijdverslag', style: headerStyle),
          pw.SizedBox(height: 4),
          pw.Text(
            '${fmt2(now.day)}-${fmt2(now.month)}-${now.year} '
            '${fmt2(now.hour)}:${fmt2(now.minute)}',
            style: pw.TextStyle(color: p.PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),

          // Teams + score
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('$homeTeamName vs $awayTeamName', style: h2),
              pw.Text('Score: ${c.homeScore} - ${c.awayScore}', style: h2),
            ],
          ),
          pw.SizedBox(height: 12),

          // Doelpunten tabel
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: pw.BoxDecoration(
              color: p.PdfColors.grey300,
            ),
            cellStyle: cell,
            border: null,
            headers: ['Tijd', 'Team', 'Speler', 'Type', 'Tegen', 'Stand'],
            data: () {
              final rows = <List<String>>[];
              var home = 0;
              var away = 0;
              for (final g in c.goals) {
                if (g.team == Team.home) {
                  home++;
                } else {
                  away++;
                }

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
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2.4),
              2: const pw.FlexColumnWidth(2.2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.4),
              5: const pw.FlexColumnWidth(1.0),
            },
            cellAlignment: pw.Alignment.centerLeft,
          ),

          pw.SizedBox(height: 16),
          pw.Text('Samenvatting', style: h2),
          pw.SizedBox(height: 6),
          pw.Bullet(text: 'Totale speeltijd: ${fmtTime(c.elapsedSeconds)}'),
          pw.Bullet(text: 'Totaal doelpunten: ${c.goals.length}'),
          pw.Bullet(text: "KV Flamingo's: ${c.homeScore}  |  Tegenstanders: ${c.awayScore}"),

          pw.SizedBox(height: 12),
          pw.Text("Spelerssamenvatting (KV Flamingo's)", style: h2),
          pw.SizedBox(height: 6),

          // NIEUW: spelerskaarten (balken + kwart-cirkel heatmaps)
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final n in (c.homePlayers.names.keys.toList()..cast<int>()..sort()))
                _playerCard(
                  playerNumber: n,
                  playerName: c.homePlayers.getName(n),
                  goalsScored: c.goals
                      .where((g) => g.team == Team.home && g.playerNumber == n)
                      .toList(),
                  goalsConceded: c.goals.where((g) => g.concededPlayerNumber == n).toList(),
                  cardWidth: 360, // ~2 per rij op A4
                ),
            ],
          ),

          pw.SizedBox(height: 12),
          // (Tegenstanders samenvatting bewust weggelaten)
        ],
      ),
    );

    return doc.save();
  }

  /// Download/share PDF (werkt op Web + mobiel + desktop)
  static Future<void> shareReport({
    required MatchController c,
    String homeTeamName = "KV Flamingo's",
    String awayTeamName = 'Tegenstanders',
    DateTime? dateTime,
  }) async {
    final now = dateTime ?? DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy').format(now);
    final fileName = 'wedstrijdverslag_$formattedDate.pdf';

    final bytes = await buildReport(
      c: c,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      dateTime: now,
    );

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  // ======= (oude) helper, elders nog bruikbaar =======
  static pw.Widget _typeTable(List<Goal> goals, pw.TextStyle cellStyle) {
    final map = <GoalType, int>{};
    for (final t in GoalType.values) map[t] = 0;
    for (final g in goals) {
      map[g.type] = (map[g.type] ?? 0) + 1;
    }

    final rows = <List<String>>[];
    for (final t in GoalType.values) {
      final cnt = map[t] ?? 0;
      rows.add([t.label, cnt.toString()]);
    }

    return pw.Table.fromTextArray(
      headers: ['Type', 'Aantal'],
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: cellStyle.copyWith(fontSize: 9),
      border: pw.TableBorder.all(color: p.PdfColors.grey600, width: .5),
      columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
    );
  }

  // ======================= NIEUWE HELPERS VOOR KAART =========================

  // --- CONFIG ---
  static const _barHeight = 16.0;
  static const _barRadius = 4.0;
  static const _barGap = 8.0;

  // Kleuren
  static final _green = p.PdfColors.green600;
  static final _greenBack = p.PdfColors.green300;
  static final _red = p.PdfColors.red600;
  static final _redBack = p.PdfColors.red300;

  // Afstandstypen herkenning (labels bevatten '7m' / '5m' / '2m')
  static bool _isDistanceType(GoalType t) {
    final lbl = t.label.toLowerCase();
    return lbl.contains('7m') || lbl.contains('5m') || lbl.contains('2m');
  }

  static List<GoalType> _nonDistanceTypes() {
    final list = <GoalType>[];
    for (final t in GoalType.values) {
      if (!_isDistanceType(t)) list.add(t);
    }
    // Sorteer alfabetisch; pas aan als je vaste volgorde wilt.
    list.sort((a, b) => a.label.compareTo(b.label));
    return list;
  }

  static Map<GoalType, int> _countByType(Iterable<Goal> goals) {
    final map = <GoalType, int>{};
    for (final t in GoalType.values) {
      map[t] = 0;
    }
    for (final g in goals) {
      map[g.type] = (map[g.type] ?? 0) + 1;
    }
    return map;
  }

  // ======= Balken (links/rechts) =======
  static pw.Widget _barRow({
    required int value,
    required int maxValue,
    required double maxWidth,
    required p.PdfColor fill,
    required p.PdfColor fillBack,
    pw.TextStyle? textStyle,
  }) {
    final maxV = maxValue <= 0 ? 1 : maxValue;
    final frac = value / maxV;
    final barW = (frac * maxWidth).clamp(0.0, maxWidth);

    return pw.Container(
      height: _barHeight,
      decoration: pw.BoxDecoration(
        color: fillBack,
        borderRadius: pw.BorderRadius.circular(_barRadius),
      ),
      child: pw.Stack(
        children: [
          // Gevulde voorgrond-balk
          pw.Positioned.fill(
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: barW,
                height: _barHeight,
                decoration: pw.BoxDecoration(
                  color: fill,
                  borderRadius: pw.BorderRadius.circular(_barRadius),
                ),
              ),
            ),
          ),
          // Cijfer in het midden
          pw.Positioned.fill(
            child: pw.Center(
              child: pw.Text(
                value.toString(),
                style: (textStyle ?? const pw.TextStyle(fontSize: 12)).copyWith(
                  color: p.PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
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
    int? fixedMax, // zet deze om L/R dezelfde schaal te geven
  }) {
    final values = [for (final t in typesOrder) counts[t] ?? 0];
    final maxValue = fixedMax ?? (values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b));

    if (typesOrder.isEmpty) {
      return pw.Container(
        height: _barHeight,
        alignment: pw.Alignment.centerLeft,
        child: pw.Text('-', style: const pw.TextStyle(fontSize: 10, color: p.PdfColors.grey700)),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < typesOrder.length; i++) ...[
          _barRow(
            value: values[i],
            maxValue: maxValue,
            maxWidth: maxWidth,
            fill: fill,
            fillBack: fillBack,
          ),
          if (i != typesOrder.length - 1) pw.SizedBox(height: _barGap),
        ],
      ],
    );
  }

  static pw.Widget _labelList({required List<GoalType> typesOrder}) {
    if (typesOrder.isEmpty) {
      return pw.Text('-', style: const pw.TextStyle(fontSize: 10, color: p.PdfColors.grey700));
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < typesOrder.length; i++) ...[
          pw.Text(
            typesOrder[i].label,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (i != typesOrder.length - 1) pw.SizedBox(height: _barGap),
        ],
      ],
    );
  }

  // ======= Afstand (7m/5m/2m) =======
  static Map<String, int> _distanceCounts(List<Goal> goals) {
    int c2 = 0, c5 = 0, c7 = 0;
    for (final g in goals) {
      final lbl = g.type.label.toLowerCase();
      if (lbl.contains('7m')) c2++;
      if (lbl.contains('5m')) c5++;
      if (lbl.contains('2m')) c7++;
    }
    return {'7m': c2, '5m': c5, '2m': c7};
  }

  static p.PdfColor _lerpColor(p.PdfColor a, p.PdfColor b, double t) {
    t = t.clamp(0, 1);
    return p.PdfColor(
      a.red + (b.red - a.red) * t,
      a.green + (b.green - a.green) * t,
      a.blue + (b.blue - a.blue) * t,
    );
  }

  // Getal-overlay in de ring (voor kwart-cirkel)
  // ringIndex: 0 = buiten (7m), 1 = midden (5m), 2 = binnen (2m)
  static pw.Widget _ringNumberOverlayQuarter({
    required bool rightSide,
    required double width,
    required double height,
    required int ringIndex,
    required int value,
  }) {
    const ringGap = 4.0;
    const ringCount = 3;
    final outerR = height;
    final ringWidth = (height - (ringGap * (ringCount - 1))) / ringCount;

    final rOuter = outerR - ringIndex * (ringWidth + ringGap);
    final rMid = rOuter - ringWidth / 2;

    final cx = rightSide ? width : 0.0;
    final cy = 0.0;

    // Hoek kiezen zodat label ‘in’ het zichtbare kwart ligt:
    final double angle = rightSide ? (3 * math.pi / 4) : (math.pi / 4); // 135° resp. 45°
    final tx = cx + rMid * math.cos(angle);
    final ty = cy + rMid * math.sin(angle); // PDF y-as omhoog

    // Stack gebruikt top-links met y omlaag -> spiegelen met hoogte
    final left = tx - 7;
    final top  = height - ty - 7;

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Container(
        width: 14,
        height: 14,
        alignment: pw.Alignment.center,
        child: pw.Text(
          value.toString(),
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: p.PdfColors.white,
          ),
        ),
      ),
    );
  }

  // Klein randlabel (7m/5m/2m) vanuit onderrand
  static pw.Widget _edgeLabel(String text, {required bool alignLeft, required double bottom}) {
    return pw.Positioned(
      left: alignLeft ? 0 : null,
      right: alignLeft ? null : 0,
      bottom: bottom,
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9, color: p.PdfColors.black),
      ),
    );
  }

  // Twee kwart-‘heatmaps’ met functionele painter (compatibel met package:pdf)
  static pw.Widget _distanceSemiCirclesSection({
    required List<Goal> goalsScored,
    required List<Goal> goalsConceded,
    double height = 110,
  }) {
    final left = _distanceCounts(goalsScored);     // {2m,5m,7m}
    final right = _distanceCounts(goalsConceded);  // {2m,5m,7m}

    final maxLeft = [left['2m']!, left['5m']!, left['7m']!].reduce((a, b) => a > b ? a : b);
    final maxRight = [right['2m']!, right['5m']!, right['7m']!].reduce((a, b) => a > b ? a : b);

    final widthEach = height * 1.7;

    pw.Widget quarter({
      required bool rightSide,
      required Map<String, int> values,
      required p.PdfColor baseColor,
      required int maxValue,
    }) {
      // kleuren (licht -> donker)
      final shades = [
        _lerpColor(baseColor, p.PdfColors.white, 0.55),
        _lerpColor(baseColor, p.PdfColors.white, 0.35),
        baseColor,
      ];
      final seq = [values['7m']!, values['5m']!, values['2m']!]; // buiten -> binnen

      return pw.Container(
        width: widthEach,
        height: height,
        child: pw.Stack(
          children: [
            // Clip op de kaart en teken volledige cirkels met middelpunt in de HOEK.
            pw.ClipRect(
              child: pw.CustomPaint(
                size: p.PdfPoint(widthEach, height),
                painter: (p.PdfGraphics canvas, p.PdfPoint size) {
                  final cx = rightSide ? size.x : 0.0;
                  final cy = 0.0;
                  const ringGap = 4.0;
                  const ringCount = 3;
                  final outerR = size.y; // straal = hoogte
                  final ringWidth = (size.y - (ringGap * (ringCount - 1))) / ringCount;

                  final maxV = maxValue <= 0 ? 1 : maxValue;

                  for (int i = 0; i < ringCount; i++) {
                    final rOuter = outerR - i * (ringWidth + ringGap);
                    final rInner = rOuter - ringWidth;

                    final t = (seq[i] / maxV).clamp(0.0, 1.0);
                    final col = _lerpColor(shades[i], baseColor, t * 0.6);

                    // buitenste schijf
                    canvas
                      ..setFillColor(col)
                      ..drawEllipse(cx, cy, rOuter, rOuter)
                      ..fillPath();

                    // binnenste uitsnijden (wit) => ring
                    canvas
                      ..setFillColor(p.PdfColors.white)
                      ..drawEllipse(cx, cy, rInner, rInner)
                      ..fillPath();
                  }

                  // dunne baseline
                  final lineColor = _lerpColor(baseColor, p.PdfColors.black, 0.2);
                  canvas
                    ..setLineWidth(0.5)
                    ..setStrokeColor(lineColor)
                    ..moveTo(0, 0)
                    ..lineTo(size.x, 0)
                    ..strokePath();
                },
              ),
            ),

            // Waarden in de ringen (buiten -> binnen)
            _ringNumberOverlayQuarter(
              rightSide: rightSide, width: widthEach, height: height, ringIndex: 0, value: seq[0],
            ),
            _ringNumberOverlayQuarter(
              rightSide: rightSide, width: widthEach, height: height, ringIndex: 1, value: seq[1],
            ),
            _ringNumberOverlayQuarter(
              rightSide: rightSide, width: widthEach, height: height, ringIndex: 2, value: seq[2],
            ),

            // Randlabels (ongeveer vaste posities vanaf onderrand)
            _edgeLabel('2m', alignLeft: !rightSide, bottom: height * .25),
            _edgeLabel('5m', alignLeft: !rightSide, bottom: height * .50),
            _edgeLabel('7m', alignLeft: !rightSide, bottom: height * .80),
          ],
        ),
      );
    }

    return pw.Container(
      height: height,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Linker kwart (groen)
          quarter(
            rightSide: false,
            values: left,
            baseColor: _green,
            maxValue: maxLeft,
          ),
          // Rechter kwart (rood)
          quarter(
            rightSide: true,
            values: right,
            baseColor: _red,
            maxValue: maxRight,
          ),
        ],
      ),
    );
  }

  // De complete spelerskaart in 3 kolommen + kwart-cirkel heatmaps eronder
  static pw.Widget _playerCard({
    required int playerNumber,
    required String playerName,
    required List<Goal> goalsScored,
    required List<Goal> goalsConceded,
    double cardWidth = 360,
  }) {
    final typesOrder = _nonDistanceTypes();
    final scoredCounts = _countByType(goalsScored);
    final concededCounts = _countByType(goalsConceded);

    // Layout-constanten
    const horizontalPad = 10.0;
    const verticalPad = 8.0;
    const colGap = 12.0;

    // Breedtes 3-koloms balkenlayout
    final innerWidth = cardWidth - 2 * horizontalPad;
    final colLeftWidth = innerWidth * 0.37;   // balken links
    final colCenterWidth = innerWidth * 0.26; // labels
    final colRightWidth = innerWidth * 0.37;  // balken rechts


    return pw.Container(
      width: cardWidth,
      padding: const pw.EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: p.PdfColors.grey600, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Titelrij
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Doelpunten', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _green)),
              pw.Text(
                playerName,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Tegendoelpunten', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _red)),
            ],
          ),
          pw.SizedBox(height: 6),

          // 3 Kolommen
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Links balken
              pw.Container(
                width: colLeftWidth,
                child: _barList(
                  counts: scoredCounts,
                  typesOrder: typesOrder,
                  fill: _green,
                  fillBack: _greenBack,
                  maxWidth: colLeftWidth,
                  // fixedMax: sharedMax,
                ),
              ),
              pw.SizedBox(width: colGap),

              // Midden labels
              pw.Container(
                width: colCenterWidth,
                child: _labelList(typesOrder: typesOrder),
              ),
              pw.SizedBox(width: colGap),

              // Rechts balken
              pw.Container(
                width: colRightWidth,
                child: _barList(
                  counts: concededCounts,
                  typesOrder: typesOrder,
                  fill: _red,
                  fillBack: _redBack,
                  maxWidth: colRightWidth,
                  // fixedMax: sharedMax,
                ),
              ),
            ],
          ),

          // Kwart-cirkel afstand heatmaps
          pw.SizedBox(height: 10),
          _distanceSemiCirclesSection(
            goalsScored: goalsScored,
            goalsConceded: goalsConceded,
            height: 110,
          ),
        ],
      ),
    );
  }
}