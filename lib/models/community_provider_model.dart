import 'package:cloud_firestore/cloud_firestore.dart';

enum ProviderStatus { pending, approved, rejected }
enum VerificationType { none, admin, community }

class CommunityProvider {
  final String id;
  final String name;
  final String phone;
  final String category;
  final String area;
  final String? description;
  final String createdByUserId;
  final String createdByUserName;
  final bool isOfflineProvider;
  final ProviderStatus status;
  final VerificationType verificationType;
  final bool isVerified;
  final double rating;
  final int totalReviews;
  final int helpedCount; // how many people found this provider useful
  final String? duplicateHash; // phone-based hash for dedup
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;

  CommunityProvider({
    required this.id,
    required this.name,
    required this.phone,
    required this.category,
    required this.area,
    this.description,
    required this.createdByUserId,
    required this.createdByUserName,
    this.isOfflineProvider = true,
    this.status = ProviderStatus.pending,
    this.verificationType = VerificationType.none,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.helpedCount = 0,
    this.duplicateHash,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
  });

  factory CommunityProvider.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityProvider(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      category: data['category'] ?? '',
      area: data['area'] ?? '',
      description: data['description'],
      createdByUserId: data['createdByUserId'] ?? '',
      createdByUserName: data['createdByUserName'] ?? '',
      isOfflineProvider: data['isOfflineProvider'] ?? true,
      status: ProviderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProviderStatus.pending,
      ),
      verificationType: VerificationType.values.firstWhere(
        (e) => e.name == data['verificationType'],
        orElse: () => VerificationType.none,
      ),
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] ?? 0,
      helpedCount: data['helpedCount'] ?? 0,
      duplicateHash: data['duplicateHash'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      approvedBy: data['approvedBy'],
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'category': category,
        'area': area,
        if (description != null) 'description': description,
        'createdByUserId': createdByUserId,
        'createdByUserName': createdByUserName,
        'isOfflineProvider': isOfflineProvider,
        'status': status.name,
        'verificationType': verificationType.name,
        'isVerified': isVerified,
        'rating': rating,
        'totalReviews': totalReviews,
        'helpedCount': helpedCount,
        'duplicateHash': duplicateHash,
        'createdAt': Timestamp.fromDate(createdAt),
        if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
        if (approvedBy != null) 'approvedBy': approvedBy,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };
}
