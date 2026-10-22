import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

/// Vérifie les identifiants dans la collection Firestore `users`.
class AuthService {
  AuthService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Retourne l'utilisateur si le login existe et que le mot de passe
  /// correspond, `null` sinon.
  Future<AppUser?> signIn(String login, String password) async {
    if (login.isEmpty || password.isEmpty) {
      debugPrint('Connexion refusée : login ou mot de passe vide');
      return null;
    }

    final doc = await _firestore.collection('users').doc(login).get();
    if (!doc.exists) {
      debugPrint('Connexion refusée : utilisateur "$login" inconnu');
      return null;
    }

    final user = AppUser.fromFirestore(doc);
    if (user.password != password) {
      debugPrint('Connexion refusée : mot de passe incorrect pour "$login"');
      return null;
    }

    debugPrint('Connexion réussie : $login');
    return user;
  }
}
