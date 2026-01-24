import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Analytics: Logged event $name with params $parameters');
    } catch (e) {
      debugPrint('Analytics: Failed to log event $name: $e');
    }
  }

  Future<void> logScreenView({required String screenName}) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('Analytics: Logged screen view $screenName');
    } catch (e) {
      debugPrint('Analytics: Failed to log screen view: $e');
    }
  }

  // Pre-defined business events
  Future<void> logSignUp() async {
    await logEvent(name: 'sign_up_click');
  }

  Future<void> logUpgradeClick({String? fromScreen}) async {
    // Log to Firebase Analytics
    await logEvent(name: 'upgrade_click', parameters: {'source': fromScreen ?? 'unknown'});
    
    // Log to Firestore for Admin Dashboard
    try {
      final docRef = _firestore.collection('metrics').doc('subscription_clicks');
      await _firestore.runTransaction((transaction) async {
         final snapshot = await transaction.get(docRef);
         if (!snapshot.exists) {
           transaction.set(docRef, {
             'count': 1,
             'updatedAt': FieldValue.serverTimestamp(),
           });
         } else {
           final newCount = (snapshot.data()?['count'] ?? 0) + 1;
           transaction.update(docRef, {
             'count': newCount,
             'updatedAt': FieldValue.serverTimestamp(),
           });
         }
      });
    } catch (e) {
      debugPrint('Analytics: Failed to increment subscription clicks in Firestore: $e');
    }
  }
}
