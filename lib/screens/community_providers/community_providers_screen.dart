import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/community_provider_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import 'add_provider_screen.dart';

class CommunityProvidersScreen extends StatefulWidget {
  final String? initialCategory;
  const CommunityProvidersScreen({super.key, this.initialCategory});

  @override
  State<CommunityProvidersScreen> createState() => _CommunityProvidersScreenState();
}

class _CommunityProvidersScreenState extends State<CommunityProvidersScreen> {
  final _firestoreService = FirestoreService();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) _selectedCategory = widget.initialCategory!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Local Directory', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.teal),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProviderScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or area...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: AppColors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Category pills
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', ...AppConstants.allCategories].map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.teal : Colors.grey.shade300),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Provider list
          Expanded(
            child: StreamBuilder<List<CommunityProvider>>(
              stream: _firestoreService.getApprovedCommunityProviders(
                category: _selectedCategory == 'All' ? null : _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.teal));
                }

                var providers = snapshot.data ?? [];

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  providers = providers.where((p) =>
                      p.name.toLowerCase().contains(_searchQuery) ||
                      p.area.toLowerCase().contains(_searchQuery) ||
                      p.category.toLowerCase().contains(_searchQuery)).toList();
                }

                if (providers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('No providers found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        const Text('Be the first to add one!', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProviderScreen())),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Provider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: providers.length,
                  itemBuilder: (context, index) => _providerCard(providers[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProviderScreen())),
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Provider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _providerCard(CommunityProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.teal.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.teal),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (provider.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppColors.teal, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(provider.category, style: const TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.gold),
                    const SizedBox(width: 2),
                    Text(
                      provider.rating > 0 ? provider.rating.toStringAsFixed(1) : 'New',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: provider.rating > 0 ? AppColors.gold : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Area + badges
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(provider.area, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ),
              if (provider.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.teal.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, size: 12, color: AppColors.teal),
                      SizedBox(width: 3),
                      Text('Verified by Local Sathi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal)),
                    ],
                  ),
                ),
            ],
          ),

          if (provider.description != null && provider.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(provider.description!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],

          if (provider.helpedCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Helped ${provider.helpedCount} people find this service',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              // Call Now - primary CTA
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    _firestoreService.incrementHelpedCount(provider.id);
                    final uri = Uri(scheme: 'tel', path: provider.phone);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.call, size: 18, color: Colors.white),
                  label: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Share
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Share.share(
                      '${provider.name} - ${provider.category}\n${provider.area}\nCall: ${provider.phone}\n\nFound on Local Sathi - https://localsathitechnologies.in',
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
