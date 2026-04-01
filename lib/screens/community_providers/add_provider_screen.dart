import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';

class AddProviderScreen extends StatefulWidget {
  const AddProviderScreen({super.key});

  @override
  State<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends State<AddProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;
  final _firestoreService = FirestoreService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a service category')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    final user = context.read<AppProvider>().currentUser!;

    final phone = '+91${_phoneController.text.trim()}';
    final result = await _firestoreService.addCommunityProvider(
      name: _nameController.text.trim(),
      phone: phone,
      category: _selectedCategory!,
      area: _areaController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      createdByUserId: user.uid,
      createdByUserName: user.name,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result == null) {
      // Success
      _showSuccessDialog();
    } else if (result == 'daily_limit') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add max 5 providers per day. Try again tomorrow!'), backgroundColor: Colors.orange),
      );
    } else if (result == 'duplicate') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This provider already exists in our directory!'), backgroundColor: Colors.orange),
      );
    } else if (result == 'exists_as_user') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This person is already registered on Local Sathi!'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.green, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Provider Added!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 8),
            const Text(
              'Pending admin approval. You will earn +20 points once approved!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Share.share(
                        'I just added ${_nameController.text} (${_selectedCategory}) to Local Sathi! Find trusted service providers near you. Download now: https://localsathitechnologies.in',
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Add a Provider', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.teal.withAlpha(20), AppColors.teal.withAlpha(8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.teal.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.teal.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.volunteer_activism, color: AppColors.teal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Help your community!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                          SizedBox(height: 2),
                          Text('Add a local service provider. Earn +20 points on approval.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name
              const Text('Provider Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                decoration: _inputDecoration('e.g. Ramesh Kumar', Icons.person),
              ),
              const SizedBox(height: 16),

              // Phone
              const Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                validator: (v) => v == null || v.trim().length != 10 ? 'Enter 10-digit number' : null,
                decoration: _inputDecoration('10-digit phone number', Icons.phone).copyWith(
                  prefixText: '+91 ',
                  prefixStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              const Text('Service Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.allCategories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.teal : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.teal : Colors.grey.shade300),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Area
              const Text('Area / Locality', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _areaController,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter area' : null,
                decoration: _inputDecoration('e.g. Nehru Nagar, Indore', Icons.location_on),
              ),
              const SizedBox(height: 16),

              // Description (optional)
              const Text('Notes (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                maxLength: 200,
                decoration: _inputDecoration('e.g. Good for urgent work, available on weekends', Icons.note),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_circle, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Add Provider',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    disabledBackgroundColor: AppColors.teal.withAlpha(150),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: AppColors.teal, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.teal, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
