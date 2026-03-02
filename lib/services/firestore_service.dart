import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ══════════════════ PROVIDERS ══════════════════

  // Get featured providers (sponsored first, then top rated)
  Stream<List<UserModel>> getFeaturedProviders({int limit = 10}) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'provider')
        .where('verificationStatus', isEqualTo: 'verified')
        .orderBy('isSponsored', descending: true)
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // Search providers by category
  Stream<List<UserModel>> searchProviders({
    String? category,
    double? lat,
    double? lng,
    double radiusKm = 5,
  }) {
    Query query = _firestore
        .collection('users')
        .where('role', isEqualTo: 'provider')
        .where('verificationStatus', isEqualTo: 'verified');

    if (category != null && category != 'All') {
      query = query.where('serviceCategories', arrayContains: category);
    }

    query = query.orderBy('isSponsored', descending: true)
        .orderBy('rating', descending: true);

    return query.snapshots().map(
        (snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // Get provider by uid
  Future<UserModel?> getProvider(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  // ══════════════════ POSTS ══════════════════

  // Get live feed posts
  Stream<List<PostModel>> getLiveFeed({int limit = 50}) {
    return _firestore
        .collection('posts')
        .where('isReported', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostModel.fromFirestore(d)).toList());
  }

  // Get user's posts
  Stream<List<PostModel>> getUserPosts(String uid) {
    return _firestore
        .collection('posts')
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostModel.fromFirestore(d)).toList());
  }

  // Create a post
  Future<void> createPost(PostModel post) async {
    await _firestore.collection('posts').add(post.toFirestore());
  }

  // Like/unlike a post
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final doc = await postRef.get();
    if (!doc.exists) return;

    final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }

    await postRef.update({
      'likedBy': likedBy,
      'likeCount': likedBy.length,
    });
  }

  // Report a post
  Future<void> reportPost(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'reportCount': FieldValue.increment(1),
      'isReported': true,
    });
  }

  // ══════════════════ REVIEWS ══════════════════

  // Get reviews for a provider
  Stream<List<ReviewModel>> getProviderReviews(String providerUid) {
    return _firestore
        .collection('reviews')
        .where('providerUid', isEqualTo: providerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ReviewModel.fromFirestore(d)).toList());
  }

  // Add a review
  Future<void> addReview(ReviewModel review) async {
    await _firestore.collection('reviews').add(review.toFirestore());

    // Update provider rating
    final reviews = await _firestore
        .collection('reviews')
        .where('providerUid', isEqualTo: review.providerUid)
        .get();

    double totalRating = 0;
    for (var doc in reviews.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }
    final avgRating = totalRating / reviews.docs.length;

    await _firestore.collection('users').doc(review.providerUid).update({
      'rating': double.parse(avgRating.toStringAsFixed(1)),
      'reviewCount': reviews.docs.length,
    });
  }

  // ══════════════════ ADMIN ══════════════════

  // Get pending verifications
  Stream<List<UserModel>> getPendingVerifications() {
    return _firestore
        .collection('users')
        .where('verificationStatus', isEqualTo: 'pending')
        .where('aadhaarDocUrl', isNull: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // Approve/reject verification
  Future<void> updateVerificationStatus(String uid, VerificationStatus status) async {
    await _firestore.collection('users').doc(uid).update({
      'verificationStatus': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get reported posts for moderation
  Stream<List<PostModel>> getReportedPosts() {
    return _firestore
        .collection('posts')
        .where('isReported', isEqualTo: true)
        .orderBy('reportCount', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostModel.fromFirestore(d)).toList());
  }

  // Delete a post (admin moderation)
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  // Dismiss report
  Future<void> dismissReport(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'isReported': false,
      'reportCount': 0,
    });
  }

  // Get categories
  Stream<List<String>> getCategories() {
    return _firestore
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()['name'] as String).toList());
  }

  // Add category
  Future<void> addCategory(String name, String icon) async {
    await _firestore.collection('categories').add({
      'name': name,
      'icon': icon,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }

  // Get app stats
  Future<Map<String, int>> getAppStats() async {
    final users = await _firestore.collection('users').count().get();
    final pending = await _firestore
        .collection('users')
        .where('verificationStatus', isEqualTo: 'pending')
        .where('aadhaarDocUrl', isNull: false)
        .count()
        .get();
    final providers = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'provider')
        .where('verificationStatus', isEqualTo: 'verified')
        .count()
        .get();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final posts = await _firestore
        .collection('posts')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .count()
        .get();

    return {
      'totalUsers': users.count ?? 0,
      'pendingVerifications': pending.count ?? 0,
      'activeProviders': providers.count ?? 0,
      'postsToday': posts.count ?? 0,
    };
  }
}
