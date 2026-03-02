import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import 'avatar_widget.dart';
import 'verified_badge.dart';

class ProviderCard extends StatelessWidget {
  final UserModel provider;
  final bool isFeatured;
  final VoidCallback? onTap;

  const ProviderCard({
    super.key,
    required this.provider,
    this.isFeatured = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isFeatured) {
      return _buildFeaturedCard(context);
    }
    return _buildListCard(context);
  }

  Widget _buildFeaturedCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: provider.isSponsored
              ? Border.all(color: AppColors.gold, width: 1.5)
              : null,
          gradient: provider.isSponsored
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFDE7), Colors.white],
                  stops: [0, 0.4],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.isSponsored)
              Align(
                alignment: Alignment.topRight,
                child: const SponsoredBadge(),
              ),
            Row(
              children: [
                AvatarWidget(
                  photoUrl: provider.profilePhotoUrl,
                  name: provider.name,
                  size: 50,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.serviceCategories.isNotEmpty
                            ? provider.serviceCategories.first
                            : 'Service Provider',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (provider.isVerified) const VerifiedBadge(showText: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: 14,
                        color: i < provider.rating.round()
                            ? AppColors.gold
                            : AppColors.textMuted.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      provider.serviceArea ?? 'Nearby',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: provider.isSponsored
              ? Border.all(color: AppColors.gold, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AvatarWidget(
              photoUrl: provider.profilePhotoUrl,
              name: provider.name,
              size: 54,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (provider.isSponsored) ...[
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            Icon(Icons.star, size: 12, color: AppColors.gold),
                            const SizedBox(width: 2),
                            Text(
                              'Sponsored',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      provider.serviceCategories.isNotEmpty
                          ? provider.serviceCategories.first
                          : 'Service Provider',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tealDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          size: 12,
                          color: i < provider.rating.round()
                              ? AppColors.gold
                              : AppColors.textMuted.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.rating.toStringAsFixed(1)} · ${provider.reviewCount} reviews',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Book', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
