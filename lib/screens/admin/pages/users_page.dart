import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/avatar_widget.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _firestore = FirestoreService();
  String _searchQuery = '';
  UserRole? _roleFilter;
  VerificationStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & filters
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or ID...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', _roleFilter == null && _statusFilter == null, () {
                      setState(() { _roleFilter = null; _statusFilter = null; });
                    }),
                    _filterChip('Customers', _roleFilter == UserRole.customer, () {
                      setState(() { _roleFilter = UserRole.customer; _statusFilter = null; });
                    }),
                    _filterChip('Providers', _roleFilter == UserRole.provider, () {
                      setState(() { _roleFilter = UserRole.provider; _statusFilter = null; });
                    }),
                    _filterChip('Admins', _roleFilter == UserRole.admin, () {
                      setState(() { _roleFilter = UserRole.admin; _statusFilter = null; });
                    }),
                    _filterChip('Verified', _statusFilter == VerificationStatus.verified, () {
                      setState(() { _statusFilter = VerificationStatus.verified; _roleFilter = null; });
                    }),
                    _filterChip('Pending', _statusFilter == VerificationStatus.pending, () {
                      setState(() { _statusFilter = VerificationStatus.pending; _roleFilter = null; });
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        // User list
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _firestore.getAllUsers(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.teal));
              }
              if (!snap.hasData || snap.data!.isEmpty) {
                return const Center(child: Text('No users found'));
              }

              var users = snap.data!;

              // Apply filters
              if (_roleFilter != null) {
                users = users.where((u) => u.role == _roleFilter).toList();
              }
              if (_statusFilter != null) {
                users = users.where((u) => u.verificationStatus == _statusFilter).toList();
              }
              if (_searchQuery.isNotEmpty) {
                users = users.where((u) =>
                    u.name.toLowerCase().contains(_searchQuery) ||
                    u.phone.contains(_searchQuery) ||
                    u.localSathiId.toLowerCase().contains(_searchQuery)).toList();
              }

              // Sort: newest first
              users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: users.length,
                itemBuilder: (ctx, i) => _userCard(users[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textSecondary,
        )),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.teal,
        backgroundColor: Colors.white,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        showCheckmark: false,
      ),
    );
  }

  Widget _userCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: InkWell(
        onTap: () => _showUserDetail(user),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AvatarWidget(name: user.name, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: AppColors.teal),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.localSathiId} · ${user.phone}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _roleBadge(user.role),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleBadge(UserRole role) {
    final colors = {
      UserRole.admin: (AppColors.tealLight, AppColors.tealDark),
      UserRole.moderator: (AppColors.orangeLight, AppColors.orange),
      UserRole.provider: (AppColors.blueLight, AppColors.blue),
      UserRole.customer: (AppColors.bg, AppColors.textMuted),
    };
    final c = colors[role]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.$1,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        role.name[0].toUpperCase() + role.name.substring(1),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c.$2),
      ),
    );
  }

  void _showUserDetail(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollCtrl) => _UserDetailSheet(
          user: user,
          scrollController: scrollCtrl,
          onRoleChanged: () => setState(() {}),
        ),
      ),
    );
  }
}

class _UserDetailSheet extends StatelessWidget {
  final UserModel user;
  final ScrollController scrollController;
  final VoidCallback onRoleChanged;
  final _firestore = FirestoreService();

  _UserDetailSheet({
    required this.user,
    required this.scrollController,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Profile header
        Row(
          children: [
            AvatarWidget(name: user.name, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(user.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 18, color: AppColors.teal),
                      ],
                    ],
                  ),
                  Text(user.localSathiId,
                      style: const TextStyle(fontSize: 13, color: AppColors.tealDark, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Info rows
        _infoRow(Icons.phone, 'Phone', user.phone),
        if (user.email != null) _infoRow(Icons.email, 'Email', user.email!),
        _infoRow(Icons.badge, 'Role', user.role.name.toUpperCase()),
        _infoRow(Icons.verified_user, 'Verification', user.verificationStatus.name.toUpperCase()),
        if (user.city != null || user.state != null)
          _infoRow(Icons.location_on, 'Location', '${user.city ?? ''}, ${user.state ?? ''}'),
        if (user.isProvider) ...[
          _infoRow(Icons.category, 'Services', user.serviceCategories.join(', ')),
          if (user.serviceArea != null)
            _infoRow(Icons.map, 'Service Area', user.serviceArea!),
          _infoRow(Icons.star, 'Rating', '${user.rating.toStringAsFixed(1)} (${user.reviewCount} reviews)'),
        ],
        if (user.aadhaarNumber != null)
          _infoRow(Icons.credit_card, 'Aadhaar', user.aadhaarNumber!),
        _infoRow(Icons.calendar_today, 'Joined', _formatDate(user.createdAt)),
        _infoRow(Icons.monetization_on, 'Sponsored', user.isSponsored ? 'Yes' : 'No'),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // Aadhaar document
        if (user.aadhaarDocUrl != null && user.aadhaarDocUrl!.isNotEmpty) ...[
          const Text('Aadhaar Document', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              user.aadhaarDocUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 180,
                  color: AppColors.bg,
                  child: const Center(child: CircularProgressIndicator(color: AppColors.teal)),
                );
              },
              errorBuilder: (ctx, _, __) => Container(
                height: 80,
                color: AppColors.bg,
                child: const Center(child: Text('Could not load document', style: TextStyle(color: AppColors.textMuted))),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action buttons
        const Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 10),

        // Change role
        _actionButton(
          Icons.admin_panel_settings,
          'Change Role',
          AppColors.teal,
          () => _showRoleDialog(context),
        ),
        const SizedBox(height: 8),

        // Toggle verification
        if (user.verificationStatus == VerificationStatus.pending)
          _actionButton(
            Icons.check_circle,
            'Approve Verification',
            AppColors.green,
            () async {
              await _firestore.updateVerificationStatus(user.uid, VerificationStatus.verified);
              onRoleChanged();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        if (user.verificationStatus == VerificationStatus.pending) const SizedBox(height: 8),

        // Toggle sponsored
        _actionButton(
          user.isSponsored ? Icons.star_border : Icons.star,
          user.isSponsored ? 'Remove Sponsored' : 'Mark as Sponsored',
          AppColors.gold,
          () async {
            await _firestore.toggleSponsored(user.uid, !user.isSponsored);
            onRoleChanged();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        const SizedBox(height: 8),

        // Delete user
        _actionButton(
          Icons.delete_forever,
          'Delete User',
          AppColors.red,
          () => _confirmDelete(context),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Role', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return RadioListTile<UserRole>(
              title: Text(role.name[0].toUpperCase() + role.name.substring(1),
                  style: const TextStyle(fontSize: 14)),
              value: role,
              groupValue: user.role,
              activeColor: AppColors.teal,
              onChanged: (val) async {
                if (val != null) {
                  await _firestore.updateUserRole(user.uid, val);
                  onRoleChanged();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('This will permanently delete ${user.name} and all their data. This cannot be undone.',
            style: const TextStyle(fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.deleteUser(user.uid);
              onRoleChanged();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
