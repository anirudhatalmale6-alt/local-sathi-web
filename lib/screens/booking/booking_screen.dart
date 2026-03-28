import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/booking_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/banner_ad_widget.dart';

class CreateBookingScreen extends StatefulWidget {
  final UserModel provider;
  const CreateBookingScreen({super.key, required this.provider});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 10, minute: 0);
  String? _selectedCategory;
  bool _submitting = false;
  double _commissionRate = 10.0;

  @override
  void initState() {
    super.initState();
    if (widget.provider.serviceCategories.isNotEmpty) {
      _selectedCategory = widget.provider.serviceCategories.first;
    }
    _loadCommissionRate();
  }

  Future<void> _loadCommissionRate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('monetisation')
          .get();
      if (doc.exists) {
        final rate = (doc.data()?['commissionRate'] as num?)?.toDouble();
        if (rate != null && mounted) {
          setState(() => _commissionRate = rate);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (_descController.text.trim().isEmpty) {
      _showError('Please describe the work needed');
      return;
    }

    final user = context.read<AppProvider>().currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    final price = double.tryParse(_priceController.text.trim());
    final commission = price != null ? (price * _commissionRate / 100) : 0.0;

    final scheduled = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    final booking = BookingModel(
      id: '',
      customerUid: user.uid,
      customerName: user.name,
      providerUid: widget.provider.uid,
      providerName: widget.provider.name,
      serviceCategory: _selectedCategory ?? 'General',
      description: _descController.text.trim(),
      agreedPrice: price,
      commissionRate: _commissionRate,
      commissionAmount: commission,
      scheduledAt: scheduled,
      createdAt: DateTime.now(),
      customerPhone: user.phone,
      providerPhone: widget.provider.phone,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
    );

    try {
      await FirebaseFirestore.instance.collection('bookings').add(booking.toFirestore());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking request sent!'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to create booking: $e');
    }

    if (mounted) setState(() => _submitting = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final price = double.tryParse(_priceController.text.trim());
    final commission = price != null ? (price * _commissionRate / 100) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Book Service'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.teal.withOpacity(0.1),
                    child: Text(
                      provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.teal),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(provider.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(
                          provider.serviceCategories.join(', '),
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        if (provider.hourlyRate != null)
                          Text(
                            '\u20B9${provider.hourlyRate}/hr',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.teal),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Banner Ad
            const BannerAdWidget(),
            const SizedBox(height: 16),

            // Category selector
            if (provider.serviceCategories.length > 1) ...[
              const Text('Service Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: provider.serviceCategories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    selectedColor: AppColors.teal.withOpacity(0.2),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            const Text('Describe the work', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Fix leaking kitchen tap, replace washer...',
              ),
            ),
            const SizedBox(height: 16),

            // Price
            const Text('Agreed Price (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'e.g. 500',
                prefixText: '\u20B9 ',
              ),
            ),
            if (price != null && price > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Platform fee: \u20B9${commission.toStringAsFixed(0)} (${_commissionRate.toStringAsFixed(0)}%) | You pay: \u20B9${price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Location
            const Text('Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Your address or area',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time
            const Text('Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _scheduledDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (date != null) setState(() => _scheduledDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.bg),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: AppColors.teal),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy').format(_scheduledDate)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _scheduledTime,
                      );
                      if (time != null) setState(() => _scheduledTime = time);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.bg),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: AppColors.teal),
                          const SizedBox(width: 8),
                          Text(_scheduledTime.format(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Booking Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
