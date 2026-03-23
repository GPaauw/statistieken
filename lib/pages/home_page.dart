import 'package:flutter/material.dart';

import '../controllers/match_controller.dart';
import '../models/goal.dart';
import '../models/match_event.dart';
import '../models/players.dart';
import '../services/pdf_exporter.dart';
import '../services/team_names.dart';
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
      homeTeamName: TeamNames.homeTeamName,
      awayTeamName: TeamNames.awayTeamName,
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

  Future<void> _pickGoalAction(int playerNumber) async {
    final selection = await _showTwoOptionPicker(
      title: 'Doelpunt registreren',
      primaryLabel: 'Voor',
      secondaryLabel: 'Tegen',
      primaryColor: Colors.blue.shade700,
      secondaryColor: Colors.red.shade600,
    );

    if (selection == null) return;

    if (selection == _TwoOptionSelection.primary) {
      await _pickTypeAndAddHomeGoal(playerNumber);
      return;
    }

    await _pickTypeAndAddConcededGoal(playerNumber);
  }

  Future<void> _pickReboundAction(int playerNumber) async {
    final selection = await _showTwoOptionPicker(
      title: 'Rebound registreren',
      primaryLabel: 'Gewonnen',
      secondaryLabel: 'Verloren',
      primaryColor: Colors.green.shade700,
      secondaryColor: Colors.red.shade600,
    );

    if (selection == null) return;

    if (selection == _TwoOptionSelection.primary) {
      _controller.addReboundWon(playerNumber);
    } else {
      _controller.addReboundLost(playerNumber);
    }
  }

  Future<_TwoOptionSelection?> _showTwoOptionPicker({
    required String title,
    required String primaryLabel,
    required String secondaryLabel,
    required Color primaryColor,
    required Color secondaryColor,
  }) async {
    return showModalBottomSheet<_TwoOptionSelection>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext, _TwoOptionSelection.primary);
                  },
                  child: Text(primaryLabel),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext, _TwoOptionSelection.secondary);
                  },
                  child: Text(secondaryLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playersPanel = _HomePlayersPanel(
      players: _controller.homePlayers,
      onGoalPick: _pickGoalAction,
      onReboundPick: _pickReboundAction,
      onAssistPick: (playerNumber) => _controller.addAssist(playerNumber),
      onInterceptionPick: (playerNumber) =>
          _controller.addInterception(playerNumber),
      onEditPlayers: (players) => _controller.updateHomePlayers(players),
    );

    final overviewPanel = _MatchOverviewPanel(
      homeScore: _controller.homeScore,
      awayScore: _controller.awayScore,
      elapsedSeconds: _controller.elapsedSeconds,
      isRunning: _controller.isRunning,
      totalEvents: _controller.totalEventsCount,
      onStart: _controller.start,
      onStop: _controller.stop,
      onReset: _controller.reset,
      onUndo: _controller.canUndo ? () => _controller.undo() : null,
      onExportPdf: _exportPdf,
    );

    final timeline = _GoalTimeline(
      events: _controller.events,
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
}

class _HomePlayersPanel extends StatelessWidget {
  final TeamPlayers players;
  final void Function(int) onGoalPick;
  final void Function(int) onReboundPick;
  final void Function(int) onAssistPick;
  final void Function(int) onInterceptionPick;
  final void Function(TeamPlayers) onEditPlayers;

  const _HomePlayersPanel({
    required this.players,
    required this.onGoalPick,
    required this.onReboundPick,
    required this.onAssistPick,
    required this.onInterceptionPick,
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
                        'Registreer per speler doelpunt, rebound, assist of onderschepping.',
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
              onGoalPick: onGoalPick,
              onReboundPick: onReboundPick,
              onAssistPick: onAssistPick,
              onInterceptionPick: onInterceptionPick,
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
                        label: TeamNames.awayTeamName,
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
                  'Geregistreerde acties: $totalEvents',
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
  final List<PlayerEvent> events;
  final TeamPlayers homePlayers;

  const _GoalTimeline({required this.events, required this.homePlayers});

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
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Nog geen geregistreerde acties',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final playerName = homePlayers.getName(event.playerNumber);
                  final eventDisplay = _eventDisplay(event, playerName);

                  return ListTile(
                    leading: Icon(eventDisplay.icon, color: eventDisplay.color),
                    title: Text(eventDisplay.title),
                    subtitle: Text(eventDisplay.subtitle),
                    trailing: Text(event.formattedTime),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  _TimelineEventDisplay _eventDisplay(PlayerEvent event, String playerName) {
    switch (event.type) {
      case PlayerEventType.goalFor:
        return _TimelineEventDisplay(
          title: '$playerName scoort voor - ${event.goalType!.label}',
          subtitle: "KV Flamingo's",
          icon: Icons.add_circle,
          color: Colors.blue,
        );
      case PlayerEventType.goalAgainst:
        return _TimelineEventDisplay(
          title: '$playerName krijgt tegen - ${event.goalType!.label}',
          subtitle: TeamNames.awayTeamName,
          icon: Icons.remove_circle,
          color: Colors.red,
        );
      case PlayerEventType.reboundWon:
        return _TimelineEventDisplay(
          title: '$playerName pakt rebound',
          subtitle: 'Gewonnen rebound',
          icon: Icons.sports_basketball,
          color: Colors.orange.shade700,
        );
      case PlayerEventType.reboundLost:
        return _TimelineEventDisplay(
          title: '$playerName verliest rebound',
          subtitle: 'Verloren rebound',
          icon: Icons.sports_basketball_outlined,
          color: Colors.red.shade600,
        );
      case PlayerEventType.assist:
        return _TimelineEventDisplay(
          title: '$playerName geeft assist',
          subtitle: 'Assist',
          icon: Icons.handshake_outlined,
          color: Colors.teal.shade700,
        );
      case PlayerEventType.interception:
        return _TimelineEventDisplay(
          title: '$playerName pakt onderschepping',
          subtitle: 'Onderschepping',
          icon: Icons.front_hand_outlined,
          color: Colors.green.shade700,
        );
    }
  }
}

enum _TwoOptionSelection { primary, secondary }

class _TimelineEventDisplay {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _TimelineEventDisplay({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
