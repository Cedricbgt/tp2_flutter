import 'package:flutter/material.dart';

import '../main.dart';
import '../models/app_user.dart';

/// Page affichée après connexion. Sera remplacée par la liste des
/// activités et la BottomNavigationBar (US#2).
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(MiagedApp.title)),
      body: Center(child: Text('Bienvenue ${user.login} !')),
    );
  }
}
