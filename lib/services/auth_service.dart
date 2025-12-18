// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to authentication state changes
  Stream<User?> get user => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? _verificationId;
  int? _resendToken;
  Completer<UserCredential>? _authCompleter;

  // Method to sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided for that user.');
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      throw Exception('An unknown error occurred: $e');
    }
  }

  // Method to sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      throw Exception('An unknown error occurred: $e');
    }
  }

  // Method to send a password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unknown error occurred: $e');
    }
  }

  // Method to verify phone number and send SMS code
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    _authCompleter = Completer<UserCredential>(); // Reset completer for new attempt

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // AUTO-RETRIEVAL: Android only
        // This callback is invoked automatically when the SMS code is auto-retrieved
        print("Phone verification completed automatically.");
        try {
          UserCredential userCredential = await _auth.signInWithCredential(credential);
          if (!_authCompleter!.isCompleted) {
            _authCompleter!.complete(userCredential);
          }
        } catch (e) {
          if (!_authCompleter!.isCompleted) {
            _authCompleter!.completeError(e);
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        // Handle error (e.g., invalid phone number, too many requests)
        print("Phone verification failed: ${e.message}");
        if (!_authCompleter!.isCompleted) {
          _authCompleter!.completeError(Exception(e.message));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        // SMS code sent to the user's phone
        print("Code sent to phone.");
        _verificationId = verificationId;
        _resendToken = resendToken;
        // The completer is not completed here, it waits for signInWithPhoneNumber
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto-retrieval timed out, user needs to enter code manually
        print("Code auto-retrieval timed out.");
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60), // Optional timeout
      forceResendingToken: _resendToken, // Use resend token if available
    );
  }

  // Method to sign in with SMS code
  Future<UserCredential> signInWithPhoneNumber(String smsCode) async {
    if (_verificationId == null) {
      throw Exception("Phone number verification not initiated or timed out.");
    }
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(userCredential);
      }
      return userCredential;
    } catch (e) {
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.completeError(e);
      }
      throw Exception("Failed to sign in with phone number: $e");
    }
  }

  // Await the result of the phone authentication flow
  Future<UserCredential> get phoneAuthResult => _authCompleter!.future;

  // Method to sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
