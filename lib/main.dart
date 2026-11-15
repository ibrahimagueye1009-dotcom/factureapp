import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/account.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    AccountStore.firebaseReady = true;
  } on FirebaseException {
    AccountStore.firebaseReady = false;
  } on Exception {
    AccountStore.firebaseReady = false;
  }
  runApp(const FacturationApp());
}

class FacturationApp extends StatelessWidget {
  const FacturationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facturation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0878CF)),
        scaffoldBackgroundColor: const Color(0xFFF3F6FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD9E2EC))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD9E2EC))),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Affiche l'écran d'authentification tant que l'utilisateur n'a
/// pas créé de compte (ou n'est pas connecté), sinon l'accueil.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _hasAccount = false;
  bool _loggedIn = false;
  bool _awaitingEmailVerification = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final has = await AccountStore.exists();
    final firebaseUser = AccountStore.currentFirebaseUser;
    var verified = false;
    var awaitingVerification = false;
    if (firebaseUser != null) {
      try {
        await firebaseUser.reload();
        verified = AccountStore.hasVerifiedFirebaseUser;
        awaitingVerification = !verified;
        if (verified) await AccountStore.associateFirebaseUser(firebaseUser);
      } on FirebaseException {
        verified = firebaseUser.emailVerified;
        awaitingVerification = !verified;
      }
    }
    final logged = firebaseUser == null && await AccountStore.loggedIn();
    if (!mounted) return;
    setState(() {
      _hasAccount = has;
      _loggedIn = verified || logged;
      _awaitingEmailVerification = awaitingVerification;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn
        ? HomeScreen(
            onLogout: () {
              if (mounted) {
                setState(() {
                  _loggedIn = false;
                  _awaitingEmailVerification = false;
                });
              }
            },
          )
        : AuthScreen(
            hasAccount: _hasAccount,
            awaitingEmailVerification: _awaitingEmailVerification,
            onAuthenticated: () {
              if (!mounted) return;
              setState(() {
                _loggedIn = true;
                _awaitingEmailVerification = false;
              });
            },
          );
  }
}
