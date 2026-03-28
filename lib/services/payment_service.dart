import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._();
  factory PaymentService() => _instance;
  PaymentService._();

  // Razorpay TEST key - replace with live key for production
  static const String _testKey = 'rzp_test_1DP5mmOlF5G5ag';

  late Razorpay _razorpay;
  Function(String paymentId)? _onSuccess;
  Function(String message)? _onFailure;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternal);
  }

  void dispose() {
    _razorpay.clear();
  }

  /// Start a payment for booking
  void payForBooking({
    required double amount,
    required String bookingId,
    required String customerName,
    required String customerPhone,
    required String description,
    required Function(String paymentId) onSuccess,
    required Function(String message) onFailure,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;

    final options = {
      'key': _testKey,
      'amount': (amount * 100).toInt(), // Razorpay expects paise
      'name': 'Local Sathi',
      'description': description,
      'prefill': {
        'contact': customerPhone,
        'name': customerName,
      },
      'notes': {
        'booking_id': bookingId,
        'type': 'booking',
      },
      'theme': {
        'color': '#00897B',
      },
    };

    _razorpay.open(options);
  }

  /// Start a payment for subscription
  void payForSubscription({
    required double amount,
    required String planName,
    required String userName,
    required String userPhone,
    required String userUid,
    required Function(String paymentId) onSuccess,
    required Function(String message) onFailure,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;

    final options = {
      'key': _testKey,
      'amount': (amount * 100).toInt(),
      'name': 'Local Sathi',
      'description': '$planName Subscription',
      'prefill': {
        'contact': userPhone,
        'name': userName,
      },
      'notes': {
        'user_uid': userUid,
        'plan': planName,
        'type': 'subscription',
      },
      'theme': {
        'color': '#00897B',
      },
    };

    _razorpay.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(response.paymentId ?? 'unknown');
  }

  void _handleError(PaymentFailureResponse response) {
    _onFailure?.call(response.message ?? 'Payment failed');
  }

  void _handleExternal(ExternalWalletResponse response) {
    // External wallet selected - treat as pending
    _onFailure?.call('External wallet (${response.walletName}) not supported yet');
  }

  /// Record payment in Firestore
  static Future<void> recordPayment({
    required String paymentId,
    required String type, // 'booking' or 'subscription'
    required String userUid,
    required double amount,
    required double commission,
    Map<String, dynamic>? metadata,
  }) async {
    await FirebaseFirestore.instance.collection('payments').add({
      'paymentId': paymentId,
      'type': type,
      'userUid': userUid,
      'amount': amount,
      'commission': commission,
      'status': 'captured',
      'createdAt': FieldValue.serverTimestamp(),
      ...?metadata,
    });
  }
}
