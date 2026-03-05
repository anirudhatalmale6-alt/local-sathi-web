import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/review_model.dart';
import '../models/feedback_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ══════════════════ PROVIDERS ══════════════════

  // Get featured providers (filter & sort client-side to avoid composite indexes)
  Stream<List<UserModel>> getFeaturedProviders({int limit = 10}) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'provider')
        .snapshots()
        .map((snap) {
      final providers = snap.docs
          .map((d) => UserModel.fromFirestore(d))
          .where((u) => u.verificationStatus == VerificationStatus.verified)
          .toList();
      // Sort: sponsored first, then by rating
      providers.sort((a, b) {
        if (a.isSponsored && !b.isSponsored) return -1;
        if (!a.isSponsored && b.isSponsored) return 1;
        return b.rating.compareTo(a.rating);
      });
      return providers.take(limit).toList();
    });
  }

  // Search providers by category (filter client-side to avoid composite indexes)
  Stream<List<UserModel>> searchProviders({
    String? category,
    double? lat,
    double? lng,
    double radiusKm = 5,
  }) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'provider')
        .snapshots()
        .map((snap) {
      var providers = snap.docs
          .map((d) => UserModel.fromFirestore(d))
          .where((u) => u.verificationStatus == VerificationStatus.verified)
          .toList();

      if (category != null && category != 'All') {
        providers = providers
            .where((u) => u.serviceCategories.contains(category))
            .toList();
      }

      // Sort: sponsored first, then by rating
      providers.sort((a, b) {
        if (a.isSponsored && !b.isSponsored) return -1;
        if (!a.isSponsored && b.isSponsored) return 1;
        return b.rating.compareTo(a.rating);
      });
      return providers;
    });
  }

  // Get provider by uid
  Future<UserModel?> getProvider(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  // ══════════════════ POSTS ══════════════════

  // Get live feed posts (filter reported client-side to avoid composite index)
  Stream<List<PostModel>> getLiveFeed({int limit = 50}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PostModel.fromFirestore(d))
            .where((p) => !p.isReported)
            .toList());
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

  // Update a post's text
  Future<void> updatePost(String postId, String newText) async {
    await _firestore.collection('posts').doc(postId).update({
      'text': newText,
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

  // Get reported posts for moderation (sort client-side to avoid composite index)
  Stream<List<PostModel>> getReportedPosts() {
    return _firestore
        .collection('posts')
        .where('isReported', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final posts = snap.docs.map((d) => PostModel.fromFirestore(d)).toList();
      posts.sort((a, b) => b.reportCount.compareTo(a.reportCount));
      return posts;
    });
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

  // Get categories as a one-shot future with fallback to defaults
  Future<List<String>> getCategoryList() async {
    try {
      final snap = await _firestore.collection('categories').orderBy('name').get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => d.data()['name'] as String).toList();
      }
    } catch (_) {}
    // Fallback to hardcoded defaults
    return ['Electrician', 'Plumber', 'Tutor', 'Carpenter', 'Painter', 'AC Repair', 'Cleaner', 'Driver'];
  }

  // Add category
  Future<void> addCategory(String name, String icon) async {
    await _firestore.collection('categories').add({
      'name': name,
      'icon': icon,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete category by id
  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }

  // Delete category by name
  Future<void> deleteCategoryByName(String name) async {
    final docs = await _firestore
        .collection('categories')
        .where('name', isEqualTo: name)
        .get();
    for (var doc in docs.docs) {
      await doc.reference.delete();
    }
  }

  // ══════════════════ FEEDBACK ══════════════════

  // Get all feedback (admin)
  Stream<List<FeedbackModel>> getAllFeedback({int limit = 50}) {
    return _firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FeedbackModel.fromFirestore(d)).toList());
  }

  // Mark feedback as read
  Future<void> markFeedbackRead(String feedbackId) async {
    await _firestore.collection('feedback').doc(feedbackId).update({
      'isRead': true,
    });
  }

  // Delete feedback
  Future<void> deleteFeedback(String feedbackId) async {
    await _firestore.collection('feedback').doc(feedbackId).delete();
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
