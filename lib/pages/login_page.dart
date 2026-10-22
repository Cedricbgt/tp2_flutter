import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/labeled_field.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final user = await context.read<AuthService>().signIn(
        _loginController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;

      if (user == null) {
        _showError('Login ou mot de passe incorrect');
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(user: user)),
      );
    } catch (e) {
      debugPrint('Erreur lors de la connexion : $e');
      if (mounted) _showError('Connexion impossible, réessayez plus tard');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        toolbarHeight: 56,
        titleSpacing: 24,
        title: const AppHeader(onDark: true),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              'v1.0',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textOnDark,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _CategoryShapes(),
                  const SizedBox(height: 38),
                  Text(
                    'Trouve ta\nprochaine activité.',
                    style: textTheme.displaySmall?.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Connecte-toi pour réserver tes sorties.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textOnDark,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  LabeledField(
                    label: 'Login',
                    fieldKey: const Key('login-field'),
                    controller: _loginController,
                    hintText: 'ton.login',
                    dark: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: 'Password',
                    fieldKey: const Key('password-field'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    dark: true,
                    onSubmitted: (_) => _loading ? null : _signIn(),
                    suffix: IconButton(
                      tooltip: _obscurePassword
                          ? 'Afficher le mot de passe'
                          : 'Masquer le mot de passe',
                      color: AppColors.textOnDark,
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Se connecter'),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'TP2 · MIAGE Développement mobile',
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.placeholder,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Les trois formes décoratives (Sport / Culture / Sorties) du haut de l'écran.
class _CategoryShapes extends StatelessWidget {
  const _CategoryShapes();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget shape(
      String label,
      Color background,
      Color foreground,
      BorderRadius radius,
    ) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(color: background, borderRadius: radius),
        child: Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    const r = Radius.circular(28);
    const big = Radius.circular(80);

    return ExcludeSemantics(
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            shape(
              'Sport',
              AppColors.accent,
              AppColors.ink,
              BorderRadius.circular(28),
            ),
            const SizedBox(width: 8),
            shape(
              'Culture',
              AppColors.darkTile,
              AppColors.textOnDark,
              const BorderRadius.only(
                topLeft: r,
                topRight: r,
                bottomLeft: r,
                bottomRight: big,
              ),
            ),
            const SizedBox(width: 8),
            shape(
              'Sorties',
              AppColors.surface,
              AppColors.ink,
              const BorderRadius.only(
                topLeft: big,
                topRight: r,
                bottomLeft: r,
                bottomRight: r,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
