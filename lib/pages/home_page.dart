import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/floating_nav_bar.dart';
import 'activities_page.dart';
import 'cart_page.dart';

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
            // Profil (US#5) arrive à l'étape suivante.
            const _ComingSoon(label: 'Profil'),
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

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: AppHeader(),
        ),
        Expanded(
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
