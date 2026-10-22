import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';

/// Logo texte « MIAGED. » avec le point en couleur d'accent.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.onDark = false});

  /// Sur fond sombre, le texte passe en blanc et le point en accent vif.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge
        ?.copyWith(color: onDark ? AppColors.surface : AppColors.ink);

    return Semantics(
      header: true,
      label: MiagedApp.title,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: MiagedApp.title,
          children: [
            TextSpan(
              text: '.',
              style: TextStyle(
                color: onDark ? AppColors.accent : AppColors.accentOnLight,
              ),
            ),
          ],
        ),
        style: style,
      ),
    );
  }
}
