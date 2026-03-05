import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/verified_badge.dart';
import 'comments_sheet.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 1),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Feed',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "What's happening in your neighbourhood",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
            sliver: StreamBuilder<List<PostModel>>(
              stream: firestoreService.getLiveFeed(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('Could not load feed', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }

                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.article_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No posts yet',
                            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to share something!',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PostCard(post: posts[index]),
                    ),
                    childCount: posts.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;

  const _PostCard({required this.post});

  void _showPostMenu(BuildContext context, bool isOwner, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.teal),
                  title: const Text('Edit Post'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.red),
                  title: Text('Delete Post', style: TextStyle(color: AppColors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(context);
                  },
                ),
              ],
              if (!isOwner && isAdmin)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.red),
                  title: Text('Delete Post (Admin)', style: TextStyle(color: AppColors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(context);
                  },
                ),
              if (!isOwner)
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppColors.orange),
                  title: const Text('Report Post'),
                  onTap: () {
                    Navigator.pop(ctx);
                    FirestoreService().reportPost(post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Post reported. Thank you.'),
                        backgroundColor: AppColors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: post.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          bool saving = false;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Edit Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  maxLength: 280,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "What's on your mind?",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      final newText = controller.text.trim();
                      if (newText.isEmpty) return;
                      setSheetState(() => saving = true);
                      try {
                        await FirestoreService().updatePost(post.id, newText);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Post updated!'),
                              backgroundColor: AppColors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (e) {
                        setSheetState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().deletePost(post.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Post deleted'),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.read<AppProvider>();
    final currentUid = appProvider.currentUser?.uid;
    final isLiked = post.likedBy.contains(currentUid);
    final isOwner = currentUid != null && post.authorUid == currentUid;
    final isAdmin = appProvider.currentUser?.isAdmin ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarWidget(
                photoUrl: post.authorPhotoUrl,
                name: post.authorName,
                size: 42,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        LocalSathiIdBadge(id: post.authorLocalSathiId),
                        if (post.authorVerified)
                          const VerifiedBadge(size: 16),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Text(
                          _timeAgo(post.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (post.location != null && post.location!.isNotEmpty) ...[
                          Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          Icon(Icons.location_on, size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 1),
                          Flexible(
                            child: Text(
                              post.location!,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 3-dot menu
              GestureDetector(
                onTap: () => _showPostMenu(context, isOwner, isAdmin),
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Post text
          Text(
            post.text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.black.withOpacity(0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                _actionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likeCount}',
                  color: isLiked ? AppColors.red : AppColors.textMuted,
                  onTap: () {
                    if (currentUid != null) {
                      FirestoreService().toggleLike(post.id, currentUid);
                    }
                  },
                ),
                const SizedBox(width: 20),
                _actionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.commentCount}',
                  color: AppColors.textMuted,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CommentsSheet(post: post),
                    );
                  },
                ),
                const SizedBox(width: 20),
                _actionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: AppColors.textMuted,
                  onTap: () {
                    final shareText = '${post.authorName} on Local Sathi:\n\n"${post.text}"\n\nDownload Local Sathi - Your Community Companion!';
                    Share.share(shareText);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dateTime);
  }
}
