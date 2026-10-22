import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';

/// Avatar rond noir avec les initiales de l'utilisateur en couleur d'accent.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 36});

  final AppUser user;
  final double size;

  /// « cedric.bagot » → « CB », « user1 » → « US ».
  String get _initials {
    final parts = user.login
        .split(RegExp(r'[._\s-]+'))
        .where((p) => p.isNotEmpty);
    if (parts.length >= 2) {
      return parts.take(2).map((p) => p[0]).join().toUpperCase();
    }
    final login = user.login;
    return login
        .substring(0, login.length < 2 ? login.length : 2)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Connecté en tant que ${user.login}',
      excludeSemantics: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.ink,
        child: Text(
          _initials,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }
}
