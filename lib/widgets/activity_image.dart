import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Image réseau d'une activité, avec un fond neutre pendant le chargement
/// et une icône si l'image est introuvable.
class ActivityImage extends StatelessWidget {
  const ActivityImage({super.key, required this.url, this.width, this.height});

  final String url;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Widget placeholder({Widget? child}) => Container(
      width: width,
      height: height,
      color: AppColors.border,
      alignment: Alignment.center,
      child: child,
    );

    if (url.isEmpty) {
      return placeholder(
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder(),
      errorBuilder: (context, error, stackTrace) => placeholder(
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
