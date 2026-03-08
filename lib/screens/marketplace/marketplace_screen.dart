import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/market_item_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import 'market_item_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                          const Expanded(
                            child: Text(
                              'Marketplace',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buy & sell locally',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Category filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', ...MarketItemModel.categories].map((cat) {
                    final selected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.teal : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: selected ? AppColors.teal : AppColors.bg,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Items grid
          StreamBuilder<List<MarketItemModel>>(
            stream: firestoreService.getMarketItems(
              category: _selectedCategory == 'All'
                  ? null
                  : _selectedCategory,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load items',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No items listed yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to sell something!',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ItemCard(item: items[index]),
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateItemSheet(context),
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Sell',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showCreateItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreateItemSheet(),
    );
  }
}

// ══════════════════ ITEM CARD ══════════════════

class _ItemCard extends StatelessWidget {
  final MarketItemModel item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat('#,##,###', 'en_IN');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarketItemDetailScreen(item: item),
          ),
        );
      },
      child: Container(
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
            // Photo
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.1,
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
                              size: 40, color: AppColors.teal),
                        ),
                      )
                    : Container(
                        color: AppColors.tealLight.withAlpha(60),
                        child: const Center(
                          child: Icon(Icons.shopping_bag,
                              size: 40, color: AppColors.teal),
                        ),
                      ),
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      '\u20B9${priceFormat.format(item.price.toInt())}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Condition + Negotiable
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.conditionLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (item.negotiable) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.greenLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Negotiable',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const Spacer(),

                    // Location
                    if (item.city != null && item.city!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              item.city!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════ CREATE ITEM SHEET ══════════════════

class _CreateItemSheet extends StatefulWidget {
  const _CreateItemSheet();

  @override
  State<_CreateItemSheet> createState() => _CreateItemSheetState();
}

class _CreateItemSheetState extends State<_CreateItemSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _category = MarketItemModel.categories.first;
  String _condition = 'Brand New';
  bool _negotiable = true;
  bool _isSubmitting = false;

  static const _conditionMap = {
    'Brand New': ItemCondition.newItem,
    'Like New': ItemCondition.likeNew,
    'Good': ItemCondition.good,
    'Fair': ItemCondition.fair,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final priceText = _priceController.text.trim();

    if (title.isEmpty || description.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid price'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final appProvider = context.read<AppProvider>();
    final user = appProvider.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final item = MarketItemModel(
        id: '',
        sellerId: user.uid,
        sellerName: user.name,
        sellerPhotoUrl: user.profilePhotoUrl,
        title: title,
        description: description,
        category: _category,
        price: price,
        negotiable: _negotiable,
        condition: _conditionMap[_condition] ?? ItemCondition.good,
        photos: [],
        location: appProvider.city.isNotEmpty
            ? '${appProvider.city}, ${appProvider.state}'
            : null,
        city: appProvider.city.isNotEmpty ? appProvider.city : null,
        state: appProvider.state.isNotEmpty ? appProvider.state : null,
        latitude: appProvider.latitude,
        longitude: appProvider.longitude,
        createdAt: DateTime.now(),
      );

      await FirestoreService().createMarketItem(item);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item listed successfully!'),
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
            content: Text('Failed to list item: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            const Text(
              'Sell an Item',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Item title',
                prefixIcon: Icon(Icons.title, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Describe your item...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child:
                      Icon(Icons.description, color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                prefixIcon:
                    Icon(Icons.category, color: AppColors.textMuted),
              ),
              items: MarketItemModel.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 12),

            // Price
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Price',
                prefixIcon: Icon(Icons.currency_rupee,
                    color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            // Condition dropdown
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.star_outline,
                    color: AppColors.textMuted),
              ),
              items: _conditionMap.keys
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _condition = val);
              },
            ),
            const SizedBox(height: 12),

            // Negotiable toggle
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Negotiable',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  Switch(
                    value: _negotiable,
                    onChanged: (val) => setState(() => _negotiable = val),
                    activeColor: AppColors.teal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'List Item for Sale',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
