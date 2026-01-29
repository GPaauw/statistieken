// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../controllers/match_controller.dart';
import '../models/goal.dart';
import '../widgets/timer_display.dart';
import '../widgets/team_players_grid.dart'; // 🔹 nieuw: onze grid

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wedstrijd teller'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900; // iets ruimer voor twee kolommen
          final scores = _ScoreBoard(
            homeScore: _controller.homeScore,
            awayScore: _controller.awayScore,
            onHomeGoal: (n) => _controller.addGoal(Team.home, n),
            onAwayGoal: (n) => _controller.addGoal(Team.away, n),
            // Optioneel: geef counts door als je die knoppen wilt laten tellen
            homeCounts: _countsByPlayer(Team.home),
            awayCounts: _countsByPlayer(Team.away),
          );

          final timeline = _GoalTimeline(goals: _controller.goals);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                            TextButton.icon(
                              icon: const Icon(Icons.replay),
                              onPressed: _controller.reset,
                              label: const Text('Reset'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Tijd: ${_format(_controller.elapsedSeconds)} '
            ' | Doelpunten: ${_controller.goals.length}',
            style: theme.textTheme.bodyMedium,
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

class _ScoreBoard extends StatelessWidget {
  final int homeScore;
  final int awayScore;
  final void Function(int) onHomeGoal; // 🔹 krijgt het spelersnummer
  final void Function(int) onAwayGoal; // 🔹 krijgt het spelersnummer
  final Map<int, int>? homeCounts;     // 🔹 optioneel: teller per speler
  final Map<int, int>? awayCounts;

  const _ScoreBoard({
    required this.homeScore,
    required this.awayScore,
    required this.onHomeGoal,
    required this.onAwayGoal,
    this.homeCounts,
    this.awayCounts,
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
              children: [
                Expanded(
                  child: _TeamScore(
                    title: 'Thuis',
                    score: homeScore,
                    color: Colors.blue.shade600,
                    onGoal: onHomeGoal,
                    counts: homeCounts,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TeamScore(
                    title: 'Uit',
                    score: awayScore,
                    color: Colors.red.shade600,
                    onGoal: onAwayGoal,
                    counts: awayCounts,
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

class _TeamScore extends StatelessWidget {
  final String title;
  final int score;
  final Color color;
  final void Function(int) onGoal;
  final Map<int, int>? counts;

  const _TeamScore({
    required this.title,
    required this.score,
    required this.color,
    required this.onGoal,
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
          Text(title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              )),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          // 🔹 Hier komt de grid met 26 spelerknoppen
          TeamPlayersGrid(
            team: title == 'Thuis' ? Team.home : Team.away,
            playerCount: 26,
            columns: 8,
            visibleRows: 2, // toont 16 knoppen; scroll voor rest
            showGoalCount: counts != null,
            goalCountsByPlayer: counts,
            onPick: onGoal, // geeft het nummer door
          ),
        ],
      ),
    );
  }
}

class _GoalTimeline extends StatelessWidget {
  final List<Goal> goals;
  const _GoalTimeline({required this.goals});

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
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Doelpunten',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: goals.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final g = goals[index];
                final isHome = g.team == Team.home;
                return ListTile(
                  leading: Icon(
                    isHome ? Icons.home : Icons.flight_takeoff,
                    color: isHome ? Colors.blue : Colors.red,
                  ),
                  title: Text('${isHome ? 'Thuis' : 'Uit'} #${g.playerNumber}'),
                  trailing: Text(g.formattedTime),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}