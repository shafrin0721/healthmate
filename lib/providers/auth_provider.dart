import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      notifyListeners();
      return userCredential.user;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<User?> signInWithApple() async {
    try {
      if (!Platform.isIOS && !Platform.isMacOS) {
        throw Exception("Apple Sign-In only supported on iOS/MacOS");
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
      );

      final credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      notifyListeners();
      return userCredential.user;
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      return null;
    }
  }

  Future<User?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(permissions: ['email']);
      if (result.status != LoginStatus.success) return null;

      final accessToken = result.accessToken;
      if (accessToken == null) return null;

      final credential = FacebookAuthProvider.credential(accessToken.token);
      final userCredential = await _auth.signInWithCredential(credential);
      notifyListeners();
      return userCredential.user;
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
  }
}
