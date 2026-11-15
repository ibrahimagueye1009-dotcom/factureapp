import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/account.dart';

class AuthScreen extends StatefulWidget {
  final bool hasAccount;
  final bool awaitingEmailVerification;
  final VoidCallback onAuthenticated;

  const AuthScreen({
    super.key,
    required this.hasAccount,
    this.awaitingEmailVerification = false,
    required this.onAuthenticated,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  bool _awaitingVerification = false;
  bool _localRegistration = false;

  late bool _register = !widget.hasAccount;

  @override
  void initState() {
    super.initState();
    _awaitingVerification = widget.awaitingEmailVerification;
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _authError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Cette adresse e-mail est déjà associée à un compte.';

        case 'invalid-email':
          return 'L’adresse e-mail n’est pas valide.';

        case 'weak-password':
          return 'Choisissez un mot de passe plus robuste.';

        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou mot de passe incorrect.';

        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez plus tard.';

        case 'network-request-failed':
          return 'Connexion Internet indisponible.';

        case 'account-exists-with-different-credential':
          return 'Un compte existe déjà avec cette adresse. Essayez votre méthode de connexion habituelle.';

        case 'operation-not-allowed':
          return 'Cette méthode de connexion n’est pas activée dans Firebase.';

        case 'requires-recent-login':
          return 'Reconnectez-vous avant de réaliser cette opération.';

        default:
          return 'Firebase Auth : ${error.message ?? error.code}';
      }
    }

    return 'Une erreur est survenue : $error';
  }

  bool get _looksLikeEmail => _contact.text.trim().contains('@');

  // CONNEXION GOOGLE
  Future<void> _signInWithGoogle() async {
    if (_busy) return;

    if (!AccountStore.firebaseReady) {
      _toast('Firebase n’est pas disponible. Vérifiez votre connexion.');
      return;
    }

    setState(() => _busy = true);

    try {
      final credential = await AccountStore.signInWithGoogle();

      final user = credential.user;

      if (user == null) {
        _toast('Google n’a pas retourné de compte utilisateur.');
        return;
      }

      // Actualiser les informations Firebase.
      await user.reload();

      final refreshedUser = AccountStore.currentFirebaseUser;

      if (refreshedUser == null) {
        _toast('Impossible de récupérer votre compte Firebase.');
        return;
      }

      // Vérifier l'adresse e-mail.
      if (!refreshedUser.emailVerified) {
        await AccountStore.signOutFirebase();

        _toast('Votre adresse Google n’est pas confirmée.');
        return;
      }

      // Associer le compte Google aux données locales.
      await AccountStore.associateFirebaseUser(refreshedUser);

      if (!mounted) return;

      _toast('Connexion Google réussie !');

      widget.onAuthenticated();
    } on FirebaseAuthException catch (error) {
      _toast(_authError(error));
    } catch (error) {
      final message = error.toString().toLowerCase();

      if (message.contains('cancel')) {
        _toast('Connexion Google annulée.');
      } else {
        _toast('Connexion Google impossible : $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // CONNEXION OU INSCRIPTION LOCALE
  Future<void> _submitLocal(
    String name,
    String contact,
    String password,
  ) async {
    if (_register) {
      final created = await AccountStore.create(
        name,
        contact,
        password,
      );

      if (!mounted) return;

      if (!created) {
        _toast('Un compte local existe déjà pour ce contact.');
        return;
      }

      _toast('Compte local créé. Vos données restent sur cet appareil.');
      widget.onAuthenticated();
      return;
    }

    final ok = await AccountStore.login(contact, password);

    if (!mounted) return;

    if (!ok) {
      _toast('Aucun compte local correspondant ou mot de passe incorrect.');
      return;
    }

    _toast('Session locale : aucune vérification Firebase effectuée.');
    widget.onAuthenticated();
  }

  // CONNEXION / INSCRIPTION PAR E-MAIL
  Future<void> _submit() async {
    if (_busy) return;

    final contact = _contact.text.trim();
    final password = _password.text;

    if (_register) {
      final name = _name.text.trim();

      if (name.isEmpty) {
        _toast('Entrez votre nom complet.');
        return;
      }

      if (contact.isEmpty) {
        _toast('Entrez un e-mail ou un numéro de téléphone.');
        return;
      }

      if (password.length < 4) {
        _toast('Le mot de passe doit contenir au moins 4 caractères.');
        return;
      }

      if (password != _confirm.text) {
        _toast('Les deux mots de passe ne sont pas identiques.');
        return;
      }

      if (!_localRegistration && AccountStore.firebaseReady) {
        if (!_looksLikeEmail) {
          _toast('Saisissez une adresse e-mail valide.');
          return;
        }

        if (password.length < 6) {
          _toast('Le mot de passe doit contenir au moins 6 caractères.');
          return;
        }

        setState(() => _busy = true);

        try {
          await AccountStore.registerWithEmail(
            name,
            contact,
            password,
          );

          if (!mounted) return;

          setState(() => _awaitingVerification = true);

          _toast(
            'E-mail de vérification envoyé. Confirmez votre adresse.',
          );
        } catch (error) {
          final pendingUser = AccountStore.currentFirebaseUser;

          if (mounted && pendingUser != null && !pendingUser.emailVerified) {
            setState(() => _awaitingVerification = true);

            _toast(
              'Compte créé. Vous pouvez renvoyer le message de vérification.',
            );
          } else {
            _toast(_authError(error));
          }
        } finally {
          if (mounted) setState(() => _busy = false);
        }

        return;
      }

      setState(() => _busy = true);

      try {
        await _submitLocal(name, contact, password);
      } catch (error) {
        _toast(_authError(error));
      } finally {
        if (mounted) setState(() => _busy = false);
      }

      return;
    }

    if (contact.isEmpty || password.isEmpty) {
      _toast('Entrez votre e-mail/téléphone et votre mot de passe.');
      return;
    }

    if (!_looksLikeEmail || !AccountStore.firebaseReady) {
      setState(() => _busy = true);

      try {
        await _submitLocal('', contact, password);
      } catch (error) {
        _toast(_authError(error));
      } finally {
        if (mounted) setState(() => _busy = false);
      }

      return;
    }

    setState(() => _busy = true);

    try {
      final credential = await AccountStore.signInWithEmail(
        contact,
        password,
      );

      final user = credential.user;

      if (user == null) {
        _toast('Firebase n’a pas retourné de compte utilisateur.');
      } else {
        await user.reload();

        final refreshed = AccountStore.currentFirebaseUser;

        if (refreshed?.emailVerified != true) {
          setState(() => _awaitingVerification = true);
          _toast('Confirmez votre adresse e-mail avant de continuer.');
        } else {
          await AccountStore.associateFirebaseUser(refreshed!);

          if (mounted) widget.onAuthenticated();
        }
      }
    } on FirebaseAuthException catch (error) {
      if ({
        'network-request-failed',
        'user-not-found',
        'wrong-password',
        'invalid-credential',
      }.contains(error.code)) {
        final localLogin = await AccountStore.login(
          contact,
          password,
        );

        if (!mounted) return;

        if (localLogin) {
          _toast(
            'Ancien compte local ouvert. Cette session n’est pas une connexion Firebase vérifiée.',
          );

          widget.onAuthenticated();
        } else {
          _toast(_authError(error));
        }
      } else {
        _toast(_authError(error));
      }
    } catch (error) {
      _toast(_authError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // VÉRIFICATION E-MAIL
  Future<void> _resendVerification() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await AccountStore.resendVerificationEmail();
      _toast('Un nouvel e-mail de vérification a été envoyé.');
    } catch (error) {
      _toast(_authError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkVerification() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final verified = await AccountStore.reloadFirebaseUser();

      if (!mounted) return;

      if (verified) {
        final user = AccountStore.currentFirebaseUser;

        if (user != null) {
          await AccountStore.associateFirebaseUser(user);
        }

        if (mounted) widget.onAuthenticated();
      } else {
        _toast(
          'Adresse non confirmée. Ouvrez le lien reçu puis réessayez.',
        );
      }
    } catch (error) {
      _toast(_authError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _contact.text.trim();

    if (!email.contains('@')) {
      _toast('Saisissez votre adresse e-mail dans le champ de connexion.');
      return;
    }

    if (!AccountStore.firebaseReady) {
      _toast('La récupération nécessite une connexion Firebase.');
      return;
    }

    setState(() => _busy = true);

    try {
      await AccountStore.sendPasswordResetEmail(email);

      _toast(
        'Si un compte existe, un e-mail de récupération a été envoyé.',
      );
    } catch (error) {
      _toast(_authError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelVerification() async {
    await AccountStore.signOutFirebase();

    if (mounted) {
      setState(() => _awaitingVerification = false);
    }
  }

  InputDecoration _dec(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
    );
  }

  // ÉCRAN DE VÉRIFICATION
  Widget _verificationScreen() {
    final email =
        AccountStore.currentFirebaseUser?.email ?? _contact.text.trim();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF092D58),
              Color(0xFF0878CF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 52,
                      color: Color(0xFF0878CF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vérifiez votre adresse e-mail',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF102B50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ouvrez le lien de confirmation envoyé à $email. '
                      'L’accès sera accordé après confirmation par Firebase.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF697789)),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _busy ? null : _checkVerification,
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('J’ai confirmé mon adresse'),
                    ),
                    TextButton.icon(
                      onPressed: _busy ? null : _resendVerification,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Renvoyer l’e-mail'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _cancelVerification,
                      child: const Text('Retour à la connexion'),
                    ),
                    if (_busy) ...[
                      const SizedBox(height: 8),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ÉCRAN PRINCIPAL
  @override
  Widget build(BuildContext context) {
    if (_awaitingVerification) {
      return _verificationScreen();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF092D58),
              Color(0xFF0878CF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      size: 46,
                      color: Color(0xFF0878CF),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _register ? 'Créer un compte' : 'Connexion',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _register
                        ? (_localRegistration || !AccountStore.firebaseReady
                            ? 'Créez un compte local. Il restera sur cet appareil.'
                            : 'Créez votre compte avec votre adresse e-mail.')
                        : 'Bienvenue ! Connectez-vous pour retrouver vos factures.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // FORMULAIRE
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_register) ...[
                          TextField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: _dec(
                              'Nom complet',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextField(
                          controller: _contact,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec(
                            _register &&
                                    AccountStore.firebaseReady &&
                                    !_localRegistration
                                ? 'Adresse e-mail'
                                : 'E-mail ou téléphone',
                            icon: Icons.alternate_email,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: _dec(
                            'Mot de passe',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() => _obscure = !_obscure);
                              },
                            ),
                          ),
                        ),
                        if (_register) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _confirm,
                            obscureText: _obscure,
                            onSubmitted: (_) => _submit(),
                            decoration: _dec(
                              'Confirmer le mot de passe',
                              icon: Icons.lock_outline,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // BOUTON E-MAIL
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0878CF),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _busy ? null : _submit,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward),
                          label: Text(
                            _register
                                ? (_localRegistration ||
                                        !AccountStore.firebaseReady
                                    ? 'Créer un compte local'
                                    : 'Créer mon compte')
                                : 'Se connecter',
                          ),
                        ),

                        // BOUTON GOOGLE
                        if (AccountStore.firebaseReady) ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OU',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF202124),
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFFDADCE0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.g_mobiledata,
                              size: 30,
                              color: Color(0xFF4285F4),
                            ),
                            label: const Text(
                              'Continuer avec Google',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        // MOT DE PASSE OUBLIÉ
                        if (!_register && AccountStore.firebaseReady) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _busy ? null : _resetPassword,
                              child: const Text('Mot de passe oublié ?'),
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        // CHANGEMENT DE MODE
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  setState(() {
                                    _register = !_register;
                                    _localRegistration = false;
                                  });
                                },
                          child: Text(
                            _register
                                ? 'J’ai déjà un compte — Se connecter'
                                : 'Créer un nouveau compte',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // INSCRIPTION LOCALE
                  if (_register && AccountStore.firebaseReady) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                _localRegistration = !_localRegistration;
                              });
                            },
                      child: Text(
                        _localRegistration
                            ? 'Utiliser l’inscription Firebase par e-mail'
                            : 'Créer plutôt un compte local hors ligne',
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    'Vos factures locales restent enregistrées sur cet appareil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
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
