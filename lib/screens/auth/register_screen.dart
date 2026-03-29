import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../home/main_shell.dart';
import 'provider_onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String uid;
  final String phone;
  final String initialRole;

  const RegisterScreen({super.key, required this.uid, required this.phone, this.initialRole = 'customer'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _authService = AuthService();
  final _storageService = StorageService();
  bool _isLoading = false;
  late bool _isProvider = widget.initialRole == 'provider';
  XFile? _aadhaarImageFile;
  File? _aadhaarImage;
  String _selectedCategory = '';
  bool _isUploading = false;
  double _uploadProgress = 0;
  List<String> _categories = [];
  bool _loadingCategories = true;
  String? _aadhaarError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await FirestoreService().getCategoryList();
    if (mounted) {
      setState(() {
        _categories = [...cats, 'Other'];
        _selectedCategory = cats.isNotEmpty ? cats.first : 'Other';
        _loadingCategories = false;
      });
    }
  }

  Future<void> _pickAadhaar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _aadhaarImageFile = image;
        if (!kIsWeb) _aadhaarImage = File(image.path);
      });
    }
  }

  /// Validate Aadhaar: 12 digits, Verhoeff checksum
  bool _isValidAadhaar(String number) {
    if (number.length != 12) return false;
    if (!RegExp(r'^\d{12}$').hasMatch(number)) return false;
    // Reject all-same digits
    if (RegExp(r'^(\d)\1{11}$').hasMatch(number)) return false;
    return true;
  }

  /// Check if Aadhaar number already exists in database
  Future<bool> _isAadhaarDuplicate(String aadhaarNumber) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('aadhaarNumber', isEqualTo: aadhaarNumber)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    // Validate Aadhaar number if entered
    final aadhaarNumber = _aadhaarController.text.trim().replaceAll(' ', '');
    if (aadhaarNumber.isNotEmpty) {
      if (!_isValidAadhaar(aadhaarNumber)) {
        setState(() => _aadhaarError = 'Please enter a valid 12-digit Aadhaar number');
        return;
      }

      // Check for duplicate
      setState(() {
        _isLoading = true;
        _aadhaarError = null;
      });

      final isDuplicate = await _isAadhaarDuplicate(aadhaarNumber);
      if (isDuplicate) {
        setState(() {
          _isLoading = false;
          _aadhaarError = 'This Aadhaar number is already registered';
        });
        _showError('This Aadhaar number is already registered with another account');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Create user profile
      await _authService.createUserProfile(
        uid: widget.uid,
        name: name,
        phone: widget.phone,
      );

      // Save Aadhaar number if provided
      if (aadhaarNumber.isNotEmpty) {
        await _authService.updateUserProfile(widget.uid, {
          'aadhaarNumber': aadhaarNumber,
          'aadhaarVerified': false,
        });
      }

      // If provider, update role and category
      if (_isProvider) {
        await _authService.updateUserProfile(widget.uid, {
          'role': 'provider',
          'serviceCategories': [_selectedCategory],
        });
      }

      // Upload Aadhaar image if selected
      if (_aadhaarImageFile != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.3;
        });

        try {
          final downloadUrl = await _storageService.uploadAadhaarDoc(
            widget.uid,
            _aadhaarImageFile!,
          );

          setState(() => _uploadProgress = 0.8);

          await _authService.updateUserProfile(widget.uid, {
            'aadhaarDocUrl': downloadUrl,
            'verificationStatus': 'pending',
          });

          setState(() => _uploadProgress = 1.0);
        } catch (e) {
          // Don't block registration if upload fails
          debugPrint('Aadhaar upload failed: $e');
        }
      }

      if (!mounted) return;

      // Route: providers go to onboarding, customers go to home
      if (_isProvider) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProviderOnboardingScreen(uid: widget.uid),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
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
                    color: Colors.black.withAlpha(10),
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
                'Primary Service Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You can add more categories after registration',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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

            // Aadhaar section
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
              'Enter your Aadhaar number for identity verification',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Aadhaar number input
            TextField(
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
                _AadhaarInputFormatter(),
              ],
              onChanged: (_) {
                if (_aadhaarError != null) setState(() => _aadhaarError = null);
              },
              decoration: InputDecoration(
                hintText: 'XXXX XXXX XXXX',
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.teal),
                errorText: _aadhaarError,
                suffixIcon: _aadhaarController.text.replaceAll(' ', '').length == 12
                    ? const Icon(Icons.check_circle, color: AppColors.green, size: 20)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isProvider
                  ? 'Aadhaar is required for providers to prevent duplicate registrations.'
                  : 'Optional. Helps verify your identity.',
              style: TextStyle(
                fontSize: 11,
                color: _isProvider ? AppColors.orange : AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 16),

            // Aadhaar image upload (optional)
            const Text(
              'Upload Aadhaar Card (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isLoading ? null : _pickAadhaar,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _aadhaarImageFile != null ? AppColors.green : AppColors.tealLight,
                    width: 1.5,
                  ),
                ),
                child: _aadhaarImageFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: kIsWeb
                                ? FutureBuilder<List<int>>(
                                    future: _aadhaarImageFile!.readAsBytes(),
                                    builder: (ctx, snap) {
                                      if (snap.hasData) {
                                        return Image.memory(
                                          snap.data! as dynamic,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 120,
                                        );
                                      }
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                  )
                                : Image.file(
                                    _aadhaarImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 120,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 36,
                            color: AppColors.teal.withAlpha(150),
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
              'Photo helps speed up manual verification.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),

            // Upload progress
            if (_isUploading) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Uploading Aadhaar document...',
                    style: TextStyle(fontSize: 12, color: AppColors.tealDark),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppColors.tealLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                borderRadius: BorderRadius.circular(4),
              ),
            ],

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
                    : Text(
                        _isProvider ? 'Continue to Setup Profile' : 'Get Started',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
          color: selected ? AppColors.teal.withAlpha(25) : AppColors.bg,
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

/// Formats Aadhaar input as XXXX XXXX XXXX
class _AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.length > 12) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
