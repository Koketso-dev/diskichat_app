import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_model.dart';

class MatchModel {
  final String id;
  final String? competitionId;
  final String competitionName;
  final int? homeTeamId; // Added
  final String homeTeam;
  final int? awayTeamId; // Added
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final DateTime matchDate;
  final String status;
  final int scoreHome;
  final int scoreAway;
  final String? venue;
  final String? apiMatchId;
  final Map<String, dynamic>? aiPrediction;
  final int fanCount;
  final String? elapsedTime;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<EventModel> events;
  final bool isMatchOfTheDay;

  MatchModel({
    required this.id,
    this.competitionId,
    this.competitionName = 'Football',
    this.homeTeamId,
    required this.homeTeam,
    this.awayTeamId,
    required this.awayTeam,
    this.homeLogo,
    this.awayLogo,
    required this.matchDate,
    this.status = 'upcoming',
    this.scoreHome = 0,
    this.scoreAway = 0,
    this.venue,
    this.apiMatchId,
    this.aiPrediction,
    this.fanCount = 0,
    this.elapsedTime,
    required this.createdAt,
    this.updatedAt,
    this.events = const [],
    this.isMatchOfTheDay = false,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      id: map['id'] ?? '',
      competitionId: map['competitionId']?.toString(),
      competitionName: map['competitionName'] ?? 'Football',
      homeTeamId: map['homeTeamId'], // Int usually
      homeTeam: map['homeTeam'] ?? '',
      awayTeamId: map['awayTeamId'],
      awayTeam: map['awayTeam'] ?? '',
      homeLogo: map['homeLogo'],
      awayLogo: map['awayLogo'],
      matchDate: (map['matchDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'upcoming',
      scoreHome: map['scoreHome'] ?? 0,
      scoreAway: map['scoreAway'] ?? 0,
      venue: map['venue'],
      apiMatchId: map['apiMatchId']?.toString(),
      aiPrediction: map['aiPrediction'],
      fanCount: map['fanCount'] ?? 0,
      elapsedTime: map['elapsedTime'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      isMatchOfTheDay: map['isMatchOfTheDay'] ?? false,
    );
  }

  factory MatchModel.fromApi(Map<String, dynamic> json) {
    return MatchModel(
      id: (json['fixture_id'] ?? '').toString(),
      competitionId: null,
      competitionName: json['league_name'] ?? 'Football',
      homeTeamId: _parseInt(json['home_team_id']), // Parse safely
      homeTeam: json['home_team'] ?? '',
      awayTeamId: _parseInt(json['away_team_id']), // Parse safely
      awayTeam: json['away_team'] ?? '',
      homeLogo: json['home_logo'],
      awayLogo: json['away_logo'],
      matchDate: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      status: _mapApiStatus(json['status_short']),
      scoreHome: json['goals_home'] ?? 0,
      scoreAway: json['goals_away'] ?? 0,
      venue: null,
      apiMatchId: (json['fixture_id'] ?? '').toString(),
      aiPrediction: null,
      fanCount: 0,
      elapsedTime: json['elapsed']?.toString(),
      createdAt: DateTime.now(),
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => EventModel.fromJson(e))
          .toList() ?? [],
      isMatchOfTheDay: false,
    );
  }

  static int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
  }

  static String _mapApiStatus(String? apiStatus) {
    if (apiStatus == null) return 'upcoming';
    final liveStatuses = ['1H', '2H', 'HT', 'ET', 'BT', 'P', 'LIVE'];
    final finishedStatuses = ['FT', 'AET', 'PEN'];
    
    if (liveStatuses.contains(apiStatus)) return 'live';
    if (finishedStatuses.contains(apiStatus)) return 'finished';
    return 'upcoming';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'competitionId': competitionId,
      'competitionName': competitionName,
      'homeTeamId': homeTeamId,
      'homeTeam': homeTeam,
      'awayTeamId': awayTeamId,
      'awayTeam': awayTeam,
      'homeLogo': homeLogo,
      'awayLogo': awayLogo,
      'matchDate': Timestamp.fromDate(matchDate),
      'status': status,
      'scoreHome': scoreHome,
      'scoreAway': scoreAway,
      'venue': venue,
      'apiMatchId': apiMatchId,
      'aiPrediction': aiPrediction,
      'fanCount': fanCount,
      'elapsedTime': elapsedTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isMatchOfTheDay': isMatchOfTheDay,
    };
  }

  // Copy with
  MatchModel copyWith({
    String? id,
    String? competitionId,
    String? competitionName,
    int? homeTeamId,
    String? homeTeam,
    int? awayTeamId,
    String? awayTeam,
    String? homeLogo,
    String? awayLogo,
    DateTime? matchDate,
    String? status,
    int? scoreHome,
    int? scoreAway,
    String? venue,
    String? apiMatchId,
    Map<String, dynamic>? aiPrediction,
    int? fanCount,
    String? elapsedTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isMatchOfTheDay,
  }) {
    return MatchModel(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      competitionName: competitionName ?? this.competitionName,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      awayTeam: awayTeam ?? this.awayTeam,
      homeLogo: homeLogo ?? this.homeLogo,
      awayLogo: awayLogo ?? this.awayLogo,
      matchDate: matchDate ?? this.matchDate,
      status: status ?? this.status,
      scoreHome: scoreHome ?? this.scoreHome,
      scoreAway: scoreAway ?? this.scoreAway,
      venue: venue ?? this.venue,
      apiMatchId: apiMatchId ?? this.apiMatchId,
      aiPrediction: aiPrediction ?? this.aiPrediction,
      fanCount: fanCount ?? this.fanCount,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isMatchOfTheDay: isMatchOfTheDay ?? this.isMatchOfTheDay,
    );
  }

  // Helpers
  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
  bool get isFinished => status == 'finished';

  String get scoreDisplay => '$scoreHome - $scoreAway';

  String get statusDisplay {
    switch (status) {
      case 'live':
        return 'LIVE';
      case 'halftime':
        return 'HT';
      case 'finished':
        return 'FT';
      case 'postponed':
        return 'Postponed';
      default:
        return 'Upcoming';
    }
  }
}