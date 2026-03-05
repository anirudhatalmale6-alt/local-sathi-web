import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String authorUid;
  final String authorName;
  final String authorLocalSathiId;
  final String? authorPhotoUrl;
  final bool authorVerified;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorLocalSathiId,
    this.authorPhotoUrl,
    this.authorVerified = false,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? '',
      authorLocalSathiId: data['authorLocalSathiId'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      authorVerified: data['authorVerified'] ?? false,
      text: data['text'] ?? '',
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
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
