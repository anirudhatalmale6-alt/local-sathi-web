import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/help_request_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import 'quick_help_detail_screen.dart';

class QuickHelpScreen extends StatefulWidget {
  const QuickHelpScreen({super.key});

  @override
  State<QuickHelpScreen> createState() => _QuickHelpScreenState();
}

class _QuickHelpScreenState extends State<QuickHelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ask for Help',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      // App bar row
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
                              'Quick Help',
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
                      const SizedBox(height: 6),
                      const Text(
                        'Get help from nearby providers',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: AppColors.tealDark,
                          unselectedLabelColor: Colors.white70,
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Outfit',
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Outfit',
                          ),
                          labelPadding: EdgeInsets.zero,
                          padding: const EdgeInsets.all(3),
                          tabs: const [
                            Tab(text: 'All Requests'),
                            Tab(text: 'My Requests'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Tab content ──
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RequestsList(
                  stream: _firestoreService.getHelpRequests(),
                  emptyIcon: Icons.handshake_outlined,
                  emptyTitle: 'No help requests yet',
                  emptySubtitle: 'Be the first to ask for help!',
                ),
                _RequestsList(
                  stream: _firestoreService.getMyHelpRequests(user.uid),
                  emptyIcon: Icons.inbox_outlined,
                  emptyTitle: 'No requests from you',
                  emptySubtitle: 'Tap + to create your first help request',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateHelpRequestSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Requests list widget (shared by both tabs)
// ═══════════════════════════════════════════════════════════════

class _RequestsList extends StatelessWidget {
  final Stream<List<HelpRequestModel>> stream;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _RequestsList({
    required this.stream,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HelpRequestModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  'Could not load requests',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(emptyIcon, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(
                  emptyTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  emptySubtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HelpRequestCard(request: requests[index]),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Single help request card
// ═══════════════════════════════════════════════════════════════

class _HelpRequestCard extends StatelessWidget {
  final HelpRequestModel request;

  const _HelpRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuickHelpDetailScreen(request: request),
          ),
        );
      },
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
            // Top row: title + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _statusChip(request.status),
              ],
            ),
            const SizedBox(height: 10),

            // Category chip + budget
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealDark,
                    ),
                  ),
                ),
                if (request.budget != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_rupee,
                            size: 12, color: AppColors.green),
                        Text(
                          request.budget!.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Bottom row: location, time, bids
            Row(
              children: [
                if (request.location != null &&
                    request.location!.isNotEmpty) ...[
                  Icon(Icons.location_on,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      request.location!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (request.city != null &&
                    request.city!.isNotEmpty) ...[
                  Icon(Icons.location_on,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      request.city!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Icon(Icons.access_time, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Text(
                  _timeAgo(request.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                // Bid count badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: request.bidCount > 0
                        ? AppColors.orangeLight
                        : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gavel,
                        size: 12,
                        color: request.bidCount > 0
                            ? AppColors.orange
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${request.bidCount} bid${request.bidCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: request.bidCount > 0
                              ? AppColors.orange
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(HelpStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case HelpStatus.open:
        bg = AppColors.greenLight;
        fg = AppColors.green;
        label = 'Open';
        break;
      case HelpStatus.inProgress:
        bg = AppColors.orangeLight;
        fg = AppColors.orange;
        label = 'In Progress';
        break;
      case HelpStatus.completed:
        bg = AppColors.tealLight;
        fg = AppColors.tealDark;
        label = 'Completed';
        break;
      case HelpStatus.cancelled:
        bg = AppColors.redLight;
        fg = AppColors.red;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
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
// Create help request bottom sheet
// ═══════════════════════════════════════════════════════════════

class _CreateHelpRequestSheet extends StatefulWidget {
  const _CreateHelpRequestSheet();

  @override
  State<_CreateHelpRequestSheet> createState() =>
      _CreateHelpRequestSheetState();
}

class _CreateHelpRequestSheetState extends State<_CreateHelpRequestSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in title, description and category'),
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
      final appProvider = context.read<AppProvider>();
      final user = appProvider.currentUser!;
      final budgetText = _budgetController.text.trim();
      final budget =
          budgetText.isNotEmpty ? double.tryParse(budgetText) : null;

      final request = HelpRequestModel(
        id: '',
        requesterId: user.uid,
        requesterName: user.name,
        requesterPhotoUrl: user.profilePhotoUrl,
        title: title,
        description: description,
        category: _selectedCategory!,
        budget: budget,
        location: user.serviceArea ?? user.city,
        city: user.city ?? appProvider.city,
        state: user.state ?? appProvider.state,
        latitude: user.latitude ?? appProvider.latitude,
        longitude: user.longitude ?? appProvider.longitude,
        createdAt: DateTime.now(),
      );

      await FirestoreService().createHelpRequest(request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Help request posted!'),
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
            content: Text('Failed to post: $e'),
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
              'Ask for Help',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Describe what you need and providers can bid to help you',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            // Title field
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'e.g. Need plumber for leaking pipe',
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

            // Description field
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Describe your problem in detail...',
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

            // Category dropdown
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text(
                    'Select a category',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textMuted),
                  items: AppConstants.allCategories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.text,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Budget field (optional)
            const Text(
              'Budget (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _budgetController,
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
                        'Post Help Request',
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
