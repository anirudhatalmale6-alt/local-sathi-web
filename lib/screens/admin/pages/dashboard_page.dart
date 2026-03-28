import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../services/firestore_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _firestore = FirestoreService();
  Map<String, int> _stats = {};
  Map<String, dynamic> _geoStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String? _error;

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      debugPrint('Dashboard: loading stats...');
      final stats = await _firestore.getAppStats()
          .timeout(const Duration(seconds: 15));
      debugPrint('Dashboard: stats loaded: $stats');
      Map<String, dynamic> geo = {};
      try {
        geo = await _firestore.getGeographicStats()
            .timeout(const Duration(seconds: 10));
        debugPrint('Dashboard: geo loaded with ${geo.length} states');
      } catch (e) {
        debugPrint('Dashboard: geo failed: $e');
      }
      if (mounted) {
        setState(() {
          _stats = stats;
          _geoStats = geo;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard: load failed: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load dashboard data. Tap retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.teal),
            SizedBox(height: 16),
            Text('Loading dashboard...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.teal,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Stats grid
          _buildStatsGrid(),
          const SizedBox(height: 24),

          // Quick actions
          _sectionTitle('Quick Actions'),
          const SizedBox(height: 12),
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Geographic breakdown
          _sectionTitle('Geographic Distribution'),
          const SizedBox(height: 12),
          _buildGeoSection(),
          const SizedBox(height: 24),

          // Commission & Bookings
          _sectionTitle('Bookings & Revenue'),
          const SizedBox(height: 12),
          _buildBookingStats(),
          const SizedBox(height: 24),

          // Live community stats
          _sectionTitle('Live Community Stats'),
          const SizedBox(height: 12),
          _buildLiveStats(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final items = [
      _StatItem('Total Users', _stats['totalUsers'] ?? 0, Icons.people, AppColors.teal, AppColors.tealLight),
      _StatItem('Active Providers', _stats['activeProviders'] ?? 0, Icons.handyman, AppColors.blue, AppColors.blueLight),
      _StatItem('Pending Verifications', _stats['pendingVerifications'] ?? 0, Icons.pending_actions, AppColors.orange, AppColors.orangeLight),
      _StatItem('Posts Today', _stats['postsToday'] ?? 0, Icons.article, AppColors.green, AppColors.greenLight),
      _StatItem('Team Members', _stats['totalAdmins'] ?? 0, Icons.admin_panel_settings, AppColors.gold, AppColors.goldLight),
      _StatItem('Total Reviews', _stats['totalReviews'] ?? 0, Icons.star, AppColors.red, AppColors.redLight),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, i) => _statCard(items[i]),
        );
      },
    );
  }

  Widget _statCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          Text(
            '${item.value}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: item.color,
            ),
          ),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionChip(Icons.verified_user, 'Review Verifications', AppColors.teal, () {
          // Navigate to verification page via parent
        }),
        _actionChip(Icons.shield, 'Moderate Content', AppColors.orange, () {}),
        _actionChip(Icons.group_add, 'Add Team Member', AppColors.blue, () {}),
        _actionChip(Icons.analytics, 'View Analytics', AppColors.green, () {}),
      ],
    );
  }

  Widget _actionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      onPressed: onTap,
    );
  }

  Widget _buildGeoSection() {
    final states = _geoStats.keys.toList()..sort();
    if (states.isEmpty) {
      return _emptyBox('No geographic data yet');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16),
        ],
      ),
      child: Column(
        children: states.map((state) {
          final stateData = _geoStats[state] as Map<String, dynamic>;
          final totalUsers = (stateData['total'] as int?) ?? 0;
          final totalProviders = (stateData['providers'] as int?) ?? 0;
          final citiesMap = (stateData['cities'] as Map<String, dynamic>?) ?? {};
          final cityNames = citiesMap.keys.toList()..sort();

          return ExpansionTile(
            title: Text(state, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('$totalUsers users · $totalProviders providers',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, size: 16, color: AppColors.tealDark),
            ),
            children: cityNames.map((city) {
              final c = citiesMap[city] as Map<String, dynamic>? ?? {};
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                title: Text(city, style: const TextStyle(fontSize: 13)),
                trailing: Text(
                  '${c['total'] ?? 0} users · ${c['providers'] ?? 0} providers',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        int total = docs.length;
        int completed = 0;
        int pending = 0;
        double totalRevenue = 0;
        double totalCommission = 0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          if (status == 'completed') {
            completed++;
            totalRevenue += (data['agreedPrice'] as num?)?.toDouble() ?? 0;
            totalCommission += (data['commissionAmount'] as num?)?.toDouble() ?? 0;
          } else if (status == 'pending') {
            pending++;
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _miniStat('Total', '$total', AppColors.blue),
                  _miniStat('Pending', '$pending', AppColors.orange),
                  _miniStat('Done', '$completed', AppColors.green),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('\u20B9${totalRevenue.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.teal)),
                      Text('Total Revenue', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('\u20B9${totalCommission.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.orange)),
                      Text('Commission Earned', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildLiveStats() {
    return StreamBuilder<Map<String, int>>(
      stream: _firestore.getCommunityStatsStream(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final data = snap.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.tealGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _liveStatItem('${data['totalUsers'] ?? 0}', 'Total Users'),
              _liveStatItem('${data['totalProviders'] ?? 0}', 'Providers'),
              _liveStatItem('${data['verifiedProfiles'] ?? 0}', 'Verified'),
            ],
          ),
        );
      },
    );
  }

  Widget _liveStatItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }

  Widget _emptyBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  _StatItem(this.label, this.value, this.icon, this.color, this.bgColor);
}
