// lib/services/pdf_exporter.dart
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;    // voor Text, Table, Row, etc.
import 'package:pdf/pdf.dart' as p;         // voor PdfColors
import 'package:printing/printing.dart';

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
      // concededPlayerNumber refers to a player on the defending team
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
          // For each home player render a compact table with goals by type and conceded by type.
          // Render two player cards per row when space allows.
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in (c.homePlayers.names.keys.toList()..cast<int>()..sort()))
                pw.Container(
                  width: 260,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: p.PdfColors.grey700),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(c.homePlayers.getName(n), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Goals scored by type (for this home player)
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Doelpunten', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 4),
                                _typeTable(c.goals.where((g) => g.team == Team.home && g.playerNumber == n).toList(), cell),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          // Goals conceded by type (when this player was the defender)
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Tegendoelpunten', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 4),
                                _typeTable(c.goals.where((g) => g.concededPlayerNumber == n).toList(), cell),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),

          pw.SizedBox(height: 12),
          // (Tegenstanders samenvatting verwijderd; alleen KV Flamingo's blijft)
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
    String fileName = 'wedstrijdverslag.pdf',
  }) async {
    final bytes = await buildReport(
      c: c,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      dateTime: dateTime,
    );

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  // Helper to render a small table with counts per GoalType for a list of goals.
  static pw.Widget _typeTable(List<Goal> goals, pw.TextStyle cellStyle) {
    // Count by type preserving enum order
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
}