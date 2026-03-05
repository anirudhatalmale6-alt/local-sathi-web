import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../home/main_shell.dart';

class ProviderOnboardingScreen extends StatefulWidget {
  final String uid;
  const ProviderOnboardingScreen({super.key, required this.uid});

  @override
  State<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  final _pageController = PageController();
  final _authService = AuthService();
  final _storageService = StorageService();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Service details
  final _descriptionController = TextEditingController();
  final _rateController = TextEditingController();
  final _selectedCategories = <String>{};
  List<String> _allCategories = [];
  bool _loadingCategories = true;

  // Step 2: Location
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _detectingLocation = false;

  // Step 3: Profile photo
  XFile? _profilePhotoFile;
  File? _profilePhoto;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await FirestoreService().getCategoryList();
    if (mounted) {
      setState(() {
        _allCategories = [...cats, 'Other'];
        _loadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedCategories.isEmpty) {
        _showError('Select at least one service category');
        return;
      }
      if (_descriptionController.text.trim().isEmpty) {
        _showError('Please describe your services');
        return;
      }
    } else if (_currentStep == 1) {
      if (_cityController.text.trim().isEmpty) {
        _showError('Please enter your city');
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep++);
  }

  void _prevStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep--);
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        _lat = position.latitude;
        _lng = position.longitude;
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (address != null && mounted) {
          setState(() {
            _areaController.text = address['area'] ?? '';
            _cityController.text = address['city'] ?? '';
            _stateController.text = address['state'] ?? '';
          });
        }
      } else {
        if (mounted) _showError('Could not detect location. Please enter manually.');
      }
    } catch (e) {
      if (mounted) _showError('Location detection failed. Please enter manually.');
    }
    if (mounted) setState(() => _detectingLocation = false);
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _profilePhotoFile = image;
        if (!kIsWeb) _profilePhoto = File(image.path);
      });
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{
        'serviceCategories': _selectedCategories.toList(),
        'serviceDescription': _descriptionController.text.trim(),
        'serviceArea': _areaController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
      };

      if (_rateController.text.isNotEmpty) {
        updates['hourlyRate'] = double.tryParse(_rateController.text) ?? 0;
      }

      if (_lat != null && _lng != null) {
        updates['latitude'] = _lat;
        updates['longitude'] = _lng;
      }

      // Upload profile photo
      if (_profilePhotoFile != null) {
        try {
          final photoUrl = await _storageService.uploadProfilePhoto(
            widget.uid,
            _profilePhotoFile!,
          );
          updates['profilePhotoUrl'] = photoUrl;
        } catch (e) {
          debugPrint('Profile photo upload failed: $e');
        }
      }

      await _authService.updateUserProfile(widget.uid, updates);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to save profile. Please try again.');
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
        title: const Text('Setup Your Profile'),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _currentStep ? AppColors.teal : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  ['Services', 'Location', 'Photo'][_currentStep],
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal),
                ),
              ],
            ),
          ),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildServiceStep(),
                _buildLocationStep(),
                _buildPhotoStep(),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _prevStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: _currentStep > 0 ? 2 : 1,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_currentStep < 2 ? _nextStep : _finishOnboarding),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _currentStep < 2 ? 'Next' : 'Finish Setup',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What services do you offer?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Select all that apply',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          if (_loadingCategories)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.teal),
            )),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allCategories.map((cat) {
              final selected = _selectedCategories.contains(cat);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedCategories.remove(cat);
                    } else {
                      _selectedCategories.add(cat);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.teal : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selected ? AppColors.teal : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.check, size: 16, color: Colors.white),
                        ),
                      Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Describe your services',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'e.g. 10+ years experience in home wiring, fan installation, switchboard repair...',
              hintStyle: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hourly / Visit Rate (optional)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rateController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'e.g. 500',
              prefixText: '\u20B9 ',
              prefixStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where do you provide services?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            'This helps nearby customers find you',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          // Auto-detect button
          if (!kIsWeb)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _detectingLocation ? null : _detectLocation,
                icon: _detectingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(_detectingLocation ? 'Detecting...' : 'Auto-detect My Location'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.teal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

          if (!kIsWeb) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'or enter manually below',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Text('Area / Locality', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 6),
          TextField(
            controller: _areaController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Andheri West',
              prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.teal, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          const Text('City', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 6),
          TextField(
            controller: _cityController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Mumbai',
              prefixIcon: Icon(Icons.location_city, color: AppColors.teal, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          const Text('State', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 6),
          TextField(
            controller: _stateController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Maharashtra',
              prefixIcon: Icon(Icons.map_outlined, color: AppColors.teal, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add a profile photo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Customers trust profiles with photos more',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 32),

          Center(
            child: GestureDetector(
              onTap: _pickProfilePhoto,
              child: Stack(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.tealLight,
                      border: Border.all(color: AppColors.teal, width: 3),
                      image: _profilePhotoFile != null && !kIsWeb
                          ? DecorationImage(
                              image: FileImage(_profilePhoto!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profilePhotoFile == null
                        ? const Icon(Icons.person, size: 60, color: AppColors.teal)
                        : (kIsWeb
                            ? FutureBuilder<List<int>>(
                                future: _profilePhotoFile!.readAsBytes(),
                                builder: (ctx, snap) {
                                  if (snap.hasData) {
                                    return ClipOval(
                                      child: Image.memory(
                                        snap.data! as dynamic,
                                        fit: BoxFit.cover,
                                        width: 150,
                                        height: 150,
                                      ),
                                    );
                                  }
                                  return const Icon(Icons.person, size: 60, color: AppColors.teal);
                                },
                              )
                            : null),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              _profilePhotoFile != null ? 'Tap to change photo' : 'Tap to add photo',
              style: const TextStyle(fontSize: 14, color: AppColors.teal, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _finishOnboarding,
              child: const Text(
                'Skip for now',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
