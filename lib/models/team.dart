// lib/models/team.dart
import 'players.dart';

class Team {
  final String id;
  final String name;
  final String abbreviation;
  final TeamPlayers players;

  Team({required this.id, required this.name, required this.abbreviation, required this.players});

  factory Team.create({String? id, required String name, String? abbreviation, TeamPlayers? players}) {
    final abbr = abbreviation ?? _abbrevFromName(name);
    return Team(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      abbreviation: abbr,
      players: players ?? TeamPlayers.default8(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
        'players': players.toJson(),
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        abbreviation: json['abbreviation'] as String,
        players: json['players'] != null
            ? TeamPlayers.fromJson(Map<String, dynamic>.from(json['players'] as Map))
            : TeamPlayers.default8(),
      );

  @override
  String toString() => 'Team($id,$name,$abbreviation,players=${players.names.length})';
}

String _abbrevFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
}
