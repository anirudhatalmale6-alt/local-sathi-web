import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userUid;
  final String userName;
  final String userLocalSathiId;
  final int rating; // 1-5 stars
  final String message;
  final String? category; // bug, feature, general
  final bool isRead;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userUid,
    required this.userName,
    required this.userLocalSathiId,
    required this.rating,
    required this.message,
    this.category,
    this.isRead = false,
    required this.createdAt,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      userUid: data['userUid'] ?? '',
      userName: data['userName'] ?? '',
      userLocalSathiId: data['userLocalSathiId'] ?? '',
      rating: data['rating'] ?? 0,
      message: data['message'] ?? '',
      category: data['category'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userUid': userUid,
      'userName': userName,
      'userLocalSathiId': userLocalSathiId,
      'rating': rating,
      'message': message,
      'category': category,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
