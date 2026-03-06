import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/provider_card.dart';
import '../provider_detail/provider_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;
  const SearchScreen({super.key, this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _firestoreService = FirestoreService();
  late String _selectedCategory;
  double _radiusKm = 5;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ['All', ...AppConstants.allCategories];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Top bar
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 22, color: AppColors.textMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText: 'Search providers, services...',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  fillColor: Colors.transparent,
                                  filled: true,
                                ),
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
          ),

          // Filters
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Location filter
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => _RadiusPicker(
                          current: _radiusKm,
                          onChanged: (v) {
                            setState(() => _radiusKm = v);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: AppColors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Within ${_radiusKm.toInt()} km',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, size: 16, color: AppColors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category pills
                  ...allCategories.map((cat) {
                    final active = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.teal : Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: active ? AppColors.teal : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: active ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Results
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            sliver: StreamBuilder<List<UserModel>>(
              stream: _firestoreService.searchProviders(
                category: _selectedCategory == 'All' ? null : _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
                  );
                }

                final providers = snapshot.data ?? [];
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? providers
                    : providers.where((p) =>
                        p.name.toLowerCase().contains(query) ||
                        p.serviceCategories.any((c) => c.toLowerCase().contains(query)))
                        .toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No providers found',
                            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different category or location',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProviderCard(
                          provider: filtered[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProviderDetailScreen(
                                  provider: filtered[index],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: filtered.length,
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

class _RadiusPicker extends StatelessWidget {
  final double current;
  final ValueChanged<double> onChanged;

  const _RadiusPicker({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [2.0, 5.0, 10.0, 25.0, 50.0];
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Radius',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...options.map((r) => ListTile(
                title: Text('Within ${r.toInt()} km'),
                trailing: current == r
                    ? const Icon(Icons.check_circle, color: AppColors.teal)
                    : null,
                onTap: () => onChanged(r),
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
