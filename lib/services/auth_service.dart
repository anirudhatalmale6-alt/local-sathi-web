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

  // Android API key from google-services.json
  static const _apiKey = 'AIzaSyDNOCIYHqUr-D3qX0Hk5on8dykkvrhB5tY';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Phone OTP verification
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
    String? recaptchaToken,
  }) async {
    if (!kIsWeb && recaptchaToken != null) {
      // Android with reCAPTCHA token: use REST API to bypass Play Integrity
      await _verifyPhoneViaRest(
        phoneNumber: phoneNumber,
        recaptchaToken: recaptchaToken,
        onCodeSent: onCodeSent,
        onError: onError,
      );
    } else if (kIsWeb) {
      // Web: use SDK directly
      await _verifyPhoneViaSdk(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onError: onError,
        onAutoVerified: onAutoVerified,
      );
    } else {
      // Android without reCAPTCHA: try SDK first, expect it may fail
      await _verifyPhoneViaSdk(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onError: onError,
        onAutoVerified: onAutoVerified,
      );
    }
  }

  // REST API with reCAPTCHA token - bypasses Play Integrity
  Future<void> _verifyPhoneViaRest({
    required String phoneNumber,
    required String recaptchaToken,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
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

      if (data.containsKey('sessionInfo')) {
        onCodeSent(data['sessionInfo'] as String);
      } else if (data.containsKey('error')) {
        final error = data['error'] as Map<String, dynamic>;
        final message = error['message'] as String? ?? '';
        if (message.contains('TOO_MANY_ATTEMPTS') || message.contains('too-many-requests')) {
          onError('Too many OTP requests. Please wait 1-2 hours before trying again.');
        } else if (message.contains('INVALID_PHONE_NUMBER')) {
          onError('Invalid phone number. Please check and try again.');
        } else if (message.contains('CAPTCHA_CHECK_FAILED')) {
          onError('Verification check failed. Please try again.');
        } else if (message.contains('QUOTA_EXCEEDED')) {
          onError('SMS quota exceeded. Please try again later.');
        } else {
          onError('Could not send OTP. Please try again.');
        }
      } else {
        onError('Could not send OTP. Please try again.');
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
    // Try SDK credential approach first
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // SDK failed - try REST API verification then sign in
      return await _signInViaRest(sessionInfo: verificationId, code: otp);
    }
  }

  // REST API sign-in as fallback
  Future<UserCredential> _signInViaRest({
    required String sessionInfo,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=$_apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionInfo': sessionInfo,
        'code': code,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      final errMsg = (data['error'] as Map<String, dynamic>)['message'] ?? '';
      if (errMsg.toString().contains('INVALID_CODE') ||
          errMsg.toString().contains('SESSION_EXPIRED')) {
        throw FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'Invalid OTP. Please try again.',
        );
      }
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Verification failed. Please try again.',
      );
    }

    // REST API succeeded - user is authenticated on server
    // Now try to get SDK to recognize the session
    final idToken = data['idToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;

    if (idToken != null) {
      // The user exists in Firebase Auth now
      // Try signing in with the credential one more time
      // (the server-side session should now be valid)
      try {
        final credential = PhoneAuthProvider.credential(
          verificationId: sessionInfo,
          smsCode: code,
        );
        return await _auth.signInWithCredential(credential);
      } catch (_) {
        // If credential approach still fails, reload the current user
        // The REST API already authenticated - check if user state updated
        await _auth.currentUser?.reload();
        if (_auth.currentUser != null) {
          // User is signed in via REST, return a mock credential result
          throw FirebaseAuthException(
            code: 'rest-auth-success',
            message: idToken,
          );
        }
      }
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
