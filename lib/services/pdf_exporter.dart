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
    String homeTeamName = 'Thuis',
    String awayTeamName = 'Uit',
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
      return c.homePlayers.getName(n);
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
                  '$home – $away',
                ]);
              }
              return rows;
            }(),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1.4),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.6),
              5: const pw.FlexColumnWidth(1.2),
            },
            cellAlignment: pw.Alignment.centerLeft,
          ),

          pw.SizedBox(height: 16),

          pw.Text('Samenvatting', style: h2),
          pw.SizedBox(height: 6),
          pw.Bullet(text: 'Totale speeltijd: ${fmtTime(c.elapsedSeconds)}'),
          pw.Bullet(text: 'Totaal doelpunten: ${c.goals.length}'),
          pw.Bullet(text: 'Thuis: ${c.homeScore}  |  Uit: ${c.awayScore}'),
        ],
      ),
    );

    return doc.save();
  }

  /// Download/share PDF (werkt op Web + mobiel + desktop)
  static Future<void> shareReport({
    required MatchController c,
    String homeTeamName = 'Thuis',
    String awayTeamName = 'Uit',
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
}