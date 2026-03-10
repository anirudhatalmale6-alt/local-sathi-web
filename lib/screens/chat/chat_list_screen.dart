import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../models/conversation_model.dart';
import '../../models/group_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/avatar_widget.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();

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
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const Center(child: Text('Not logged in'));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.teal,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.teal,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 20), text: 'Chats'),
            Tab(icon: Icon(Icons.group_outlined, size: 20), text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChatsTab(currentUid: currentUid, firestoreService: _firestoreService),
          _GroupsTab(currentUid: currentUid, firestoreService: _firestoreService),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.teal,
        onPressed: () {
          if (_tabController.index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
          }
        },
        child: Icon(
          _tabController.index == 1 ? Icons.group_add : Icons.edit,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ChatsTab extends StatefulWidget {
  final String currentUid;
  final FirestoreService firestoreService;

  const _ChatsTab({required this.currentUid, required this.firestoreService});

  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab> {
  // Track which conversations we've already enriched to avoid repeated lookups
  final _enrichedConvIds = <String>{};
  // Local name cache for conversations with missing names
  final _nameCache = <String, String>{};
  final _photoCache = <String, String?>{};

  /// For conversations missing participant names, fetch from users collection
  /// and update the conversation document (one-time fix per conversation).
  void _enrichMissingNames(List<ConversationModel> convs) {
    for (final conv in convs) {
      if (_enrichedConvIds.contains(conv.id)) continue;
      final otherUid = conv.otherUid(widget.currentUid);
      final name = conv.participantNames[otherUid];
      if (name == null || name.isEmpty || name == 'User') {
        _enrichedConvIds.add(conv.id);
        // Fetch the user profile and update the conversation
        FirebaseFirestore.instance.collection('users').doc(otherUid).get().then((doc) {
          if (doc.exists) {
            final userName = doc.data()?['name'] as String? ?? 'User';
            final userPhoto = doc.data()?['profilePhotoUrl'] as String?;
            // Update conversation document so future loads have the correct name
            FirebaseFirestore.instance.collection('conversations').doc(conv.id).update({
              'participantNames.$otherUid': userName,
              if (userPhoto != null) 'participantPhotos.$otherUid': userPhoto,
            });
            // Also cache locally for immediate display
            if (mounted) {
              setState(() {
                _nameCache[otherUid] = userName;
                _photoCache[otherUid] = userPhoto;
              });
            }
          }
        });
      }
    }
  }

  /// Get display name, checking local cache if Firestore data is missing
  String _getDisplayName(ConversationModel conv) {
    final name = conv.displayName(widget.currentUid);
    if (name != 'User') return name;
    final otherUid = conv.otherUid(widget.currentUid);
    return _nameCache[otherUid] ?? 'User';
  }

  /// Get display photo, checking local cache if Firestore data is missing
  String? _getDisplayPhoto(ConversationModel conv) {
    final photo = conv.displayPhoto(widget.currentUid);
    if (photo != null) return photo;
    final otherUid = conv.otherUid(widget.currentUid);
    return _photoCache[otherUid];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConversationModel>>(
      stream: widget.firestoreService.getConversationsFiltered(widget.currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }
        final convs = snapshot.data ?? [];
        if (convs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 56, color: AppColors.textMuted.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text('No messages yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                const Text('Start a conversation from someone\'s profile', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          );
        }
        // Enrich any conversations with missing names
        _enrichMissingNames(convs);

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: convs.length,
          itemBuilder: (context, index) {
            final conv = convs[index];
            final unread = conv.unreadFor(widget.currentUid);
            return _conversationTile(context, conv, unread);
          },
        );
      },
    );
  }

  Widget _conversationTile(BuildContext context, ConversationModel conv, int unread) {
    final displayName = _getDisplayName(conv);
    final displayPhoto = _getDisplayPhoto(conv);
    final otherUid = conv.otherUid(widget.currentUid);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: AvatarWidget(
        photoUrl: displayPhoto,
        name: displayName,
        size: 48,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.text,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _timeAgo(conv.lastMessageTime),
            style: TextStyle(
              fontSize: 11,
              color: unread > 0 ? AppColors.teal : AppColors.textMuted,
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (conv.lastSenderUid == widget.currentUid)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.done_all, size: 14, color: AppColors.teal),
            ),
          Expanded(
            child: Text(
              conv.lastMessage,
              style: TextStyle(
                fontSize: 13,
                color: unread > 0 ? AppColors.text : AppColors.textMuted,
                fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$unread', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatScreen(
            otherUid: otherUid,
            otherName: displayName,
            otherPhotoUrl: displayPhoto,
          ),
        ));
      },
      onLongPress: () => _showChatOptions(context, conv, otherUid, displayName),
    );
  }

  void _showChatOptions(BuildContext context, ConversationModel conv, String otherUid, String otherName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(otherName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.red),
                title: const Text('Delete Chat', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Remove from your chat list', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteChat(conv, otherName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: AppColors.orange),
                title: const Text('Block User', style: TextStyle(fontSize: 14)),
                subtitle: const Text('They won\'t be able to message you', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmBlockUser(otherUid, otherName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteChat(ConversationModel conv, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Delete your conversation with $name? This cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await widget.firestoreService.deleteConversation(conv.id, widget.currentUid);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Chat deleted'),
                    backgroundColor: AppColors.textMuted,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmBlockUser(String otherUid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block User?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Block $name? They won\'t be able to send you messages.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await widget.firestoreService.blockUser(widget.currentUid, otherUid);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name blocked'),
                    backgroundColor: AppColors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}

class _GroupsTab extends StatelessWidget {
  final String currentUid;
  final FirestoreService firestoreService;

  const _GroupsTab({required this.currentUid, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GroupModel>>(
      stream: firestoreService.getAllGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_outlined, size: 56, color: AppColors.textMuted.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text('No groups yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                const Text('Create a group to start connecting!', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final isMember = group.isMember(currentUid);
            return _groupTile(context, group, isMember);
          },
        );
      },
    );
  }

  Widget _groupTile(BuildContext context, GroupModel group, bool isMember) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: _categoryColor(group.category),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(_categoryIcon(group.category), color: Colors.white, size: 24),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(group.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isMember ? AppColors.greenLight : AppColors.tealLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isMember ? 'Joined' : 'Join',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isMember ? AppColors.green : AppColors.teal),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.lastMessage.isNotEmpty)
            Text(
              '${group.lastSenderName}: ${group.lastMessage}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.people, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text('${group.memberCount} members', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _categoryColor(group.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(group.category, style: TextStyle(fontSize: 9, color: _categoryColor(group.category), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
      onTap: () async {
        if (!isMember) {
          await FirestoreService().joinGroup(group.id, currentUid);
        }
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => GroupChatScreen(groupId: group.id, groupName: group.name),
          ));
        }
      },
    );
  }

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'community': return AppColors.teal;
      case 'jobs': return AppColors.blue;
      case 'services': return AppColors.green;
      case 'buy/sell': return AppColors.orange;
      case 'events': return const Color(0xFF9C27B0);
      default: return AppColors.teal;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'community': return Icons.people;
      case 'jobs': return Icons.work;
      case 'services': return Icons.handyman;
      case 'buy/sell': return Icons.shopping_bag;
      case 'events': return Icons.event;
      default: return Icons.group;
    }
  }
}
