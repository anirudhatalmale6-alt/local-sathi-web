import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, accepted, inProgress, completed, cancelled }

class BookingModel {
  final String id;
  final String customerUid;
  final String customerName;
  final String providerUid;
  final String providerName;
  final String serviceCategory;
  final String description;
  final double? agreedPrice;
  final double commissionRate; // % taken by platform
  final double commissionAmount;
  final BookingStatus status;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? customerPhone;
  final String? providerPhone;
  final String? location;

  BookingModel({
    required this.id,
    required this.customerUid,
    required this.customerName,
    required this.providerUid,
    required this.providerName,
    required this.serviceCategory,
    required this.description,
    this.agreedPrice,
    this.commissionRate = 10.0,
    this.commissionAmount = 0,
    this.status = BookingStatus.pending,
    required this.scheduledAt,
    required this.createdAt,
    this.completedAt,
    this.customerPhone,
    this.providerPhone,
    this.location,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      customerUid: data['customerUid'] ?? '',
      customerName: data['customerName'] ?? '',
      providerUid: data['providerUid'] ?? '',
      providerName: data['providerName'] ?? '',
      serviceCategory: data['serviceCategory'] ?? '',
      description: data['description'] ?? '',
      agreedPrice: (data['agreedPrice'] as num?)?.toDouble(),
      commissionRate: (data['commissionRate'] as num?)?.toDouble() ?? 10.0,
      commissionAmount: (data['commissionAmount'] as num?)?.toDouble() ?? 0,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      customerPhone: data['customerPhone'],
      providerPhone: data['providerPhone'],
      location: data['location'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerUid': customerUid,
      'customerName': customerName,
      'providerUid': providerUid,
      'providerName': providerName,
      'serviceCategory': serviceCategory,
      'description': description,
      'agreedPrice': agreedPrice,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'status': status.name,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'customerPhone': customerPhone,
      'providerPhone': providerPhone,
      'location': location,
    };
  }

  String get statusLabel {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}
