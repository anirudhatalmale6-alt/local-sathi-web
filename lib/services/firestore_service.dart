import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/review_model.dart';
import '../models/feedback_model.dart';
import '../models/wallet_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/group_model.dart';
import '../models/community_provider_model.dart';
import '../models/help_request_model.dart';
import '../models/job_model.dart';
import '../models/market_item_model.dart';
import '../models/lost_found_item_model.dart';
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

  // ===== WALLET MONEY OPERATIONS =====

  // Deposit money to wallet (after Razorpay payment success)
  Future<void> walletDeposit(String uid, double amount, String paymentId) async {
    final walletRef = _firestore.collection('wallets').doc(uid);
    final txRef = walletRef.collection('transactions').doc();
    final amountPaise = (amount * 100).round(); // store as paise for precision

    final batch = _firestore.batch();
    batch.set(walletRef, {
      'moneyBalance': FieldValue.increment(amountPaise),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));

    batch.set(txRef, {
      'description': 'Added money to wallet',
      'points': 0,
      'amount': amount,
      'type': WalletTransactionType.deposit.name,
      'paymentId': paymentId,
      'status': 'completed',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  // Get wallet money balance (returns in rupees)
  Future<double> getWalletMoneyBalance(String uid) async {
    final doc = await _firestore.collection('wallets').doc(uid).get();
    if (!doc.exists) return 0;
    final paise = (doc.data()?['moneyBalance'] ?? 0) as int;
    return paise / 100.0;
  }

  // Transfer money to another user
  Future<bool> walletTransfer(String fromUid, String fromName, String toUid, String toName, double amount) async {
    final amountPaise = (amount * 100).round();

    // Check sender balance
    final senderDoc = await _firestore.collection('wallets').doc(fromUid).get();
    final senderBalance = (senderDoc.data()?['moneyBalance'] ?? 0) as int;
    if (senderBalance < amountPaise) return false;

    final senderRef = _firestore.collection('wallets').doc(fromUid);
    final receiverRef = _firestore.collection('wallets').doc(toUid);
    final senderTxRef = senderRef.collection('transactions').doc();
    final receiverTxRef = receiverRef.collection('transactions').doc();
    final now = DateTime.now();

    final batch = _firestore.batch();

    // Deduct from sender
    batch.set(senderRef, {
      'moneyBalance': FieldValue.increment(-amountPaise),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(senderTxRef, {
      'description': 'Sent to $toName',
      'points': 0,
      'amount': amount,
      'type': WalletTransactionType.transferOut.name,
      'relatedUserId': toUid,
      'relatedUserName': toName,
      'status': 'completed',
      'createdAt': Timestamp.fromDate(now),
    });

    // Add to receiver
    batch.set(receiverRef, {
      'moneyBalance': FieldValue.increment(amountPaise),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(receiverTxRef, {
      'description': 'Received from $fromName',
      'points': 0,
      'amount': amount,
      'type': WalletTransactionType.transferIn.name,
      'relatedUserId': fromUid,
      'relatedUserName': fromName,
      'status': 'completed',
      'createdAt': Timestamp.fromDate(now),
    });

    await batch.commit();
    return true;
  }

  // Request withdrawal
  Future<void> walletWithdrawRequest(String uid, String userName, double amount, String upiId) async {
    final amountPaise = (amount * 100).round();

    // Check balance
    final walletDoc = await _firestore.collection('wallets').doc(uid).get();
    final balance = (walletDoc.data()?['moneyBalance'] ?? 0) as int;
    if (balance < amountPaise) throw Exception('Insufficient balance');

    final walletRef = _firestore.collection('wallets').doc(uid);
    final txRef = walletRef.collection('transactions').doc();
    final now = DateTime.now();

    final batch = _firestore.batch();

    // Deduct balance immediately (hold)
    batch.set(walletRef, {
      'moneyBalance': FieldValue.increment(-amountPaise),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    // Add pending transaction
    batch.set(txRef, {
      'description': 'Withdrawal to UPI: $upiId',
      'points': 0,
      'amount': amount,
      'type': WalletTransactionType.withdraw.name,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
    });

    // Add to admin withdrawal requests
    batch.set(_firestore.collection('withdrawRequests').doc(txRef.id), {
      'uid': uid,
      'userName': userName,
      'amount': amount,
      'upiId': upiId,
      'transactionId': txRef.id,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  // Find user by phone number (for transfers)
  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    final snap = await _firestore.collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return {'uid': doc.id, ...doc.data()};
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

  // ══════════════════ FOLLOW SYSTEM ══════════════════

  /// Follow a user
  Future<void> followUser(String currentUid, String targetUid) async {
    final batch = _firestore.batch();

    // Add to current user's following
    batch.set(
      _firestore.collection('follows').doc(currentUid).collection('following').doc(targetUid),
      {'followedAt': Timestamp.fromDate(DateTime.now())},
    );

    // Add to target user's followers
    batch.set(
      _firestore.collection('follows').doc(targetUid).collection('followers').doc(currentUid),
      {'followedAt': Timestamp.fromDate(DateTime.now())},
    );

    // Increment counts
    batch.update(_firestore.collection('users').doc(currentUid), {
      'followingCount': FieldValue.increment(1),
    });
    batch.update(_firestore.collection('users').doc(targetUid), {
      'followersCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Unfollow a user
  Future<void> unfollowUser(String currentUid, String targetUid) async {
    final batch = _firestore.batch();

    batch.delete(
      _firestore.collection('follows').doc(currentUid).collection('following').doc(targetUid),
    );
    batch.delete(
      _firestore.collection('follows').doc(targetUid).collection('followers').doc(currentUid),
    );

    batch.update(_firestore.collection('users').doc(currentUid), {
      'followingCount': FieldValue.increment(-1),
    });
    batch.update(_firestore.collection('users').doc(targetUid), {
      'followersCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// Check if current user follows target
  Future<bool> isFollowing(String currentUid, String targetUid) async {
    final doc = await _firestore
        .collection('follows')
        .doc(currentUid)
        .collection('following')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  /// Get followers list (user models)
  Stream<List<UserModel>> getFollowers(String uid) {
    return _firestore
        .collection('follows')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .asyncMap((snap) async {
      final users = <UserModel>[];
      for (final doc in snap.docs) {
        final userDoc = await _firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) users.add(UserModel.fromFirestore(userDoc));
      }
      return users;
    });
  }

  /// Get following list (user models)
  Stream<List<UserModel>> getFollowing(String uid) {
    return _firestore
        .collection('follows')
        .doc(uid)
        .collection('following')
        .snapshots()
        .asyncMap((snap) async {
      final users = <UserModel>[];
      for (final doc in snap.docs) {
        final userDoc = await _firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) users.add(UserModel.fromFirestore(userDoc));
      }
      return users;
    });
  }

  /// Get suggested users (same city/state, not already following)
  Future<List<UserModel>> getSuggestedUsers(String currentUid, {String? city, String? state, int limit = 20}) async {
    final snap = await _firestore.collection('users').get();
    final followingSnap = await _firestore
        .collection('follows')
        .doc(currentUid)
        .collection('following')
        .get();
    final followingIds = followingSnap.docs.map((d) => d.id).toSet();

    final users = snap.docs
        .map((d) => UserModel.fromFirestore(d))
        .where((u) => u.uid != currentUid && !followingIds.contains(u.uid))
        .toList();

    // Sort: same city first, then same state, then others
    users.sort((a, b) {
      int aScore = 0, bScore = 0;
      if (city != null && a.city?.toLowerCase() == city.toLowerCase()) aScore += 2;
      if (state != null && a.state?.toLowerCase() == state.toLowerCase()) aScore += 1;
      if (city != null && b.city?.toLowerCase() == city.toLowerCase()) bScore += 2;
      if (state != null && b.state?.toLowerCase() == state.toLowerCase()) bScore += 1;
      return bScore.compareTo(aScore);
    });

    return users.take(limit).toList();
  }

  // ══════════════════ DIRECT MESSAGING ══════════════════

  /// Get conversation ID for two users (deterministic)
  String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Send a message (creates conversation if needed)
  Future<void> sendMessage({
    required String currentUid,
    required String otherUid,
    required String text,
    required String currentName,
    String? currentPhoto,
    required String otherName,
    String? otherPhoto,
  }) async {
    final conversationId = getConversationId(currentUid, otherUid);
    final convRef = _firestore.collection('conversations').doc(conversationId);
    final msgRef = convRef.collection('messages').doc();
    final now = DateTime.now();

    final batch = _firestore.batch();

    // Create/update conversation
    batch.set(convRef, {
      'participants': [currentUid, otherUid],
      'lastMessage': text,
      'lastSenderUid': currentUid,
      'lastMessageTime': Timestamp.fromDate(now),
      'unreadCounts.$otherUid': FieldValue.increment(1),
      'participantNames.$currentUid': currentName,
      'participantNames.$otherUid': otherName,
      'participantPhotos.$currentUid': currentPhoto,
      'participantPhotos.$otherUid': otherPhoto,
    }, SetOptions(merge: true));

    // Add message
    batch.set(msgRef, MessageModel(
      id: msgRef.id,
      senderUid: currentUid,
      text: text,
      createdAt: now,
    ).toFirestore());

    await batch.commit();
  }

  /// Get conversations for a user
  Stream<List<ConversationModel>> getConversations(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final convs = snap.docs.map((d) => ConversationModel.fromFirestore(d)).toList();
      convs.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return convs;
    });
  }

  /// Get messages for a conversation
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  /// Mark messages as read
  Future<void> markMessagesRead(String conversationId, String uid) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCounts.$uid': 0,
    });
  }

  /// Get total unread message count for a user
  Stream<int> getTotalUnreadCount(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final unread = (data['unreadCounts'] as Map<String, dynamic>?)?[uid];
        if (unread != null) total += (unread as num).toInt();
      }
      return total;
    });
  }

  // ══════════════════ GROUPS ══════════════════

  /// Create a group
  Future<String> createGroup({
    required String name,
    required String description,
    required String category,
    required String createdBy,
    required String createdByName,
  }) async {
    final now = DateTime.now();
    final docRef = await _firestore.collection('groups').add(GroupModel(
      id: '',
      name: name,
      description: description,
      category: category,
      createdBy: createdBy,
      createdByName: createdByName,
      members: [createdBy],
      memberCount: 1,
      lastMessageTime: now,
      createdAt: now,
    ).toFirestore());
    return docRef.id;
  }

  /// Join a group
  Future<void> joinGroup(String groupId, String uid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([uid]),
      'memberCount': FieldValue.increment(1),
    });
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId, String uid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid]),
      'memberCount': FieldValue.increment(-1),
    });
  }

  /// Send a group message
  Future<void> sendGroupMessage({
    required String groupId,
    required String senderUid,
    required String senderName,
    String? senderPhotoUrl,
    required String text,
  }) async {
    final now = DateTime.now();
    final msgRef = _firestore.collection('groups').doc(groupId).collection('messages').doc();
    final batch = _firestore.batch();

    batch.set(msgRef, GroupMessageModel(
      id: msgRef.id,
      senderUid: senderUid,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: text,
      createdAt: now,
    ).toFirestore());

    batch.update(_firestore.collection('groups').doc(groupId), {
      'lastMessage': text,
      'lastSenderName': senderName,
      'lastMessageTime': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Get all groups
  Stream<List<GroupModel>> getAllGroups() {
    return _firestore
        .collection('groups')
        .snapshots()
        .map((snap) {
      final groups = snap.docs.map((d) => GroupModel.fromFirestore(d)).toList();
      groups.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return groups;
    });
  }

  /// Get groups user is a member of
  Stream<List<GroupModel>> getUserGroups(String uid) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final groups = snap.docs.map((d) => GroupModel.fromFirestore(d)).toList();
      groups.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return groups;
    });
  }

  /// Get group messages
  Stream<List<GroupMessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => GroupMessageModel.fromFirestore(d)).toList());
  }

  // ══════════════════ ONLINE STATUS ══════════════════

  /// Set user online/offline status
  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    final updates = <String, dynamic>{
      'isOnline': isOnline,
    };
    if (!isOnline) {
      updates['lastSeen'] = Timestamp.fromDate(DateTime.now());
    }
    await _firestore.collection('users').doc(uid).update(updates);
  }

  // ══════════════════ QUICK HELP (HELP REQUESTS + BIDDING) ══════════════════

  /// Create a help request
  Future<void> createHelpRequest(HelpRequestModel request) async {
    await _firestore.collection('helpRequests').add(request.toFirestore());
  }

  /// Get open help requests stream (sorted by newest)
  Stream<List<HelpRequestModel>> getHelpRequests({String? category}) {
    return _firestore
        .collection('helpRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      var items = snap.docs.map((d) => HelpRequestModel.fromFirestore(d)).toList();
      if (category != null && category.isNotEmpty) {
        items = items.where((r) => r.category == category).toList();
      }
      return items;
    });
  }

  /// Get help requests for a specific user
  Stream<List<HelpRequestModel>> getMyHelpRequests(String uid) {
    return _firestore
        .collection('helpRequests')
        .where('requesterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => HelpRequestModel.fromFirestore(d)).toList());
  }

  /// Place a bid on a help request
  Future<void> placeBid(String requestId, BidModel bid) async {
    final batch = _firestore.batch();
    final bidRef = _firestore.collection('helpRequests').doc(requestId).collection('bids').doc();
    batch.set(bidRef, bid.toFirestore());
    batch.update(_firestore.collection('helpRequests').doc(requestId), {
      'bidCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Get bids for a help request
  Stream<List<BidModel>> getBids(String requestId) {
    return _firestore
        .collection('helpRequests')
        .doc(requestId)
        .collection('bids')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BidModel.fromFirestore(d)).toList());
  }

  /// Accept a bid
  Future<void> acceptBid(String requestId, String bidId, String providerId) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('helpRequests').doc(requestId), {
      'status': 'inProgress',
      'acceptedBidId': bidId,
      'acceptedProviderId': providerId,
    });
    batch.update(
      _firestore.collection('helpRequests').doc(requestId).collection('bids').doc(bidId),
      {'status': 'accepted'},
    );
    await batch.commit();
  }

  /// Complete a help request
  Future<void> completeHelpRequest(String requestId) async {
    await _firestore.collection('helpRequests').doc(requestId).update({
      'status': 'completed',
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ══════════════════ LOCAL JOB BOARD ══════════════════

  /// Create a job listing
  Future<void> createJobListing(JobModel job) async {
    await _firestore.collection('jobListings').add(job.toFirestore());
  }

  /// Get job listings stream
  Stream<List<JobModel>> getJobListings({String? category, String? jobType}) {
    return _firestore
        .collection('jobListings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      var items = snap.docs.map((d) => JobModel.fromFirestore(d)).toList();
      if (category != null && category.isNotEmpty) {
        items = items.where((j) => j.category == category).toList();
      }
      if (jobType != null && jobType.isNotEmpty) {
        items = items.where((j) => j.jobType.name == jobType).toList();
      }
      return items;
    });
  }

  /// Get jobs posted by a specific user
  Stream<List<JobModel>> getMyJobListings(String uid) {
    return _firestore
        .collection('jobListings')
        .where('posterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => JobModel.fromFirestore(d)).toList());
  }

  /// Apply for a job
  Future<void> applyForJob(String jobId, JobApplicationModel application) async {
    final batch = _firestore.batch();
    final appRef = _firestore.collection('jobListings').doc(jobId).collection('applications').doc();
    batch.set(appRef, application.toFirestore());
    batch.update(_firestore.collection('jobListings').doc(jobId), {
      'applicationCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Get applications for a job
  Stream<List<JobApplicationModel>> getJobApplications(String jobId) {
    return _firestore
        .collection('jobListings')
        .doc(jobId)
        .collection('applications')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => JobApplicationModel.fromFirestore(d)).toList());
  }

  /// Close a job listing
  Future<void> closeJobListing(String jobId) async {
    await _firestore.collection('jobListings').doc(jobId).update({
      'status': 'closed',
    });
  }

  // ══════════════════ LOCAL MARKETPLACE ══════════════════

  /// Create a market item listing
  Future<void> createMarketItem(MarketItemModel item) async {
    await _firestore.collection('marketItems').add(item.toFirestore());
  }

  /// Get market items stream
  Stream<List<MarketItemModel>> getMarketItems({String? category}) {
    return _firestore
        .collection('marketItems')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      var items = snap.docs.map((d) => MarketItemModel.fromFirestore(d)).toList();
      // Only show available items
      items = items.where((i) => i.status == ItemStatus.available).toList();
      if (category != null && category.isNotEmpty) {
        items = items.where((i) => i.category == category).toList();
      }
      return items;
    });
  }

  /// Get my market items
  Stream<List<MarketItemModel>> getMyMarketItems(String uid) {
    return _firestore
        .collection('marketItems')
        .where('sellerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MarketItemModel.fromFirestore(d)).toList());
  }

  /// Mark item as sold
  Future<void> markItemSold(String itemId) async {
    await _firestore.collection('marketItems').doc(itemId).update({
      'status': 'sold',
    });
  }

  /// Delete a market item
  Future<void> deleteMarketItem(String itemId) async {
    await _firestore.collection('marketItems').doc(itemId).update({
      'status': 'removed',
    });
  }

  /// Increment item views
  Future<void> incrementItemViews(String itemId) async {
    await _firestore.collection('marketItems').doc(itemId).update({
      'views': FieldValue.increment(1),
    });
  }

  // ══════════════════ LOST & FOUND ══════════════════

  /// Create a lost/found item report
  Future<void> createLostFoundItem(LostFoundItemModel item) async {
    await _firestore.collection('lostFoundItems').add(item.toFirestore());
  }

  /// Get lost/found items stream
  Stream<List<LostFoundItemModel>> getLostFoundItems({String? itemType, String? category}) {
    return _firestore
        .collection('lostFoundItems')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      var items = snap.docs.map((d) => LostFoundItemModel.fromFirestore(d)).toList();
      // Only show active items
      items = items.where((i) => i.status == LostFoundStatus.active).toList();
      if (itemType != null && itemType.isNotEmpty) {
        items = items.where((i) => i.itemType.name == itemType).toList();
      }
      if (category != null && category.isNotEmpty) {
        items = items.where((i) => i.category == category).toList();
      }
      return items;
    });
  }

  /// Get user's lost/found items
  Stream<List<LostFoundItemModel>> getMyLostFoundItems(String uid) {
    return _firestore
        .collection('lostFoundItems')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LostFoundItemModel.fromFirestore(d)).toList());
  }

  /// Mark item as claimed
  Future<void> claimLostFoundItem(String itemId) async {
    await _firestore.collection('lostFoundItems').doc(itemId).update({
      'status': 'claimed',
    });
  }

  /// Close a lost/found item report
  Future<void> closeLostFoundItem(String itemId) async {
    await _firestore.collection('lostFoundItems').doc(itemId).update({
      'status': 'closed',
    });
  }

  /// Increment lost/found item views
  Future<void> incrementLostFoundViews(String itemId) async {
    await _firestore.collection('lostFoundItems').doc(itemId).update({
      'views': FieldValue.increment(1),
    });
  }

  // ══════════════════ CHAT PRIVACY (BLOCK & DELETE) ══════════════════

  /// Block a user
  Future<void> blockUser(String currentUid, String blockedUid) async {
    await _firestore.collection('blocks').doc(currentUid).set({
      'blockedUsers': FieldValue.arrayUnion([blockedUid]),
    }, SetOptions(merge: true));
  }

  /// Unblock a user
  Future<void> unblockUser(String currentUid, String blockedUid) async {
    await _firestore.collection('blocks').doc(currentUid).set({
      'blockedUsers': FieldValue.arrayRemove([blockedUid]),
    }, SetOptions(merge: true));
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String currentUid, String otherUid) async {
    final doc = await _firestore.collection('blocks').doc(currentUid).get();
    if (!doc.exists) return false;
    final blocked = List<String>.from(doc.data()?['blockedUsers'] ?? []);
    return blocked.contains(otherUid);
  }

  /// Get blocked users list
  Stream<List<String>> getBlockedUsers(String uid) {
    return _firestore.collection('blocks').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      return List<String>.from(doc.data()?['blockedUsers'] ?? []);
    });
  }

  /// Check if either user has blocked the other
  Future<bool> isBlocked(String uid1, String uid2) async {
    final b1 = await isUserBlocked(uid1, uid2);
    if (b1) return true;
    final b2 = await isUserBlocked(uid2, uid1);
    return b2;
  }

  /// Delete a conversation (hide for current user)
  Future<void> deleteConversation(String conversationId, String uid) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'deletedBy': FieldValue.arrayUnion([uid]),
    });
  }

  /// Edit a message (only sender can edit)
  Future<void> editMessage(String conversationId, String messageId, String newText) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText,
      'isEdited': true,
    });

    // Update last message in conversation if this was the latest
    final convRef = _firestore.collection('conversations').doc(conversationId);
    final convDoc = await convRef.get();
    if (convDoc.exists) {
      final lastMsg = convDoc.data()?['lastMessage'];
      // We update lastMessage optimistically — if the edited message was the latest
      final messagesSnap = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (messagesSnap.docs.isNotEmpty && messagesSnap.docs.first.id == messageId) {
        await convRef.update({'lastMessage': newText});
      }
    }
  }

  /// Delete a message (soft delete — only sender can delete)
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': 'This message was deleted',
      'isDeleted': true,
    });

    // Update last message in conversation if this was the latest
    final messagesSnap = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (messagesSnap.docs.isNotEmpty && messagesSnap.docs.first.id == messageId) {
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': 'This message was deleted',
      });
    }
  }

  /// Get conversations excluding deleted ones
  Stream<List<ConversationModel>> getConversationsFiltered(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final convs = snap.docs
          .map((d) => ConversationModel.fromFirestore(d))
          .where((c) {
            // Hide conversations deleted by this user
            return !c.deletedBy.contains(uid);
          })
          .toList();
      convs.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return convs;
    });
  }

  // ===== COMMUNITY PROVIDERS =====

  // Add a community provider (user submission)
  Future<String?> addCommunityProvider({
    required String name,
    required String phone,
    required String category,
    required String area,
    String? description,
    required String createdByUserId,
    required String createdByUserName,
  }) async {
    // Check daily submission limit (max 5/day)
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final submissions = await _firestore
        .collection('communityProviders')
        .where('createdByUserId', isEqualTo: createdByUserId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    if (submissions.docs.length >= 5) return 'daily_limit';

    // Check for duplicate (same phone number)
    final duplicateCheck = await _firestore
        .collection('communityProviders')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (duplicateCheck.docs.isNotEmpty) return 'duplicate';

    // Also check in main users collection
    final userDupCheck = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (userDupCheck.docs.isNotEmpty) return 'exists_as_user';

    final provider = CommunityProvider(
      id: '',
      name: name,
      phone: phone,
      category: category,
      area: area,
      description: description,
      createdByUserId: createdByUserId,
      createdByUserName: createdByUserName,
      isOfflineProvider: true,
      status: ProviderStatus.pending,
      duplicateHash: phone.replaceAll(RegExp(r'[^0-9]'), ''),
      createdAt: DateTime.now(),
    );

    await _firestore.collection('communityProviders').add(provider.toFirestore());
    return null; // success
  }

  // Get pending community providers (admin)
  Stream<List<CommunityProvider>> getPendingCommunityProviders() {
    return _firestore
        .collection('communityProviders')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommunityProvider.fromFirestore(d)).toList());
  }

  // Get all community providers (admin)
  Stream<List<CommunityProvider>> getAllCommunityProviders() {
    return _firestore
        .collection('communityProviders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommunityProvider.fromFirestore(d)).toList());
  }

  // Get approved community providers (for search/display)
  Stream<List<CommunityProvider>> getApprovedCommunityProviders({String? category, String? area}) {
    Query query = _firestore
        .collection('communityProviders')
        .where('status', isEqualTo: 'approved');
    if (category != null) query = query.where('category', isEqualTo: category);
    return query.snapshots().map((snap) {
      var list = snap.docs.map((d) => CommunityProvider.fromFirestore(d)).toList();
      // Verified first, then by rating
      list.sort((a, b) {
        if (a.isVerified != b.isVerified) return a.isVerified ? -1 : 1;
        return b.rating.compareTo(a.rating);
      });
      if (area != null) {
        list = list.where((p) => p.area.toLowerCase().contains(area.toLowerCase())).toList();
      }
      return list;
    });
  }

  // Approve community provider
  Future<void> approveCommunityProvider(String providerId, String adminUid) async {
    final providerDoc = await _firestore.collection('communityProviders').doc(providerId).get();
    if (!providerDoc.exists) return;

    final data = providerDoc.data()!;
    await _firestore.collection('communityProviders').doc(providerId).update({
      'status': 'approved',
      'isVerified': true,
      'verificationType': 'admin',
      'approvedAt': Timestamp.fromDate(DateTime.now()),
      'approvedBy': adminUid,
    });

    // Award points to the contributor
    final contributorUid = data['createdByUserId'] as String;
    await awardPoints(contributorUid, 20, 'Provider "${data['name']}" approved! +20 pts');
  }

  // Reject community provider
  Future<void> rejectCommunityProvider(String providerId, {String? reason}) async {
    await _firestore.collection('communityProviders').doc(providerId).update({
      'status': 'rejected',
      if (reason != null) 'rejectionReason': reason,
    });
  }

  // Mark community provider as verified by admin
  Future<void> verifyCommunityProvider(String providerId) async {
    await _firestore.collection('communityProviders').doc(providerId).update({
      'isVerified': true,
      'verificationType': 'admin',
    });
  }

  // Increment helped count (when someone calls)
  Future<void> incrementHelpedCount(String providerId) async {
    await _firestore.collection('communityProviders').doc(providerId).update({
      'helpedCount': FieldValue.increment(1),
    });
  }

  // Get user's contribution stats
  Future<Map<String, int>> getUserContributionStats(String uid) async {
    final all = await _firestore
        .collection('communityProviders')
        .where('createdByUserId', isEqualTo: uid)
        .get();
    int total = all.docs.length;
    int approved = all.docs.where((d) => d.data()['status'] == 'approved').length;
    int pending = all.docs.where((d) => d.data()['status'] == 'pending').length;
    int totalHelped = 0;
    for (final doc in all.docs) {
      totalHelped += (doc.data()['helpedCount'] ?? 0) as int;
    }
    return {'total': total, 'approved': approved, 'pending': pending, 'helped': totalHelped};
  }
}
