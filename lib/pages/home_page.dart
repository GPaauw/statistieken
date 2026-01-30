// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../controllers/match_controller.dart';
import '../models/goal.dart';
import '../widgets/timer_display.dart';
import '../widgets/team_players_columns.dart';
import '../widgets/goal_type_picker.dart';

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

  /// Eerst speler kiezen → daarna popup met type doelpunt
  Future<void> _pickTypeAndAdd(Team team, int playerNumber) async {
    final type = await showGoalTypePicker(context);
    if (type == null) return; // geannuleerd
    _controller.addGoal(team, playerNumber, type);
  }

  @override
  Widget build(BuildContext context) {
    final scores = _ScoreBoard(
      homeScore: _controller.homeScore,
      awayScore: _controller.awayScore,
      onHomePick: (n) => _pickTypeAndAdd(Team.home, n),
      onAwayPick: (n) => _pickTypeAndAdd(Team.away, n),
      homeCounts: _countsByPlayer(Team.home),
      awayCounts: _countsByPlayer(Team.away),
      homePlayers: _controller.homePlayers,
      awayPlayers: _controller.awayPlayers,
    );

    final timeline = _GoalTimeline(goals: _controller.goals);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wedstrijd teller'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

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

  final dynamic homePlayers;
  final dynamic awayPlayers;

  const _ScoreBoard({
    required this.homeScore,
    required this.awayScore,
    required this.onHomePick,
    required this.onAwayPick,
    required this.homeCounts,
    required this.awayCounts,
    required this.homePlayers,
    required this.awayPlayers,
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
                    onPick: onHomePick,
                    counts: homeCounts,
                    players: homePlayers,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TeamScore(
                    title: 'Uit',
                    score: awayScore,
                    color: Colors.red.shade600,
                    onPick: onAwayPick,
                    counts: awayCounts,
                    players: awayPlayers,
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

// ===================== TEAM SCORE COLUMN ========================

class _TeamScore extends StatelessWidget {
  final String title;
  final int score;
  final Color color;

  final void Function(int) onPick;
  final Map<int, int>? counts;

  final dynamic players;

  const _TeamScore({
    required this.title,
    required this.score,
    required this.color,
    required this.onPick,
    required this.players,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final team = title == 'Thuis' ? Team.home : Team.away;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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

          const SizedBox(height: 12),

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

            return ListTile(
              leading: Icon(
                isHome ? Icons.home : Icons.flight_takeoff,
                color: isHome ? Colors.blue : Colors.red,
              ),
              title: Text('${g.teamLabel} ${g.playerLabel} — ${g.type.label}'),
              trailing: Text(g.formattedTime),
            );
          },
        ),
      ),
    );
  }
}