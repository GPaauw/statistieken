// lib/models/players.dart

class Player {
  final int number;
  final String name;

  Player({
    required this.number,
    required this.name,
  });
}

class TeamPlayers {
  final Map<int, String> names;

  TeamPlayers({required this.names});

  factory TeamPlayers.default16() {
    return TeamPlayers(
      names: {for (int i = 1; i <= 16; i++) i: "Speler $i"},
    );
  }

  factory TeamPlayers.default8() {
    return TeamPlayers(
      names: {for (int i = 1; i <= 8; i++) i: "Speler $i"},
    );
  }

  List<Player> get players => names.entries
      .map((e) => Player(number: e.key, name: e.value))
      .toList();

  String getName(int number) => names[number] ?? "Speler $number";

  TeamPlayers copyWithName(int number, String newName) {
    final updated = Map<int, String>.from(names);
    updated[number] =
        newName.trim().isEmpty ? "Speler $number" : newName.trim();
    return TeamPlayers(names: updated);
  }

  TeamPlayers addOne() {
    final updated = Map<int, String>.from(names);
    final next = updated.keys.isEmpty ? 1 : updated.keys.reduce((a, b) => a > b ? a : b) + 1;
    updated[next] = "Speler $next";
    return TeamPlayers(names: updated);
  }

  Map<String, String> toJson() => {for (final e in names.entries) e.key.toString(): e.value};

  factory TeamPlayers.fromJson(Map<String, dynamic> json) {
    final map = <int, String>{};
    for (final entry in json.entries) {
      final key = int.tryParse(entry.key) ?? 0;
      if (key > 0) map[key] = entry.value as String;
    }
    return TeamPlayers(names: map);
  }
}