import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorUid;
  final String authorName;
  final String authorLocalSathiId;
  final String? authorPhotoUrl;
  final bool authorVerified;
  final String text;
  final int likeCount;
  final int commentCount;
  final List<String> likedBy;
  final bool isReported;
  final int reportCount;
  final String? location;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorLocalSathiId,
    this.authorPhotoUrl,
    this.authorVerified = false,
    required this.text,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedBy = const [],
    this.isReported = false,
    this.reportCount = 0,
    this.location,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? '',
      authorLocalSathiId: data['authorLocalSathiId'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      authorVerified: data['authorVerified'] ?? false,
      text: data['text'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isReported: data['isReported'] ?? false,
      reportCount: data['reportCount'] ?? 0,
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorLocalSathiId': authorLocalSathiId,
      'authorPhotoUrl': authorPhotoUrl,
      'authorVerified': authorVerified,
      'text': text,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'likedBy': likedBy,
      'isReported': isReported,
      'reportCount': reportCount,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
