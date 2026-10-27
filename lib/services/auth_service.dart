// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Google से साइन इन
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Google साइन-इन पॉपअप को ट्रिगर करें
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // यूज़र ने पॉपअप बंद कर दिया
        return null;
      }

      // 2. Google से ऑथेंटिकेशन डिटेल्स प्राप्त करें
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Firebase के लिए क्रेडेंशियल बनाएं
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase में साइन इन करें
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      return userCredential.user; // यूज़र को वापस भेजें

    } catch (e) {
      print("Google साइन-इन में एरर: $e");
      return null;
    }
  }

  // साइन आउट
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Google से साइन आउट
    await _auth.signOut();         // Firebase से साइन आउट
  }
}