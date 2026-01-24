import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/lineup_model.dart';
import 'firestore_service.dart';

class ApiService {
  final FirestoreService _firestoreService = FirestoreService();

  // Get matches (mapped to /api/matches which now returns ALL)
  // API Methods removed as backend is deprecated. use Firestore.
  
  // Get lineups - Redirecting to FirestoreService
  Future<List<LineupModel>> getLineups(String fixtureId) async {
    return await _firestoreService.getLineups(fixtureId);
  }

  // Submit feedback - writing directly to Firestore
  Future<void> submitFeedback({
    String? userId,
    required String type,
    required String description,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': userId,
        'type': type,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error submitting feedback: $e');
    }
  }
}
