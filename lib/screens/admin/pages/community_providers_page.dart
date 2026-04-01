import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../models/community_provider_model.dart';
import '../../../services/firestore_service.dart';

class CommunityProvidersPage extends StatefulWidget {
  const CommunityProvidersPage({super.key});

  @override
  State<CommunityProvidersPage> createState() => _CommunityProvidersPageState();
}

class _CommunityProvidersPageState extends State<CommunityProvidersPage> {
  final _firestoreService = FirestoreService();
  String _filter = 'pending'; // pending, approved, rejected, all

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              _filterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _filterChip('Approved', 'approved'),
              const SizedBox(width: 8),
              _filterChip('Rejected', 'rejected'),
              const SizedBox(width: 8),
              _filterChip('All', 'all'),
            ],
          ),
        ),

        // Provider list
        Expanded(
          child: StreamBuilder<List<CommunityProvider>>(
            stream: _firestoreService.getAllCommunityProviders(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.teal));

              var providers = snapshot.data!;
              if (_filter != 'all') {
                providers = providers.where((p) => p.status.name == _filter).toList();
              }

              if (providers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('No $_filter providers', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: providers.length,
                itemBuilder: (context, index) => _adminProviderCard(providers[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.teal : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _adminProviderCard(CommunityProvider provider) {
    Color statusColor;
    String statusText;
    switch (provider.status) {
      case ProviderStatus.pending:
        statusColor = Colors.orange;
        statusText = 'PENDING';
        break;
      case ProviderStatus.approved:
        statusColor = AppColors.green;
        statusText = 'APPROVED';
        break;
      case ProviderStatus.rejected:
        statusColor = AppColors.red;
        statusText = 'REJECTED';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: provider.status == ProviderStatus.pending
            ? Border.all(color: Colors.orange.withAlpha(80), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.teal.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                    Text(provider.category, style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Details
          _detailRow(Icons.phone, provider.phone),
          _detailRow(Icons.location_on, provider.area),
          if (provider.description != null) _detailRow(Icons.note, provider.description!),
          _detailRow(Icons.person, 'Added by: ${provider.createdByUserName}'),
          _detailRow(Icons.calendar_today, '${provider.createdAt.day}/${provider.createdAt.month}/${provider.createdAt.year}'),

          if (provider.status == ProviderStatus.pending) ...[
            const Divider(height: 20),
            Row(
              children: [
                // Quick call
                IconButton(
                  onPressed: () async {
                    final uri = Uri(scheme: 'tel', path: provider.phone);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  icon: const Icon(Icons.call, color: AppColors.teal),
                  tooltip: 'Call to verify',
                ),
                const Spacer(),
                // Reject
                OutlinedButton(
                  onPressed: () => _showRejectDialog(provider),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                // Mark as Duplicate
                OutlinedButton(
                  onPressed: () => _firestoreService.rejectCommunityProvider(provider.id, reason: 'Duplicate entry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Duplicate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                // Approve
                ElevatedButton.icon(
                  onPressed: () async {
                    await _firestoreService.approveCommunityProvider(provider.id, 'admin');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${provider.name} approved! +20 pts to contributor.'), backgroundColor: AppColors.green),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  void _showRejectDialog(CommunityProvider provider) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Provider'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason (optional)', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _firestoreService.rejectCommunityProvider(provider.id, reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
