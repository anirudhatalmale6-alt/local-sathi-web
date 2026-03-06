import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/avatar_widget.dart';
import 'user_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  List<UserModel> _suggestedUsers = [];
  List<UserModel> _searchResults = [];
  bool _loading = true;
  bool _searching = false;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadSuggested();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggested() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    final appProvider = context.read<AppProvider>();
    try {
      final users = await _firestoreService.getSuggestedUsers(
        currentUid,
        city: appProvider.city.isNotEmpty ? appProvider.city : null,
        state: appProvider.state.isNotEmpty ? appProvider.state : null,
      );
      if (mounted) setState(() { _suggestedUsers = users; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      setState(() { _searching = false; _searchResults = []; });
      return;
    }
    final q = query.toLowerCase();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final results = _suggestedUsers.where((u) {
      if (u.uid == currentUid) return false;
      return u.name.toLowerCase().contains(q) ||
          u.localSathiId.toLowerCase().contains(q) ||
          (u.city?.toLowerCase().contains(q) ?? false) ||
          u.serviceCategories.any((c) => c.toLowerCase().contains(q));
    }).toList();
    setState(() { _searching = true; _searchResults = results; });
  }

  List<UserModel> get _filteredUsers {
    final source = _searching ? _searchResults : _suggestedUsers;
    if (_filter == 'All') return source;
    if (_filter == 'Providers') return source.where((u) => u.isProvider).toList();
    if (_filter == 'Nearby') {
      final appProvider = context.read<AppProvider>();
      return source.where((u) => u.city?.toLowerCase() == appProvider.city.toLowerCase()).toList();
    }
    if (_filter == 'Verified') return source.where((u) => u.isVerified).toList();
    return source;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Discover People'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search by name, ID, city, or service...',
                prefixIcon: const Icon(Icons.search, color: AppColors.teal),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Providers', 'Nearby', 'Verified'].map((f) {
                final active = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textSecondary,
                    )),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = f),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.teal,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),

          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.explore_off, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            const Text('No users found', style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSuggested,
                        color: AppColors.teal,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) => _userCard(_filteredUsers[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  AvatarWidget(photoUrl: user.profilePhotoUrl, name: user.name, size: 52),
                  if (user.isOnline)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(user.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified)
                          Icon(Icons.check_circle, size: 16, color: AppColors.green),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.isProvider
                          ? user.serviceCategories.take(2).join(', ')
                          : user.localSathiId,
                      style: const TextStyle(fontSize: 12, color: AppColors.tealDark, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    if (user.city != null && user.city!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Text(
                            [user.city, user.state].where((s) => s != null && s.isNotEmpty).join(', '),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Follow count
              Column(
                children: [
                  Text('${user.followersCount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal)),
                  const Text('followers', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
