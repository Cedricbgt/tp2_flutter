import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaged/models/activity.dart';
import 'package:miaged/models/app_user.dart';
import 'package:miaged/pages/activity_detail_page.dart';
import 'package:miaged/pages/add_activity_page.dart';
import 'package:miaged/pages/cart_page.dart';
import 'package:miaged/pages/home_page.dart';
import 'package:miaged/pages/login_page.dart';
import 'package:miaged/pages/profile_page.dart';
import 'package:miaged/services/activity_service.dart';
import 'package:miaged/services/auth_service.dart';
import 'package:miaged/services/cart_service.dart';
import 'package:miaged/services/category_classifier.dart';
import 'package:miaged/services/user_service.dart';
import 'package:miaged/widgets/activity_image.dart';
import 'package:miaged/widgets/cart_item.dart';
import 'package:miaged/widgets/floating_nav_bar.dart';
import 'package:provider/provider.dart';

class FakeAuthService implements AuthService {
  @override
  Future<AppUser?> signIn(String login, String password) async =>
      login == 'user1' && password == 'password1'
      ? const AppUser(login: 'user1', password: 'password1')
      : null;
}

const ski = Activity(
  id: 'ski',
  title: 'Journée ski',
  imageUrl: '',
  category: 'Sport',
  location: 'Isola 2000',
  price: 49,
  maxPeople: 20,
);

const yoga = Activity(
  id: 'yoga',
  title: 'Yoga',
  imageUrl: '',
  category: 'Bien-être',
  location: 'Plage du Castel, Nice',
  price: 12.5,
  maxPeople: 10,
);

const user1 = AppUser(login: 'user1', password: 'password1');

class FakeActivityService implements ActivityService {
  final added = <Activity>[];

  @override
  Stream<List<Activity>> watchActivities() => Stream.value(const [ski, yoga]);

  @override
  Future<void> addActivity(Activity activity) async => added.add(activity);
}

/// IA simulée : renvoie [category], échoue si elle vaut `null`,
/// ou simule un quota atteint si [busy].
class FakeClassifier implements CategoryClassifier {
  FakeClassifier([this.category = 'Sport', this.busy = false]);

  final String? category;
  final bool busy;
  int calls = 0;

  @override
  Future<String> classify(Uint8List imageBytes, String mimeType) async {
    calls++;
    if (busy) throw const ClassifierBusyException();
    final category = this.category;
    if (category == null) throw Exception('IA indisponible');
    return category;
  }
}

/// Image PNG de 1 x 1 pixel.
final testImage = PickedImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  ),
  'image/png',
);

/// Utilisateurs en mémoire.
class FakeUserService implements UserService {
  FakeUserService()
    : users = {
        'user1': const AppUser(
          login: 'user1',
          password: 'password1',
          birthday: '12/12/1993',
          address: 'Promenade des anglais',
          postalCode: '06000',
          city: 'Nice',
        ),
      };

  final Map<String, AppUser> users;

  @override
  Future<AppUser?> getUser(String login) async => users[login];

  @override
  Future<void> updateUser(AppUser user) async => users[user.login] = user;
}

/// Panier en mémoire, par login.
class FakeCartService implements CartService {
  final _carts = <String, List<Activity>>{};
  final _changes = StreamController<void>.broadcast();

  List<Activity> cartOf(String login) => _carts[login] ?? [];

  @override
  Stream<List<Activity>> watchCart(String login) async* {
    yield cartOf(login);
    await for (final _ in _changes.stream) {
      yield cartOf(login);
    }
  }

  @override
  Future<void> addToCart(String login, Activity activity) async {
    final cart = _carts.putIfAbsent(login, () => []);
    if (cart.every((a) => a.id != activity.id)) cart.insert(0, activity);
    _changes.add(null);
  }

  @override
  Future<void> removeFromCart(String login, String activityId) async {
    _carts[login]?.removeWhere((a) => a.id == activityId);
    _changes.add(null);
  }
}

/// Affiche [home] sur un écran de la taille des maquettes (390 x 844).
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  FakeCartService? cartService,
  FakeUserService? userService,
  FakeActivityService? activityService,
  CategoryClassifier? classifier,
}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => FakeAuthService()),
        Provider<ActivityService>(
          create: (_) => activityService ?? FakeActivityService(),
        ),
        Provider<CartService>(create: (_) => cartService ?? FakeCartService()),
        Provider<UserService>(create: (_) => userService ?? FakeUserService()),
        Provider<CategoryClassifier>(
          create: (_) => classifier ?? FakeClassifier(),
        ),
      ],
      child: MaterialApp(home: home),
    ),
  );
}

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
    testWidgets('Barre de navigation avec Activités sélectionné', (
      tester,
    ) async {
      await pumpApp(tester, const HomePage(user: user1));
      await tester.pumpAndSettle();

      final bar = tester.widget<FloatingNavBar>(find.byType(FloatingNavBar));
      expect(bar.items.map((i) => i.label), ['Activités', 'Panier', 'Profil']);
      expect(bar.currentIndex, 0);
    });

    testWidgets('Affiche titre, lieu et prix de chaque activité', (
      tester,
    ) async {
      await pumpApp(tester, const HomePage(user: user1));
      await tester.pumpAndSettle();

      expect(find.text('Journée ski'), findsOneWidget);
      expect(find.text('Isola 2000'), findsOneWidget);
      expect(find.text('49 €'), findsOneWidget);
      expect(find.text('12,50 €'), findsOneWidget);
    });

    testWidgets('Clic sur une activité : ouvre le détail', (tester) async {
      await pumpApp(tester, const HomePage(user: user1));
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

  group('US#3 Détail et ajout au panier', () {
    testWidgets('Affiche image, titre, catégorie, lieu, max et prix', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const ActivityDetailPage(activity: ski, user: user1),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActivityImage), findsOneWidget);
      expect(find.text('Journée ski'), findsOneWidget);
      expect(find.text('Sport'), findsOneWidget);
      expect(find.text('Isola 2000'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('49 €'), findsOneWidget);
      expect(find.byTooltip('Retour'), findsOneWidget);
    });

    testWidgets('Ajouter au panier : enregistre et met à jour le bouton', (
      tester,
    ) async {
      final cart = FakeCartService();
      await pumpApp(
        tester,
        const ActivityDetailPage(activity: ski, user: user1),
        cartService: cart,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajouter au panier'));
      await tester.pumpAndSettle();

      expect(cart.cartOf('user1').map((a) => a.id), ['ski']);
      expect(find.text('Dans le panier'), findsOneWidget);
      expect(find.text('Journée ski ajouté au panier'), findsOneWidget);
    });

    testWidgets('Activité déjà dans le panier : bouton désactivé', (
      tester,
    ) async {
      final cart = FakeCartService();
      await cart.addToCart('user1', ski);
      await pumpApp(
        tester,
        const ActivityDetailPage(activity: ski, user: user1),
        cartService: cart,
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text('Dans le panier'), findsOneWidget);
    });
  });

  group('US#4 Panier', () {
    Future<FakeCartService> pumpCart(WidgetTester tester) async {
      final cart = FakeCartService();
      await cart.addToCart('user1', ski);
      await cart.addToCart('user1', yoga);
      await pumpApp(
        tester,
        const Scaffold(body: CartPage(user: user1)),
        cartService: cart,
      );
      await tester.pumpAndSettle();
      return cart;
    }

    String total(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('cart-total'))).data!;

    testWidgets('Affiche image, titre, lieu et prix de chaque activité', (
      tester,
    ) async {
      await pumpCart(tester);

      expect(find.byType(CartItem), findsNWidgets(2));
      expect(find.byType(ActivityImage), findsNWidgets(2));
      expect(find.text('Journée ski'), findsOneWidget);
      expect(find.text('Isola 2000'), findsOneWidget);
      expect(find.text('49 €'), findsOneWidget);
      expect(find.text('12,50 €'), findsOneWidget);
    });

    testWidgets('Affiche le total général', (tester) async {
      await pumpCart(tester);

      expect(total(tester), '61,50 €');
    });

    testWidgets('La croix retire l’activité et met à jour le total', (
      tester,
    ) async {
      final cart = await pumpCart(tester);

      await tester.tap(find.byTooltip('Retirer Journée ski'));
      await tester.pumpAndSettle();

      expect(cart.cartOf('user1').map((a) => a.id), ['yoga']);
      expect(find.text('Journée ski'), findsNothing);
      expect(total(tester), '12,50 €');
    });

    testWidgets('Aucun autre bouton d’action (pas de paiement)', (
      tester,
    ) async {
      await pumpCart(tester);

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('Panier vide : message, pas de total', (tester) async {
      await pumpApp(tester, const Scaffold(body: CartPage(user: user1)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ton panier est vide'), findsOneWidget);
      expect(find.byKey(const Key('cart-total')), findsNothing);
    });
  });

  group('US#5 Profil', () {
    Future<FakeUserService> pumpProfile(WidgetTester tester) async {
      final users = FakeUserService();
      await pumpApp(
        tester,
        const Scaffold(body: ProfilePage(user: user1)),
        userService: users,
      );
      await tester.pumpAndSettle();
      return users;
    }

    TextField field(WidgetTester tester, String key) =>
        tester.widget<TextField>(find.byKey(Key(key)));

    testWidgets('Affiche les informations récupérées en base', (tester) async {
      await pumpProfile(tester);

      expect(field(tester, 'profile-login').controller!.text, 'user1');
      expect(field(tester, 'profile-password').controller!.text, 'password1');
      expect(field(tester, 'profile-birthday').controller!.text, '12/12/1993');
      expect(
        field(tester, 'profile-address').controller!.text,
        'Promenade des anglais',
      );
      expect(field(tester, 'profile-postal-code').controller!.text, '06000');
      expect(field(tester, 'profile-city').controller!.text, 'Nice');
    });

    testWidgets('Login en lecture seule, password masqué', (tester) async {
      await pumpProfile(tester);

      expect(field(tester, 'profile-login').readOnly, isTrue);
      expect(field(tester, 'profile-password').obscureText, isTrue);
    });

    testWidgets('Code postal : clavier numérique, chiffres uniquement', (
      tester,
    ) async {
      await pumpProfile(tester);

      expect(
        field(tester, 'profile-postal-code').keyboardType,
        TextInputType.number,
      );
      await tester.enterText(
        find.byKey(const Key('profile-postal-code')),
        'a06b00x0',
      );
      expect(field(tester, 'profile-postal-code').controller!.text, '06000');
    });

    testWidgets('Valider enregistre les modifications en base', (tester) async {
      final users = await pumpProfile(tester);

      await tester.enterText(find.byKey(const Key('profile-city')), 'Lyon');
      await tester.enterText(
        find.byKey(const Key('profile-postal-code')),
        '69002',
      );
      await tester.ensureVisible(find.text('Valider'));
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      expect(users.users['user1']!.city, 'Lyon');
      expect(users.users['user1']!.postalCode, '69002');
      expect(users.users['user1']!.address, 'Promenade des anglais');
      expect(find.text('Profil mis à jour'), findsOneWidget);
    });

    testWidgets('Se déconnecter revient à la page de login', (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(ProfilePage), findsNothing);
    });
  });

  group('US#6 Ajout d’activité avec IA', () {
    Future<FakeActivityService> pumpAdd(
      WidgetTester tester, {
      CategoryClassifier? classifier,
      PickedImage? image,
    }) async {
      final activities = FakeActivityService();
      await pumpApp(
        tester,
        AddActivityPage(pickImage: () async => image ?? testImage),
        activityService: activities,
        classifier: classifier,
      );
      await tester.pumpAndSettle();
      return activities;
    }

    String detectedCategory(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('detected-category'))).data!;

    Future<void> fillForm(WidgetTester tester) async {
      await tester.enterText(find.byKey(const Key('add-title')), 'Kayak');
      await tester.enterText(find.byKey(const Key('add-location')), 'Antibes');
      await tester.enterText(find.byKey(const Key('add-max-people')), '8');
      await tester.enterText(find.byKey(const Key('add-price')), '40');
    }

    Future<void> tapValider(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Valider'));
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();
    }

    testWidgets('Le profil propose d’ajouter une activité', (tester) async {
      await pumpApp(tester, const Scaffold(body: ProfilePage(user: user1)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajouter une activité'));
      await tester.pumpAndSettle();

      expect(find.byType(AddActivityPage), findsOneWidget);
    });

    testWidgets('La catégorie est détectée par l’IA à partir de l’image', (
      tester,
    ) async {
      final classifier = FakeClassifier('Nature');
      await pumpAdd(tester, classifier: classifier);
      expect(detectedCategory(tester), 'Ajoute une photo');

      await tester.tap(find.text('Ajouter une photo'));
      await tester.pumpAndSettle();

      expect(classifier.calls, 1);
      expect(detectedCategory(tester), 'Nature');
    });

    testWidgets('La catégorie n’est pas éditable', (tester) async {
      await pumpAdd(tester);

      // Seuls titre, lieu, personnes max et prix sont des champs de saisie.
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('Prix et personnes max : clavier numérique, chiffres seuls', (
      tester,
    ) async {
      await pumpAdd(tester);

      for (final key in ['add-price', 'add-max-people']) {
        final field = find.byKey(Key(key));
        expect(
          tester.widget<TextField>(field).keyboardType,
          TextInputType.number,
        );
        await tester.enterText(field, '2a5,€');
        expect(tester.widget<TextField>(field).controller!.text, '25');
      }
    });

    testWidgets('Valider enregistre l’activité en base', (tester) async {
      final activities = await pumpAdd(tester);

      await tester.tap(find.text('Ajouter une photo'));
      await tester.pumpAndSettle();
      await fillForm(tester);
      await tapValider(tester);

      expect(activities.added, hasLength(1));
      final added = activities.added.single;
      expect(added.title, 'Kayak');
      expect(added.category, 'Sport');
      expect(added.location, 'Antibes');
      expect(added.maxPeople, 8);
      expect(added.price, 40);
      expect(added.imageUrl, startsWith('data:image/png;base64,'));
      expect(find.byType(AddActivityPage), findsNothing);
    });

    testWidgets('Sans image : rien n’est enregistré', (tester) async {
      final activities = await pumpAdd(tester);

      await fillForm(tester);
      await tapValider(tester);

      expect(activities.added, isEmpty);
      expect(find.text('Ajoute une photo'), findsWidgets);
    });

    testWidgets(
      'IA en échec : message, relance possible, pas d’enregistrement',
      (tester) async {
        final activities = await pumpAdd(
          tester,
          classifier: FakeClassifier(null),
        );

        await tester.tap(find.text('Ajouter une photo'));
        await tester.pumpAndSettle();
        expect(detectedCategory(tester), "Échec de l'analyse");
        expect(find.byTooltip("Relancer l'analyse"), findsOneWidget);

        await fillForm(tester);
        await tapValider(tester);
        expect(activities.added, isEmpty);
      },
    );

    testWidgets('Quota IA atteint : message dédié', (tester) async {
      await pumpAdd(tester, classifier: FakeClassifier('Sport', true));

      await tester.tap(find.text('Ajouter une photo'));
      await tester.pumpAndSettle();

      expect(detectedCategory(tester), contains('réessaie dans une minute'));
      expect(find.byTooltip("Relancer l'analyse"), findsOneWidget);
    });
  });
}
