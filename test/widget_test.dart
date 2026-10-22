import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaged/models/app_user.dart';
import 'package:miaged/pages/home_page.dart';
import 'package:miaged/pages/login_page.dart';
import 'package:miaged/services/auth_service.dart';

class FakeAuthService implements AuthService {
  @override
  Future<AppUser?> signIn(String login, String password) async =>
      login == 'user1' && password == 'password1'
          ? const AppUser(login: 'user1', password: 'password1')
          : null;
}

Widget buildLogin() => MaterialApp(
      home: LoginPage(authService: FakeAuthService()),
    );

void main() {
  testWidgets('Affiche les champs Login, Password et le bouton',
      (tester) async {
    await tester.pumpWidget(buildLogin());

    expect(find.widgetWithText(TextField, 'Login'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);

    final password = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Password'),
    );
    expect(password.obscureText, isTrue);
  });

  testWidgets('Champs vides : reste sur la page de login', (tester) async {
    await tester.pumpWidget(buildLogin());

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('Mauvais identifiants : reste sur la page de login',
      (tester) async {
    await tester.pumpWidget(buildLogin());

    await tester.enterText(find.widgetWithText(TextField, 'Login'), 'user1');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'faux');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Login ou mot de passe incorrect'), findsOneWidget);
  });

  testWidgets('Bons identifiants : redirige vers la page suivante',
      (tester) async {
    await tester.pumpWidget(buildLogin());

    await tester.enterText(find.widgetWithText(TextField, 'Login'), 'user1');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password'), 'password1');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Bienvenue user1 !'), findsOneWidget);
  });
}
