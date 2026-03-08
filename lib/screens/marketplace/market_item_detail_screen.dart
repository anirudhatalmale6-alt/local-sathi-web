import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/market_item_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';

class MarketItemDetailScreen extends StatefulWidget {
  final MarketItemModel item;

  const MarketItemDetailScreen({super.key, required this.item});

  @override
  State<MarketItemDetailScreen> createState() => _MarketItemDetailScreenState();
}

class _MarketItemDetailScreenState extends State<MarketItemDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Increment views on open
    FirestoreService().incrementItemViews(widget.item.id);
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return DateFormat('d MMM yyyy').format(dateTime);
  }

  void _confirmMarkSold() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Sold?'),
        content:
            const Text('This item will no longer appear in the marketplace.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().markItemSold(widget.item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Item marked as sold!'),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Mark Sold',
                style: TextStyle(color: AppColors.orange,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Item?'),
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
                await FirestoreService().deleteMarketItem(widget.item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Item deleted'),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Delete',
                style: TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final appProvider = context.watch<AppProvider>();
    final currentUid = appProvider.currentUser?.uid;
    final isSeller = currentUid != null && item.sellerId == currentUid;
    final priceFormat = NumberFormat('#,##,###', 'en_IN');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Photo area
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Image / Placeholder
                      SizedBox(
                        width: double.infinity,
                        height: 320,
                        child: item.photos.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.photos.first,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.tealLight.withAlpha(60),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.tealLight.withAlpha(60),
                                  child: const Icon(Icons.shopping_bag,
                                      size: 80, color: AppColors.teal),
                                ),
                              )
                            : Container(
                                color: AppColors.tealLight.withAlpha(60),
                                child: const Center(
                                  child: Icon(Icons.shopping_bag,
                                      size: 80, color: AppColors.teal),
                                ),
                              ),
                      ),

                      // Gradient overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.4),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),

                      // Views count
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.visibility,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${item.views}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Category chip on photo
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    padding: const EdgeInsets.all(20),
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
                        // Title
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Price + Negotiable badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '\u20B9${priceFormat.format(item.price.toInt())}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green,
                              ),
                            ),
                            if (item.negotiable) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.greenLight,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: const Text(
                                  'Negotiable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.green,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Condition chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            item.conditionLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Description section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    padding: const EdgeInsets.all(20),
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
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Seller info
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
                    child: Row(
                      children: [
                        // Seller avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.tealLight.withAlpha(100),
                          backgroundImage: item.sellerPhotoUrl != null &&
                                  item.sellerPhotoUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  item.sellerPhotoUrl!)
                              : null,
                          child: item.sellerPhotoUrl == null ||
                                  item.sellerPhotoUrl!.isEmpty
                              ? Text(
                                  item.sellerName.isNotEmpty
                                      ? item.sellerName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teal,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Seller name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.sellerName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Seller',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Chat button (placeholder)
                        if (!isSeller)
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Coming soon: Chat with seller'),
                                  backgroundColor: AppColors.teal,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.tealLight.withAlpha(80),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 16, color: AppColors.teal),
                                  SizedBox(width: 6),
                                  Text(
                                    'Chat',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Location + Time
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
                      children: [
                        // Location row
                        if (item.city != null && item.city!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.tealLight.withAlpha(80),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.location_on,
                                      size: 18, color: AppColors.teal),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    [
                                      if (item.city != null) item.city!,
                                      if (item.state != null) item.state!,
                                    ].join(', '),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Posted time row
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.blueLight.withAlpha(80),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.access_time,
                                  size: 18, color: AppColors.blue),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Posted ${_timeAgo(item.createdAt)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom spacer
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
          ),

          // Bottom bar
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: isSeller
                ? Row(
                    children: [
                      // Mark as Sold
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirmMarkSold,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Mark as Sold',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete
                      OutlinedButton(
                        onPressed: _confirmDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                          side: const BorderSide(color: AppColors.red),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Icon(Icons.delete_outline, size: 22),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Coming soon: Chat with seller'),
                            backgroundColor: AppColors.teal,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text(
                        'Message Seller',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
