import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderUid;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderUid: data['senderUid'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderUid': senderUid,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
