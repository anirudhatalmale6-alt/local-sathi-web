import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/avatar_widget.dart';
import 'user_profile_screen.dart';

class FollowListScreen extends StatelessWidget {
  final String uid;
  final String name;
  final int initialTab;

  const FollowListScreen({
    super.key,
    required this.uid,
    required this.name,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(name),
          bottom: const TabBar(
            labelColor: AppColors.teal,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.teal,
            tabs: [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _UserList(stream: FirestoreService().getFollowers(uid), emptyMessage: 'No followers yet'),
            _UserList(stream: FirestoreService().getFollowing(uid), emptyMessage: 'Not following anyone'),
          ],
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  final String emptyMessage;

  const _UserList({required this.stream, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text(emptyMessage, style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: AvatarWidget(photoUrl: user.profilePhotoUrl, name: user.name, size: 44),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                  user.isProvider ? user.serviceCategories.join(', ') : (user.city ?? user.localSathiId),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                trailing: user.isOnline
                    ? Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
                      )
                    : null,
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
