import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Register with email, password, and username
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user's display name with the provided username
      await userCredential.user!.updateDisplayName(username);

      return userCredential.user;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update username (not needed for registration, but keeping for other use cases)
  Future<void> updateUsername(String username) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(username);
      } else {
        throw Exception('User is not logged in');
      }
    } catch (e) {
      print('Error updating username: $e');
      rethrow;
    }
  }
}
