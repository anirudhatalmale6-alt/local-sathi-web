import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Community';
  bool _creating = false;

  final _categories = ['Community', 'Jobs', 'Services', 'Buy/Sell', 'Events', 'General'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name'), backgroundColor: AppColors.red),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final profile = await AuthService().getUserProfile(uid);

      final groupId = await FirestoreService().createGroup(
        name: name,
        description: _descCtrl.text.trim(),
        category: _category,
        createdBy: uid,
        createdByName: profile?.name ?? 'User',
      );

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => GroupChatScreen(groupId: groupId, groupName: name),
        ));
      }
    } catch (e) {
      setState(() => _creating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Create Group')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Group icon
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.group_add, size: 40, color: AppColors.teal),
            ),
          ),
          const SizedBox(height: 24),

          // Name
          const Text('Group Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g., Ranikhet Community',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.group, color: AppColors.teal),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What is this group about?',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // Category
          const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _categories.map((cat) {
              final selected = _category == cat;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.teal : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? AppColors.teal : AppColors.tealLight, width: 1.5),
                  ),
                  child: Text(cat, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.text,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _creating ? null : _createGroup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _creating
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
