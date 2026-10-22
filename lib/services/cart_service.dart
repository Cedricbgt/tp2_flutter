import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity.dart';

/// Panier d'un utilisateur : sous-collection `users/{login}/cart`.
///
/// Chaque document a pour id celui de l'activité (pas de doublon possible)
/// et contient une copie de l'activité, pour afficher le panier sans
/// requête supplémentaire.
class CartService {
  CartService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _cart(String login) =>
      _firestore.collection('users').doc(login).collection('cart');

  /// Activités du panier, de la plus récemment ajoutée à la plus ancienne.
  Stream<List<Activity>> watchCart(String login) {
    return _cart(login)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Activity.fromFirestore).toList());
  }

  Future<void> addToCart(String login, Activity activity) {
    return _cart(login).doc(activity.id).set({
      ...activity.toFirestore(),
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromCart(String login, String activityId) {
    return _cart(login).doc(activityId).delete();
  }
}
