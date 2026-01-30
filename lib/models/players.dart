// lib/models/players.dart

class TeamPlayers {
  final Map<int, String> names;

  TeamPlayers({required this.names});

  factory TeamPlayers.default16() {
    return TeamPlayers(
      names: {
        for (int i = 1; i <= 16; i++) i: 'Speler $i',
      },
    );
  }

  String getName(int number) => names[number] ?? 'Speler $number';

  TeamPlayers copyWithName(int number, String newName) {
    final newMap = Map<int, String>.from(names);
    newMap[number] = newName;
    return TeamPlayers(names: newMap);
  }
}

