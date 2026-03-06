import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/avatar_widget.dart';

class TeamPage extends StatefulWidget {
  final UserModel currentUser;
  const TeamPage({super.key, required this.currentUser});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final _firestore = FirestoreService();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Add team member card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.tealGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.group_add, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text('Add Team Member',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Search by phone number to add a user as admin or moderator.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter phone number...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.phone, color: Colors.white54, size: 18),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _searchAndAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.tealDark,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Search', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Roles explanation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Role Permissions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _roleInfo(
                'Admin',
                'Full access: manage users, verify, moderate, manage team, change settings',
                AppColors.teal,
              ),
              const SizedBox(height: 10),
              _roleInfo(
                'Moderator',
                'Can verify users, moderate posts & reviews. Cannot manage team or settings',
                AppColors.orange,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Team members list
        const Text('Current Team',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 12),

        StreamBuilder<List<UserModel>>(
          stream: _firestore.getTeamMembers(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.teal));
            }
            final members = snap.data ?? [];
            if (members.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('No team members yet',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              );
            }

            return Column(
              children: members.map((m) => _teamMemberCard(m)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _roleInfo(String role, String desc, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(role,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(desc,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ),
      ],
    );
  }

  Widget _teamMemberCard(UserModel member) {
    final isCurrentUser = member.uid == widget.currentUser.uid;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser ? Border.all(color: AppColors.teal, width: 1) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          AvatarWidget(name: member.name, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(member.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text('You',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.tealDark)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${member.phone} · ${member.localSathiId}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: member.isAdmin ? AppColors.tealLight : AppColors.orangeLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              member.isAdmin ? 'Admin' : 'Moderator',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: member.isAdmin ? AppColors.tealDark : AppColors.orange,
              ),
            ),
          ),
          if (!isCurrentUser) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) => _handleTeamAction(val, member),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: member.isAdmin ? 'demote' : 'promote',
                  child: Row(
                    children: [
                      Icon(member.isAdmin ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 16, color: AppColors.orange),
                      const SizedBox(width: 8),
                      Text(member.isAdmin ? 'Demote to Moderator' : 'Promote to Admin',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, size: 16, color: AppColors.red),
                      SizedBox(width: 8),
                      Text('Remove from Team', style: TextStyle(fontSize: 13, color: AppColors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleTeamAction(String action, UserModel member) async {
    switch (action) {
      case 'promote':
        await _firestore.updateUserRole(member.uid, UserRole.admin);
        break;
      case 'demote':
        await _firestore.updateUserRole(member.uid, UserRole.moderator);
        break;
      case 'remove':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove from team?', style: TextStyle(fontSize: 16)),
            content: Text('${member.name} will lose admin access and become a regular user.'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                child: const Text('Remove', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          // Set back to their original role (provider if they have categories, otherwise customer)
          final newRole = member.serviceCategories.isNotEmpty
              ? UserRole.provider
              : UserRole.customer;
          await _firestore.updateUserRole(member.uid, newRole);
        }
        break;
    }
  }

  Future<void> _searchAndAdd() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;

    // Search for user by phone
    final snap = await _firestore.getAllUsers().first;
    final match = snap.where((u) => u.phone.contains(phone)).toList();

    if (!mounted) return;

    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No user found with phone "$phone"'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final user = match.first;

    if (user.hasAdminAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} is already a team member'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Show dialog to choose role
    final role = await showDialog<UserRole>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${user.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${user.name} (${user.phone}) will be added to the team.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            const Text('Choose role:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Admin'),
              subtitle: const Text('Full access', style: TextStyle(fontSize: 12)),
              leading: const Icon(Icons.admin_panel_settings, color: AppColors.teal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () => Navigator.pop(ctx, UserRole.admin),
            ),
            ListTile(
              title: const Text('Moderator'),
              subtitle: const Text('Limited access', style: TextStyle(fontSize: 12)),
              leading: const Icon(Icons.shield, color: AppColors.orange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () => Navigator.pop(ctx, UserRole.moderator),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (role != null) {
      await _firestore.updateUserRole(user.uid, role);
      _phoneCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} added as ${role.name}'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
