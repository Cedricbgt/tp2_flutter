import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MiagedApp());
}

class MiagedApp extends StatelessWidget {
  const MiagedApp({super.key});

  static const title = 'MIAGED';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
