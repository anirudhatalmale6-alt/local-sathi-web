import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../admin/admin_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final user = appProvider.currentUser;

    if (user == null) {
      final isLoading = appProvider.isLoading;
      final error = appProvider.loadError;
      if (error != null && !isLoading) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.red),
                const SizedBox(height: 12),
                const Text('Could not load profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(error, style: TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => appProvider.loadCurrentUser(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero header
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    children: [
                      // Settings button
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => _showSettings(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            child: const Icon(
                              Icons.settings,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.orange, Color(0xFFFF9800)],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // LS ID
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield, size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              user.localSathiId,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Verification badge
                      if (user.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 14, color: AppColors.greenLight),
                              const SizedBox(width: 4),
                              Text(
                                'Aadhaar Verified',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.greenLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Stats card (Freelancer-style)
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItemRich(
                      '${user.rating.toStringAsFixed(1)} \u2605',
                      'Rating',
                      user.rating >= 4 ? AppColors.green : (user.rating >= 3 ? AppColors.gold : AppColors.orange),
                    ),
                    Container(width: 1, height: 30, color: AppColors.bg),
                    _statItemRich('${user.reviewCount}', 'Reviews', AppColors.blue),
                    Container(width: 1, height: 30, color: AppColors.bg),
                    _statItemRich(
                      "${_monthName(user.createdAt.month)} '${user.createdAt.year.toString().substring(2)}",
                      'Joined',
                      AppColors.teal,
                    ),
                    if (user.isProvider) ...[
                      Container(width: 1, height: 30, color: AppColors.bg),
                      _statItemRich(
                        user.isVerified ? '\u2713' : '-',
                        'Verified',
                        user.isVerified ? AppColors.green : AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Content sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (user.isProvider && user.serviceCategories.isNotEmpty) ...[
                    _sectionCard(
                      'Services Offered',
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: user.serviceCategories.map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.tealLight,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tealDark,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _sectionCard(
                    'Details',
                    Column(
                      children: [
                        _detailRow(Icons.phone, user.phone),
                        _detailRow(Icons.person, user.isProvider ? 'Service Provider' : (user.isAdmin ? 'Admin' : 'Customer')),
                        if (user.isProvider && user.serviceDescription != null && user.serviceDescription!.isNotEmpty)
                          _detailRow(Icons.description_outlined, user.serviceDescription!),
                        if (user.isProvider)
                          _detailRow(Icons.access_time, 'Mon-Sat, 8:00 AM - 8:00 PM'),
                        _detailRow(Icons.location_on,
                            [user.serviceArea, user.city, user.state].where((s) => s != null && s.isNotEmpty).join(', ').isNotEmpty
                                ? [user.serviceArea, user.city, user.state].where((s) => s != null && s.isNotEmpty).join(', ')
                                : 'Location not set — tap Settings to add'),
                        if (user.hourlyRate != null)
                          _detailRow(Icons.currency_rupee,
                              '\u20B9${user.hourlyRate!.toInt()}/visit'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Admin link (shown for admin users)
                  if (user.isAdmin)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminScreen()),
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
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: AppColors.teal),
                            const SizedBox(width: 12),
                            const Text(
                              'Admin Panel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItemRich(String value, String label, Color accentColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
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
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showSettings(BuildContext context) {
    final appProvider = context.read<AppProvider>();
    final user = appProvider.currentUser;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.teal),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                _showEditProfileDialog(context);
              },
            ),
            if (user != null && !user.isVerified)
              ListTile(
                leading: const Icon(Icons.verified_user, color: AppColors.orange),
                title: const Text('Verify Aadhaar'),
                subtitle: Text(
                  user.aadhaarDocUrl != null ? 'Verification pending' : 'Upload your Aadhaar card',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAadhaarUploadDialog(context);
                },
              ),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.red),
              title: Text('Sign Out', style: TextStyle(color: AppColors.red)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AppProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final appProvider = context.read<AppProvider>();
    final user = appProvider.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final descCtrl = TextEditingController(text: user.serviceDescription ?? '');
    final rateCtrl = TextEditingController(
      text: user.hourlyRate != null ? user.hourlyRate!.toInt().toString() : '',
    );
    final areaCtrl = TextEditingController(text: user.serviceArea ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 16),
                const Text('Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Your full name', isDense: true),
                ),
                if (user.isProvider) ...[
                  const SizedBox(height: 14),
                  const Text('Service Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    maxLength: 200,
                    decoration: const InputDecoration(hintText: 'Describe your services', isDense: true),
                  ),
                  const SizedBox(height: 8),
                  const Text('Rate per Visit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(hintText: 'e.g. 500', prefixText: '\u20B9 ', isDense: true),
                  ),
                  const SizedBox(height: 14),
                  const Text('Service Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: areaCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. Andheri West', isDense: true),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.red),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              final updates = <String, dynamic>{
                                'name': name,
                              };
                              if (user.isProvider) {
                                updates['serviceDescription'] = descCtrl.text.trim();
                                updates['serviceArea'] = areaCtrl.text.trim();
                                if (rateCtrl.text.isNotEmpty) {
                                  updates['hourlyRate'] = double.tryParse(rateCtrl.text) ?? 0;
                                }
                              }
                              await AuthService().updateUserProfile(user.uid, updates);
                              await appProvider.loadCurrentUser();
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Profile updated successfully!'),
                                    backgroundColor: AppColors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to save: $e'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAadhaarUploadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AadhaarUploadSheet(),
    );
  }
}

class _AadhaarUploadSheet extends StatefulWidget {
  const _AadhaarUploadSheet();

  @override
  State<_AadhaarUploadSheet> createState() => _AadhaarUploadSheetState();
}

class _AadhaarUploadSheetState extends State<_AadhaarUploadSheet> {
  XFile? _imageFile;
  File? _image;
  bool _uploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _imageFile = image;
        if (!kIsWeb) _image = File(image.path);
      });
    }
  }

  Future<void> _upload() async {
    if (_imageFile == null) return;
    setState(() => _uploading = true);

    try {
      final appProvider = context.read<AppProvider>();
      final user = appProvider.currentUser!;
      final storageService = StorageService();

      final downloadUrl = await storageService.uploadAadhaarDoc(user.uid, _imageFile!);
      await AuthService().updateUserProfile(user.uid, {
        'aadhaarDocUrl': downloadUrl,
        'verificationStatus': 'pending',
      });
      await appProvider.loadCurrentUser();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Aadhaar uploaded! Verification pending.'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Upload failed. Please try again.'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Verify Aadhaar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          Text(
            'Upload a clear photo of your Aadhaar card. Our admin will verify it within 24 hours.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _uploading ? null : _pickImage,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _imageFile != null ? AppColors.green : AppColors.tealLight,
                  width: 1.5,
                ),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? const Center(child: Icon(Icons.image, size: 40, color: AppColors.green))
                          : Image.file(_image!, fit: BoxFit.cover, width: double.infinity, height: 140),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.teal.withAlpha(150)),
                        const SizedBox(height: 8),
                        const Text('Tap to select Aadhaar photo', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _imageFile == null || _uploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _uploading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Upload & Submit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
