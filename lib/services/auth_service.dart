import 'package:firebase_auth/firebase_auth.dart';

/// The two people allowed in this app.
const kAllowedEmails = {
  'subrat7211@gmail.com',
  'vanshikasinghsengar3@gmail.com',
};

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static bool isAllowed(String email) =>
      kAllowedEmails.contains(email.trim().toLowerCase());

  /// Sign in with email + password. Returns null on success, error string on failure.
  static Future<String?> signIn(String email, String password) async {
    if (!isAllowed(email)) return 'This email is not invited to Gata.';
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account yet — sign up first.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong password.';
        case 'too-many-requests':
          return 'Too many tries. Wait a moment.';
        default:
          return e.message ?? 'Sign-in failed.';
      }
    }
  }

  /// Create account + sign in. Returns null on success, error string on failure.
  static Future<String?> signUp(String email, String password) async {
    if (!isAllowed(email)) return 'This email is not invited to Gata.';
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return null; // already registered → try sign-in next
        case 'weak-password':
          return 'Password too weak (min 6 chars).';
        default:
          return e.message ?? 'Sign-up failed.';
      }
    }
  }

  /// Try sign-up; if account exists, fall back to sign-in.
  static Future<String?> signUpOrIn(String email, String password) async {
    final err = await signUp(email, password);
    if (err != null) return err;
    if (_auth.currentUser != null) return null;
    return signIn(email, password);
  }

  static Future<void> signOut() => _auth.signOut();

  static String myEmail() => currentUser?.email ?? '';
  static bool get isMe =>
      currentUser?.email?.toLowerCase() == 'subrat7211@gmail.com';
}
