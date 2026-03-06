import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_widget.dart';

class ProviderDetailScreen extends StatelessWidget {
  final UserModel provider;

  const ProviderDetailScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Hero header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(gradient: AppColors.tealGradient),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // Back button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withAlpha(38),
                                    ),
                                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Avatar & info
                          AvatarWidget(
                            photoUrl: provider.profilePhotoUrl,
                            name: provider.name,
                            size: 80,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            provider.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            provider.serviceCategories.isNotEmpty
                                ? provider.serviceCategories.first
                                : 'Service Provider',
                            style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(204)),
                          ),
                          const SizedBox(height: 8),
                          // Verification badges row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (provider.isVerified)
                                _heroBadge(Icons.check_circle, 'Aadhaar Verified', AppColors.green),
                              if (provider.isVerified) const SizedBox(width: 8),
                              _heroBadge(Icons.phone_android, 'Phone Verified', AppColors.blue),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // Rating card (Freelancer-style)
                SliverToBoxAdapter(
                  child: StreamBuilder<List<ReviewModel>>(
                    stream: firestoreService.getProviderReviews(provider.uid),
                    builder: (context, snapshot) {
                      final reviews = snapshot.data ?? [];
                      return _buildRatingCard(reviews);
                    },
                  ),
                ),

                // Stats row
                SliverToBoxAdapter(
                  child: _buildStatsRow(),
                ),

                // Body content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location
                        if (provider.serviceArea != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.teal),
                              const SizedBox(width: 4),
                              Text(
                                [provider.serviceArea, provider.city, provider.state]
                                    .where((s) => s != null && s.isNotEmpty)
                                    .join(', '),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // About
                        if (provider.serviceDescription != null && provider.serviceDescription!.isNotEmpty) ...[
                          Text(
                            provider.serviceDescription!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Services
                        if (provider.serviceCategories.isNotEmpty) ...[
                          const Text('Services Offered', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: provider.serviceCategories.map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.tealLight,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.tealDark),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Verifications section
                        _buildVerificationsSection(),
                        const SizedBox(height: 20),

                        // Reviews header + Write Review button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Reviews', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                            GestureDetector(
                              onTap: () => _showReviewDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppColors.teal, Color(0xFF00897B)]),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.rate_review_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Write Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Reviews list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: StreamBuilder<List<ReviewModel>>(
                    stream: firestoreService.getProviderReviews(provider.uid),
                    builder: (context, snapshot) {
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.rate_review_outlined, size: 36, color: AppColors.textMuted),
                                const SizedBox(height: 8),
                                const Text(
                                  'No reviews yet',
                                  style: TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Be the first to review this provider!',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final review = reviews[index];
                            return _buildReviewCard(review);
                          },
                          childCount: reviews.length,
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),

          // Bottom action bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black.withAlpha(15))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchCall(context),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(context),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Freelancer-style rating card with breakdown
  Widget _buildRatingCard(List<ReviewModel> reviews) {
    final ratingValue = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : provider.rating;
    final reviewCount = reviews.isNotEmpty ? reviews.length : provider.reviewCount;

    // Calculate rating distribution
    final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final star = r.rating.round().clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }
    final maxCount = dist.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: big rating number
          Column(
            children: [
              Text(
                ratingValue.toStringAsFixed(1),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.text, height: 1),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < ratingValue.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16,
                  color: i < ratingValue.round() ? AppColors.gold : AppColors.textMuted,
                )),
              ),
              const SizedBox(height: 4),
              Text(
                '$reviewCount review${reviewCount != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Right: rating bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = dist[star] ?? 0;
                final fraction = maxCount > 0 ? count / maxCount : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 8,
                            backgroundColor: AppColors.bg,
                            valueColor: AlwaysStoppedAnimation(
                              star >= 4 ? AppColors.green : (star >= 3 ? AppColors.gold : AppColors.orange),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Stats row (Freelancer-inspired)
  Widget _buildStatsRow() {
    final memberSince = DateFormat('MMM yyyy').format(provider.createdAt);
    final hasRate = provider.hourlyRate != null && provider.hourlyRate! > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statBadge(Icons.calendar_month_rounded, memberSince, 'Member Since', AppColors.blue),
          _divider(),
          _statBadge(
            Icons.currency_rupee_rounded,
            hasRate ? '${provider.hourlyRate!.toInt()}' : '-',
            'Per Visit',
            AppColors.green,
          ),
          _divider(),
          _statBadge(
            Icons.workspace_premium_rounded,
            provider.isVerified ? 'Yes' : 'No',
            'Verified',
            provider.isVerified ? AppColors.green : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _statBadge(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: AppColors.bg);
  }

  // Verifications section
  Widget _buildVerificationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 12),
          _verificationRow(Icons.phone_android, 'Phone Number', true),
          _verificationRow(Icons.badge_outlined, 'Aadhaar Card', provider.isVerified),
          _verificationRow(Icons.shield_outlined, 'Local Sathi ID', true),
          _verificationRow(Icons.location_on_outlined, 'Location', provider.serviceArea != null),
          _verificationRow(Icons.photo_camera_outlined, 'Profile Photo', provider.profilePhotoUrl != null),
        ],
      ),
    );
  }

  Widget _verificationRow(IconData icon, String label, bool verified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: verified ? AppColors.green : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: verified ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ),
          Icon(
            verified ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: verified ? AppColors.green : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                photoUrl: review.reviewerPhotoUrl,
                name: review.reviewerName,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(review.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Star rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _ratingColor(review.rating).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: _ratingColor(review.rating)),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _ratingColor(review.rating),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Color _ratingColor(double rating) {
    if (rating >= 4) return AppColors.green;
    if (rating >= 3) return AppColors.gold;
    return AppColors.orange;
  }

  Widget _heroBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(77),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
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
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return DateFormat('d MMM yyyy').format(dateTime);
  }

  void _showReviewDialog(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        providerUid: provider.uid,
        providerName: provider.name,
        reviewerUid: currentUser.uid,
      ),
    );
  }

  void _launchCall(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: provider.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchWhatsApp(BuildContext context) async {
    // Format phone for WhatsApp (remove +, spaces)
    final phone = provider.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Hi ${provider.name}, I found you on Local Sathi. I need help with ${provider.serviceCategories.isNotEmpty ? provider.serviceCategories.first : "a service"}.',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Review bottom sheet with voice input support
class _ReviewSheet extends StatefulWidget {
  final String providerUid;
  final String providerName;
  final String reviewerUid;

  const _ReviewSheet({
    required this.providerUid,
    required this.providerName,
    required this.reviewerUid,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _textController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  // Voice
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _toggleVoice() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    bool available = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
          });
          if (result.finalResult) {
            setState(() => _isListening = false);
          }
        },
        localeId: 'hi_IN',
        listenFor: const Duration(seconds: 30),
      );
    }
  }

  void _submit() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write or record your review')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get reviewer profile
      final authService = AuthService();
      final profile = await authService.getUserProfile(widget.reviewerUid);

      final review = ReviewModel(
        id: '',
        providerUid: widget.providerUid,
        reviewerUid: widget.reviewerUid,
        reviewerName: profile?.name ?? 'User',
        reviewerPhotoUrl: profile?.profilePhotoUrl,
        rating: _rating,
        text: _textController.text.trim(),
        createdAt: DateTime.now(),
      );

      await FirestoreService().addReview(review);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted! +15 Sathi Points earned'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
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
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Review ${widget.providerName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            const SizedBox(height: 16),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = (i + 1).toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40,
                      color: i < _rating ? AppColors.gold : AppColors.textMuted,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              _rating >= 5
                  ? 'Excellent!'
                  : _rating >= 4
                      ? 'Very Good'
                      : _rating >= 3
                          ? 'Good'
                          : _rating >= 2
                              ? 'Fair'
                              : 'Poor',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Text input with mic button
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _isListening
                    ? 'Listening... apni baat bolein'
                    : 'Write your review or tap mic to speak...',
                hintStyle: TextStyle(
                  color: _isListening ? AppColors.red : AppColors.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.bg),
                ),
                filled: true,
                fillColor: AppColors.bg,
                suffixIcon: GestureDetector(
                  onTap: _toggleVoice,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? AppColors.red : AppColors.teal,
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Recording... speak in Hindi or English',
                      style: TextStyle(fontSize: 12, color: AppColors.red),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
