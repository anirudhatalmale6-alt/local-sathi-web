import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../services/firestore_service.dart';
import '../../../services/update_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // App Update Management
        _sectionTitle('App Update Management'),
        const SizedBox(height: 12),
        _buildUpdateSection(),
        const SizedBox(height: 24),

        // Sathi AI Configuration
        _sectionTitle('Sathi AI Configuration'),
        const SizedBox(height: 12),
        _buildAiConfigSection(),
        const SizedBox(height: 24),

        // Category Management
        _sectionTitle('Service Categories'),
        const SizedBox(height: 12),
        _buildCategorySection(),
        const SizedBox(height: 24),

        // App Info
        _sectionTitle('App Information'),
        const SizedBox(height: 12),
        _buildAppInfo(),
      ],
    );
  }

  // ═══════════════ UPDATE MANAGEMENT ═══════════════
  Widget _buildUpdateSection() {
    return StreamBuilder<AppVersionInfo?>(
      stream: UpdateService().getVersionConfig(),
      builder: (context, snap) {
        final config = snap.data;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (config != null) ...[
                _configRow('Current Version', config.currentVersion),
                _configRow('Min Version', config.minVersion),
                _configRow('Update URL', config.updateUrl, isUrl: true),
                _configRow('Release Notes', config.releaseNotes),
                if (config.betaEnabled) ...[
                  _configRow('Beta Version', config.betaVersion ?? 'N/A'),
                  _configRow('Beta URL', config.betaUrl ?? 'N/A'),
                ],
              ] else
                const Text('No version config set',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateConfigDialog(config),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Update Config',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _configRow(String label, String value, {bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isUrl ? AppColors.blue : AppColors.text,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateConfigDialog(AppVersionInfo? existing) {
    final versionCtrl = TextEditingController(text: existing?.currentVersion ?? '1.0.0');
    final minVersionCtrl = TextEditingController(text: existing?.minVersion ?? '1.0.0');
    final urlCtrl = TextEditingController(text: existing?.updateUrl ?? '');
    final notesCtrl = TextEditingController(text: existing?.releaseNotes ?? '');
    bool betaEnabled = existing?.betaEnabled ?? false;
    final betaVersionCtrl = TextEditingController(text: existing?.betaVersion ?? '');
    final betaUrlCtrl = TextEditingController(text: existing?.betaUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Update Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Current Version', versionCtrl),
                _dialogField('Min Version (force update)', minVersionCtrl),
                _dialogField('APK Download URL', urlCtrl),
                _dialogField('Release Notes', notesCtrl, maxLines: 3),
                const Divider(height: 24),
                SwitchListTile(
                  title: const Text('Enable Beta Channel', style: TextStyle(fontSize: 13)),
                  value: betaEnabled,
                  onChanged: (v) => setDialogState(() => betaEnabled = v),
                  activeColor: AppColors.teal,
                  contentPadding: EdgeInsets.zero,
                ),
                if (betaEnabled) ...[
                  _dialogField('Beta Version', betaVersionCtrl),
                  _dialogField('Beta APK URL', betaUrlCtrl),
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
                final info = AppVersionInfo(
                  currentVersion: versionCtrl.text.trim(),
                  minVersion: minVersionCtrl.text.trim(),
                  updateUrl: urlCtrl.text.trim(),
                  releaseNotes: notesCtrl.text.trim(),
                  betaEnabled: betaEnabled,
                  betaVersion: betaEnabled ? betaVersionCtrl.text.trim() : null,
                  betaUrl: betaEnabled ? betaUrlCtrl.text.trim() : null,
                );
                await UpdateService().updateVersionConfig(info);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Update config saved!'),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          filled: true,
          fillColor: AppColors.bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  // ═══════════════ AI CONFIGURATION ═══════════════
  Widget _buildAiConfigSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('app_config').doc('ai').snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final currentKey = data?['geminiApiKey'] as String?;
        final hasKey = currentKey != null && currentKey.isNotEmpty;
        final maskedKey = hasKey
            ? '${currentKey!.substring(0, 10)}...${currentKey.substring(currentKey.length - 4)}'
            : 'Not configured';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasKey ? AppColors.green.withAlpha(25) : AppColors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasKey ? Icons.check_circle : Icons.warning_rounded,
                      color: hasKey ? AppColors.green : AppColors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasKey ? 'Gemini API Key Active' : 'Gemini API Key Missing',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: hasKey ? AppColors.green : AppColors.red,
                          ),
                        ),
                        Text(
                          maskedKey,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Get a free API key from Google AI Studio:\naistudio.google.com/apikey',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAiKeyDialog(currentKey),
                  icon: Icon(hasKey ? Icons.edit : Icons.add, size: 18),
                  label: Text(hasKey ? 'Update API Key' : 'Add API Key',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B1FA2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAiKeyDialog(String? existingKey) {
    final ctrl = TextEditingController(text: existingKey ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your Gemini API key here. Get one free from Google AI Studio.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
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
              final key = ctrl.text.trim();
              if (key.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('app_config')
                  .doc('ai')
                  .set({'geminiApiKey': key}, SetOptions(merge: true));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('API key saved! Sathi AI is now active.'),
                    backgroundColor: AppColors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ═══════════════ CATEGORY MANAGEMENT ═══════════════
  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Manage service categories available in the app.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
              IconButton(
                onPressed: _showAddCategoryDialog,
                icon: const Icon(Icons.add_circle, color: AppColors.teal),
                tooltip: 'Add Category',
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<String>>(
            stream: _firestore.getCategories(),
            builder: (context, snap) {
              final categories = snap.data ?? AppConstants.allCategories;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) => Chip(
                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => _confirmDeleteCategory(cat),
                  backgroundColor: AppColors.bg,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Category name',
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await _firestore.addCategory(name, '');
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?', style: TextStyle(fontSize: 16)),
        content: Text('Remove "$name" from service categories?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _firestore.deleteCategoryByName(name);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ═══════════════ APP INFO ═══════════════
  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: const Column(
        children: [
          _InfoRow(label: 'App Name', value: AppConstants.appName),
          _InfoRow(label: 'Package', value: 'com.localsathi.local_sathi'),
          _InfoRow(label: 'Firebase', value: 'local-sathi-eced8'),
          _InfoRow(label: 'AI Model', value: 'gemini-2.5-flash'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
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
}
