import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../models/app_user.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import '../utils/price_format.dart';
import '../widgets/app_header.dart';
import '../widgets/cart_item.dart';
import '../widgets/floating_nav_bar.dart';

/// Panier de l'utilisateur connecté (US#4).
class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.user});

  final AppUser user;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Créé une seule fois pour ne pas se réabonner à chaque rebuild.
  late final Stream<List<Activity>> _cart = context
      .read<CartService>()
      .watchCart(widget.user.login);

  Future<void> _remove(Activity activity) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<CartService>().removeFromCart(
        widget.user.login,
        activity.id,
      );
    } catch (e) {
      debugPrint('Erreur lors du retrait du panier : $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Impossible de retirer cette activité')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: StreamBuilder<List<Activity>>(
          stream: _cart,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Erreur de chargement du panier : ${snapshot.error}');
            }
            final cart = snapshot.data;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                FloatingNavBar.reservedHeight,
              ),
              children: [
                const SizedBox(
                  height: 56,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppHeader(),
                  ),
                ),
                const SizedBox(height: 8),
                _Title(count: cart?.length),
                const SizedBox(height: 12),
                if (snapshot.hasError)
                  const _Message('Impossible de charger le panier')
                else if (cart == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (cart.isEmpty)
                  const _Message(
                    'Ton panier est vide.\n'
                    'Ajoute des activités depuis l’onglet Activités.',
                  )
                else ...[
                  for (final activity in cart) ...[
                    CartItem(
                      key: ValueKey(activity.id),
                      activity: activity,
                      onRemove: () => _remove(activity),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  _TotalCard(cart: cart),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.count});

  /// `null` pendant le chargement.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = this.count;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text('Mon panier', style: textTheme.headlineMedium)),
        if (count != null)
          Text(
            count > 1 ? '$count activités' : '$count activité',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// Carte noire avec le sous-total et le total général.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.cart});

  final List<Activity> cart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = formatPrice(
      cart.fold<double>(0, (sum, activity) => sum + activity.price),
    );
    final secondary = textTheme.bodyMedium?.copyWith(
      color: AppColors.textOnDark,
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sous-total (${cart.length})', style: secondary),
              Text(total, style: secondary),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.darkBorder),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Total',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              // Un gros montant se réduit au lieu de déborder.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    total,
                    key: const Key('cart-total'),
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.accent,
                      fontSize: 34,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
