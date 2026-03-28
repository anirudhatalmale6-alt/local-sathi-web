import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlan { free, basic, premium, providerPremium }

class SubscriptionModel {
  final String uid;
  final SubscriptionPlan plan;
  final bool isActive;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String? paymentId;
  final double amountPaid;
  final String currency;

  SubscriptionModel({
    required this.uid,
    required this.plan,
    required this.isActive,
    required this.startedAt,
    required this.expiresAt,
    this.paymentId,
    this.amountPaid = 0,
    this.currency = 'INR',
  });

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isActiveNow => isActive && !isExpired;

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      uid: doc.id,
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == data['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      isActive: data['isActive'] ?? false,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentId: data['paymentId'],
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] ?? 'INR',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'plan': plan.name,
      'isActive': isActive,
      'startedAt': Timestamp.fromDate(startedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'paymentId': paymentId,
      'amountPaid': amountPaid,
      'currency': currency,
    };
  }

  /// Plan display info
  static Map<String, dynamic> planInfo(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return {
          'name': 'Free',
          'price': 0,
          'priceLabel': 'Free',
          'features': ['Basic access', 'Ads supported', 'Limited features'],
          'color': 0xFF9E9E9E,
        };
      case SubscriptionPlan.basic:
        return {
          'name': 'Basic',
          'price': 49,
          'priceLabel': '49/month',
          'features': ['No ads', 'Priority support', 'All features'],
          'color': 0xFF1565C0,
        };
      case SubscriptionPlan.premium:
        return {
          'name': 'Premium',
          'price': 99,
          'priceLabel': '99/month',
          'features': [
            'No ads',
            'Priority support',
            'All features',
            'Featured profile',
            'Verified badge priority',
          ],
          'color': 0xFFFF8F00,
        };
      case SubscriptionPlan.providerPremium:
        return {
          'name': 'Provider Pro',
          'price': 199,
          'priceLabel': '199/month',
          'features': [
            'No ads',
            'Featured listing',
            'Top search results',
            'Priority booking',
            'Analytics dashboard',
            'Verified badge priority',
          ],
          'color': 0xFF00897B,
        };
    }
  }
}
