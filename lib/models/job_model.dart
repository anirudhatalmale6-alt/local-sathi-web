import 'package:cloud_firestore/cloud_firestore.dart';

enum JobType { daily, partTime, fullTime, contract }
enum JobStatus { open, filled, completed, closed }

class JobModel {
  final String id;
  final String posterId;
  final String posterName;
  final String? posterPhotoUrl;
  final String title;
  final String description;
  final String category;
  final JobType jobType;
  final double? wage;
  final String? wageFrequency; // daily, weekly, monthly, fixed
  final String? location;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final JobStatus status;
  final int applicationCount;
  final DateTime createdAt;
  final DateTime? startDate;

  JobModel({
    required this.id,
    required this.posterId,
    required this.posterName,
    this.posterPhotoUrl,
    required this.title,
    required this.description,
    required this.category,
    this.jobType = JobType.daily,
    this.wage,
    this.wageFrequency,
    this.location,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.status = JobStatus.open,
    this.applicationCount = 0,
    required this.createdAt,
    this.startDate,
  });

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      posterId: data['posterId'] ?? '',
      posterName: data['posterName'] ?? '',
      posterPhotoUrl: data['posterPhotoUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      jobType: JobType.values.firstWhere(
        (e) => e.name == (data['jobType'] ?? 'daily'),
        orElse: () => JobType.daily,
      ),
      wage: (data['wage'] as num?)?.toDouble(),
      wageFrequency: data['wageFrequency'],
      location: data['location'],
      city: data['city'],
      state: data['state'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: JobStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'open'),
        orElse: () => JobStatus.open,
      ),
      applicationCount: data['applicationCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'posterId': posterId,
      'posterName': posterName,
      'posterPhotoUrl': posterPhotoUrl,
      'title': title,
      'description': description,
      'category': category,
      'jobType': jobType.name,
      'wage': wage,
      'wageFrequency': wageFrequency,
      'location': location,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'applicationCount': applicationCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    };
  }

  String get jobTypeLabel {
    switch (jobType) {
      case JobType.daily: return 'Daily';
      case JobType.partTime: return 'Part-time';
      case JobType.fullTime: return 'Full-time';
      case JobType.contract: return 'Contract';
    }
  }
}

class JobApplicationModel {
  final String id;
  final String applicantId;
  final String applicantName;
  final String? applicantPhotoUrl;
  final String message;
  final String status; // pending, approved, rejected
  final DateTime createdAt;

  JobApplicationModel({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    this.applicantPhotoUrl,
    required this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  factory JobApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobApplicationModel(
      id: doc.id,
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      applicantPhotoUrl: data['applicantPhotoUrl'],
      message: data['message'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantPhotoUrl': applicantPhotoUrl,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
