import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chat_screen.dart';
import 'follow_list_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final UserModel user;
  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _firestoreService = FirestoreService();
  bool _isFollowing = false;
  bool _loading = true;
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid == _user.uid) {
      setState(() => _loading = false);
      return;
    }
    final following = await _firestoreService.isFollowing(currentUid, _user.uid);
    if (mounted) setState(() { _isFollowing = following; _loading = false; });
  }

  Future<void> _toggleFollow() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    setState(() => _loading = true);
    try {
      if (_isFollowing) {
        await _firestoreService.unfollowUser(currentUid, _user.uid);
        _user = _user.copyWith(followersCount: _user.followersCount - 1);
      } else {
        await _firestoreService.followUser(currentUid, _user.uid);
        _user = _user.copyWith(followersCount: _user.followersCount + 1);
      }
      _isFollowing = !_isFollowing;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openChat() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(
        otherUid: _user.uid,
        otherName: _user.name,
        otherPhotoUrl: _user.profilePhotoUrl,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = currentUid == _user.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Large profile photo
                      Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 4),
                          gradient: _user.profilePhotoUrl == null
                              ? const LinearGradient(colors: [AppColors.orange, Color(0xFFFF9800)])
                              : null,
                          image: _user.profilePhotoUrl != null
                              ? DecorationImage(image: NetworkImage(_user.profilePhotoUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _user.profilePhotoUrl == null
                            ? Center(child: Text(
                                _user.name.isNotEmpty ? _user.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white),
                              ))
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Name
                      Text(_user.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),

                      // LS ID + verification
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(_user.localSathiId,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                          if (_user.isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 12, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text('Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_user.bio != null && _user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_user.bio!, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)), textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 4),

                      // Online status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _user.isOnline ? AppColors.green : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _user.isOnline ? 'Online' : (_user.lastSeen != null ? 'Last seen ${_timeAgo(_user.lastSeen!)}' : 'Offline'),
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Stats card
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statTap(
                      '${_user.followersCount}', 'Followers',
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => FollowListScreen(uid: _user.uid, name: _user.name, initialTab: 0),
                      )),
                    ),
                    Container(width: 1, height: 30, color: AppColors.bg),
                    _statTap(
                      '${_user.followingCount}', 'Following',
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => FollowListScreen(uid: _user.uid, name: _user.name, initialTab: 1),
                      )),
                    ),
                    Container(width: 1, height: 30, color: AppColors.bg),
                    _statItem('${_user.rating.toStringAsFixed(1)} \u2605', 'Rating',
                      _user.rating >= 4 ? AppColors.green : AppColors.gold),
                    Container(width: 1, height: 30, color: AppColors.bg),
                    _statItem('${_user.reviewCount}', 'Reviews', AppColors.blue),
                  ],
                ),
              ),
            ),

            // Action buttons
            if (!isOwnProfile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _toggleFollow,
                        icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add, size: 18),
                        label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey[300] : AppColors.teal,
                          foregroundColor: _isFollowing ? AppColors.text : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openChat,
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Details card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _sectionCard('Details', Column(
                children: [
                  if (_user.isProvider && _user.serviceCategories.isNotEmpty) ...[
                    _detailRow(Icons.work, _user.serviceCategories.join(', ')),
                  ],
                  if (_user.serviceDescription != null && _user.serviceDescription!.isNotEmpty)
                    _detailRow(Icons.description_outlined, _user.serviceDescription!),
                  _detailRow(Icons.location_on, [_user.serviceArea, _user.city, _user.state]
                      .where((s) => s != null && s.isNotEmpty).join(', ').isNotEmpty
                      ? [_user.serviceArea, _user.city, _user.state].where((s) => s != null && s.isNotEmpty).join(', ')
                      : 'Location not set'),
                  if (_user.hourlyRate != null)
                    _detailRow(Icons.currency_rupee, '\u20B9${_user.hourlyRate!.toInt()}/visit'),
                  _detailRow(Icons.person, _user.isProvider ? 'Service Provider' : 'Community Member'),
                  _detailRow(Icons.calendar_today, 'Joined ${_monthName(_user.createdAt.month)} ${_user.createdAt.year}'),
                ],
              )),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statTap(String value, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.teal)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  String _monthName(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${_monthName(dt.month)} ${dt.day}';
  }
}
