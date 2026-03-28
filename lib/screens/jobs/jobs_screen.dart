import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/job_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/banner_ad_widget.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _firestoreService = FirestoreService();
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Daily',
    'Part-time',
    'Full-time',
    'Contract',
  ];

  String? get _jobTypeFilter {
    switch (_selectedFilter) {
      case 'Daily':
        return 'daily';
      case 'Part-time':
        return 'partTime';
      case 'Full-time':
        return 'fullTime';
      case 'Contract':
        return 'contract';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(40),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Job Board',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find or post local work opportunities',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filters.map((f) {
                    final selected = _selectedFilter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.teal : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: selected ? AppColors.teal : AppColors.bg,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Banner Ad
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: BannerAdWidget(),
            ),
          ),

          // Job listings
          StreamBuilder<List<JobModel>>(
            stream:
                _firestoreService.getJobListings(jobType: _jobTypeFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load jobs',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final jobs = snapshot.data ?? [];
              if (jobs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No jobs posted yet',
                          style: TextStyle(
                              fontSize: 16, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to post a job!',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _JobCard(job: jobs[index]),
                    ),
                    childCount: jobs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateJobSheet(context),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Post Job',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showCreateJobSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateJobSheet(),
    );
  }
}

// ─────────────────────── JOB CARD ───────────────────────

class _JobCard extends StatelessWidget {
  final JobModel job;

  const _JobCard({required this.job});

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return AppColors.green;
      case JobStatus.filled:
        return AppColors.orange;
      case JobStatus.completed:
        return AppColors.blue;
      case JobStatus.closed:
        return AppColors.textMuted;
    }
  }

  Color _statusBgColor(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return AppColors.greenLight;
      case JobStatus.filled:
        return AppColors.orangeLight;
      case JobStatus.completed:
        return AppColors.blueLight;
      case JobStatus.closed:
        return const Color(0xFFE5E7EB);
    }
  }

  String _statusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return 'Open';
      case JobStatus.filled:
        return 'Filled';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.closed:
        return 'Closed';
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailScreen(job: job),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBgColor(job.status),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _statusLabel(job.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(job.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category + job type chips
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    job.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealDark,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    job.jobTypeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blueDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Wage + frequency
            if (job.wage != null) ...[
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 16, color: AppColors.green),
                  const SizedBox(width: 2),
                  Text(
                    '${job.wage!.toStringAsFixed(job.wage! == job.wage!.roundToDouble() ? 0 : 2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                  if (job.wageFrequency != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '/ ${job.wageFrequency}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Location + poster + time
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (job.location != null && job.location!.isNotEmpty) ...[
                    Icon(Icons.location_on,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        job.location!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(' · ',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                  Text(
                    job.posterName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(' · ',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(
                    _timeAgo(job.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  if (job.applicationCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 13, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text(
                            '${job.applicationCount} applied',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── CREATE JOB SHEET ───────────────────────

class _CreateJobSheet extends StatefulWidget {
  const _CreateJobSheet();

  @override
  State<_CreateJobSheet> createState() => _CreateJobSheetState();
}

class _CreateJobSheetState extends State<_CreateJobSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wageController = TextEditingController();

  String _selectedCategory = 'Shop Helper';
  JobType _selectedJobType = JobType.daily;
  String _selectedWageFrequency = 'Daily';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Shop Helper',
    'House Maid',
    'Driver',
    'Cook',
    'Construction Labour',
    'Tuition Teacher',
    'Delivery',
    'Security Guard',
    'Office Assistant',
    'Gardener',
    'Other',
  ];

  final List<String> _wageFrequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'Fixed',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  Future<void> _submitJob() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in title and description'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final appProvider = context.read<AppProvider>();
    final user = appProvider.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final wage = double.tryParse(_wageController.text.trim());
      final job = JobModel(
        id: '',
        posterId: user.uid,
        posterName: user.name,
        posterPhotoUrl: user.profilePhotoUrl,
        title: title,
        description: description,
        category: _selectedCategory,
        jobType: _selectedJobType,
        wage: wage,
        wageFrequency: _selectedWageFrequency.toLowerCase(),
        location: user.city ?? appProvider.city,
        city: user.city ?? appProvider.city,
        state: user.state ?? appProvider.state,
        latitude: appProvider.latitude,
        longitude: appProvider.longitude,
        createdAt: DateTime.now(),
      );

      await FirestoreService().createJobListing(job);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job posted successfully!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post job: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Post a Job',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find local workers for your needs',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Job title
            const Text(
              'Job Title',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Shop Helper Needed',
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Describe the job requirements...',
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category dropdown
            const Text(
              'Category',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary),
                  items: _categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Job type selector
            const Text(
              'Job Type',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: JobType.values.map((type) {
                final selected = _selectedJobType == type;
                String label;
                switch (type) {
                  case JobType.daily:
                    label = 'Daily';
                  case JobType.partTime:
                    label = 'Part-time';
                  case JobType.fullTime:
                    label = 'Full-time';
                  case JobType.contract:
                    label = 'Contract';
                }
                return GestureDetector(
                  onTap: () => setState(() => _selectedJobType = type),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.teal : AppColors.bg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: selected ? AppColors.teal : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Wage + frequency row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wage',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _wageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Amount',
                          prefixText: '\u20B9 ',
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Frequency',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedWageFrequency,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                size: 20, color: AppColors.textSecondary),
                            items: _wageFrequencies.map((f) {
                              return DropdownMenuItem(
                                  value: f, child: Text(f, style: const TextStyle(fontSize: 14)));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedWageFrequency = v);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Post Job',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
