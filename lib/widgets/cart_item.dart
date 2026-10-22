import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../theme/app_theme.dart';
import 'activity_image.dart';

/// Ligne du panier : image 72x72, titre, lieu, prix et bouton de retrait.
class CartItem extends StatelessWidget {
  const CartItem({super.key, required this.activity, required this.onRemove});

  final Activity activity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ActivityImage(url: activity.imageUrl, width: 72, height: 72),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  activity.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(activity.formattedPrice, style: textTheme.titleSmall),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Retirer ${activity.title}',
            icon: const Icon(Icons.close, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.ink,
              fixedSize: const Size(44, 44),
            ),
          ),
        ],
      ),
    );
  }
}
