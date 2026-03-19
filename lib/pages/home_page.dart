import 'package:flutter/material.dart';

import '../controllers/match_controller.dart';
import '../models/goal.dart';
import '../models/players.dart';
import '../services/pdf_exporter.dart';
import '../widgets/goal_type_picker.dart';
import '../widgets/player_name_editor.dart';
import '../widgets/team_players_columns.dart';
import '../widgets/timer_display.dart';

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

  Future<void> _exportPdf() async {
    await PdfExporter.shareReport(
      c: _controller,
      homeTeamName: "KV Flamingo's",
      awayTeamName: 'Tegenstanders',
    );
  }

  Future<void> _pickTypeAndAddHomeGoal(int playerNumber) async {
    final type = await showGoalTypePicker(context);
    if (type == null) return;

    _controller.addHomeGoal(playerNumber, type);
  }

  Future<void> _pickTypeAndAddConcededGoal(int playerNumber) async {
    final type = await showGoalTypePicker(context);
    if (type == null) return;

    _controller.addConcededGoal(playerNumber, type);
  }

  @override
  Widget build(BuildContext context) {
    final playersPanel = _HomePlayersPanel(
      players: _controller.homePlayers,
      scoredCounts: _countsByPlayer(Team.home),
      concededCounts: _countsByPlayer(Team.away),
      onScoredPick: _pickTypeAndAddHomeGoal,
      onConcededPick: _pickTypeAndAddConcededGoal,
      onEditPlayers: (players) => _controller.updateHomePlayers(players),
    );

    final overviewPanel = _MatchOverviewPanel(
      homeScore: _controller.homeScore,
      awayScore: _controller.awayScore,
      elapsedSeconds: _controller.elapsedSeconds,
      isRunning: _controller.isRunning,
      totalEvents: _controller.goals.length,
      onStart: _controller.start,
      onStop: _controller.stop,
      onReset: _controller.reset,
      onUndo: _controller.canUndo ? () => _controller.undo() : null,
      onExportPdf: _exportPdf,
    );

    final timeline = _GoalTimeline(
      goals: _controller.goals,
      homePlayers: _controller.homePlayers,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Statistieken'), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1150;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: playersPanel),
                      const SizedBox(width: 16),
                      SizedBox(width: 320, child: overviewPanel),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: timeline),
                    ],
                  )
                : Column(
                    children: [
                      overviewPanel,
                      const SizedBox(height: 16),
                      playersPanel,
                      const SizedBox(height: 16),
                      timeline,
                    ],
                  ),
          );
        },
      ),
    );
  }

  Map<int, int> _countsByPlayer(Team team) {
    final map = <int, int>{};
    for (final goal in _controller.goals.where((g) => g.team == team)) {
      map[goal.playerNumber] = (map[goal.playerNumber] ?? 0) + 1;
    }
    return map;
  }
}

class _HomePlayersPanel extends StatelessWidget {
  final TeamPlayers players;
  final Map<int, int> scoredCounts;
  final Map<int, int> concededCounts;
  final void Function(int) onScoredPick;
  final void Function(int) onConcededPick;
  final void Function(TeamPlayers) onEditPlayers;

  const _HomePlayersPanel({
    required this.players,
    required this.scoredCounts,
    required this.concededCounts,
    required this.onScoredPick,
    required this.onConcededPick,
    required this.onEditPlayers,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "KV Flamingo's",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Klik per speler op Doelpunt of Tegen en kies daarna het type.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () async {
                    final updated = await showPlayerNameEditor(
                      context,
                      players,
                    );
                    if (updated != null) {
                      onEditPlayers(updated);
                    }
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Bewerk namen'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TeamPlayersColumns(
              players: players,
              onScoredPick: onScoredPick,
              onConcededPick: onConcededPick,
              scoredCountsByPlayer: scoredCounts,
              concededCountsByPlayer: concededCounts,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchOverviewPanel extends StatelessWidget {
  final int homeScore;
  final int awayScore;
  final int elapsedSeconds;
  final bool isRunning;
  final int totalEvents;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final VoidCallback? onUndo;
  final Future<void> Function() onExportPdf;

  const _MatchOverviewPanel({
    required this.homeScore,
    required this.awayScore,
    required this.elapsedSeconds,
    required this.isRunning,
    required this.totalEvents,
    required this.onStart,
    required this.onStop,
    required this.onReset,
    required this.onUndo,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Wedstrijd',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ScoreValue(
                        label: "KV Flamingo's",
                        score: homeScore,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '-',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Expanded(
                      child: _ScoreValue(
                        label: 'Tegenstanders',
                        score: awayScore,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TimerDisplay(seconds: elapsedSeconds, isRunning: isRunning),
                const SizedBox(height: 16),
                Text(
                  'Geregistreerde momenten: $totalEvents',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: isRunning ? null : onStart,
                  label: const Text('Start'),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.pause),
                  onPressed: isRunning ? onStop : null,
                  label: const Text('Stop'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.replay),
                  onPressed: onReset,
                  label: const Text('Reset'),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.undo),
                  onPressed: onUndo,
                  label: const Text('Ongedaan'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => onExportPdf(),
                  label: const Text('Exporteer PDF'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreValue extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreValue({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GoalTimeline extends StatelessWidget {
  final List<Goal> goals;
  final TeamPlayers homePlayers;

  const _GoalTimeline({required this.goals, required this.homePlayers});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Text(
                'Tijdlijn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            if (goals.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Nog geen doelpunten',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: goals.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final isHome = goal.team == Team.home;
                  final playerName = homePlayers.getName(goal.playerNumber);
                  final title = isHome
                      ? '$playerName scoort - ${goal.type.label}'
                      : '$playerName krijgt tegen - ${goal.type.label}';

                  return ListTile(
                    leading: Icon(
                      isHome ? Icons.add_circle : Icons.remove_circle,
                      color: isHome ? Colors.blue : Colors.red,
                    ),
                    title: Text(title),
                    subtitle: Text(goal.teamLabel),
                    trailing: Text(goal.formattedTime),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
