import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/review_model.dart';
import '../models/feedback_model.dart';
import '../models/wallet_model.dart';
import '../config/constants.dart';

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
    // Award points for first post
    try {
      await awardPointsOnce(
        post.authorUid,
        SathiPoints.firstPost,
        'First post bonus',
        'first_post',
      );
    } catch (_) {}
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

  // ══════════════════ COMMENTS ══════════════════

  // Get comments for a post
  Stream<List<CommentModel>> getPostComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommentModel.fromFirestore(d)).toList());
  }

  // Add a comment to a post
  Future<void> addComment(String postId, CommentModel comment) async {
    final batch = _firestore.batch();
    final commentRef = _firestore.collection('posts').doc(postId).collection('comments').doc();
    batch.set(commentRef, comment.toFirestore());
    batch.update(_firestore.collection('posts').doc(postId), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  // Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('posts').doc(postId).collection('comments').doc(commentId));
    batch.update(_firestore.collection('posts').doc(postId), {
      'commentCount': FieldValue.increment(-1),
    });
    await batch.commit();
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

    // Award points for leaving a review
    try {
      await awardPoints(review.reviewerUid, SathiPoints.review, 'Left a review');
    } catch (_) {}
  }

  // ══════════════════ ADMIN ══════════════════

  // Get pending verifications (client-side filter to avoid composite index)
  Stream<List<UserModel>> getPendingVerifications() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserModel.fromFirestore(d))
            .where((u) =>
                u.verificationStatus == VerificationStatus.pending &&
                u.aadhaarDocUrl != null &&
                u.aadhaarDocUrl!.isNotEmpty)
            .toList());
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
    // Fallback to comprehensive defaults from constants
    return AppConstants.allCategories.toList();
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

  // ══════════════════ LIVE STATS ══════════════════

  // Live community stats stream (for home screen bar)
  Stream<Map<String, int>> getCommunityStatsStream() {
    return _firestore.collection('users').snapshots().map((snap) {
      final docs = snap.docs;
      int total = docs.length;
      int providers = 0;
      int verified = 0;
      for (final doc in docs) {
        final data = doc.data();
        if (data['role'] == 'provider') providers++;
        if (data['verificationStatus'] == 'verified') verified++;
      }
      return {
        'totalUsers': total,
        'totalProviders': providers,
        'verifiedProfiles': verified,
      };
    });
  }

  // Geographic breakdown (admin analytics)
  Future<Map<String, dynamic>> getGeographicStats() async {
    final snap = await _firestore.collection('users').get();
    final stateMap = <String, Map<String, dynamic>>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final state = (data['state'] as String?)?.trim() ?? '';
      final city = (data['city'] as String?)?.trim() ?? '';
      final role = data['role'] ?? 'customer';

      if (state.isEmpty && city.isEmpty) continue;

      final stateKey = state.isNotEmpty ? state : 'Unknown';
      stateMap.putIfAbsent(stateKey, () => {'total': 0, 'providers': 0, 'cities': <String, Map<String, int>>{}});
      stateMap[stateKey]!['total'] = (stateMap[stateKey]!['total'] as int) + 1;
      if (role == 'provider') {
        stateMap[stateKey]!['providers'] = (stateMap[stateKey]!['providers'] as int) + 1;
      }

      if (city.isNotEmpty) {
        final cities = stateMap[stateKey]!['cities'] as Map<String, Map<String, int>>;
        cities.putIfAbsent(city, () => {'total': 0, 'providers': 0});
        cities[city]!['total'] = (cities[city]!['total'] ?? 0) + 1;
        if (role == 'provider') {
          cities[city]!['providers'] = (cities[city]!['providers'] ?? 0) + 1;
        }
      }
    }

    return stateMap;
  }

  // ══════════════════ SATHI WALLET ══════════════════

  // Award points to a user
  Future<void> awardPoints(String uid, int points, String description, {WalletTransactionType type = WalletTransactionType.earned}) async {
    final walletRef = _firestore.collection('wallets').doc(uid);
    final txRef = walletRef.collection('transactions').doc();

    final batch = _firestore.batch();

    // Update balance (create or increment)
    batch.set(walletRef, {
      'balance': FieldValue.increment(points),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));

    // Add transaction record
    batch.set(txRef, WalletTransaction(
      id: txRef.id,
      description: description,
      points: points,
      type: type,
      createdAt: DateTime.now(),
    ).toFirestore());

    await batch.commit();
  }

  // Get wallet balance
  Future<int> getWalletBalance(String uid) async {
    final doc = await _firestore.collection('wallets').doc(uid).get();
    if (!doc.exists) return 0;
    return (doc.data()?['balance'] ?? 0) as int;
  }

  // Check if a reward has already been given (prevents duplicate awards)
  Future<bool> hasRewardBeenGiven(String uid, String rewardKey) async {
    final doc = await _firestore.collection('wallets').doc(uid).get();
    if (!doc.exists) return false;
    final rewards = List<String>.from(doc.data()?['rewardsGiven'] ?? []);
    return rewards.contains(rewardKey);
  }

  // Mark a reward as given
  Future<void> markRewardGiven(String uid, String rewardKey) async {
    await _firestore.collection('wallets').doc(uid).set({
      'rewardsGiven': FieldValue.arrayUnion([rewardKey]),
    }, SetOptions(merge: true));
  }

  // Award points with duplicate check
  Future<void> awardPointsOnce(String uid, int points, String description, String rewardKey) async {
    if (await hasRewardBeenGiven(uid, rewardKey)) return;
    await awardPoints(uid, points, description);
    await markRewardGiven(uid, rewardKey);
  }

  // Get app stats (client-side counting to avoid composite index requirements)
  Future<Map<String, int>> getAppStats() async {
    // Fetch all users once and count client-side
    final usersSnap = await _firestore.collection('users').get();
    final allUsers = usersSnap.docs.map((d) => d.data()).toList();

    final totalUsers = allUsers.length;
    final pendingVerifications = allUsers.where((u) =>
        u['verificationStatus'] == 'pending' && u['aadhaarDocUrl'] != null).length;
    final activeProviders = allUsers.where((u) =>
        u['role'] == 'provider' && u['verificationStatus'] == 'verified').length;
    final totalAdmins = allUsers.where((u) =>
        u['role'] == 'admin' || u['role'] == 'moderator').length;

    // Posts today
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final postsSnap = await _firestore
        .collection('posts')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    // Reviews total
    final reviewsSnap = await _firestore.collection('reviews').get();

    return {
      'totalUsers': totalUsers,
      'pendingVerifications': pendingVerifications,
      'activeProviders': activeProviders,
      'postsToday': postsSnap.docs.length,
      'totalAdmins': totalAdmins,
      'totalReviews': reviewsSnap.docs.length,
    };
  }

  // ══════════════════ ADMIN PANEL ══════════════════

  // Get all users with optional filtering
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // Update user role
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get team members (admins + moderators)
  Stream<List<UserModel>> getTeamMembers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserModel.fromFirestore(d))
            .where((u) => u.role == UserRole.admin || u.role == UserRole.moderator)
            .toList());
  }

  // Delete user account
  Future<void> deleteUser(String uid) async {
    // Delete user's posts
    final postsSnap = await _firestore
        .collection('posts')
        .where('authorUid', isEqualTo: uid)
        .get();
    for (final doc in postsSnap.docs) {
      await doc.reference.delete();
    }
    // Delete user's reviews
    final reviewsSnap = await _firestore
        .collection('reviews')
        .where('reviewerUid', isEqualTo: uid)
        .get();
    for (final doc in reviewsSnap.docs) {
      await doc.reference.delete();
    }
    // Delete wallet
    await _firestore.collection('wallets').doc(uid).delete();
    // Delete user document
    await _firestore.collection('users').doc(uid).delete();
  }

  // Get all reviews
  Stream<List<ReviewModel>> getAllReviews() {
    return _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ReviewModel.fromFirestore(d)).toList());
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    await _firestore.collection('reviews').doc(reviewId).delete();
  }

  // Toggle user sponsored status
  Future<void> toggleSponsored(String uid, bool sponsored) async {
    await _firestore.collection('users').doc(uid).update({
      'isSponsored': sponsored,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
