import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Phone OTP verification
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // Sign in with OTP
  Future<UserCredential> signInWithOTP({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Sign in with credential (auto-verified)
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  // Create user profile in Firestore
  Future<UserModel> createUserProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    // Generate unique Local Sathi ID
    final counterDoc = await _firestore.collection('counters').doc('users').get();
    int nextId = AppConstants.startingId;
    if (counterDoc.exists) {
      nextId = (counterDoc.data()?['nextId'] ?? AppConstants.startingId);
    }

    final localSathiId = '${AppConstants.idPrefix}$nextId';

    final user = UserModel(
      uid: uid,
      name: name,
      phone: phone,
      localSathiId: localSathiId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toFirestore());

    // Increment counter
    await _firestore.collection('counters').doc('users').set({
      'nextId': nextId + 1,
    });

    return user;
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
