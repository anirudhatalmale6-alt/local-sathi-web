import 'package:cloud_firestore/cloud_firestore.dart';

enum HelpStatus { open, inProgress, completed, cancelled }

class HelpRequestModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterPhotoUrl;
  final String title;
  final String description;
  final String category;
  final double? budget;
  final String? location;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final HelpStatus status;
  final int bidCount;
  final String? acceptedBidId;
  final String? acceptedProviderId;
  final DateTime createdAt;
  final DateTime? completedAt;

  HelpRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhotoUrl,
    required this.title,
    required this.description,
    required this.category,
    this.budget,
    this.location,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.status = HelpStatus.open,
    this.bidCount = 0,
    this.acceptedBidId,
    this.acceptedProviderId,
    required this.createdAt,
    this.completedAt,
  });

  factory HelpRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HelpRequestModel(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      requesterPhotoUrl: data['requesterPhotoUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      budget: (data['budget'] as num?)?.toDouble(),
      location: data['location'],
      city: data['city'],
      state: data['state'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: HelpStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'open'),
        orElse: () => HelpStatus.open,
      ),
      bidCount: data['bidCount'] ?? 0,
      acceptedBidId: data['acceptedBidId'],
      acceptedProviderId: data['acceptedProviderId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhotoUrl': requesterPhotoUrl,
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'location': location,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'bidCount': bidCount,
      'acceptedBidId': acceptedBidId,
      'acceptedProviderId': acceptedProviderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}

class BidModel {
  final String id;
  final String bidderId;
  final String bidderName;
  final String? bidderPhotoUrl;
  final double? bidderRating;
  final double amount;
  final String message;
  final String? estimatedTime;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  BidModel({
    required this.id,
    required this.bidderId,
    required this.bidderName,
    this.bidderPhotoUrl,
    this.bidderRating,
    required this.amount,
    required this.message,
    this.estimatedTime,
    this.status = 'pending',
    required this.createdAt,
  });

  factory BidModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BidModel(
      id: doc.id,
      bidderId: data['bidderId'] ?? '',
      bidderName: data['bidderName'] ?? '',
      bidderPhotoUrl: data['bidderPhotoUrl'],
      bidderRating: (data['bidderRating'] as num?)?.toDouble(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      message: data['message'] ?? '',
      estimatedTime: data['estimatedTime'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bidderId': bidderId,
      'bidderName': bidderName,
      'bidderPhotoUrl': bidderPhotoUrl,
      'bidderRating': bidderRating,
      'amount': amount,
      'message': message,
      'estimatedTime': estimatedTime,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
