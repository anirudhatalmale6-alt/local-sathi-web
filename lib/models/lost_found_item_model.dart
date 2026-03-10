import 'package:cloud_firestore/cloud_firestore.dart';

enum LostFoundType { lost, found }
enum LostFoundStatus { active, claimed, closed }

class LostFoundItemModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final LostFoundType itemType;
  final String title;
  final String description;
  final String category;
  final String? color;
  final String? location;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final List<String> photos;
  final LostFoundStatus status;
  final int views;
  final int contactCount;
  final DateTime createdAt;
  final DateTime? dateOccurred;

  LostFoundItemModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.itemType,
    required this.title,
    required this.description,
    required this.category,
    this.color,
    this.location,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.photos = const [],
    this.status = LostFoundStatus.active,
    this.views = 0,
    this.contactCount = 0,
    required this.createdAt,
    this.dateOccurred,
  });

  factory LostFoundItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LostFoundItemModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      itemType: LostFoundType.values.firstWhere(
        (e) => e.name == (data['itemType'] ?? 'lost'),
        orElse: () => LostFoundType.lost,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      color: data['color'],
      location: data['location'],
      city: data['city'],
      state: data['state'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      photos: List<String>.from(data['photos'] ?? []),
      status: LostFoundStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'active'),
        orElse: () => LostFoundStatus.active,
      ),
      views: data['views'] ?? 0,
      contactCount: data['contactCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateOccurred: (data['dateOccurred'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'itemType': itemType.name,
      'title': title,
      'description': description,
      'category': category,
      'color': color,
      'location': location,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'photos': photos,
      'status': status.name,
      'views': views,
      'contactCount': contactCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'dateOccurred': dateOccurred != null ? Timestamp.fromDate(dateOccurred!) : null,
    };
  }

  String get typeLabel => itemType == LostFoundType.lost ? 'Lost' : 'Found';

  static const List<String> categories = [
    'Documents / ID',
    'Mobile / Tablet',
    'Electronics',
    'Keys',
    'Wallet / Purse',
    'Jewelry',
    'Bags',
    'Clothing',
    'Pet',
    'Vehicle',
    'Money',
    'Other',
  ];
}
