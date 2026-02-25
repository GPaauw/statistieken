// lib/services/pdf_exporter.dart
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as p;
import 'package:printing/printing.dart';

import '../controllers/match_controller.dart';
import '../models/goal.dart';

class PdfExporter {
  static Future<Uint8List> buildReport({
    required MatchController c,
    String homeTeamName = "KV Flamingo's",
    String awayTeamName = "Tegenstanders",
    DateTime? dateTime,
  }) async {
    final now = dateTime ?? DateTime.now();
    final doc = pw.Document();

    // Helpers
    String fmt2(int v) => v.toString().padLeft(2, '0');
    String fmtTime(int s) => "${fmt2(s ~/ 60)}:${fmt2(s % 60)}";

    String scorerName(Goal g) {
      return g.team == Team.home
          ? c.homePlayers.getName(g.playerNumber)
          : c.awayPlayers.getName(g.playerNumber);
    }

    String? concededName(Goal g) {
      if (g.concededPlayerNumber == null) return null;
      return g.team == Team.home
          ? c.awayPlayers.getName(g.concededPlayerNumber!)
          : c.homePlayers.getName(g.concededPlayerNumber!);
    }

    final h1 = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
    final h2 = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final cell = pw.TextStyle(fontSize: 11);

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // Titel
          pw.Text('Wedstrijdverslag', style: h1),
          pw.SizedBox(height: 4),
          pw.Text(
            "${fmt2(now.day)}-${fmt2(now.month)}-${now.year}  "
            "${fmt2(now.hour)}:${fmt2(now.minute)}",
            style: pw.TextStyle(color: p.PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),

          // Teams + score
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("$homeTeamName vs $awayTeamName", style: h2),
              pw.Text("Score: ${c.homeScore} - ${c.awayScore}", style: h2),
            ],
          ),
          pw.SizedBox(height: 12),

          // Doelpunten tabel
          _buildGoalsTable(c, homeTeamName, awayTeamName, fmtTime, scorerName, concededName, cell),

          pw.SizedBox(height: 16),
          pw.Text("Samenvatting", style: h2),
          pw.SizedBox(height: 6),

          pw.Bullet(text: "Totale speeltijd: ${fmtTime(c.elapsedSeconds)}"),
          pw.Bullet(text: "Totaal doelpunten: ${c.goals.length}"),
          pw.Bullet(
            text:
                "$homeTeamName: ${c.homeScore}  |  $awayTeamName: ${c.awayScore}",
          ),

          pw.SizedBox(height: 16),
          pw.Text("Spelerssamenvatting ($homeTeamName)", style: h2),
          pw.SizedBox(height: 8),

          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final n in (c.homePlayers.names.keys.toList()..sort()))
                _playerCard(
                  c: c,
                  playerNumber: n,
                  playerName: c.homePlayers.getName(n),
                ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Download/share PDF
  static Future<void> shareReport({
    required MatchController c,
    String homeTeamName = "KV Flamingo's",
    String awayTeamName = "Tegenstanders",
    DateTime? dateTime,
    String fileName = "wedstrijdverslag.pdf",
  }) async {
    final bytes = await buildReport(
      c: c,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      dateTime: dateTime,
    );

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  // ───────────────────────────────────────────────────────────────
  //  PDF SECTIONS
  // ───────────────────────────────────────────────────────────────

  static pw.Widget _buildGoalsTable(
    MatchController c,
    String homeTeam,
    String awayTeam,
    String Function(int) fmtTime,
    String Function(Goal) scorer,
    String? Function(Goal) conceded,
    pw.TextStyle cell,
  ) {
    int home = 0;
    int away = 0;

    final rows = <List<String>>[];

    for (final g in c.goals) {
      if (g.team == Team.home) {
        home++;
      } else {
        away++;
      }

      rows.add([
        fmtTime(g.secondStamp),
        g.team == Team.home ? homeTeam : awayTeam,
        scorer(g),
        g.type.label,
        conceded(g) ?? "",
        "$home - $away",
      ]);
    }

    return pw.Table.fromTextArray(
      headers: ['Tijd', 'Team', 'Speler', 'Type', 'Tegen', 'Stand'],
      data: rows,
      cellStyle: cell,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: p.PdfColors.grey300),
      border: null,
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(2.2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.0),
      },
    );
  }

  // ───────────────────────────────────────────────────────────────
  //  PLAYER CARD
  // ───────────────────────────────────────────────────────────────

  static pw.Widget _playerCard({
    required MatchController c,
    required int playerNumber,
    required String playerName,
  }) {
    final goals = c.goals
        .where((g) => g.team == Team.home && g.playerNumber == playerNumber)
        .toList();
    final conceded =
        c.goals.where((g) => g.concededPlayerNumber == playerNumber).toList();

    return pw.Container(
      width: 260,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: p.PdfColors.grey700),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            playerName,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          // Staafdiagrammen
          _barChart(goals.length, conceded.length),

          pw.SizedBox(height: 12),

          pw.Text("Doelpunten per type",
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _typeTable(goals, pw.TextStyle(fontSize: 9)),

          pw.SizedBox(height: 10),

          pw.Text("Tegendoelpunten per type",
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _typeTable(conceded, pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  //  BAR CHART
  // ───────────────────────────────────────────────────────────────

  static pw.Widget _barChart(int goals, int conceded) {
    const maxWidth = 130.0;

    int total = (goals + conceded == 0) ? 1 : (goals + conceded);

    double width(int v) => maxWidth * (v / total);

    pw.Widget bar(double w, p.PdfColor color) {
      return pw.Container(
        height: 10,
        width: w,
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(2),
        ),
      );
    }

    return pw.Column(
      children: [
        pw.Row(children: [
          pw.Expanded(child: pw.Text("Doelpunten: $goals", style: pw.TextStyle(fontSize: 10))),
          bar(width(goals), p.PdfColors.green800),
        ]),
        pw.SizedBox(height: 6),
        pw.Row(children: [
          pw.Expanded(child: pw.Text("Tegendoelpunten: $conceded", style: pw.TextStyle(fontSize: 10))),
          bar(width(conceded), p.PdfColors.red700),
        ]),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────
  //  TYPE TABLE
  // ───────────────────────────────────────────────────────────────

  static pw.Widget _typeTable(List<Goal> goals, pw.TextStyle cellStyle) {
    final counts = {for (var t in GoalType.values) t: 0};

    for (final g in goals) {
      counts[g.type] = (counts[g.type] ?? 0) + 1;
    }

    final rows = [
      for (final t in GoalType.values) [t.label, counts[t].toString()]
    ];

    return pw.Table.fromTextArray(
      headers: ['Type', 'Aantal'],
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: cellStyle,
      border: pw.TableBorder.all(color: p.PdfColors.grey600, width: .5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
    );
  }
}