class LineupModel {
  final int fixtureId;
  final int teamId;
  final String formation;
  final List<Player> startXI;
  final List<Player> substitutes;
  final Coach? coach;

  LineupModel({
    required this.fixtureId,
    required this.teamId,
    required this.formation,
    required this.startXI,
    required this.substitutes,
    this.coach,
  });

  factory LineupModel.fromJson(Map<String, dynamic> json) {
    return LineupModel(
      fixtureId: json['fixture_id'] ?? 0,
      teamId: json['team'] != null ? json['team']['id'] : (json['team_id'] ?? 0),
      formation: json['formation'] ?? '',
      startXI: (json['startXI'] as List<dynamic>?)
          ?.map((e) => Player.fromJson(e))
          .toList() ??
          [],
      substitutes: (json['substitutes'] as List<dynamic>?)
          ?.map((e) => Player.fromJson(e))
          .toList() ??
          [],
      coach: json['coach'] != null ? Coach.fromJson(json['coach']) : null,
    );
  }
}

class Player {
  final int id;
  final String name;
  final int number;
  final String? pos; // G, D, M, F
  final String? grid; // "1:1", "2:3" etc from API-Football

  Player({
    required this.id,
    required this.name,
    required this.number,
    this.pos,
    this.grid,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    // API-Football structure is { player: { id, name, number, pos, grid } }
    // Or sometimes flat based on DB storage. Our sync script stored the full object structure.
    // Let's assume typical API-Football structure inside the list
    /*
      {
        "player": { "id": 1, "name": "...", "number": 1, "pos": "G", "grid": "1:1" }
      }
    */
    final p = json['player'] ?? json; // Handle both nested and flat if DB init changed

    return Player(
      id: p['id'] ?? 0,
      name: p['name'] ?? 'Unknown',
      number: p['number'] ?? 0,
      pos: p['pos'],
      grid: p['grid'],
    );
  }
}

class Coach {
  final int id;
  final String name;
  final String? photo;

  Coach({required this.id, required this.name, this.photo});

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      photo: json['photo'],
    );
  }
}
