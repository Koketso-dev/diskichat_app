// Need a League Model. Using map for now or create simple model.

class League {
  final int id;
  final String name;
  final String logo;
  final String country;

  League({required this.id, required this.name, required this.logo, required this.country});

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id'],
      name: json['name'],
      logo: json['logo'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class CompetitionsService {
  Future<List<League>> getCompetitions() async {
    // Static return for PSL (League 288) since we are moving to local/firestore
    // and this is the main focus for now.
    return [
      League(
        id: 288,
        name: 'Premier Soccer League',
        logo: 'https://media.api-sports.io/football/leagues/288.png',
        country: 'South Africa',
      ),
    ];
  }
}
