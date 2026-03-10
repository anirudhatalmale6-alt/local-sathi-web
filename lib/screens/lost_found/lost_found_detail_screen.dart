import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../models/lost_found_item_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chat_screen.dart';

class LostFoundDetailScreen extends StatefulWidget {
  final LostFoundItemModel item;

  const LostFoundDetailScreen({super.key, required this.item});

  @override
  State<LostFoundDetailScreen> createState() => _LostFoundDetailScreenState();
}

class _LostFoundDetailScreenState extends State<LostFoundDetailScreen> {
  @override
  void initState() {
    super.initState();
    FirestoreService().incrementLostFoundViews(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isLost = item.itemType == LostFoundType.lost;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid == item.userId;
    final themeColor =
        isLost ? const Color(0xFFE53935) : const Color(0xFF43A047);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLost
                      ? [const Color(0xFFE53935), const Color(0xFFEF5350)]
                      : [const Color(0xFF43A047), const Color(0xFF66BB6A)],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(40),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isLost ? 'Lost Item' : 'Found Item',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.status == LostFoundStatus.active
                                  ? 'Active'
                                  : item.status == LostFoundStatus.claimed
                                      ? 'Claimed'
                                      : 'Closed',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Type icon + title
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                isLost
                                    ? Icons.search_rounded
                                    : Icons.volunteer_activism_rounded,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description card
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Details card
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _detailRow(
                          Icons.category,
                          'Category',
                          item.category,
                          themeColor,
                        ),
                        if (item.color != null && item.color!.isNotEmpty)
                          _detailRow(
                            Icons.color_lens_outlined,
                            'Color / Features',
                            item.color!,
                            themeColor,
                          ),
                        if (item.location != null &&
                            item.location!.isNotEmpty)
                          _detailRow(
                            Icons.location_on,
                            isLost ? 'Last seen at' : 'Found at',
                            item.location!,
                            themeColor,
                          ),
                        if (item.city != null && item.city!.isNotEmpty)
                          _detailRow(
                            Icons.place,
                            'City',
                            '${item.city}${item.state != null ? ', ${item.state}' : ''}',
                            themeColor,
                          ),
                        _detailRow(
                          Icons.access_time,
                          'Reported',
                          _formatDate(item.createdAt),
                          themeColor,
                        ),
                        _detailRow(
                          Icons.visibility_outlined,
                          'Views',
                          '${item.views}',
                          themeColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reported by card
                  _card(
                    child: Row(
                      children: [
                        AvatarWidget(
                          photoUrl: item.userPhotoUrl,
                          name: item.userName,
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reported by',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                item.userName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isOwner && currentUid != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUid: item.userId,
                                    otherName: item.userName,
                                    otherPhotoUrl: item.userPhotoUrl,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isLost
                                      ? [
                                          const Color(0xFFE53935),
                                          const Color(0xFFEF5350)
                                        ]
                                      : [
                                          const Color(0xFF43A047),
                                          const Color(0xFF66BB6A)
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat_bubble_outline,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    isLost ? 'I Found It!' : 'It\'s Mine!',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Owner actions
                  if (isOwner && item.status == LostFoundStatus.active) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await FirestoreService()
                                  .claimLostFoundItem(item.id);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isLost
                                        ? 'Great! Glad you found it!'
                                        : 'Marked as claimed by owner!'),
                                    backgroundColor: AppColors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.check_circle,
                                color: AppColors.green, size: 20),
                            label: Text(
                              isLost ? 'Found It!' : 'Owner Found',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.green,
                              side:
                                  const BorderSide(color: AppColors.green),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await FirestoreService()
                                  .closeLostFoundItem(item.id);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Report closed'),
                                    backgroundColor: AppColors.textMuted,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.close,
                                color: AppColors.red, size: 20),
                            label: const Text(
                              'Close Report',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.red,
                              side: const BorderSide(color: AppColors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _detailRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(icon, size: 16, color: color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Today at $h:$m';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
