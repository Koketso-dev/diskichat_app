import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/team_model.dart';
import '../data/models/match_model.dart';

class TeamsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Team>> getTeams({String? country}) async {
    try {
      // Fetch from the seeded 'teams' collection
      // This is much better than extracting from matches as it contains all teams in the league
      // even if they haven't played a match yet in our system.
      
      Query query = _firestore.collection('teams');
      
      // We can add filtering if needed, e.g. by country if passed
      // But our seed was specific to PSL (South Africa), so most should be ZA.
      if (country != null) {
        query = query.where('country', isEqualTo: country);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure ID is passed correctly. The model expects 'id' in json.
        // Our seed stored it as number.
        return Team.fromJson(data);
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
        
    } catch (e) {
      print('Error fetching teams from Firestore: $e');
      return []; 
    }
  }
}
