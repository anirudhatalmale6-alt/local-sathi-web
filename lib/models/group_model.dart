import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? imageUrl;
  final String createdBy;
  final String createdByName;
  final List<String> members;
  final int memberCount;
  final String lastMessage;
  final String lastSenderName;
  final DateTime lastMessageTime;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'General',
    this.imageUrl,
    required this.createdBy,
    this.createdByName = '',
    this.members = const [],
    this.memberCount = 0,
    this.lastMessage = '',
    this.lastSenderName = '',
    required this.lastMessageTime,
    required this.createdAt,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      lastMessage: data['lastMessage'] ?? '',
      lastSenderName: data['lastSenderName'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'members': members,
      'memberCount': memberCount,
      'lastMessage': lastMessage,
      'lastSenderName': lastSenderName,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool isMember(String uid) => members.contains(uid);
}

class GroupMessageModel {
  final String id;
  final String senderUid;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final DateTime createdAt;

  GroupMessageModel({
    required this.id,
    required this.senderUid,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory GroupMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMessageModel(
      id: doc.id,
      senderUid: data['senderUid'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderUid': senderUid,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
