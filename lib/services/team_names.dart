// lib/services/team_names.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/team.dart';

/// Team management + persistence facade used by the UI.
class TeamNames {
  static const _teamsKey = 'teams_v1';
  static const _selectedHomeKey = 'selected_home_team_v1';
  static const _awayKey = 'away_team_name_v1';

  static List<Team> _teams = [];
  static String _awayTeamName = 'Tegenstanders';
  static String? _selectedHomeTeamId;

  /// Initialize from SharedPreferences. Safe to call multiple times.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teamsJson = prefs.getString(_teamsKey);
      if (teamsJson != null) {
        final raw = json.decode(teamsJson) as List<dynamic>;
        _teams = raw
            .map((e) => Team.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      _selectedHomeTeamId = prefs.getString(_selectedHomeKey);
      _awayTeamName = prefs.getString(_awayKey) ?? _awayTeamName;

      if (_teams.isEmpty) {
        final defaultTeam = Team.create(name: "KV Flamingo's", abbreviation: 'KF');
        _teams = [defaultTeam];
        _selectedHomeTeamId ??= defaultTeam.id;
        await _saveTeams();
      } else {
        _selectedHomeTeamId ??= _teams.first.id;
      }
    } catch (_) {
      // fallback defaults
      _teams = [Team.create(name: "KV Flamingo's", abbreviation: 'KF')];
      _selectedHomeTeamId ??= _teams.first.id;
    }
  }

  static List<Team> get teams => List.unmodifiable(_teams);

  static Team? get selectedHomeTeam {
    if (_teams.isEmpty) return null;
    if (_selectedHomeTeamId == null) return _teams.first;
    try {
      return _teams.firstWhere((t) => t.id == _selectedHomeTeamId);
    } catch (_) {
      return _teams.first;
    }
  }

  static String get homeTeamName => selectedHomeTeam?.name ?? "KV Flamingo's";

  static String get awayTeamName => _awayTeamName;

  /// Set either home name (select or create team) or away name.
  /// This is intentionally synchronous for simple callers; persistence runs
  /// in the background when needed.
  static void setNames({String? home, String? away}) {
    if (away != null) {
      _awayTeamName = away;
      SharedPreferences.getInstance().then((p) => p.setString(_awayKey, away));
    }

    if (home != null) {
      final idx = _teams.indexWhere((t) => t.name == home);
      if (idx >= 0) {
        _selectedHomeTeamId = _teams[idx].id;
        SharedPreferences.getInstance().then((p) => p.setString(_selectedHomeKey, _selectedHomeTeamId!));
      } else {
        final created = Team.create(name: home, abbreviation: _abbrevFromName(home));
        _teams.add(created);
        _selectedHomeTeamId = created.id;
        _saveTeams();
      }
    }
  }

  static Future<void> addTeam(Team t) async {
    _teams.add(t);
    await _saveTeams();
  }

  static Future<void> updateTeam(Team t) async {
    final idx = _teams.indexWhere((x) => x.id == t.id);
    if (idx >= 0) {
      _teams[idx] = t;
      await _saveTeams();
    }
  }

  static Future<void> deleteTeam(String id) async {
    _teams.removeWhere((t) => t.id == id);
    if (_selectedHomeTeamId == id) {
      _selectedHomeTeamId = _teams.isNotEmpty ? _teams.first.id : null;
    }
    await _saveTeams();
    final prefs = await SharedPreferences.getInstance();
    if (_selectedHomeTeamId != null) {
      await prefs.setString(_selectedHomeKey, _selectedHomeTeamId!);
    } else {
      await prefs.remove(_selectedHomeKey);
    }
  }

  static Future<void> selectHomeTeam(String id) async {
    _selectedHomeTeamId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedHomeKey, id);
  }

  static Future<void> _saveTeams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teamsKey, json.encode(_teams.map((t) => t.toJson()).toList()));
    await prefs.setString(_awayKey, _awayTeamName);
    if (_selectedHomeTeamId != null) await prefs.setString(_selectedHomeKey, _selectedHomeTeamId!);
  }

  static String _abbrevFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }
}

