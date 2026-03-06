import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import 'pages/dashboard_page.dart';
import 'pages/users_page.dart';
import 'pages/verification_page.dart';
import 'pages/moderation_page.dart';
import 'pages/team_page.dart';
import 'pages/settings_page.dart';

class AdminPanel extends StatefulWidget {
  final UserModel currentUser;
  const AdminPanel({super.key, required this.currentUser});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;

  late final List<_NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = [
      _NavItem(Icons.dashboard_rounded, 'Dashboard'),
      _NavItem(Icons.people_rounded, 'Users'),
      _NavItem(Icons.verified_user_rounded, 'Verification'),
      _NavItem(Icons.shield_rounded, 'Moderation'),
      if (widget.currentUser.isAdmin)
        _NavItem(Icons.group_add_rounded, 'Team'),
      if (widget.currentUser.isAdmin)
        _NavItem(Icons.settings_rounded, 'Settings'),
    ];
  }

  Widget _getPage(int index) {
    // Map index to page considering conditional items
    final label = _navItems[index].label;
    switch (label) {
      case 'Dashboard':
        return const DashboardPage();
      case 'Users':
        return const UsersPage();
      case 'Verification':
        return const VerificationPage();
      case 'Moderation':
        return const ModerationPage();
      case 'Team':
        return TeamPage(currentUser: widget.currentUser);
      case 'Settings':
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isWide ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isWide) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isWide),
                Expanded(child: _getPage(_selectedIndex)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex.clamp(0, _navItems.length - 1),
              onTap: (i) => setState(() => _selectedIndex = i),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.teal,
              unselectedItemColor: AppColors.textMuted,
              selectedFontSize: 11,
              unselectedFontSize: 10,
              items: _navItems
                  .map((n) => BottomNavigationBarItem(
                        icon: Icon(n.icon, size: 22),
                        label: n.label,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildTopBar(bool isWide) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: isWide ? 24 : 8,
        right: 24,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, color: AppColors.text),
            ),
          if (!isWide) const SizedBox(width: 4),
          Text(
            _navItems[_selectedIndex].label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.currentUser.isAdmin
                  ? AppColors.tealLight
                  : AppColors.orangeLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              widget.currentUser.isAdmin ? 'Admin' : 'Moderator',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.currentUser.isAdmin
                    ? AppColors.tealDark
                    : AppColors.orange,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.teal,
            child: Text(
              widget.currentUser.name.isNotEmpty
                  ? widget.currentUser.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: AppColors.text,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 16),
          // Logo area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.tealGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Local Sathi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Admin Panel',
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Nav items
          ..._navItems.asMap().entries.map((e) => _sidebarItem(e.key, e.value)),
          const Spacer(),
          // Back to app
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white54),
                label: const Text('Back to App',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, _NavItem item) {
    final selected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.teal.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 20,
                    color: selected ? AppColors.teal : Colors.white54),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.teal : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.text,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.tealGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ..._navItems.asMap().entries.map((e) {
              final selected = _selectedIndex == e.key;
              return ListTile(
                leading: Icon(e.value.icon,
                    color: selected ? AppColors.teal : Colors.white54, size: 22),
                title: Text(
                  e.value.label,
                  style: TextStyle(
                    color: selected ? AppColors.teal : Colors.white70,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                selected: selected,
                selectedTileColor: AppColors.teal.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  setState(() => _selectedIndex = e.key);
                  Navigator.pop(context);
                },
              );
            }),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.arrow_back, color: Colors.white54, size: 22),
              title: const Text('Back to App',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.pop(context); // go back
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
