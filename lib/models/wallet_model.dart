import 'package:cloud_firestore/cloud_firestore.dart';

enum WalletTransactionType {
  earned,
  redeemed,
  bonus,
}

class WalletTransaction {
  final String id;
  final String description;
  final int points;
  final WalletTransactionType type;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.description,
    required this.points,
    required this.type,
    required this.createdAt,
  });

  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      id: doc.id,
      description: data['description'] ?? '',
      points: data['points'] ?? 0,
      type: WalletTransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => WalletTransactionType.earned,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'description': description,
        'points': points,
        'type': type.name,
        'createdAt': Timestamp.fromDate(createdAt),
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
