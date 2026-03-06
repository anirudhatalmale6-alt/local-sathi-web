import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/post_model.dart';
import '../../../models/review_model.dart';
import '../../../models/feedback_model.dart';
import '../../../services/firestore_service.dart';

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.teal,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            indicator: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Reported Posts'),
              Tab(text: 'Reviews'),
              Tab(text: 'Feedback'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _reportedPostsTab(),
              _reviewsTab(),
              _feedbackTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════ REPORTED POSTS TAB ═══════════════
  Widget _reportedPostsTab() {
    return StreamBuilder<List<PostModel>>(
      stream: _firestore.getReportedPosts(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }
        final posts = snap.data ?? [];
        if (posts.isEmpty) {
          return _emptyState(Icons.shield_outlined, 'No reported posts');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: posts.length,
          itemBuilder: (ctx, i) => _reportCard(posts[i]),
        );
      },
    );
  }

  Widget _reportCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.redLight, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${post.reportCount} reports',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.red),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post.authorName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                post.authorLocalSathiId,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.text,
              style: const TextStyle(fontSize: 13, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _firestore.deletePost(post.id);
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _firestore.dismissReport(post.id);
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════ REVIEWS TAB ═══════════════
  Widget _reviewsTab() {
    return StreamBuilder<List<ReviewModel>>(
      stream: _firestore.getAllReviews(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }
        final reviews = snap.data ?? [];
        if (reviews.isEmpty) {
          return _emptyState(Icons.star_border, 'No reviews yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: reviews.length,
          itemBuilder: (ctx, i) => _reviewCard(reviews[i]),
        );
      },
    );
  }

  Widget _reviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(review.reviewerName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating.round() ? Icons.star : Icons.star_border,
                  size: 14,
                  color: AppColors.gold,
                )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(review.text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Review?', style: TextStyle(fontSize: 16)),
                      content: const Text('This will permanently remove this review.'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _firestore.deleteReview(review.id);
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════ FEEDBACK TAB ═══════════════
  Widget _feedbackTab() {
    return StreamBuilder<List<FeedbackModel>>(
      stream: _firestore.getAllFeedback(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return _emptyState(Icons.feedback_outlined, 'No feedback yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          itemBuilder: (ctx, i) => _feedbackCard(items[i]),
        );
      },
    );
  }

  Widget _feedbackCard(FeedbackModel fb) {
    final catColors = {
      'bug': AppColors.red,
      'feature': AppColors.blue,
      'general': AppColors.teal,
    };
    final color = catColors[fb.category] ?? AppColors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: fb.isRead ? null : Border.all(color: AppColors.tealLight, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (fb.category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    fb.category!.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!fb.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(fb.userName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < fb.rating ? Icons.star : Icons.star_border,
                  size: 12,
                  color: AppColors.gold,
                )),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(fb.message,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!fb.isRead)
                TextButton.icon(
                  onPressed: () => _firestore.markFeedbackRead(fb.id),
                  icon: const Icon(Icons.done, size: 14),
                  label: const Text('Mark Read', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.teal),
                ),
              TextButton.icon(
                onPressed: () => _firestore.deleteFeedback(fb.id),
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text('Delete', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
