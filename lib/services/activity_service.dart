import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity.dart';

/// Accès à la collection Firestore `activities`.
class ActivityService {
  ActivityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Liste des activités triées par titre, mise à jour en temps réel.
  Stream<List<Activity>> watchActivities() {
    return _firestore
        .collection('activities')
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Activity.fromFirestore).toList());
  }
}
