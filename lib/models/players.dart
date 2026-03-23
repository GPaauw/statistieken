// lib/models/players.dart

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
}