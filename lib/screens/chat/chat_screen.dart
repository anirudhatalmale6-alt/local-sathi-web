import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../models/message_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar_widget.dart';

class ChatScreen extends StatefulWidget {
  final String otherUid;
  final String otherName;
  final String? otherPhotoUrl;

  const ChatScreen({
    super.key,
    required this.otherUid,
    required this.otherName,
    this.otherPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _firestoreService = FirestoreService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final String _currentUid;
  late final String _conversationId;
  String _currentName = '';
  String? _currentPhoto;
  bool _sending = false;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser!.uid;
    _conversationId = _firestoreService.getConversationId(_currentUid, widget.otherUid);
    _loadCurrentUserInfo();
    _checkBlocked();
    // Mark as read
    _firestoreService.markMessagesRead(_conversationId, _currentUid);
  }

  Future<void> _checkBlocked() async {
    final blocked = await _firestoreService.isBlocked(_currentUid, widget.otherUid);
    if (mounted) setState(() => _isBlocked = blocked);
  }

  Future<void> _toggleBlock() async {
    if (_isBlocked) {
      await _firestoreService.unblockUser(_currentUid, widget.otherUid);
      if (mounted) {
        setState(() => _isBlocked = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.otherName} unblocked'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Block User?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text('Block ${widget.otherName}? They won\'t be able to message you.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
              child: const Text('Block'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _firestoreService.blockUser(_currentUid, widget.otherUid);
        if (mounted) {
          setState(() => _isBlocked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.otherName} blocked'),
              backgroundColor: AppColors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserInfo() async {
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
    if (text.isEmpty || _sending || _isBlocked) return;

    _textController.clear();
    setState(() => _sending = true);

    try {
      await _firestoreService.sendMessage(
        currentUid: _currentUid,
        otherUid: widget.otherUid,
        text: text,
        currentName: _currentName,
        currentPhoto: _currentPhoto,
        otherName: widget.otherName,
        otherPhoto: widget.otherPhotoUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppColors.red),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarWidget(photoUrl: widget.otherPhotoUrl, name: widget.otherName, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'block') _toggleBlock();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(_isBlocked ? Icons.check_circle : Icons.block,
                        size: 20, color: _isBlocked ? AppColors.green : AppColors.orange),
                    const SizedBox(width: 8),
                    Text(_isBlocked ? 'Unblock' : 'Block User',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _firestoreService.getMessages(_conversationId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                }
                // Mark as read when new messages arrive
                if (messages.isNotEmpty && messages.last.senderUid != _currentUid) {
                  _firestoreService.markMessagesRead(_conversationId, _currentUid);
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.waving_hand, size: 48, color: AppColors.gold),
                        const SizedBox(height: 8),
                        Text('Say hi to ${widget.otherName}!',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
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
                    final showTime = index == 0 ||
                        messages[index].createdAt.difference(messages[index - 1].createdAt).inMinutes > 5;

                    return Column(
                      children: [
                        if (showTime)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _formatTime(msg.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ),
                        _messageBubble(msg, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input bar or blocked notice
          if (_isBlocked)
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              color: AppColors.bg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  const Text(
                    'Chat blocked. Unblock to send messages.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
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
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppColors.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
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
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.tealBlueGradient,
                      ),
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

  Widget _messageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: msg.isDeleted ? null : () => _showMessageOptions(msg, isMe),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: msg.isDeleted
                ? (isMe ? AppColors.teal.withOpacity(0.5) : Colors.grey.shade100)
                : (isMe ? AppColors.teal : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (msg.isDeleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: 14,
                      color: isMe ? Colors.white60 : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'This message was deleted',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isMe ? Colors.white60 : AppColors.textMuted,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  msg.text,
                  style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppColors.text, height: 1.3),
                ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.isEdited && !msg.isDeleted) ...[
                    Text(
                      'edited',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: isMe ? Colors.white60 : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _shortTime(msg.createdAt),
                    style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : AppColors.textMuted),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.done_all, size: 12, color: msg.isRead ? Colors.white : Colors.white54),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(MessageModel msg, bool isMe) {
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
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Copy option (available for everyone)
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.teal),
                title: const Text('Copy', style: TextStyle(fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyMessage(msg.text);
                },
              ),
              // Edit option (only for sender, within 15 minutes)
              if (isMe && DateTime.now().difference(msg.createdAt).inMinutes <= 15)
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.blue),
                  title: const Text('Edit', style: TextStyle(fontSize: 15)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(msg);
                  },
                ),
              // Delete option (only for sender)
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.red),
                  title: const Text('Delete', style: TextStyle(fontSize: 15, color: AppColors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteMessage(msg);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showEditDialog(MessageModel msg) {
    final editController = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: editController,
          maxLines: 5,
          minLines: 1,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Edit your message...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != msg.text) {
                Navigator.pop(ctx);
                await _firestoreService.editMessage(_conversationId, msg.id, newText);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(MessageModel msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('This message will be deleted for everyone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteMessage(_conversationId, msg.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today ${_shortTime(dt)}';
    if (diff.inDays == 1) return 'Yesterday ${_shortTime(dt)}';
    return '${dt.day}/${dt.month} ${_shortTime(dt)}';
  }

  String _shortTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
