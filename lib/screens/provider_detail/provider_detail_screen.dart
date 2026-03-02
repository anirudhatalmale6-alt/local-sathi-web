import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../services/firestore_service.dart';
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
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 20,
                                    ),
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            provider.serviceCategories.isNotEmpty
                                ? provider.serviceCategories.first
                                : 'Service Provider',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (provider.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 14, color: AppColors.greenLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Aadhaar Verified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.greenLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // Stats row
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.bg,
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _metaItem(provider.rating.toStringAsFixed(1), 'Rating'),
                        _metaItem('${provider.reviewCount}', 'Reviews'),
                        _metaItem(provider.serviceArea ?? 'Nearby', 'Area'),
                      ],
                    ),
                  ),
                ),

                // Body
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                                provider.serviceArea!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // About
                        if (provider.serviceDescription != null) ...[
                          Text(
                            provider.serviceDescription!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Services
                        if (provider.serviceCategories.isNotEmpty) ...[
                          const Text(
                            'Services Offered',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...provider.serviceCategories.map((s) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      s,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 20),
                        ],

                        // Reviews
                        const Text(
                          'Reviews',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'No reviews yet. Be the first to review!',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final review = reviews[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
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
                                        size: 32,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review.reviewerName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                Icons.star,
                                                size: 12,
                                                color: i < review.rating.round()
                                                    ? AppColors.gold
                                                    : AppColors.textMuted.withOpacity(0.3),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    review.text,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
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
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.black.withOpacity(0.06)),
              ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Chat feature coming soon!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

  Widget _metaItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  void _launchCall(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: provider.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
