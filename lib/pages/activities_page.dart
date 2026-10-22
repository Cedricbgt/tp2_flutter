import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../models/app_user.dart';
import '../services/activity_service.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_card.dart';
import '../widgets/app_header.dart';
import '../widgets/floating_nav_bar.dart';
import 'activity_detail_page.dart';

/// Liste de toutes les activités (US#2).
class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key, required this.user});

  final AppUser user;

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  // Créé une seule fois pour ne pas se réabonner à chaque rebuild.
  late final Stream<List<Activity>> _activities = context
      .read<ActivityService>()
      .watchActivities();

  /// Catégorie filtrée ; `null` = toutes.
  String? _selectedCategory;

  void _openDetail(Activity activity) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ActivityDetailPage(activity: activity)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Activity>>(
      stream: _activities,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Erreur de chargement des activités : ${snapshot.error}');
          return const Center(
            child: Text('Impossible de charger les activités'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data!;
        if (activities.isEmpty) {
          return const Center(child: Text('Aucune activité pour le moment'));
        }

        final categories = activities.map((a) => a.category).toSet().toList()
          ..sort();
        final visible = _selectedCategory == null
            ? activities
            : activities.where((a) => a.category == _selectedCategory).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverList.list(
                    children: [
                      _Header(user: widget.user),
                      const SizedBox(height: 8),
                      _Greeting(user: widget.user),
                      const SizedBox(height: 16),
                      _CategoryChips(
                        categories: categories,
                        selected: _selectedCategory,
                        onSelected: (category) =>
                            setState(() => _selectedCategory = category),
                      ),
                      if (visible.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ActivityCard(
                          activity: visible.first,
                          onTap: () => _openDetail(visible.first),
                        ),
                      ],
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 172,
                        ),
                    itemCount: visible.length > 1 ? visible.length - 1 : 0,
                    itemBuilder: (context, index) {
                      final activity = visible[index + 1];
                      return ActivityTile(
                        activity: activity,
                        onTap: () => _openDetail(activity),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: FloatingNavBar.reservedHeight),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser user;

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
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppHeader(),
          Semantics(
            label: 'Connecté en tant que ${user.login}',
            excludeSemantics: true,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.ink,
              child: Text(
                _initials,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'Salut ${user.login},\n',
        children: const [
          TextSpan(
            text: 'on fait quoi ce week-end ?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = index == 0 ? null : categories[index - 1];
          return _CategoryChip(
            label: category ?? 'Tout',
            selected: category == selected,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.ink : AppColors.surface,
        shape: StadiumBorder(
          side: selected
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? AppColors.surface : AppColors.ink,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
