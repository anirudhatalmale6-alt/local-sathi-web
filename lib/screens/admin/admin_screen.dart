import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../services/update_service.dart';
import '../../widgets/avatar_widget.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _firestoreService = FirestoreService();
  Map<String, int> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _ensureVersionConfig();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _firestoreService.getAppStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load stats: $e');
      if (mounted) {
        setState(() {
          _loadingStats = false;
        });
      }
    }
  }

  /// Ensure version config exists in Firestore
  Future<void> _ensureVersionConfig() async {
    try {
      final updateService = UpdateService();
      final stream = updateService.getVersionConfig();
      final config = await stream.first;
      if (config == null) {
        // Seed initial version config
        await updateService.updateVersionConfig(AppVersionInfo(
          currentVersion: '1.8.3',
          minVersion: '1.0.0',
          updateUrl: 'https://github.com/anirudhatalmale6-alt/local-sathi-web/releases/download/v1.8.3/local-sathi-v1.8.3.apk',
          releaseNotes: 'Fixed Sathi AI and in-app download!',
        ));
      }
    } catch (_) {}
  }

  void _showUpdateConfigDialog(AppVersionInfo? existing) {
    final versionCtrl = TextEditingController(text: existing?.currentVersion ?? '1.0.0');
    final minVersionCtrl = TextEditingController(text: existing?.minVersion ?? '1.0.0');
    final urlCtrl = TextEditingController(text: existing?.updateUrl ?? '');
    final notesCtrl = TextEditingController(text: existing?.releaseNotes ?? '');
    final betaVersionCtrl = TextEditingController(text: existing?.betaVersion ?? '');
    final betaUrlCtrl = TextEditingController(text: existing?.betaUrl ?? '');
    bool betaEnabled = existing?.betaEnabled ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Push App Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Version', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: versionCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. 1.2.0', isDense: true),
                ),
                const SizedBox(height: 12),
                const Text('Minimum Version (force update below this)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: minVersionCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. 1.0.0', isDense: true),
                ),
                const SizedBox(height: 12),
                const Text('Download URL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(hintText: 'GitHub release or Play Store URL', isDense: true),
                ),
                const SizedBox(height: 12),
                const Text('Release Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'What\'s new in this version?', isDense: true),
                ),
                const SizedBox(height: 16),
                // Beta toggle
                Row(
                  children: [
                    Switch(
                      value: betaEnabled,
                      activeColor: AppColors.orange,
                      onChanged: (v) => setDialogState(() => betaEnabled = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('Enable Beta Channel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (betaEnabled) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: betaVersionCtrl,
                    decoration: const InputDecoration(hintText: 'Beta version (e.g. 1.3.0-beta)', isDense: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: betaUrlCtrl,
                    decoration: const InputDecoration(hintText: 'Beta download URL', isDense: true),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final version = versionCtrl.text.trim();
                final minVersion = minVersionCtrl.text.trim();
                final url = urlCtrl.text.trim();
                final notes = notesCtrl.text.trim();
                if (version.isEmpty || url.isEmpty) return;

                final info = AppVersionInfo(
                  currentVersion: version,
                  minVersion: minVersion.isNotEmpty ? minVersion : '1.0.0',
                  updateUrl: url,
                  releaseNotes: notes.isNotEmpty ? notes : 'New version available!',
                  betaEnabled: betaEnabled,
                  betaVersion: betaEnabled ? betaVersionCtrl.text.trim() : null,
                  betaUrl: betaEnabled ? betaUrlCtrl.text.trim() : null,
                );

                await UpdateService().updateVersionConfig(info);
                if (ctx.mounted) Navigator.pop(ctx);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Update v$version pushed! All users will be notified.'),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Push Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Category name (e.g. Doctor)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(hintText: 'Emoji icon (e.g. 🩺)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final icon = iconController.text.trim();
              if (name.isNotEmpty) {
                await _firestoreService.addCategory(name, icon.isNotEmpty ? icon : '📌');
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg,
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _statCard('\u{1F465}', _stats['totalUsers'] ?? 0, 'Total Users',
                      const Color(0xFFE3F2FD)),
                  _statCard('\u{23F3}', _stats['pendingVerifications'] ?? 0,
                      'Pending Verifications', const Color(0xFFFFF3E0)),
                  _statCard('\u2705', _stats['activeProviders'] ?? 0,
                      'Active Providers', const Color(0xFFE8F5E9)),
                  _statCard('\u{1F4DD}', _stats['postsToday'] ?? 0,
                      'Posts Today', const Color(0xFFFCE4EC)),
                ],
              ),
            ),

            // Geographic Analytics
            _sectionTitle('Geographic Analytics'),
            _buildGeographicAnalytics(),
            const SizedBox(height: 16),

            // App Update Management
            _sectionTitle('App Update Management'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: StreamBuilder<AppVersionInfo?>(
                  stream: UpdateService().getVersionConfig(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.system_update, size: 20, color: AppColors.tealDark),
                            const SizedBox(width: 8),
                            Text(
                              info != null ? 'Current: v${info.currentVersion}' : 'No version set',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
                            ),
                            const Spacer(),
                            if (info?.betaEnabled == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.orangeLight,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'Beta: v${info?.betaVersion ?? '-'}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.orange),
                                ),
                              ),
                          ],
                        ),
                        if (info != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Min version: v${info.minVersion} · Notes: ${info.releaseNotes}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showUpdateConfigDialog(info),
                            icon: const Icon(Icons.publish, size: 18),
                            label: const Text('Push New Update'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Manage Categories
            _sectionTitle('Manage Categories'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<List<String>>(
                stream: _firestoreService.getCategories(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...categories.map((cat) => Chip(
                                label: Text(cat, style: const TextStyle(fontSize: 12)),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => _firestoreService.deleteCategoryByName(cat),
                                backgroundColor: AppColors.tealLight,
                              )),
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 18, color: AppColors.teal),
                            label: const Text('Add New', style: TextStyle(fontSize: 12, color: AppColors.teal)),
                            backgroundColor: AppColors.bg,
                            onPressed: () => _showAddCategoryDialog(),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Pending Verifications
            _sectionTitle('Pending Aadhaar Verifications'),
            StreamBuilder<List<UserModel>>(
              stream: _firestoreService.getPendingVerifications(),
              builder: (context, snapshot) {
                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return _emptyState('No pending verifications');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _verifyCard(user);
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Reported Posts
            _sectionTitle('Reported Posts'),
            StreamBuilder<List<PostModel>>(
              stream: _firestoreService.getReportedPosts(),
              builder: (context, snapshot) {
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return _emptyState('No reported posts');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _reportCard(post);
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // User Feedback
            _sectionTitle('User Feedback'),
            StreamBuilder<List<FeedbackModel>>(
              stream: _firestoreService.getAllFeedback(),
              builder: (context, snapshot) {
                final feedbacks = snapshot.data ?? [];
                if (feedbacks.isEmpty) {
                  return _emptyState('No feedback yet');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final fb = feedbacks[index];
                    return _feedbackCard(fb);
                  },
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGeographicAnalytics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _firestoreService.getGeographicStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
          );
        }

        final geoStats = snapshot.data!;
        if (geoStats.isEmpty) {
          return _emptyState('No geographic data yet. Users will appear here as they register with location.');
        }

        // Sort states by total users descending
        final sortedStates = geoStats.entries.toList()
          ..sort((a, b) => ((b.value as Map)['total'] as int).compareTo((a.value as Map)['total'] as int));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary row
                Row(
                  children: [
                    Icon(Icons.public_rounded, size: 20, color: AppColors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '${sortedStates.length} State${sortedStates.length != 1 ? 's' : ''} • India',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // State list with expandable cities
                ...sortedStates.map((entry) {
                  final stateName = entry.key;
                  final stateData = entry.value as Map<String, dynamic>;
                  final total = stateData['total'] as int;
                  final providers = stateData['providers'] as int;
                  final cities = stateData['cities'] as Map<String, Map<String, int>>;

                  // Sort cities by total
                  final sortedCities = cities.entries.toList()
                    ..sort((a, b) => (b.value['total'] ?? 0).compareTo(a.value['total'] ?? 0));

                  return _GeoStateItem(
                    stateName: stateName,
                    total: total,
                    providers: providers,
                    cities: sortedCities,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String emoji, int value, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadingStats ? '...' : '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _verifyCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          AvatarWidget(name: user.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'Aadhaar: ${user.aadhaarNumber ?? 'Document uploaded'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _circleButton(
                Icons.check,
                AppColors.greenLight,
                AppColors.green,
                () async {
                  await _firestoreService.updateVerificationStatus(
                    user.uid,
                    VerificationStatus.verified,
                  );
                  _loadStats();
                },
              ),
              const SizedBox(width: 8),
              _circleButton(
                Icons.close,
                AppColors.redLight,
                AppColors.red,
                () async {
                  await _firestoreService.updateVerificationStatus(
                    user.uid,
                    VerificationStatus.rejected,
                  );
                  _loadStats();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleButton(
      IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  Widget _feedbackCard(FeedbackModel fb) {
    final categoryIcon = fb.category == 'bug'
        ? Icons.bug_report_outlined
        : fb.category == 'feature'
            ? Icons.lightbulb_outline
            : Icons.chat_bubble_outline;
    final categoryLabel = fb.category == 'bug'
        ? 'Bug Report'
        : fb.category == 'feature'
            ? 'Feature Request'
            : 'General';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: fb.isRead ? null : Border.all(color: AppColors.teal.withAlpha(60), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(name: fb.userName, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fb.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      fb.userLocalSathiId,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Star rating
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 14,
                    color: i < fb.rating ? AppColors.gold : AppColors.textMuted.withAlpha(60),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(categoryIcon, size: 14, color: AppColors.tealDark),
                const SizedBox(width: 4),
                Text(
                  categoryLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fb.message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!fb.isRead)
                GestureDetector(
                  onTap: () => _firestoreService.markFeedbackRead(fb.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'Mark Read',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tealDark,
                      ),
                    ),
                  ),
                ),
              if (!fb.isRead) const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _firestoreService.deleteFeedback(fb.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${post.text}"',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            'By ${post.authorName} · ${post.reportCount} reports',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => _firestoreService.deletePost(post.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Remove Post',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _firestoreService.dismissReport(post.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Expandable state item for geographic analytics
class _GeoStateItem extends StatefulWidget {
  final String stateName;
  final int total;
  final int providers;
  final List<MapEntry<String, Map<String, int>>> cities;

  const _GeoStateItem({
    required this.stateName,
    required this.total,
    required this.providers,
    required this.cities,
  });

  @override
  State<_GeoStateItem> createState() => _GeoStateItemState();
}

class _GeoStateItemState extends State<_GeoStateItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.cities.isNotEmpty ? () => setState(() => _expanded = !_expanded) : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.location_city_rounded,
                  size: 16,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.stateName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.total}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue),
                  ),
                ),
                if (widget.providers > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orangeLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.providers} SP',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.orange),
                    ),
                  ),
                ],
                if (widget.cities.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 8),
            child: Column(
              children: widget.cities.map((cityEntry) {
                final cityName = cityEntry.key;
                final cityTotal = cityEntry.value['total'] ?? 0;
                final cityProviders = cityEntry.value['providers'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cityName,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      Text(
                        '$cityTotal users',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      if (cityProviders > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '($cityProviders SP)',
                          style: TextStyle(fontSize: 11, color: AppColors.orange),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        if (!_expanded) Divider(height: 1, color: AppColors.bg),
      ],
    );
  }
}
