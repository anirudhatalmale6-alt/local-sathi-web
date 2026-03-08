import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/help_request_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';

class QuickHelpDetailScreen extends StatelessWidget {
  final HelpRequestModel request;

  const QuickHelpDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final isRequester = user.uid == request.requesterId;
    final isProvider = user.isProvider;
    final canBid = !isRequester &&
        isProvider &&
        request.status == HelpStatus.open;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── Scrollable content ──
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Gradient header ──
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.tealGradient,
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(28)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // App bar
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
                                const Expanded(
                                  child: Text(
                                    'Help Request',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 38),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              request.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Category + status row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(40),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    request.category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _statusChip(request.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Request details card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 16,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            request.description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Info row: budget + location + time
                          Wrap(
                            spacing: 16,
                            runSpacing: 10,
                            children: [
                              if (request.budget != null)
                                _infoItem(
                                  Icons.currency_rupee,
                                  'Budget: ${request.budget!.toStringAsFixed(0)}',
                                  AppColors.green,
                                ),
                              _infoItem(
                                Icons.location_on,
                                request.location ??
                                    request.city ??
                                    'Not specified',
                                AppColors.teal,
                              ),
                              _infoItem(
                                Icons.access_time,
                                _timeAgo(request.createdAt),
                                AppColors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Requester info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Avatar initial
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.tealLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: request.requesterPhotoUrl != null &&
                                          request
                                              .requesterPhotoUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            request.requesterPhotoUrl!,
                                            width: 38,
                                            height: 38,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => Center(
                                              child: Text(
                                                request.requesterName
                                                        .isNotEmpty
                                                    ? request.requesterName[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.tealDark,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            request.requesterName.isNotEmpty
                                                ? request.requesterName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.tealDark,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Requested by',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      Text(
                                        request.requesterName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bids section header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bids',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        StreamBuilder<List<BidModel>>(
                          stream: FirestoreService().getBids(request.id),
                          builder: (context, snap) {
                            final count = snap.data?.length ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: count > 0
                                    ? AppColors.orangeLight
                                    : AppColors.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count bid${count == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: count > 0
                                      ? AppColors.orange
                                      : AppColors.textMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bids list ──
                StreamBuilder<List<BidModel>>(
                  stream: FirestoreService().getBids(request.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.teal),
                          ),
                        ),
                      );
                    }

                    final bids = snapshot.data ?? [];
                    if (bids.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.gavel_outlined,
                                  size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No bids yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Providers will bid on this request soon',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final bid = bids[index];
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                index == bids.length - 1 ? 20 : 8),
                            child: _BidCard(
                              bid: bid,
                              isRequester: isRequester,
                              requestId: request.id,
                              requestStatus: request.status,
                              acceptedBidId: request.acceptedBidId,
                            ),
                          );
                        },
                        childCount: bids.length,
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // ── Bottom bar ──
          _BottomBar(
            canBid: canBid,
            isRequester: isRequester,
            request: request,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(HelpStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case HelpStatus.open:
        bg = Colors.white.withAlpha(40);
        fg = Colors.white;
        label = 'Open';
        break;
      case HelpStatus.inProgress:
        bg = AppColors.orangeLight;
        fg = AppColors.orange;
        label = 'In Progress';
        break;
      case HelpStatus.completed:
        bg = AppColors.greenLight;
        fg = AppColors.green;
        label = 'Completed';
        break;
      case HelpStatus.cancelled:
        bg = AppColors.redLight;
        fg = AppColors.red;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ],
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

// ═══════════════════════════════════════════════════════════════
// Bid card
// ═══════════════════════════════════════════════════════════════

class _BidCard extends StatelessWidget {
  final BidModel bid;
  final bool isRequester;
  final String requestId;
  final HelpStatus requestStatus;
  final String? acceptedBidId;

  const _BidCard({
    required this.bid,
    required this.isRequester,
    required this.requestId,
    required this.requestStatus,
    this.acceptedBidId,
  });

  @override
  Widget build(BuildContext context) {
    final isAccepted = bid.id == acceptedBidId;
    final canAccept = isRequester &&
        requestStatus == HelpStatus.open &&
        bid.status == 'pending';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isAccepted
            ? Border.all(color: AppColors.green, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Bidder avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: bid.bidderPhotoUrl != null &&
                        bid.bidderPhotoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          bid.bidderPhotoUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              bid.bidderName.isNotEmpty
                                  ? bid.bidderName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tealDark,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          bid.bidderName.isNotEmpty
                              ? bid.bidderName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tealDark,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bid.bidderName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (bid.bidderRating != null &&
                            bid.bidderRating! > 0) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.star_rounded,
                              size: 14, color: AppColors.gold),
                          const SizedBox(width: 1),
                          Text(
                            bid.bidderRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (isAccepted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.greenLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Accepted',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _timeAgo(bid.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Bid amount
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_rupee,
                        size: 14, color: AppColors.green),
                    Text(
                      bid.amount.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bid message
          if (bid.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bid.message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // Estimated time
          if (bid.estimatedTime != null &&
              bid.estimatedTime!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Est. time: ${bid.estimatedTime}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],

          // Accept button (only for requester, only when open)
          if (canAccept) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptBid(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Accept Bid',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptBid(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept this bid?'),
        content: Text(
          'You are accepting ${bid.bidderName}\'s bid of Rs ${bid.amount.toStringAsFixed(0)}. The provider will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Accept',
              style: TextStyle(
                  color: AppColors.green, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirestoreService().acceptBid(requestId, bid.id, bid.bidderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bid from ${bid.bidderName} accepted!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept bid: $e'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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

// ═══════════════════════════════════════════════════════════════
// Bottom bar (Place Bid / Status info)
// ═══════════════════════════════════════════════════════════════

class _BottomBar extends StatelessWidget {
  final bool canBid;
  final bool isRequester;
  final HelpRequestModel request;

  const _BottomBar({
    required this.canBid,
    required this.isRequester,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: canBid
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPlaceBidSheet(context),
                icon: const Icon(Icons.gavel, size: 18),
                label: const Text(
                  'Place Bid',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            )
          : _buildStatusInfo(context),
    );
  }

  Widget _buildStatusInfo(BuildContext context) {
    IconData icon;
    Color color;
    String text;

    if (isRequester) {
      switch (request.status) {
        case HelpStatus.open:
          icon = Icons.hourglass_top;
          color = AppColors.teal;
          text = 'Your request is open -- waiting for bids';
          break;
        case HelpStatus.inProgress:
          icon = Icons.handshake;
          color = AppColors.orange;
          text = 'A provider has been assigned to your request';
          break;
        case HelpStatus.completed:
          icon = Icons.check_circle;
          color = AppColors.green;
          text = 'This request has been completed';
          break;
        case HelpStatus.cancelled:
          icon = Icons.cancel;
          color = AppColors.red;
          text = 'This request was cancelled';
          break;
      }
    } else {
      switch (request.status) {
        case HelpStatus.open:
          icon = Icons.info_outline;
          color = AppColors.textMuted;
          text = 'Only providers can place bids on help requests';
          break;
        case HelpStatus.inProgress:
          icon = Icons.handshake;
          color = AppColors.orange;
          text = 'A bid has been accepted for this request';
          break;
        case HelpStatus.completed:
          icon = Icons.check_circle;
          color = AppColors.green;
          text = 'This request has been completed';
          break;
        case HelpStatus.cancelled:
          icon = Icons.cancel;
          color = AppColors.red;
          text = 'This request was cancelled';
          break;
      }
    }

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _showPlaceBidSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceBidSheet(requestId: request.id),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Place bid bottom sheet
// ═══════════════════════════════════════════════════════════════

class _PlaceBidSheet extends StatefulWidget {
  final String requestId;

  const _PlaceBidSheet({required this.requestId});

  @override
  State<_PlaceBidSheet> createState() => _PlaceBidSheetState();
}

class _PlaceBidSheetState extends State<_PlaceBidSheet> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    final message = _messageController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0 || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount and message'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = context.read<AppProvider>().currentUser!;
      final estimatedTime = _estimatedTimeController.text.trim();

      final bid = BidModel(
        id: '',
        bidderId: user.uid,
        bidderName: user.name,
        bidderPhotoUrl: user.profilePhotoUrl,
        bidderRating: user.rating > 0 ? user.rating : null,
        amount: amount,
        message: message,
        estimatedTime: estimatedTime.isNotEmpty ? estimatedTime : null,
        createdAt: DateTime.now(),
      );

      await FirestoreService().placeBid(widget.requestId, bid);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bid placed successfully!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place bid: $e'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Place Your Bid',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tell the requester your price and how you can help',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            // Amount field
            const Text(
              'Your Price (Rs)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 500',
                prefixIcon: const Icon(Icons.currency_rupee,
                    size: 18, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),

            // Message field
            const Text(
              'Message',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _messageController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Describe your experience and how you can help...',
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),

            // Estimated time field
            const Text(
              'Estimated Time (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _estimatedTimeController,
              decoration: InputDecoration(
                hintText: 'e.g. 2 hours, 1 day',
                prefixIcon: const Icon(Icons.schedule,
                    size: 18, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit Bid',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
