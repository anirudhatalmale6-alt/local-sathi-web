import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/verified_badge.dart';

class CommentsSheet extends StatefulWidget {
  final PostModel post;

  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _posting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final appProvider = context.read<AppProvider>();
    final user = appProvider.currentUser;
    if (user == null) return;

    setState(() => _posting = true);

    try {
      final comment = CommentModel(
        id: '',
        authorUid: user.uid,
        authorName: user.name,
        authorLocalSathiId: user.localSathiId,
        authorPhotoUrl: user.profilePhotoUrl,
        authorVerified: user.verificationStatus.name == 'verified',
        text: text,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addComment(widget.post.id, comment);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Comment?'),
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
                await _firestoreService.deleteComment(widget.post.id, commentId);
              } catch (e) {
                if (mounted) {
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
    final isAdmin = appProvider.currentUser?.isAdmin ?? false;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<List<CommentModel>>(
                      stream: _firestoreService.getPostComments(widget.post.id),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? widget.post.commentCount;
                        return Text(
                          '($count)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _firestoreService.getPostComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  );
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No comments yet',
                          style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isOwner = currentUid == comment.authorUid;
                    final canDelete = isOwner || isAdmin;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AvatarWidget(
                          photoUrl: comment.authorPhotoUrl,
                          name: comment.authorName,
                          size: 36,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      children: [
                                        Text(
                                          comment.authorName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        LocalSathiIdBadge(
                                          id: comment.authorLocalSathiId,
                                          fontSize: 9,
                                        ),
                                        if (comment.authorVerified)
                                          const VerifiedBadge(size: 14),
                                      ],
                                    ),
                                  ),
                                  if (canDelete)
                                    GestureDetector(
                                      onTap: () => _deleteComment(comment.id),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.text,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _timeAgo(comment.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Comment input
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, MediaQuery.of(context).viewInsets.bottom + 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.black.withOpacity(0.05)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLines: 3,
                      minLines: 1,
                      maxLength: 280,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _posting ? null : _postComment,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.tealBlueGradient,
                      ),
                      child: _posting
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
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
