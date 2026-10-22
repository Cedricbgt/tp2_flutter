import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilisateur stocké dans la collection Firestore `users`.
/// L'identifiant du document sert de login.
class AppUser {
  const AppUser({
    required this.login,
    required this.password,
    this.birthday = '',
    this.address = '',
    this.postalCode = '',
    this.city = '',
  });

  final String login;
  final String password;
  final String birthday;
  final String address;
  final String postalCode;
  final String city;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      login: doc.id,
      password: data['password'] as String? ?? '',
      birthday: data['birthday'] as String? ?? '',
      address: data['address'] as String? ?? '',
      postalCode: data['postalCode'] as String? ?? '',
      city: data['city'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'password': password,
        'birthday': birthday,
        'address': address,
        'postalCode': postalCode,
        'city': city,
      };
}
