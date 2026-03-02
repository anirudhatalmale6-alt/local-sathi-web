import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import 'home_screen.dart';
import '../search/search_screen.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    SizedBox(), // Placeholder for center FAB
    FeedScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      appProvider.loadCurrentUser();
      appProvider.loadLocation();
    });
  }

  void _onNavTap(int index) {
    if (index == 2) {
      // Center button = compose post
      _openCompose();
      return;
    }
    context.read<AppProvider>().setTabIndex(index);
  }

  void _openCompose() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ComposeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final idx = appProvider.currentTabIndex;

        return Scaffold(
          body: IndexedStack(
            index: idx < 2 ? idx : (idx > 2 ? idx - 1 : 0),
            children: [
              _screens[0],
              _screens[1],
              _screens[3],
              _screens[4],
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    _navItem(0, Icons.home_rounded, 'Home', idx == 0),
                    _navItem(1, Icons.search_rounded, 'Search', idx == 1),
                    _centerButton(),
                    _navItem(3, Icons.article_rounded, 'Feed', idx == 3),
                    _navItem(4, Icons.person_rounded, 'Profile', idx == 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(height: 4),
            Icon(
              icon,
              size: 24,
              color: active ? AppColors.teal : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppColors.teal : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerButton() {
    return Expanded(
      child: GestureDetector(
        onTap: _openCompose,
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.tealBlueGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet();

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _textController = TextEditingController();
  int _charCount = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final user = appProvider.currentUser;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).viewInsets.top + 80),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                ElevatedButton(
                  onPressed: _charCount > 0 ? () async {
                    final text = _textController.text.trim();
                    if (text.isEmpty || user == null) return;

                    final post = PostModel(
                      id: '',
                      authorUid: user.uid,
                      authorName: user.name,
                      authorLocalSathiId: user.localSathiId,
                      text: text,
                      createdAt: DateTime.now(),
                    );

                    try {
                      await FirestoreService().createPost(post);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Post published!'),
                          backgroundColor: AppColors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to post: $e'),
                          backgroundColor: AppColors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } : null,
                  child: const Text('Post'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.orange,
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${user?.name ?? 'User'} ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '· ${user?.localSathiId ?? ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Text area
            TextField(
              controller: _textController,
              maxLines: 5,
              maxLength: 280,
              onChanged: (v) => setState(() => _charCount = v.length),
              decoration: const InputDecoration(
                hintText: "What's happening in your neighbourhood?",
                border: InputBorder.none,
                fillColor: Colors.transparent,
                counterText: '',
              ),
              autofocus: true,
            ),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.location_on, color: AppColors.teal, size: 22),
                Text(
                  '$_charCount / 280',
                  style: TextStyle(
                    fontSize: 12,
                    color: _charCount > 250 ? AppColors.red : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
