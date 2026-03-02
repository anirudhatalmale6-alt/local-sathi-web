import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/avatar_widget.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _firestoreService = FirestoreService();
  Map<String, int> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _firestoreService.getAppStats();
    setState(() {
      _stats = stats;
      _loadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg,
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _statCard('\u{1F465}', _stats['totalUsers'] ?? 0, 'Total Users',
                      const Color(0xFFE3F2FD)),
                  _statCard('\u{23F3}', _stats['pendingVerifications'] ?? 0,
                      'Pending Verifications', const Color(0xFFFFF3E0)),
                  _statCard('\u2705', _stats['activeProviders'] ?? 0,
                      'Active Providers', const Color(0xFFE8F5E9)),
                  _statCard('\u{1F4DD}', _stats['postsToday'] ?? 0,
                      'Posts Today', const Color(0xFFFCE4EC)),
                ],
              ),
            ),

            // Pending Verifications
            _sectionTitle('Pending Aadhaar Verifications'),
            StreamBuilder<List<UserModel>>(
              stream: _firestoreService.getPendingVerifications(),
              builder: (context, snapshot) {
                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return _emptyState('No pending verifications');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _verifyCard(user);
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Reported Posts
            _sectionTitle('Reported Posts'),
            StreamBuilder<List<PostModel>>(
              stream: _firestoreService.getReportedPosts(),
              builder: (context, snapshot) {
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return _emptyState('No reported posts');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _reportCard(post);
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // User Feedback
            _sectionTitle('User Feedback'),
            StreamBuilder<List<FeedbackModel>>(
              stream: _firestoreService.getAllFeedback(),
              builder: (context, snapshot) {
                final feedbacks = snapshot.data ?? [];
                if (feedbacks.isEmpty) {
                  return _emptyState('No feedback yet');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final fb = feedbacks[index];
                    return _feedbackCard(fb);
                  },
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String emoji, int value, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadingStats ? '...' : '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _verifyCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          AvatarWidget(name: user.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'Aadhaar: ${user.aadhaarNumber ?? 'Document uploaded'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _circleButton(
                Icons.check,
                AppColors.greenLight,
                AppColors.green,
                () async {
                  await _firestoreService.updateVerificationStatus(
                    user.uid,
                    VerificationStatus.verified,
                  );
                  _loadStats();
                },
              ),
              const SizedBox(width: 8),
              _circleButton(
                Icons.close,
                AppColors.redLight,
                AppColors.red,
                () async {
                  await _firestoreService.updateVerificationStatus(
                    user.uid,
                    VerificationStatus.rejected,
                  );
                  _loadStats();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleButton(
      IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  Widget _feedbackCard(FeedbackModel fb) {
    final categoryIcon = fb.category == 'bug'
        ? Icons.bug_report_outlined
        : fb.category == 'feature'
            ? Icons.lightbulb_outline
            : Icons.chat_bubble_outline;
    final categoryLabel = fb.category == 'bug'
        ? 'Bug Report'
        : fb.category == 'feature'
            ? 'Feature Request'
            : 'General';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: fb.isRead ? null : Border.all(color: AppColors.teal.withAlpha(60), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(name: fb.userName, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fb.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      fb.userLocalSathiId,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Star rating
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 14,
                    color: i < fb.rating ? AppColors.gold : AppColors.textMuted.withAlpha(60),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(categoryIcon, size: 14, color: AppColors.tealDark),
                const SizedBox(width: 4),
                Text(
                  categoryLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fb.message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!fb.isRead)
                GestureDetector(
                  onTap: () => _firestoreService.markFeedbackRead(fb.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Mark Read',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tealDark,
                      ),
                    ),
                  ),
                ),
              if (!fb.isRead) const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _firestoreService.deleteFeedback(fb.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${post.text}"',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            'By ${post.authorName} · ${post.reportCount} reports',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => _firestoreService.deletePost(post.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Remove Post',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _firestoreService.dismissReport(post.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
