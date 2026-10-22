import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaged/models/activity.dart';
import 'package:miaged/models/app_user.dart';
import 'package:miaged/pages/activity_detail_page.dart';
import 'package:miaged/pages/home_page.dart';
import 'package:miaged/pages/login_page.dart';
import 'package:miaged/services/activity_service.dart';
import 'package:miaged/services/auth_service.dart';
import 'package:miaged/widgets/floating_nav_bar.dart';
import 'package:provider/provider.dart';

class FakeAuthService implements AuthService {
  @override
  Future<AppUser?> signIn(String login, String password) async =>
      login == 'user1' && password == 'password1'
      ? const AppUser(login: 'user1', password: 'password1')
      : null;
}

class FakeActivityService implements ActivityService {
  @override
  Stream<List<Activity>> watchActivities() => Stream.value(const [
    Activity(
      id: 'ski',
      title: 'Journée ski',
      imageUrl: '',
      category: 'Sport',
      location: 'Isola 2000',
      price: 49,
      maxPeople: 20,
    ),
    Activity(
      id: 'yoga',
      title: 'Yoga',
      imageUrl: '',
      category: 'Bien-être',
      location: 'Plage du Castel, Nice',
      price: 12.5,
      maxPeople: 10,
    ),
  ]);
}

/// Affiche [home] sur un écran de la taille des maquettes (390 x 844).
Future<void> pumpApp(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(buildApp(home));
}

Widget buildApp(Widget home) => MultiProvider(
  providers: [
    Provider<AuthService>(create: (_) => FakeAuthService()),
    Provider<ActivityService>(create: (_) => FakeActivityService()),
  ],
  child: MaterialApp(home: home),
);

Future<void> signIn(WidgetTester tester, String login, String password) async {
  await tester.enterText(find.byKey(const Key('login-field')), login);
  await tester.enterText(find.byKey(const Key('password-field')), password);
  await tester.tap(find.text('Se connecter'));
  await tester.pumpAndSettle();
}

void main() {
  group('US#1 Login', () {
    testWidgets('Affiche les champs Login, Password et le bouton', (
      tester,
    ) async {
      await pumpApp(tester, const LoginPage());

      expect(find.byKey(const Key('login-field')), findsOneWidget);
      expect(find.byKey(const Key('password-field')), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);

      final password = tester.widget<TextField>(
        find.byKey(const Key('password-field')),
      );
      expect(password.obscureText, isTrue);
    });

    testWidgets('Champs vides : reste sur la page de login', (tester) async {
      await pumpApp(tester, const LoginPage());

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('Mauvais identifiants : reste sur la page de login', (
      tester,
    ) async {
      await pumpApp(tester, const LoginPage());

      await signIn(tester, 'user1', 'faux');

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Login ou mot de passe incorrect'), findsOneWidget);
    });

    testWidgets('Bons identifiants : redirige vers les activités', (
      tester,
    ) async {
      await pumpApp(tester, const LoginPage());

      await signIn(tester, 'user1', 'password1');

      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('US#2 Liste des activités', () {
    const user = AppUser(login: 'user1', password: 'password1');

    testWidgets('Barre de navigation avec Activités sélectionné', (
      tester,
    ) async {
      await pumpApp(tester, const HomePage(user: user));
      await tester.pumpAndSettle();

      final bar = tester.widget<FloatingNavBar>(find.byType(FloatingNavBar));
      expect(bar.items.map((i) => i.label), ['Activités', 'Panier', 'Profil']);
      expect(bar.currentIndex, 0);
    });

    testWidgets('Affiche titre, lieu et prix de chaque activité', (
      tester,
    ) async {
      await pumpApp(tester, const HomePage(user: user));
      await tester.pumpAndSettle();

      expect(find.text('Journée ski'), findsOneWidget);
      expect(find.text('Isola 2000'), findsOneWidget);
      expect(find.text('49 €'), findsOneWidget);
      expect(find.text('12,50 €'), findsOneWidget);
    });

    testWidgets('Clic sur une activité : ouvre le détail', (tester) async {
      await pumpApp(tester, const HomePage(user: user));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Journée ski'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityDetailPage), findsOneWidget);
      expect(find.text('Sport'), findsOneWidget);
      expect(find.text('Personnes max'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityDetailPage), findsNothing);
    });
  });
}
