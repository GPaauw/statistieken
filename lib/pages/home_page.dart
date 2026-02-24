// lib/pages/home_page.dart
import 'package:flutter/material.dart';

import '../controllers/match_controller.dart';
import '../models/goal.dart';
import '../models/players.dart';

import '../widgets/timer_display.dart';
import '../widgets/team_players_columns.dart';
import '../widgets/goal_type_picker.dart';
import '../widgets/player_name_editor.dart';
import '../widgets/conceded_player_picker.dart';
import '../services/pdf_exporter.dart'; // 👈 nieuw

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final MatchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MatchController(onTick: _safeSetState);
  }

  void _safeSetState() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// PDF exporteren (Methode A)
  Future<void> _exportPdf() async {
    await PdfExporter.shareReport(
      c: _controller,
      homeTeamName: "KV Flamingo's",
      awayTeamName: 'Tegenstanders',
      fileName: 'wedstrijdverslag.pdf',
    );
  }

  /// Flow:
  /// 1) speler (#) kiezen
  /// 2) type popup
  /// 3) EXTRA: als UIT scoort → popup met THUIS-spelers "Tegen: ..."
  Future<void> _pickTypeAndAdd(Team scoringTeam, int playerNumber) async {
    final type = await showGoalTypePicker(context);
    if (type == null) return;

    int? conceded;
    if (scoringTeam == Team.away) {
      conceded = await showConcededPlayerPicker(
        context: context,
        defendingTeam: Team.home,
        players: _controller.homePlayers,
      );
      if (conceded == null) return;
    }

    _controller.addGoal(
      scoringTeam,
      playerNumber,
      type,
      concededPlayerNumber: conceded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _GoalTimeline(
      goals: _controller.goals,
      homePlayers: _controller.homePlayers,
      awayPlayers: _controller.awayPlayers,
    );

    final scores = _ScoreBoard(
      homeScore: _controller.homeScore,
      awayScore: _controller.awayScore,

      onHomePick: (n) => _pickTypeAndAdd(Team.home, n),
      onAwayPick: (n) => _pickTypeAndAdd(Team.away, n),

      homeCounts: _countsByPlayer(Team.home),
      awayCounts: _countsByPlayer(Team.away),

      homePlayers: _controller.homePlayers,
      awayPlayers: _controller.awayPlayers,

      onEditHomePlayers: (p) => _controller.updateHomePlayers(p),
      onEditAwayPlayers: (p) => _controller.updateAwayPlayers(p),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistieken'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Ongedaan',
            icon: const Icon(Icons.undo),
            onPressed: _controller.canUndo
                ? () {
                    _controller.undo();
                    _safeSetState();
                  }
                : null,
          ),
          IconButton(
            tooltip: 'Exporteer PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Timer + besturing
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        TimerDisplay(
                          seconds: _controller.elapsedSeconds,
                          isRunning: _controller.isRunning,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: _controller.start,
                              label: const Text('Start'),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.pause),
                              onPressed: _controller.stop,
                              label: const Text('Stop'),
                            ),
                            // Undo moved to AppBar for consistent visibility
                            TextButton.icon(
                              icon: const Icon(Icons.replay),
                              onPressed: _controller.reset,
                              label: const Text('Reset'),
                            ),
                            // 👇 Extra knop om ook hier te exporteren
                            FilledButton.icon(
                              icon: const Icon(Icons.picture_as_pdf),
                              onPressed: _exportPdf,
                              label: const Text('Exporteer PDF'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Scorebord + Timeline naast elkaar (breed) of onder elkaar (smal)
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: scores),
                          const SizedBox(width: 16),
                          Expanded(child: timeline),
                        ],
                      )
                    : Column(
                        children: [
                          scores,
                          const SizedBox(height: 16),
                          timeline,
                        ],
                      ),
              ],
            ),
          );
        },
      ),

      // onderbalk: status
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Tijd: ${_format(_controller.elapsedSeconds)}  |  '
            'Doelpunten: ${_controller.goals.length}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Map<int, int> _countsByPlayer(Team team) {
    final map = <int, int>{};
    for (final g in _controller.goals.where((g) => g.team == team)) {
      map[g.playerNumber] = (map[g.playerNumber] ?? 0) + 1;
    }
    return map;
  }
}

// ===================== SCOREBOARD ========================

class _ScoreBoard extends StatelessWidget {
  final int homeScore;
  final int awayScore;

  final void Function(int) onHomePick;
  final void Function(int) onAwayPick;

  final Map<int, int>? homeCounts;
  final Map<int, int>? awayCounts;

  final TeamPlayers homePlayers;
  final TeamPlayers awayPlayers;

  final void Function(TeamPlayers) onEditHomePlayers;
  final void Function(TeamPlayers) onEditAwayPlayers;

  const _ScoreBoard({
    required this.homeScore,
    required this.awayScore,
    required this.onHomePick,
    required this.onAwayPick,
    required this.homeCounts,
    required this.awayCounts,
    required this.homePlayers,
    required this.awayPlayers,
    required this.onEditHomePlayers,
    required this.onEditAwayPlayers,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Scorebord',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _TeamScore(
                    team: Team.home,
                    title: "KV Flamingo's",
                    score: homeScore,
                    color: Colors.blue.shade600,
                    onPick: onHomePick,
                    counts: homeCounts,
                    players: homePlayers,
                    onEditPlayers: onEditHomePlayers,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TeamScore(
                    team: Team.away,
                    title: 'Tegenstanders',
                    score: awayScore,
                    color: Colors.red.shade600,
                    onPick: onAwayPick,
                    counts: awayCounts,
                    players: awayPlayers,
                    onEditPlayers: onEditAwayPlayers,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== TEAM SCORE (per team) ========================

class _TeamScore extends StatelessWidget {
  final Team team;
  final String title;
  final int score;
  final Color color;

  final void Function(int) onPick; // klik op spelersknop (#n)
  final Map<int, int>? counts;

  final TeamPlayers players;
  final void Function(TeamPlayers) onEditPlayers;

  const _TeamScore({
    required this.team,
    required this.title,
    required this.score,
    required this.color,
    required this.onPick,
    required this.players,
    required this.onEditPlayers,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Titel
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          // Bewerk namen
          TextButton.icon(
            onPressed: () async {
              final updated = await showPlayerNameEditor(context, players);
              if (updated != null) {
                onEditPlayers(updated);
              }
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Bewerk namen'),
          ),

          const SizedBox(height: 8),

          // Totaalscore
          Text(
            '$score',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),

          const SizedBox(height: 12),

          // Twee kolommen met spelerknoppen (namen)
          TeamPlayersColumns(
            team: team,
            players: players,
            onPick: onPick,
            showGoalCount: counts != null,
            goalCountsByPlayer: counts,
          ),
        ],
      ),
    );
  }
}

// ===================== TIMELINE ========================

class _GoalTimeline extends StatelessWidget {
  final List<Goal> goals;
  final TeamPlayers homePlayers;
  final TeamPlayers awayPlayers;

  const _GoalTimeline({
    required this.goals,
    required this.homePlayers,
    required this.awayPlayers,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Nog geen doelpunten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goals.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final g = goals[index];
            final isHome = g.team == Team.home;

            final scorerName =
                isHome ? homePlayers.getName(g.playerNumber)
                       : awayPlayers.getName(g.playerNumber);

            final concededName = g.concededPlayerNumber == null
                ? null
                : homePlayers.getName(g.concededPlayerNumber!); // in jouw flow alleen bij UIT

            return ListTile(
              leading: Icon(
                isHome ? Icons.home : Icons.flight_takeoff,
                color: isHome ? Colors.blue : Colors.red,
              ),
              title: Text('${g.teamLabel} $scorerName — ${g.type.label}'),
              subtitle: concededName == null ? null : Text('Tegen: $concededName'),
              trailing: Text(g.formattedTime),
              isThreeLine: concededName != null,
            );
          },
        ),
      ),
    );
  }
}