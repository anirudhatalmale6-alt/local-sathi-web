import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../home/main_shell.dart';

class RegisterScreen extends StatefulWidget {
  final String uid;
  final String phone;

  const RegisterScreen({super.key, required this.uid, required this.phone});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isProvider = false;
  File? _aadhaarImage;
  String _selectedCategory = 'Electrician';

  final _categories = [
    'Electrician', 'Plumber', 'Tutor', 'Carpenter',
    'Painter', 'AC Repair', 'Cleaner', 'Driver', 'Other',
  ];

  Future<void> _pickAadhaar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _aadhaarImage = File(image.path));
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.createUserProfile(
        uid: widget.uid,
        name: name,
        phone: widget.phone,
      );

      // If provider, update role
      if (_isProvider) {
        await _authService.updateUserProfile(widget.uid, {
          'role': 'provider',
          'serviceCategories': [_selectedCategory],
        });
      }

      // TODO: Upload Aadhaar image to Firebase Storage

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Registration failed. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Create Profile'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            const Text(
              'Your Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.teal),
              ),
            ),
            const SizedBox(height: 24),

            // Role toggle
            Container(
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
                  const Text(
                    'I want to...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _roleCard(
                          'Find Services',
                          Icons.search,
                          !_isProvider,
                          () => setState(() => _isProvider = false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _roleCard(
                          'Offer Services',
                          Icons.handyman,
                          _isProvider,
                          () => setState(() => _isProvider = true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_isProvider) ...[
              const SizedBox(height: 24),
              const Text(
                'Service Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.teal : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected ? AppColors.teal : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        cat,
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
            ],

            const SizedBox(height: 24),

            // Aadhaar upload
            const Text(
              'Aadhaar Verification',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload your Aadhaar card for identity verification',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickAadhaar,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.tealLight,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _aadhaarImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _aadhaarImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 36,
                            color: AppColors.teal.withOpacity(0.6),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to upload Aadhaar card',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can skip this now and verify later from your profile.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),

            const SizedBox(height: 32),

            // Register button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(String title, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal.withOpacity(0.1) : AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.teal : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: selected ? AppColors.teal : AppColors.textMuted),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.teal : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
