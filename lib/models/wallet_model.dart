import 'package:cloud_firestore/cloud_firestore.dart';

enum WalletTransactionType {
  earned,
  redeemed,
  bonus,
  deposit,
  withdraw,
  transferIn,
  transferOut,
}

class WalletTransaction {
  final String id;
  final String description;
  final int points;
  final double? amount; // INR amount for money transactions
  final WalletTransactionType type;
  final DateTime createdAt;
  final String? relatedUserId; // for transfers
  final String? relatedUserName; // for transfers
  final String? paymentId; // Razorpay payment ID for deposits
  final String? status; // pending, completed, rejected (for withdrawals)

  WalletTransaction({
    required this.id,
    required this.description,
    required this.points,
    this.amount,
    required this.type,
    required this.createdAt,
    this.relatedUserId,
    this.relatedUserName,
    this.paymentId,
    this.status,
  });

  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      id: doc.id,
      description: data['description'] ?? '',
      points: data['points'] ?? 0,
      amount: (data['amount'] as num?)?.toDouble(),
      type: WalletTransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => WalletTransactionType.earned,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedUserId: data['relatedUserId'],
      relatedUserName: data['relatedUserName'],
      paymentId: data['paymentId'],
      status: data['status'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'description': description,
        'points': points,
        if (amount != null) 'amount': amount,
        'type': type.name,
        'createdAt': Timestamp.fromDate(createdAt),
        if (relatedUserId != null) 'relatedUserId': relatedUserId,
        if (relatedUserName != null) 'relatedUserName': relatedUserName,
        if (paymentId != null) 'paymentId': paymentId,
        if (status != null) 'status': status,
      };
}

// Points configuration
class SathiPoints {
  static const int registration = 50;
  static const int firstPost = 20;
  static const int review = 15;
  static const int referral = 100;
  static const int dailyLogin = 5;
  static const int profileComplete = 30;
  static const int verificationApproved = 50;
}
