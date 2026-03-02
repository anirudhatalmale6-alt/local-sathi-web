import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String providerUid;
  final String reviewerUid;
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final double rating;
  final String text;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.providerUid,
    required this.reviewerUid,
    required this.reviewerName,
    this.reviewerPhotoUrl,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      providerUid: data['providerUid'] ?? '',
      reviewerUid: data['reviewerUid'] ?? '',
      reviewerName: data['reviewerName'] ?? '',
      reviewerPhotoUrl: data['reviewerPhotoUrl'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerUid': providerUid,
      'reviewerUid': reviewerUid,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'rating': rating,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
