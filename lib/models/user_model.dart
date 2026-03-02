import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, provider, admin }

enum VerificationStatus { pending, verified, rejected }

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final String? profilePhotoUrl;
  final String localSathiId; // LS-100001
  final UserRole role;
  final VerificationStatus verificationStatus;
  final String? aadhaarDocUrl;
  final String? aadhaarNumber; // masked: XXXX-XXXX-1234
  final List<String> serviceCategories;
  final String? serviceDescription;
  final double? hourlyRate;
  final String? serviceArea;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final double rating;
  final int reviewCount;
  final bool isSponsored;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    this.profilePhotoUrl,
    required this.localSathiId,
    this.role = UserRole.customer,
    this.verificationStatus = VerificationStatus.pending,
    this.aadhaarDocUrl,
    this.aadhaarNumber,
    this.serviceCategories = const [],
    this.serviceDescription,
    this.hourlyRate,
    this.serviceArea,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isSponsored = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isProvider => role == UserRole.provider;
  bool get isAdmin => role == UserRole.admin;
  bool get isVerified => verificationStatus == VerificationStatus.verified;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      profilePhotoUrl: data['profilePhotoUrl'],
      localSathiId: data['localSathiId'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.customer,
      ),
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == data['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      aadhaarDocUrl: data['aadhaarDocUrl'],
      aadhaarNumber: data['aadhaarNumber'],
      serviceCategories: List<String>.from(data['serviceCategories'] ?? []),
      serviceDescription: data['serviceDescription'],
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble(),
      serviceArea: data['serviceArea'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      city: data['city'],
      state: data['state'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      isSponsored: data['isSponsored'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'profilePhotoUrl': profilePhotoUrl,
      'localSathiId': localSathiId,
      'role': role.name,
      'verificationStatus': verificationStatus.name,
      'aadhaarDocUrl': aadhaarDocUrl,
      'aadhaarNumber': aadhaarNumber,
      'serviceCategories': serviceCategories,
      'serviceDescription': serviceDescription,
      'hourlyRate': hourlyRate,
      'serviceArea': serviceArea,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'rating': rating,
      'reviewCount': reviewCount,
      'isSponsored': isSponsored,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? profilePhotoUrl,
    UserRole? role,
    VerificationStatus? verificationStatus,
    String? aadhaarDocUrl,
    String? aadhaarNumber,
    List<String>? serviceCategories,
    String? serviceDescription,
    double? hourlyRate,
    String? serviceArea,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    double? rating,
    int? reviewCount,
    bool? isSponsored,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      localSathiId: localSathiId,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      aadhaarDocUrl: aadhaarDocUrl ?? this.aadhaarDocUrl,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      serviceArea: serviceArea ?? this.serviceArea,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isSponsored: isSponsored ?? this.isSponsored,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
