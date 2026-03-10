import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderUid;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final List<String> deletedBy;

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    this.lastSenderUid = '',
    required this.lastMessageTime,
    this.unreadCounts = const {},
    this.participantNames = const {},
    this.participantPhotos = const {},
    this.deletedBy = const [],
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastSenderUid: data['lastSenderUid'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(
        (data['unreadCounts'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ?? {},
      ),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantPhotos: Map<String, String?>.from(data['participantPhotos'] ?? {}),
      deletedBy: List<String>.from(data['deletedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastSenderUid': lastSenderUid,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCounts': unreadCounts,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
    };
  }

  /// Get the other participant's UID
  String otherUid(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => participants.first);

  /// Get conversation display name for the other user
  String displayName(String myUid) {
    final other = otherUid(myUid);
    return participantNames[other] ?? 'User';
  }

  /// Get other user's photo URL
  String? displayPhoto(String myUid) {
    final other = otherUid(myUid);
    return participantPhotos[other];
  }

  /// Get unread count for a user
  int unreadFor(String uid) => unreadCounts[uid] ?? 0;
}
