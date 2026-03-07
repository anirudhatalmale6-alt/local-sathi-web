import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../config/constants.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Android API key from google-services.json
  static const _apiKey = 'AIzaSyDNOCIYHqUr-D3qX0Hk5on8dykkvrhB5tY';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send OTP via REST API with reCAPTCHA token
  /// Returns sessionInfo (used as verificationId)
  Future<String> sendOTPViaRest({
    required String phoneNumber,
    required String recaptchaToken,
  }) async {
    final response = await http.post(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=$_apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'recaptchaToken': recaptchaToken,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('sendVerificationCode response: ${response.statusCode}');

    if (data.containsKey('sessionInfo')) {
      return data['sessionInfo'] as String;
    }

    // Handle errors
    final error = data['error'] as Map<String, dynamic>?;
    final message = error?['message'] as String? ?? 'Unknown error';

    if (message.contains('TOO_MANY_ATTEMPTS') || message.contains('too-many-requests')) {
      throw 'Too many OTP requests. Please wait 1-2 hours before trying again.';
    } else if (message.contains('INVALID_PHONE_NUMBER')) {
      throw 'Invalid phone number. Please check and try again.';
    } else if (message.contains('QUOTA_EXCEEDED')) {
      throw 'SMS quota exceeded. Please try again later.';
    }
    throw 'Could not send OTP. Please try again.';
  }

  /// Verify OTP via REST API and sign into Firebase
  Future<UserCredential> verifyOTPViaRest({
    required String sessionInfo,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=$_apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionInfo': sessionInfo,
        'code': otp,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('signInWithPhoneNumber response: ${response.statusCode}');

    if (data.containsKey('error')) {
      final errMsg = (data['error'] as Map<String, dynamic>)['message'] ?? '';
      if (errMsg.toString().contains('INVALID_CODE') ||
          errMsg.toString().contains('SESSION_EXPIRED')) {
        throw 'Invalid OTP. Please try again.';
      }
      throw 'Verification failed. Please try again.';
    }

    // REST API succeeded. Now sign into the Firebase SDK.
    // First try PhoneAuthProvider.credential (works if backend session is compatible)
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: sessionInfo,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('SDK signInWithCredential failed: $e');
    }

    // Fallback: the REST API already authenticated the user.
    // The idToken proves the user is verified. Reload auth state.
    // Try reloading to pick up the session.
    await Future.delayed(const Duration(milliseconds: 500));
    await _auth.currentUser?.reload();
    if (_auth.currentUser != null) {
      // User is signed in through REST, create a fake UserCredential
      // by signing in again with the same credential
      final credential = PhoneAuthProvider.credential(
        verificationId: sessionInfo,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    }

    throw 'Sign in failed. Please try again.';
  }

  /// SDK-based phone verification (for web or when Play Integrity works)
  Future<void> verifyPhoneViaSdk({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    if (!kIsWeb) {
      await _auth.setSettings(forceRecaptchaFlow: true);
    }
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

  // Sign in with OTP (SDK approach)
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
