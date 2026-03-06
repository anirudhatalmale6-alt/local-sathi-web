import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../models/group_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_widget.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _firestoreService = FirestoreService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final String _currentUid;
  String _currentName = '';
  String? _currentPhoto;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser!.uid;
    _loadProfile();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService().getUserProfile(_currentUid);
    if (profile != null && mounted) {
      setState(() {
        _currentName = profile.name;
        _currentPhoto = profile.profilePhotoUrl;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    try {
      await _firestoreService.sendGroupMessage(
        groupId: widget.groupId,
        senderUid: _currentUid,
        senderName: _currentName,
        senderPhotoUrl: _currentPhoto,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showGroupInfo() async {
    final doc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
    if (!doc.exists || !mounted) return;
    final group = GroupModel.fromFirestore(doc);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(group.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(group.description.isNotEmpty ? group.description : 'No description', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: AppColors.teal),
                const SizedBox(width: 6),
                Text('${group.memberCount} members', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(8)),
                  child: Text(group.category, style: const TextStyle(fontSize: 11, color: AppColors.tealDark, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (group.isMember(_currentUid))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _firestoreService.leaveGroup(widget.groupId, _currentUid);
                    if (mounted) {
                      Navigator.pop(context); // close sheet
                      Navigator.pop(context); // go back
                    }
                  },
                  icon: const Icon(Icons.exit_to_app, color: AppColors.red),
                  label: const Text('Leave Group', style: TextStyle(color: AppColors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: _showGroupInfo),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<GroupMessageModel>>(
              stream: _firestoreService.getGroupMessages(widget.groupId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                }
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum, size: 48, color: AppColors.tealLight),
                        SizedBox(height: 8),
                        Text('No messages yet. Start the conversation!', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderUid == _currentUid;
                    final showAvatar = !isMe && (index == 0 || messages[index - 1].senderUid != msg.senderUid);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe && showAvatar)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: AvatarWidget(photoUrl: msg.senderPhotoUrl, name: msg.senderName, size: 28),
                              )
                            else if (!isMe)
                              const SizedBox(width: 34),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isMe ? AppColors.teal : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe && showAvatar)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(msg.senderName,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tealDark)),
                                      ),
                                    Text(msg.text, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppColors.text)),
                                    const SizedBox(height: 2),
                                    Text(_shortTime(msg.createdAt),
                                      style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Message ${widget.groupName}...',
                      filled: true, fillColor: AppColors.bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.tealBlueGradient),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
