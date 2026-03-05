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

    // Auto-assign admin role to first user (LS-100001) or designated admin phones
    final isFirstUser = nextId == AppConstants.startingId;
    final isAdminPhone = AppConstants.adminPhones.contains(phone.replaceAll('+91', ''));
    final autoRole = (isFirstUser || isAdminPhone) ? UserRole.admin : UserRole.customer;

    final user = UserModel(
      uid: uid,
      name: name,
      phone: phone,
      localSathiId: localSathiId,
      role: autoRole,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toFirestore());

    // Increment counter
    await _firestore.collection('counters').doc('users').set({
      'nextId': nextId + 1,
    });

    // If this is an admin, seed initial app config
    if (autoRole == UserRole.admin) {
      await _seedAppConfig();
    }

    return user;
  }

  /// Seed initial app config if not exists
  Future<void> _seedAppConfig() async {
    final versionDoc = await _firestore.collection('app_config').doc('version').get();
    if (!versionDoc.exists) {
      await _firestore.collection('app_config').doc('version').set({
        'currentVersion': '1.4.1',
        'minVersion': '1.0.0',
        'updateUrl': 'https://github.com/anirudhatalmale6-alt/local-sathi-app/releases',
        'releaseNotes': 'Welcome to Local Sathi!',
        'betaEnabled': false,
      });
    }

    // Seed default categories if none exist
    final catSnap = await _firestore.collection('categories').limit(1).get();
    if (catSnap.docs.isEmpty) {
      final defaultCategories = [
        {'name': 'Electrician', 'icon': '⚡'},
        {'name': 'Plumber', 'icon': '🔧'},
        {'name': 'Tutor', 'icon': '📚'},
        {'name': 'Carpenter', 'icon': '🪚'},
        {'name': 'Painter', 'icon': '🎨'},
        {'name': 'AC Repair', 'icon': '❄️'},
        {'name': 'Cleaner', 'icon': '🧹'},
        {'name': 'Driver', 'icon': '🚗'},
      ];
      final batch = _firestore.batch();
      for (final cat in defaultCategories) {
        batch.set(_firestore.collection('categories').doc(), {
          ...cat,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
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
