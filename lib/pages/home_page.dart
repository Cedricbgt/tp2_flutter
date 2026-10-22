import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../widgets/floating_nav_bar.dart';
import 'activities_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';

/// Page principale après connexion : contenu + barre de navigation
/// (Activités, Panier, Profil).
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});

  final AppUser user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _navItems = [
    FloatingNavItem(icon: Icons.local_activity_outlined, label: 'Activités'),
    FloatingNavItem(icon: Icons.shopping_bag_outlined, label: 'Panier'),
    FloatingNavItem(icon: Icons.person_outline, label: 'Profil'),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            ActivitiesPage(user: widget.user),
            CartPage(user: widget.user),
            ProfilePage(user: widget.user),
          ],
        ),
      ),
      bottomNavigationBar: FloatingNavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
