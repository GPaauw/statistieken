// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../controllers/match_controller.dart';
import '../models/goal.dart';
import '../widgets/score_button.dart';
import '../widgets/timer_display.dart';
import '../widgets/player_picker.dart'; // 🔹 nieuw

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

  Future<void> _pickAndAddGoal(Team team) async {
    await showTeamPlayerPicker(
      context: context,
      team: team,
      onPick: (number) => _controller.addGoal(team, number),
    );
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
          final isWide = constraints.maxWidth > 700;
          final scores = _ScoreBoard(
            homeScore: _controller.homeScore,
            awayScore: _controller.awayScore,
            onHomeGoal: () => _pickAndAddGoal(Team.home), // 🔹 aangepast
            onAwayGoal: () => _pickAndAddGoal(Team.away), // 🔹 aangepast
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
}

class _ScoreBoard extends StatelessWidget {
  final int homeScore;
  final int awayScore;
  final VoidCallback onHomeGoal;
  final VoidCallback onAwayGoal;

  const _ScoreBoard({
    required this.homeScore,
    required this.awayScore,
    required this.onHomeGoal,
    required this.onAwayGoal,
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TeamScore(
                    title: 'Uit',
                    score: awayScore,
                    color: Colors.red.shade600,
                    onGoal: onAwayGoal,
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
  final VoidCallback onGoal;

  const _TeamScore({
    required this.title,
    required this.score,
    required this.color,
    required this.onGoal,
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
          const SizedBox(height: 8),
          // 🔹 Dit opent nu de spelerkeuze modal
          ScoreButton(
            label: 'Doelpunt',
            color: color,
            onPressed: onGoal,
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
                  title: Text('${g.teamLabel} ${g.playerLabel}'), // 🔹 speler erbij
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