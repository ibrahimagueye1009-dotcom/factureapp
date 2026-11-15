import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Account {
  final String id;
  final String name;
  final String contact;
  final String createdAt;
  final int schemaVersion;

  const Account({
    required this.id,
    required this.name,
    required this.contact,
    required this.createdAt,
    this.schemaVersion = 2,
  });

  bool get isLegacy => schemaVersion < 2;
}

/// Gestion des comptes locaux et Firebase.
class AccountStore {
  static const _legacyAccountKey = 'account_v1';
  static const _legacySessionKey = 'account_session_v1';
  static const _accountsKey = 'accounts_v2';
  static const _activeAccountKey = 'account_session_user_v2';
  static const _salt = 'facturation_pro::saer::dte::2026';

  static bool firebaseReady = false;

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  // Google Sign-In 7.x
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleInitialization;

  static Future<void> _initializeGoogleSignIn() {
    return _googleInitialization ??= _googleSignIn.initialize();
  }

  static User? get currentFirebaseUser =>
      firebaseReady ? _auth.currentUser : null;

  static bool get hasVerifiedFirebaseUser =>
      firebaseReady && (_auth.currentUser?.emailVerified ?? false);

  // INSCRIPTION PAR E-MAIL
  static Future<void> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user?.updateDisplayName(name.trim());
    await credential.user?.sendEmailVerification();
  }

  // CONNEXION PAR E-MAIL
  static Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // CONNEXION AVEC GOOGLE
  static Future<UserCredential> signInWithGoogle() async {
    if (!firebaseReady) {
      throw FirebaseAuthException(
        code: 'firebase-not-ready',
        message: 'Firebase n’est pas initialisé.',
      );
    }

    await _initializeGoogleSignIn();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google n’a pas fourni de jeton d’identification.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  // VÉRIFICATION DE L'ADRESSE E-MAIL
  static Future<bool> reloadFirebaseUser() async {
    final user = currentFirebaseUser;
    if (user == null) return false;

    await user.reload();
    return hasVerifiedFirebaseUser;
  }

  static Future<void> resendVerificationEmail() async {
    final user = currentFirebaseUser;

    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }

    await user.sendEmailVerification();
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // DÉCONNEXION FIREBASE ET GOOGLE
  static Future<void> signOutFirebase() async {
    if (!firebaseReady) return;

    await _auth.signOut();

    // La déconnexion Firebase reste prioritaire.
    // Une erreur Google ne doit pas bloquer la fermeture de session.
    try {
      await _initializeGoogleSignIn();
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  // ASSOCIATION DU COMPTE FIREBASE AUX DONNÉES LOCALES
  static Future<void> associateFirebaseUser(User user) async {
    final email = user.email?.trim();

    if (email == null || email.isEmpty || !user.emailVerified) {
      return;
    }

    final id = _idFor(email);
    final p = await SharedPreferences.getInstance();
    final accounts = await _readAccounts();
    final existing = accounts[id];

    if (existing != null &&
        existing['contact']?.toString().trim().toLowerCase() !=
            email.toLowerCase()) {
      return;
    }

    accounts[id] = {
      ...?existing,
      'name': user.displayName ?? existing?['name'] ?? email,
      'contact': email,
      'createdAt': existing?['createdAt'] ?? DateTime.now().toIso8601String(),
      'schemaVersion': existing?['schemaVersion'] ?? 2,
      'firebaseUid': user.uid,
    };

    await p.setString(_accountsKey, jsonEncode(accounts));
    await p.setString(_activeAccountKey, id);
    await p.setBool(_legacySessionKey, false);
  }

  // OUTILS INTERNES
  static String _hash(String password) =>
      sha256.convert(utf8.encode('$_salt:$password')).toString();

  static String _idFor(String contact) => sha256
      .convert(utf8.encode(contact.trim().toLowerCase()))
      .toString()
      .substring(0, 24);

  static Future<Map<String, Map<String, dynamic>>> _readAccounts() async {
    final p = await SharedPreferences.getInstance();
    final accounts = <String, Map<String, dynamic>>{};

    final rawAccounts = p.getString(_accountsKey);

    if (rawAccounts != null) {
      try {
        final decoded =
            Map<String, dynamic>.from(jsonDecode(rawAccounts) as Map);

        for (final entry in decoded.entries) {
          accounts[entry.key] = Map<String, dynamic>.from(entry.value as Map);
        }
      } catch (_) {}
    }

    final legacy = p.getString(_legacyAccountKey);

    if (legacy != null) {
      try {
        final data = Map<String, dynamic>.from(jsonDecode(legacy) as Map);
        final id = _idFor(data['contact']?.toString() ?? '');

        accounts.putIfAbsent(
          id,
          () => {...data, 'schemaVersion': 1},
        );

        if (p.getBool(_legacySessionKey) == true &&
            p.getString(_activeAccountKey) == null) {
          await p.setString(_activeAccountKey, id);
        }

        if (rawAccounts == null) {
          await p.setString(_accountsKey, jsonEncode(accounts));
        }
      } catch (_) {}
    }

    return accounts;
  }

  static Account _toAccount(
    String id,
    Map<String, dynamic> data,
  ) =>
      Account(
        id: id,
        name: data['name']?.toString() ?? '',
        contact: data['contact']?.toString() ?? '',
        createdAt: data['createdAt']?.toString() ?? '',
        schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 1,
      );

  // SESSION LOCALE
  static Future<String> scopeId() async => (await current())?.id ?? 'legacy';

  static Future<Account?> current() async {
    final accounts = await _readAccounts();
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_activeAccountKey);

    if (id == null) return null;

    final data = accounts[id];
    return data == null ? null : _toAccount(id, data);
  }

  static Future<bool> exists() async => (await _readAccounts()).isNotEmpty;

  static Future<bool> loggedIn() async {
    final accounts = await _readAccounts();
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_activeAccountKey);

    if (id == null) return false;

    return accounts.containsKey(id);
  }

  // CRÉATION D'UN COMPTE LOCAL
  static Future<bool> create(
    String name,
    String contact,
    String password,
  ) async {
    final p = await SharedPreferences.getInstance();
    final accounts = await _readAccounts();
    final id = _idFor(contact);

    if (accounts.containsKey(id)) return false;

    accounts[id] = {
      'name': name.trim(),
      'contact': contact.trim(),
      'hash': _hash(password),
      'createdAt': DateTime.now().toIso8601String(),
      'schemaVersion': 2,
    };

    await p.setString(_accountsKey, jsonEncode(accounts));
    await p.setString(_activeAccountKey, id);
    await p.setBool(_legacySessionKey, false);

    return true;
  }

  // CONNEXION À UN COMPTE LOCAL
  static Future<bool> login(
    String contact,
    String password,
  ) async {
    final id = _idFor(contact);
    final accounts = await _readAccounts();
    final data = accounts[id];

    if (data == null ||
        data['contact']?.toString().trim().toLowerCase() !=
            contact.trim().toLowerCase() ||
        data['hash'] != _hash(password)) {
      return false;
    }

    final p = await SharedPreferences.getInstance();

    await p.setString(_activeAccountKey, id);
    await p.setBool(_legacySessionKey, false);

    return true;
  }

  // DÉCONNEXION LOCALE
  static Future<void> logout() async {
    await signOutFirebase();

    final p = await SharedPreferences.getInstance();

    await p.remove(_activeAccountKey);
    await p.setBool(_legacySessionKey, false);
  }

  // SUPPRESSION DU COMPTE LOCAL ACTIF
  static Future<void> deleteAccount() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_activeAccountKey);
    final accounts = await _readAccounts();

    if (id != null) accounts.remove(id);

    await p.setString(_accountsKey, jsonEncode(accounts));
    await p.remove(_activeAccountKey);
    await p.remove(_legacyAccountKey);
    await p.remove(_legacySessionKey);
  }
}
