import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/labeled_field.dart';
import '../widgets/user_avatar.dart';
import 'login_page.dart';

/// Profil de l'utilisateur connecté : consultation et modification (US#5).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.user});

  final AppUser user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _login = TextEditingController(text: widget.user.login);
  final _password = TextEditingController();
  final _birthday = TextEditingController();
  final _address = TextEditingController();
  final _postalCode = TextEditingController();
  final _city = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _login,
      _password,
      _birthday,
      _address,
      _postalCode,
      _city,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Charge le profil depuis la base (et non depuis la session), pour
  /// afficher les dernières données enregistrées.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final user = await context.read<UserService>().getUser(widget.user.login);
      if (!mounted) return;
      if (user == null) {
        debugPrint('Profil introuvable : ${widget.user.login}');
        setState(() => _loadError = 'Profil introuvable');
      } else {
        _password.text = user.password;
        _birthday.text = user.birthday;
        _address.text = user.address;
        _postalCode.text = user.postalCode;
        _city.text = user.city;
      }
    } catch (e) {
      debugPrint('Erreur de chargement du profil : $e');
      if (mounted) {
        setState(() => _loadError = 'Impossible de charger le profil');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    void show(String message) =>
        messenger.showSnackBar(SnackBar(content: Text(message)));

    if (_password.text.isEmpty) {
      show('Le mot de passe ne peut pas être vide');
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<UserService>().updateUser(
        AppUser(
          login: widget.user.login,
          password: _password.text,
          birthday: _birthday.text.trim(),
          address: _address.text.trim(),
          postalCode: _postalCode.text.trim(),
          city: _city.text.trim(),
        ),
      );
      show('Profil mis à jour');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du profil : $e');
      show("Impossible d'enregistrer le profil");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_birthday.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Anniversaire',
    );
    if (picked == null) return;
    String two(int n) => n.toString().padLeft(2, '0');
    _birthday.text = '${two(picked.day)}/${two(picked.month)}/${picked.year}';
  }

  /// « 12/12/1993 » → DateTime, `null` si le format est invalide.
  static DateTime? _parseDate(String text) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
    if (match == null) return null;
    return DateTime.tryParse('${match[3]}-${match[2]}-${match[1]}');
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            FloatingNavBar.reservedHeight,
          ),
          children: [
            SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AppHeader(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Se déconnecter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                UserAvatar(user: widget.user, size: 60),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mon profil', style: textTheme.headlineSmall),
                      Text(
                        '@${widget.user.login}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              _LoadError(message: _loadError!, onRetry: _load)
            else
              _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    const gap = SizedBox(height: 10);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: 'Login',
            fieldKey: const Key('profile-login'),
            controller: _login,
            readOnly: true,
          ),
          gap,
          LabeledField(
            label: 'Password',
            fieldKey: const Key('profile-password'),
            controller: _password,
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          gap,
          LabeledField(
            label: 'Anniversaire',
            fieldKey: const Key('profile-birthday'),
            controller: _birthday,
            hintText: 'JJ/MM/AAAA',
            keyboardType: TextInputType.datetime,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
              LengthLimitingTextInputFormatter(10),
            ],
            textInputAction: TextInputAction.next,
            suffix: IconButton(
              tooltip: 'Choisir une date',
              onPressed: _pickBirthday,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
          ),
          gap,
          LabeledField(
            label: 'Adresse',
            fieldKey: const Key('profile-address'),
            controller: _address,
            textInputAction: TextInputAction.next,
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Code postal',
                  fieldKey: const Key('profile-postal-code'),
                  controller: _postalCode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LabeledField(
                  label: 'Ville',
                  fieldKey: const Key('profile-city'),
                  controller: _city,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
