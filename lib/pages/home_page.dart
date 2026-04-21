import 'package:flutter/material.dart';

import '../controllers/match_controller.dart';
import '../models/goal.dart';
import '../models/match_event.dart';
import '../models/players.dart';
import '../services/pdf_exporter.dart';
import '../services/team_names.dart';
import '../widgets/team_editor.dart';
import '../widgets/team_management.dart';
import '../services/theme_service.dart';
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
    TeamNames.init().then((_) {
      final selected = TeamNames.selectedHomeTeam;
      if (selected != null) {
        _controller.updateHomePlayers(selected.players);
      }
      _safeSetState();
    });
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

  void _editAwayNameDialog() {
    final controller = TextEditingController(text: TeamNames.awayTeamName);
    showDialog<void>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('Bewerk tegenstandersnaam'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Naam tegenstanders'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: const Text('Annuleer'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                TeamNames.setNames(away: val);
                _safeSetState();
              }
              Navigator.of(dContext).pop();
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    try {
      await PdfExporter.shareReport(
        c: _controller,
        homeTeamName: TeamNames.homeTeamName,
        awayTeamName: TeamNames.awayTeamName,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF export mislukt: $error')));
    }
  }

  Future<void> _pickTypeAndAddHomeGoal(int playerNumber) async {
    final type = await showGoalTypePicker(context, title: 'Type doelpunt voor');
    if (type == null) return;

    _controller.addHomeGoal(playerNumber, type);
  }

  Future<void> _pickTypeAndAddConcededGoal(int playerNumber) async {
    final type = await showGoalTypePicker(
      context,
      title: 'Type doelpunt tegen',
    );
    if (type == null) return;

    _controller.addConcededGoal(playerNumber, type);
  }

  Future<void> _pickTypeAndAddMissedShot(int playerNumber) async {
    final type = await showGoalTypePicker(context, title: 'Type schot gemist');
    if (type == null) return;

    _controller.addMissedShot(playerNumber, type);
  }

  Future<void> _pickShotAction(int playerNumber) async {
    final selection = await _showShotPicker();

    if (selection == null) return;

    switch (selection) {
      case _ShotSelection.goalFor:
        await _pickTypeAndAddHomeGoal(playerNumber);
      case _ShotSelection.goalAgainst:
        await _pickTypeAndAddConcededGoal(playerNumber);
      case _ShotSelection.missed:
        await _pickTypeAndAddMissedShot(playerNumber);
    }
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

  Future<_ShotSelection?> _showShotPicker() async {
    return showModalBottomSheet<_ShotSelection>(
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
                  'Schot registreren',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext, _ShotSelection.goalFor);
                  },
                  child: const Text('Doelpunt voor'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext, _ShotSelection.goalAgainst);
                  },
                  child: const Text('Doelpunt tegen'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext, _ShotSelection.missed);
                  },
                  child: const Text('Schot gemist'),
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
      onShotPick: _pickShotAction,
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
      onEditAwayName: _editAwayNameDialog,
    );

    final timeline = _GoalTimeline(
      events: _controller.events,
      homePlayers: _controller.homePlayers,
    );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 180,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: PopupMenuButton<String>(
            tooltip: 'Thuissel',
            onSelected: (value) async {
              if (value.startsWith('select:')) {
                final id = value.substring('select:'.length);
                await TeamNames.selectHomeTeam(id);
                // load selected team's players into the match controller
                final selected = TeamNames.selectedHomeTeam;
                if (selected != null) {
                  _controller.updateHomePlayers(selected.players);
                }
                _safeSetState();
              } else if (value == 'new') {
                final created = await showTeamEditor(context);
                if (created != null) {
                  await TeamNames.addTeam(created);
                  await TeamNames.selectHomeTeam(created.id);
                  _controller.updateHomePlayers(created.players);
                  _safeSetState();
                }
              } else if (value == 'manage') {
                await showManageTeamsDialog(context);
                final selected = TeamNames.selectedHomeTeam;
                if (selected != null) {
                  _controller.updateHomePlayers(selected.players);
                }
                _safeSetState();
              }
            },
            itemBuilder: (ctx) {
              final items = <PopupMenuEntry<String>>[];
              for (final t in TeamNames.teams) {
                items.add(PopupMenuItem(
                  value: 'select:${t.id}',
                  child: Row(
                    children: [
                      CircleAvatar(radius: 14, child: Icon(Icons.checkroom, size: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.name)),
                    ],
                  ),
                ));
              }
              items.add(const PopupMenuDivider());
              items.add(const PopupMenuItem(value: 'new', child: Text('Nieuw team...')));
              items.add(const PopupMenuItem(value: 'manage', child: Text('Beheer teams...')));
              return items;
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.checkroom, size: 18),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(TeamNames.homeTeamName, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
        title: const Text('Statistieken'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.instance.modeNotifier,
              builder: (context, mode, _) {
                return IconButton(
                  onPressed: () => ThemeService.instance.toggle(),
                  icon: Icon(
                    mode == ThemeMode.dark ? Icons.nights_stay : Icons.wb_sunny,
                  ),
                  tooltip: 'Thema',
                );
              },
            ),
          ),
        ],
      ),
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
  final void Function(int) onShotPick;
  final void Function(int) onReboundPick;
  final void Function(int) onAssistPick;
  final void Function(int) onInterceptionPick;
  final void Function(TeamPlayers) onEditPlayers;

  const _HomePlayersPanel({
    required this.players,
    required this.onShotPick,
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
                        TeamNames.homeTeamName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registreer per speler schot, rebound, assist of onderschepping.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        final updated = players.addOne();
                        onEditPlayers(updated);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Speler toegevoegd')),
                        );
                      },
                      icon: const Icon(Icons.add),
                      tooltip: 'Speler toevoegen',
                    ),
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
              ],
            ),
            const SizedBox(height: 16),
            TeamPlayersColumns(
              players: players,
              onShotPick: onShotPick,
              onReboundPick: onReboundPick,
              onAssistPick: onAssistPick,
              onInterceptionPick: onInterceptionPick,
              onPlayersChanged: (updated) => onEditPlayers(updated),
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
  final VoidCallback onEditAwayName;

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
    required this.onEditAwayName,
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
                        label: TeamNames.homeTeamName,
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
                        onEdit: onEditAwayName,
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
  final VoidCallback? onEdit;

  const _ScoreValue({
    required this.label,
    required this.score,
    required this.color,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.edit, size: 16, color: color),
                ),
              ),
            ],
          ],
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
          subtitle: TeamNames.homeTeamName,
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
      case PlayerEventType.shotMissed:
        return _TimelineEventDisplay(
          title: '$playerName mist schot - ${event.goalType!.label}',
          subtitle: 'Schot gemist',
          icon: Icons.sports_soccer,
          color: Colors.orange.shade700,
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

enum _ShotSelection { goalFor, goalAgainst, missed }

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
