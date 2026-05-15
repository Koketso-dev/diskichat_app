import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionModel {
  final String matchId;
  final String predictedWinner; // home, away, draw
  final String predictedScore;
  final double confidence;
  final List<String> keyFactors;
  final String? starPlayer;
  final DateTime createdAt;

  PredictionModel({
    required this.matchId,
    required this.predictedWinner,
    required this.predictedScore,
    required this.confidence,
    required this.keyFactors,
    this.starPlayer,
    required this.createdAt,
  });

  factory PredictionModel.fromMap(Map<String, dynamic> map) {
    return PredictionModel(
      matchId: map['matchId'] ?? '',
      predictedWinner: map['predictedWinner'] ?? '',
      predictedScore: map['predictedScore'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      keyFactors: List<String>.from(map['keyFactors'] ?? []),
      starPlayer: map['starPlayer'],
      createdAt: () {
        final raw = map['createdAt'];
        if (raw == null) return DateTime.now();
        if (raw is Timestamp) return raw.toDate();
        return DateTime.tryParse(raw.toString()) ?? DateTime.now();
      }(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'predictedWinner': predictedWinner,
      'predictedScore': predictedScore,
      'confidence': confidence,
      'keyFactors': keyFactors,
      'starPlayer': starPlayer,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}