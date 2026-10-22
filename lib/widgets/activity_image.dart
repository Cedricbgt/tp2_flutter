import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Image d'une activité (URL réseau ou data URL), avec un fond neutre
/// pendant le chargement et une icône si l'image est introuvable.
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

    Widget broken(BuildContext context, Object error, StackTrace? stack) =>
        placeholder(
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textSecondary,
          ),
        );

    // Photo ajoutée depuis l'appli : stockée en data URL dans Firestore.
    if (url.startsWith('data:')) {
      final data = UriData.parse(url);
      return Image.memory(
        data.contentAsBytes(),
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: broken,
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder(),
      errorBuilder: broken,
    );
  }
}
