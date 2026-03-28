import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../models/booking_model.dart';
import '../../widgets/banner_ad_widget.dart';

class BookingsListScreen extends StatelessWidget {
  const BookingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.teal,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.teal,
            tabs: const [
              Tab(text: 'As Customer'),
              Tab(text: 'As Provider'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingsList(uid: uid, isProvider: false),
            _BookingsList(uid: uid, isProvider: true),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final String uid;
  final bool isProvider;
  const _BookingsList({required this.uid, required this.isProvider});

  @override
  Widget build(BuildContext context) {
    final field = isProvider ? 'providerUid' : 'customerUid';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where(field, isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  isProvider ? 'No booking requests yet' : 'No bookings yet',
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + 1, // +1 for banner ad
          itemBuilder: (context, index) {
            // Show banner ad at position 2 (after first 2 items)
            if (index == 2) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: BannerAdWidget(),
              );
            }
            final docIndex = index > 2 ? index - 1 : index;
            if (docIndex >= docs.length) return const SizedBox.shrink();

            final booking = BookingModel.fromFirestore(docs[docIndex]);
            return _BookingCard(
              booking: booking,
              isProvider: isProvider,
            );
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isProvider;
  const _BookingCard({required this.booking, required this.isProvider});

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.orange;
      case BookingStatus.accepted:
        return AppColors.blue;
      case BookingStatus.inProgress:
        return AppColors.teal;
      case BookingStatus.completed:
        return AppColors.green;
      case BookingStatus.cancelled:
        return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProvider ? booking.customerName : booking.providerName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      booking.serviceCategory,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(booking.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(booking.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            booking.description,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Details row
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd MMM, hh:mm a').format(booking.scheduledAt),
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const Spacer(),
              if (booking.agreedPrice != null) ...[
                Text(
                  '\u20B9${booking.agreedPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.teal),
                ),
              ],
            ],
          ),

          // Commission info (visible to admin/provider)
          if (isProvider && booking.agreedPrice != null && booking.commissionAmount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Platform commission: \u20B9${booking.commissionAmount.toStringAsFixed(0)} (${booking.commissionRate.toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 11, color: AppColors.orange),
              ),
            ),
          ],

          // Action buttons for provider
          if (isProvider && booking.status == BookingStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(booking.id, BookingStatus.cancelled),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(booking.id, BookingStatus.accepted),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],

          // Mark complete button
          if (isProvider && booking.status == BookingStatus.accepted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateStatus(booking.id, BookingStatus.completed),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                child: const Text('Mark Completed'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateStatus(String bookingId, BookingStatus status) {
    final data = <String, dynamic>{'status': status.name};
    if (status == BookingStatus.completed) {
      data['completedAt'] = Timestamp.fromDate(DateTime.now());
    }
    FirebaseFirestore.instance.collection('bookings').doc(bookingId).update(data);
  }
}
