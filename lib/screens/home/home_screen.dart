import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/ad_service.dart';
import '../../models/user_model.dart';
import '../../widgets/provider_card.dart';
import '../../widgets/feedback_bar.dart';
import '../../widgets/banner_ad_widget.dart';
import '../notifications/notifications_screen.dart';
import '../provider_detail/provider_detail_screen.dart';
import '../emergency/emergency_sheet.dart';
import '../wallet/wallet_screen.dart';
import '../work_nearby/work_nearby_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../quick_help/quick_help_screen.dart';
import '../jobs/jobs_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../subscription/subscription_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final firestoreService = FirestoreService();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = kIsWeb && screenWidth >= 900;
    final isWide = screenWidth >= 1200;

    // Responsive grid columns for categories
    int categoryColumns = 3;
    if (isWide) {
      categoryColumns = 6;
    } else if (isDesktop) {
      categoryColumns = 5;
    } else if (screenWidth >= 600) {
      categoryColumns = 4;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Header
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
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 20, 12,
                    isDesktop ? 32 : 20, 20,
                  ),
                  child: isDesktop
                      ? _buildDesktopHeader(context, appProvider)
                      : _buildMobileHeader(context, appProvider),
                ),
              ),
            ),
          ),

          // Content area with max-width on desktop
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Community Stats Bar
                    StreamBuilder<Map<String, int>>(
                      stream: firestoreService.getCommunityStatsStream(),
                      builder: (context, snapshot) {
                        final stats = snapshot.data;
                        return Container(
                          margin: EdgeInsets.fromLTRB(isDesktop ? 32 : 20, 16, isDesktop ? 32 : 20, 0),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _liveStatItem(Icons.people_rounded, '${stats?['totalUsers'] ?? '-'}', 'Members', AppColors.blue),
                              Container(width: 1, height: 28, color: AppColors.bg),
                              _liveStatItem(Icons.handyman_rounded, '${stats?['totalProviders'] ?? '-'}', 'Providers', AppColors.orange),
                              Container(width: 1, height: 28, color: AppColors.bg),
                              _liveStatItem(Icons.verified_rounded, '${stats?['verifiedProfiles'] ?? '-'}', 'Verified', AppColors.green),
                            ],
                          ),
                        );
                      },
                    ),

                    // Banner Ad
                    Padding(
                      padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 20, 12, isDesktop ? 32 : 20, 0),
                      child: const BannerAdWidget(),
                    ),

                    // Quick Actions
                    Padding(
                      padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 20, 16, isDesktop ? 32 : 20, 0),
                      child: isDesktop
                          ? _buildDesktopQuickActions(context, appProvider)
                          : _buildMobileQuickActions(context, appProvider),
                    ),

                    // Features Section
                    Padding(
                      padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 20, 16, isDesktop ? 32 : 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Features',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _featureCard(
                                  context,
                                  icon: Icons.flash_on_rounded,
                                  label: isDesktop ? 'Quick Help' : 'Quick\nHelp',
                                  gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF26A69A)]),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickHelpScreen())),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _featureCard(
                                  context,
                                  icon: Icons.work_rounded,
                                  label: isDesktop ? 'Job Board' : 'Job\nBoard',
                                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsScreen())),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _featureCard(
                                  context,
                                  icon: Icons.storefront_rounded,
                                  label: isDesktop ? 'Marketplace' : 'Market\nPlace',
                                  gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF9800)]),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _featureCard(
                                  context,
                                  icon: Icons.search_rounded,
                                  label: isDesktop ? 'Lost & Found' : 'Lost &\nFound',
                                  gradient: const LinearGradient(colors: [Color(0xFF6A4C93), Color(0xFF9D84B7)]),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LostFoundScreen())),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Services header
                    Padding(
                      padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 20, 20, isDesktop ? 32 : 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Services',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                          ),
                          GestureDetector(
                            onTap: () => appProvider.setTabIndex(1),
                            child: const Text(
                              'See all',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.teal),
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

          // Category grid (responsive columns)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 20),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = isDesktop ? 1200.0 : constraints.crossAxisExtent;
                final sideMargin = isDesktop
                    ? ((constraints.crossAxisExtent - maxWidth) / 2).clamp(0.0, double.infinity)
                    : 0.0;
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: sideMargin),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: categoryColumns,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: isDesktop ? 1.1 : 1.0,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = AppConstants.categories[index];
                        return GestureDetector(
                          onTap: () => appProvider.setTabIndex(1),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: isDesktop ? 52 : 48,
                                    height: isDesktop ? 52 : 48,
                                    decoration: BoxDecoration(
                                      color: Color(cat['color'] as int),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        cat['icon'] as String,
                                        style: TextStyle(fontSize: isDesktop ? 26 : 24),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cat['name'] as String,
                                    style: TextStyle(
                                      fontSize: isDesktop ? 13 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: AppConstants.categories.length,
                    ),
                  ),
                );
              },
            ),
          ),

          // Banner Ad (between sections)
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 20, 16, isDesktop ? 32 : 20, 0),
                  child: const BannerAdWidget(),
                ),
              ),
            ),
          ),

          // Featured Providers section
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 20, 24, isDesktop ? 32 : 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Featured Providers',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      GestureDetector(
                        onTap: () => appProvider.setTabIndex(1),
                        child: const Text(
                          'See all',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.teal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Featured providers
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                child: SizedBox(
                  height: 180,
                  child: StreamBuilder<List<UserModel>>(
                    stream: firestoreService.getFeaturedProviders(limit: isDesktop ? 10 : 5),
                    builder: (context, snapshot) {
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyProviders();
                      }

                      final providers = snapshot.data!;
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 20),
                        itemCount: providers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          return ProviderCard(
                            provider: providers[index],
                            isFeatured: true,
                            onTap: () {
                              AdService().onUserAction();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProviderDetailScreen(
                                    provider: providers[index],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Feedback bar
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: appProvider.currentUser != null
                      ? FeedbackBar(
                          userUid: appProvider.currentUser!.uid,
                          userName: appProvider.currentUser!.name,
                          userLocalSathiId: appProvider.currentUser!.localSathiId,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  // Desktop header: single row with greeting, location, search, notification
  Widget _buildDesktopHeader(BuildContext context, AppProvider appProvider) {
    return Row(
      children: [
        // Greeting + location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text(
                    appProvider.city.isNotEmpty
                        ? '${appProvider.city}, ${appProvider.state}'
                        : 'Detecting location...',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Search bar (wider on desktop)
        GestureDetector(
          onTap: () => appProvider.setTabIndex(1),
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 22, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Text(
                  'Find electricians, plumbers, tutors...',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Notification bell
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
            child: const Center(
              child: Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile header: original stacked layout
  Widget _buildMobileHeader(BuildContext context, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _greeting(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: const Center(
                  child: Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.8)),
            const SizedBox(width: 4),
            Text(
              appProvider.city.isNotEmpty
                  ? '${appProvider.city}, ${appProvider.state}'
                  : 'Detecting location...',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => appProvider.setTabIndex(1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 22, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Text(
                  'Find electricians, plumbers, tutors...',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Desktop quick actions: wrap in a nice grid
  Widget _buildDesktopQuickActions(BuildContext context, AppProvider appProvider) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _desktopActionButton(
          context,
          icon: Icons.emergency,
          label: 'SOS Emergency',
          gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF5252)]),
          shadowColor: const Color(0xFFE53935),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const EmergencySheet(),
          ),
        ),
        _desktopActionButton(
          context,
          icon: Icons.stars_rounded,
          label: 'Sathi Wallet',
          gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFFA726)]),
          shadowColor: const Color(0xFFFF8F00),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
        ),
        _desktopActionButton(
          context,
          icon: Icons.smart_toy_rounded,
          label: 'Sathi AI',
          gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)]),
          shadowColor: const Color(0xFF7B1FA2),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
        ),
        if (!AdService().isPremium)
          _desktopActionButton(
            context,
            icon: Icons.diamond,
            label: 'Go PRO',
            gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFFCA28)]),
            shadowColor: const Color(0xFFFF6F00),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
          ),
        if (appProvider.currentUser?.isProvider == true)
          _desktopActionButton(
            context,
            icon: Icons.work,
            label: 'Work Near Me',
            gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
            shadowColor: const Color(0xFF1565C0),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkNearbyScreen())),
          ),
      ],
    );
  }

  Widget _desktopActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Gradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: shadowColor.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile quick actions: original row layout
  Widget _buildMobileQuickActions(BuildContext context, AppProvider appProvider) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const EmergencySheet(),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF5252)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFFE53935).withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text('SOS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFFA726)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFFFF8F00).withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text('Wallet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF7B1FA2).withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('\u{1F916}', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 6),
                  Text('AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (!AdService().isPremium)
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFFCA28)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF6F00).withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.diamond, color: Colors.white, size: 20),
                    SizedBox(width: 4),
                    Text('PRO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        if (!AdService().isPremium)
          const SizedBox(width: 10),
        if (appProvider.currentUser?.isProvider == true)
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkNearbyScreen())),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text('Jobs', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyProviders() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 32, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(
              'Service providers will appear here',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color, height: 1),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! \u{1F64F}';
    if (hour < 17) return 'Good Afternoon! \u{1F64F}';
    return 'Good Evening! \u{1F64F}';
  }
}
