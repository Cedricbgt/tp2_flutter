import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authService});

  /// Injectable pour les tests ; par défaut, Firestore.
  final AuthService? authService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService = widget.authService ?? AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.signIn(
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
    return Scaffold(
      appBar: AppBar(title: const Text(MiagedApp.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _loginController,
                decoration: const InputDecoration(labelText: 'Login'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSubmitted: (_) => _loading ? null : _signIn(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _signIn,
                child: _loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
