import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Lecture et mise à jour du profil dans la collection Firestore `users`.
class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String login) =>
      _firestore.collection('users').doc(login);

  /// Retourne `null` si l'utilisateur n'existe pas.
  Future<AppUser?> getUser(String login) async {
    final doc = await _doc(login).get();
    return doc.exists ? AppUser.fromFirestore(doc) : null;
  }

  /// Met à jour les champs du profil. Le login (id du document) ne change pas
  /// et le panier (sous-collection) n'est pas touché.
  Future<void> updateUser(AppUser user) {
    return _doc(user.login).update(user.toFirestore());
  }
}
