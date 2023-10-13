import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/collectibles_logic.dart';

class AuthWidget extends StatelessWidget with GetItMixin {
  AuthWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = getX((AuthLogic a) => a.auth.currentUser);
    final user = watchStream((AuthLogic a) => a.auth.authStateChanges(), currentUser);
    if (user.hasData && !user.data!.isAnonymous) {
      return AuthAccountWidget();
    } else {
      return AuthLoginWidget();
    }
  }
}

class StreamingValueListenable<T> extends ValueNotifier<T> {
  StreamingValueListenable(Stream<T> stream, T defaultValue) : super(defaultValue) {
    _subscription = stream.asBroadcastStream().listen(
          (T value) => value = value,
        );
  }

  late final StreamSubscription<T> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Shows buttons that is used for logging in.
class AuthLoginWidget extends StatelessWidget with GetItMixin {
  AuthLoginWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text($strings.signinLoginTitle),
        const SizedBox(width: 20),
        //gmail
        AppBtn(
          onPressed: () async {
            debugPrint('Starting authentication with Google');
            final auth = getX((AuthLogic a) => a.auth);
            final googleUser = await GoogleSignIn().signIn();
            final googleAuth = await googleUser?.authentication;
            if (googleAuth != null) {
              final credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );
              // Once signed in, return the UserCredential
              await auth.signInWithCredential(credential);
              getX((SettingsLogic s) => s.sync());
              getX((CollectiblesLogic c) => c.sync());
            }
          },
          padding: EdgeInsets.symmetric(vertical: $styles.insets.sm),
          bgColor: Colors.transparent,
          semanticLabel: $strings.signinGoogleSemanticFocus,
          child: SizedBox(
            height: 30,
            width: 30,
            child: Container(
              transform: Matrix4.translationValues(-8.0, -7.0, 0.0),
              child: const Icon(Icons.g_mobiledata, size: 48),
            ),
          ),
        ),
        const SizedBox(width: 15),
        //apple
        AppBtn(
          onPressed: () async {
            debugPrint('Starting authentication with Apple');
            final auth = getX((AuthLogic a) => a.auth);
            final appleProvider = AppleAuthProvider()
              ..addScope('email')
              ..addScope('profile');
            try {
              final userCred = await auth.signInWithProvider(appleProvider);
              debugPrint(userCred.user?.toString());
              final info = userCred.additionalUserInfo;
              debugPrint('newUser: ${info?.isNewUser}, ${info?.profile?.toString()}');
              getX((SettingsLogic s) => s.sync());
              getX((CollectiblesLogic c) => c.sync());
            } on FirebaseAuthException catch (e) {
              debugPrint(e.message);
            } catch (e) {
              debugPrint(e.toString());
            }
          },
          padding: EdgeInsets.symmetric(vertical: $styles.insets.sm),
          bgColor: Colors.transparent,
          semanticLabel: $strings.signinAppleSemanticFocus,
          child: const Icon(Icons.apple, size: 30),
        ),
        const SizedBox(width: 20),
      ]
          .animate(interval: 50.ms)
          .fade(delay: $styles.times.pageTransition + 50.ms)
          .slide(begin: Offset(0.1, 0), curve: Curves.easeOut),
    );
  }
}

/// Shows current account information and log out button.
class AuthAccountWidget extends StatelessWidget with GetItMixin {
  AuthAccountWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = getX((AuthLogic a) => a.auth.currentUser!);
    final name = user.displayName ?? user.email!.substring(0, user.email!.indexOf('@'));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(2),
          child: Text($strings.signinWelcomeTitle(name)),
        ),
        const SizedBox(width: 10),
        AppBtn(
          onPressed: () async {
            final auth = getX((AuthLogic a) => a.auth);
            await auth.signOut();
            getX((SettingsLogic s) => s.load());
          },
          padding: EdgeInsets.symmetric(vertical: $styles.insets.sm),
          bgColor: Colors.transparent,
          semanticLabel: $strings.signinLogoutSemanticFocus,
          child: const Icon(Icons.logout, size: 30),
        ),
        const SizedBox(width: 20),
      ]
          .animate(interval: 50.ms)
          .fade(delay: $styles.times.pageTransition + 50.ms)
          .slide(begin: Offset(0.1, 0), curve: Curves.easeOut),
    );
  }
}
