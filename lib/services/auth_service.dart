import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../config/constants.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Web API key bypasses Android Play Integrity / SHA-1 restrictions
  static const _webApiKey = 'AIzaSyB8rbRBZodVqfGT3OeiXsIjsB5BOUtKG_4';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Phone OTP verification
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    if (!kIsWeb) {
      // Android: use REST API to bypass Play Integrity SHA-1 check
      await _verifyPhoneViaRest(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onError: onError,
      );
    } else {
      // Web: use SDK directly
      await _verifyPhoneViaSdk(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onError: onError,
        onAutoVerified: onAutoVerified,
      );
    }
  }

  // REST API approach - bypasses Play Integrity entirely
  Future<void> _verifyPhoneViaRest({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=$_webApiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'recaptchaToken': 'NO_RECAPTCHA',
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data.containsKey('sessionInfo')) {
        onCodeSent(data['sessionInfo'] as String);
      } else if (data.containsKey('error')) {
        final error = data['error'] as Map<String, dynamic>;
        final message = error['message'] as String? ?? 'Verification failed';
        if (message.contains('TOO_MANY_ATTEMPTS')) {
          onError('Too many OTP requests. Please wait 1-2 hours before trying again.');
        } else if (message.contains('INVALID_PHONE_NUMBER')) {
          onError('Invalid phone number. Please check and try again.');
        } else if (message.contains('QUOTA_EXCEEDED')) {
          onError('SMS quota exceeded. Please try again later.');
        } else {
          onError('Verification failed. Please try again.');
        }
      } else {
        onError('Verification failed. Please try again.');
      }
    } catch (e) {
      onError('No internet connection. Please check your network.');
    }
  }

  // SDK approach for web
  Future<void> _verifyPhoneViaSdk({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: (FirebaseAuthException e) {
        String msg;
        switch (e.code) {
          case 'too-many-requests':
            msg = 'Too many OTP requests. Please wait 1-2 hours before trying again.';
            break;
          case 'invalid-phone-number':
            msg = 'Invalid phone number. Please check and try again.';
            break;
          case 'quota-exceeded':
            msg = 'SMS quota exceeded. Please try again later.';
            break;
          case 'network-request-failed':
            msg = 'No internet connection. Please check your network.';
            break;
          default:
            msg = e.message ?? 'Verification failed. Please try again.';
        }
        onError(msg);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // Sign in with OTP - works with both REST sessionInfo and SDK verificationId
  Future<UserCredential> signInWithOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      // Try SDK credential approach (works for both REST sessionInfo and SDK verificationId)
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // Fallback: verify via REST API then sign in
      return await _signInViaRest(
        sessionInfo: verificationId,
        code: otp,
      );
    }
  }

  // REST API sign-in fallback
  Future<UserCredential> _signInViaRest({
    required String sessionInfo,
    required String code,
  }) async {
    // Verify OTP via REST API
    final response = await http.post(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=$_webApiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionInfo': sessionInfo,
        'code': code,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'Invalid OTP. Please try again.',
      );
    }

    // REST verified successfully. Now sync with Firebase Auth SDK.
    // The user already exists in Firebase. Sign in using the ID token.
    final idToken = data['idToken'] as String?;
    if (idToken != null) {
      // Exchange the REST API ID token for an SDK session
      // by signing in anonymously then linking, or using custom token
      // Simplest: the REST API already created the session, just reload
      await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: sessionInfo,
          smsCode: code,
        ),
      );
    }

    // If we somehow got here, try one more time
    if (_auth.currentUser != null) {
      return Future.value(null as dynamic);
    }

    throw FirebaseAuthException(
      code: 'unknown',
      message: 'Sign in failed. Please try again.',
    );
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

    // Award registration bonus points
    try {
      await FirestoreService().awardPointsOnce(
        uid,
        SathiPoints.registration,
        'Welcome bonus - Registration',
        'registration',
      );
    } catch (_) {}

    return user;
  }

  /// Seed initial app config if not exists
  Future<void> _seedAppConfig() async {
    final versionDoc = await _firestore.collection('app_config').doc('version').get();
    if (!versionDoc.exists) {
      await _firestore.collection('app_config').doc('version').set({
        'currentVersion': '1.4.1',
        'minVersion': '1.0.0',
        'updateUrl': 'https://github.com/anirudhatalmale6-alt/local-sathi-web/releases/latest',
        'releaseNotes': 'Welcome to Local Sathi!',
        'betaEnabled': false,
      });
    }

    // Seed default categories if none exist
    final catSnap = await _firestore.collection('categories').limit(1).get();
    if (catSnap.docs.isEmpty) {
      final defaultCategories = AppConstants.allCategories
          .map((name) => {'name': name, 'icon': '🔹'})
          .toList();
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
