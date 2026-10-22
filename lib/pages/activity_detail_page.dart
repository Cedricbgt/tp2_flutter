import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../models/app_user.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_card.dart';
import '../widgets/activity_image.dart';

/// Détail d'une activité, avec ajout au panier (US#3).
class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({
    super.key,
    required this.activity,
    required this.user,
  });

  final Activity activity;
  final AppUser user;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  static const _imageHeight = 400.0;
  static const _sheetOverlap = 40.0;

  // Vrai si l'activité est déjà dans le panier (mis à jour en temps réel).
  late final Stream<bool> _inCart = context
      .read<CartService>()
      .watchCart(widget.user.login)
      .map((cart) => cart.any((a) => a.id == widget.activity.id));

  bool _adding = false;

  Activity get activity => widget.activity;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<CartService>().addToCart(widget.user.login, activity);
      messenger.showSnackBar(
        SnackBar(content: Text('${activity.title} ajouté au panier')),
      );
    } catch (e) {
      debugPrint("Erreur lors de l'ajout au panier : $e");
      messenger.showSnackBar(
        const SnackBar(content: Text("Impossible d'ajouter au panier")),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _imageHeight,
            child: ActivityImage(url: activity.imageUrl),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: _imageHeight - _sheetOverlap),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.sizeOf(context).height -
                        _imageHeight +
                        _sheetOverlap,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.sheet),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pill(
                        text: activity.category,
                        background: AppColors.ink,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(activity.title, style: textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoTile(
                              label: 'Lieu',
                              value: activity.location,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InfoTile(
                              label: 'Personnes max',
                              value: '${activity.maxPeople}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                tooltip: 'Retour',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface.withValues(alpha: 0.95),
                  foregroundColor: AppColors.ink,
                  fixedSize: const Size(48, 48),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: StreamBuilder<bool>(
        stream: _inCart,
        builder: (context, snapshot) => _PriceBar(
          price: activity.formattedPrice,
          inCart: snapshot.data ?? false,
          loading: _adding,
          onAddToCart: _addToCart,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Barre fixe en bas : prix + bouton « Ajouter au panier ».
class _PriceBar extends StatelessWidget {
  const _PriceBar({
    required this.price,
    required this.inCart,
    required this.loading,
    required this.onAddToCart,
  });

  final String price;
  final bool inCart;
  final bool loading;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.cardLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prix',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    price,
                    style: textTheme.headlineSmall?.copyWith(fontSize: 26),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: inCart || loading ? null : onAddToCart,
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: AppColors.ink.withValues(
                      alpha: 0.85,
                    ),
                    disabledForegroundColor: AppColors.surface,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: loading
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                inCart ? Icons.check : Icons.add,
                                size: 18,
                                color: AppColors.ink,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          inCart ? 'Dans le panier' : 'Ajouter au panier',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
