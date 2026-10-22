import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FloatingNavItem {
  const FloatingNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barre de navigation flottante en forme de pilule noire.
/// À utiliser avec `extendBody: true` sur le Scaffold.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  static const height = 68.0;
  static const bottomMargin = 24.0;

  /// Espace à réserver en bas des contenus défilants.
  static const reservedHeight = height + bottomMargin + 16;

  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, bottomMargin),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const ShapeDecoration(
            color: AppColors.ink,
            shape: StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flexible : sur un écran étroit, les libellés se tronquent
              // au lieu de déborder.
              for (var i = 0; i < items.length; i++)
                Flexible(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.textOnDark;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: color,
      fontSize: selected ? 14 : 13,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.accent : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 52,
            constraints: const BoxConstraints(minWidth: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.label,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
