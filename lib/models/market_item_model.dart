import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemCondition { newItem, likeNew, good, fair }
enum ItemStatus { available, sold, removed }

class MarketItemModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerPhotoUrl;
  final String title;
  final String description;
  final String category;
  final double price;
  final bool negotiable;
  final ItemCondition condition;
  final List<String> photos;
  final String? location;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final ItemStatus status;
  final int views;
  final int inquiryCount;
  final DateTime createdAt;

  MarketItemModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhotoUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.negotiable = true,
    this.condition = ItemCondition.good,
    this.photos = const [],
    this.location,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.status = ItemStatus.available,
    this.views = 0,
    this.inquiryCount = 0,
    required this.createdAt,
  });

  factory MarketItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MarketItemModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerPhotoUrl: data['sellerPhotoUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      negotiable: data['negotiable'] ?? true,
      condition: ItemCondition.values.firstWhere(
        (e) => e.name == (data['condition'] ?? 'good'),
        orElse: () => ItemCondition.good,
      ),
      photos: List<String>.from(data['photos'] ?? []),
      location: data['location'],
      city: data['city'],
      state: data['state'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: ItemStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'available'),
        orElse: () => ItemStatus.available,
      ),
      views: data['views'] ?? 0,
      inquiryCount: data['inquiryCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhotoUrl': sellerPhotoUrl,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'negotiable': negotiable,
      'condition': condition.name,
      'photos': photos,
      'location': location,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'views': views,
      'inquiryCount': inquiryCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get conditionLabel {
    switch (condition) {
      case ItemCondition.newItem: return 'Brand New';
      case ItemCondition.likeNew: return 'Like New';
      case ItemCondition.good: return 'Good';
      case ItemCondition.fair: return 'Fair';
    }
  }

  static const List<String> categories = [
    'Furniture',
    'Electronics',
    'Phones & Tablets',
    'Bikes & Scooters',
    'Cars',
    'Appliances',
    'Clothing',
    'Books',
    'Sports & Fitness',
    'Property / Rooms',
    'Tools & Equipment',
    'Other',
  ];
}
