import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String phoneNumber;
  final String? avatarUrl;
  final String rank; // amateur, semi_pro, pro, world_class, legend
  final int points;
  final String? favoriteTeam;
  final String? favoriteTeamLogo;
  final String? country;
  final String? bio;
  final String subscriptionType; // basic, pro, gold
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.phoneNumber,
    this.avatarUrl,
    this.rank = 'amateur',
    this.points = 0,
    this.favoriteTeam,
    this.favoriteTeamLogo,
    this.country,
    this.bio,
    this.subscriptionType = 'basic',
    required this.createdAt,
    this.updatedAt,
  });

  // From Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      avatarUrl: map['avatarUrl'],
      rank: map['rank'] ?? 'amateur',
      points: map['points'] ?? 0,
      favoriteTeam: map['favoriteTeam'],
      favoriteTeamLogo: map['favoriteTeamLogo'],
      country: map['country'],
      bio: map['bio'],
      subscriptionType: map['subscriptionType'] ?? 'basic',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'rank': rank,
      'points': points,
      'favoriteTeam': favoriteTeam,
      'favoriteTeamLogo': favoriteTeamLogo,
      'country': country,
      'bio': bio,
      'subscriptionType': subscriptionType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Copy with
  UserModel copyWith({
    String? id,
    String? username,
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    String? rank,
    int? points,
    String? favoriteTeam,
    String? favoriteTeamLogo,
    String? country,
    String? bio,
    String? subscriptionType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rank: rank ?? this.rank,
      points: points ?? this.points,
      favoriteTeam: favoriteTeam ?? this.favoriteTeam,
      favoriteTeamLogo: favoriteTeamLogo ?? this.favoriteTeamLogo,
      country: country ?? this.country,
      bio: bio ?? this.bio,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}