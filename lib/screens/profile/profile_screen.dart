import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/update_service.dart';
import '../../widgets/update_dialog.dart';
import '../admin/admin_panel.dart';
import '../auth/login_screen.dart';
import '../wallet/wallet_screen.dart';

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

                      // Avatar with profile photo
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: user.profilePhotoUrl == null
                              ? const LinearGradient(colors: [AppColors.orange, Color(0xFFFF9800)])
                              : null,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 4,
                          ),
                          image: user.profilePhotoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(user.profilePhotoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user.profilePhotoUrl == null
                            ? Center(
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
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

                  // Admin link (shown for admin & moderator users)
                  if (user.hasAdminAccess)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AdminPanel(currentUser: user)),
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
              leading: Icon(Icons.stars_rounded, color: AppColors.orange),
              title: const Text('Sathi Wallet'),
              subtitle: Text(
                'View your reward points',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.system_update, color: AppColors.teal),
              title: const Text('Check for Updates'),
              subtitle: Text(
                'v1.9.1',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              onTap: () {
                Navigator.pop(context);
                _checkForUpdates(context);
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditProfilePage(user: user, appProvider: appProvider),
      ),
    );
  }

  void _checkForUpdates(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
    );

    try {
      final updateService = UpdateService();
      final result = await updateService.checkForUpdate();

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading

      if (result.type != UpdateType.none && result.info != null) {
        showDialog(
          context: context,
          barrierDismissible: result.type != UpdateType.forced,
          builder: (_) => UpdateDialog(
            updateType: result.type,
            versionInfo: result.info!,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You\'re on the latest version!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not check for updates. Try again later.'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

class _EditProfilePage extends StatefulWidget {
  final UserModel user;
  final AppProvider appProvider;
  const _EditProfilePage({required this.user, required this.appProvider});

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _areaCtrl;
  bool _saving = false;
  bool _uploadingPhoto = false;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u.name);
    _emailCtrl = TextEditingController(text: u.email ?? '');
    _cityCtrl = TextEditingController(text: u.city ?? '');
    _stateCtrl = TextEditingController(text: u.state ?? '');
    _descCtrl = TextEditingController(text: u.serviceDescription ?? '');
    _rateCtrl = TextEditingController(
        text: u.hourlyRate != null ? u.hourlyRate!.toInt().toString() : '');
    _areaCtrl = TextEditingController(text: u.serviceArea ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _descCtrl.dispose();
    _rateCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (image == null) return;

    setState(() {
      _pickedImage = image;
      _uploadingPhoto = true;
    });

    try {
      final url = await StorageService().uploadProfilePhoto(widget.user.uid, image);
      await AuthService().updateUserProfile(widget.user.uid, {'profilePhotoUrl': url});
      await widget.appProvider.loadCurrentUser();
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo updated!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final updates = <String, dynamic>{
        'name': name,
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      };

      if (widget.user.isProvider) {
        updates['serviceDescription'] = _descCtrl.text.trim();
        updates['serviceArea'] = _areaCtrl.text.trim();
        if (_rateCtrl.text.isNotEmpty) {
          updates['hourlyRate'] = double.tryParse(_rateCtrl.text) ?? 0;
        }
      }

      await AuthService().updateUserProfile(widget.user.uid, updates);
      await widget.appProvider.loadCurrentUser();

      if (mounted) {
        Navigator.pop(context);
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
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile photo section
          Center(
            child: GestureDetector(
              onTap: _uploadingPhoto ? null : _pickProfilePhoto,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.tealLight,
                      border: Border.all(color: AppColors.teal, width: 3),
                      image: _pickedImage != null && !kIsWeb
                          ? DecorationImage(image: FileImage(File(_pickedImage!.path)), fit: BoxFit.cover)
                          : user.profilePhotoUrl != null
                              ? DecorationImage(image: NetworkImage(user.profilePhotoUrl!), fit: BoxFit.cover)
                              : null,
                    ),
                    child: _uploadingPhoto
                        ? const Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))
                        : (user.profilePhotoUrl == null && _pickedImage == null)
                            ? Icon(Icons.person, size: 48, color: AppColors.teal.withOpacity(0.5))
                            : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Tap to change photo',
              style: TextStyle(fontSize: 12, color: AppColors.tealDark, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),

          // Basic info section
          _sectionLabel('Basic Information'),
          const SizedBox(height: 10),
          _fieldCard([
            _formField('Full Name', _nameCtrl, Icons.person, TextInputType.name, TextCapitalization.words),
            _formField('Email (optional)', _emailCtrl, Icons.email, TextInputType.emailAddress, TextCapitalization.none),
            _formField('City', _cityCtrl, Icons.location_city, TextInputType.text, TextCapitalization.words),
            _formField('State', _stateCtrl, Icons.map, TextInputType.text, TextCapitalization.words),
          ]),

          // Provider-specific fields
          if (user.isProvider) ...[
            const SizedBox(height: 20),
            _sectionLabel('Service Information'),
            const SizedBox(height: 10),
            _fieldCard([
              _formField('Service Description', _descCtrl, Icons.description, TextInputType.text, TextCapitalization.sentences, maxLines: 3, maxLength: 200),
              _formField('Service Area', _areaCtrl, Icons.place, TextInputType.text, TextCapitalization.words),
              _formField('Rate per Visit (\u20B9)', _rateCtrl, Icons.currency_rupee, TextInputType.number, TextCapitalization.none),
            ]),
          ],

          // Read-only info
          const SizedBox(height: 20),
          _sectionLabel('Account Details'),
          const SizedBox(height: 10),
          _infoCard([
            _readOnlyRow(Icons.phone, 'Phone', user.phone),
            _readOnlyRow(Icons.shield, 'Local Sathi ID', user.localSathiId),
            _readOnlyRow(Icons.person_outline, 'Role', user.role.name[0].toUpperCase() + user.role.name.substring(1)),
            _readOnlyRow(Icons.verified_user, 'Verification', user.isVerified ? 'Verified' : user.verificationStatus.name),
            if (user.isProvider)
              _readOnlyRow(Icons.star, 'Rating', '${user.rating.toStringAsFixed(1)} (${user.reviewCount} reviews)'),
          ]),

          const SizedBox(height: 28),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text));
  }

  Widget _fieldCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(children: children),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, IconData icon, TextInputType keyType, TextCapitalization cap, {int maxLines = 1, int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: keyType,
        textCapitalization: cap,
        maxLines: maxLines,
        maxLength: maxLength,
        inputFormatters: keyType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: Icon(icon, size: 20, color: AppColors.teal),
          filled: true,
          fillColor: AppColors.bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(children: children),
    );
  }

  Widget _readOnlyRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
