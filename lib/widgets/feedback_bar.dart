import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';
import '../models/feedback_model.dart';

class FeedbackBar extends StatelessWidget {
  final String userUid;
  final String userName;
  final String userLocalSathiId;

  const FeedbackBar({
    super.key,
    required this.userUid,
    required this.userName,
    required this.userLocalSathiId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFeedbackSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.teal.withAlpha(25),
              AppColors.blue.withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.tealLight, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tealLight,
              ),
              child: const Icon(Icons.rate_review_rounded, size: 18, color: AppColors.tealDark),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help us improve!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    'Rate your experience & share feedback',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.teal, size: 22),
          ],
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedbackSheet(
        userUid: userUid,
        userName: userName,
        userLocalSathiId: userLocalSathiId,
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  final String userUid;
  final String userName;
  final String userLocalSathiId;

  const _FeedbackSheet({
    required this.userUid,
    required this.userName,
    required this.userLocalSathiId,
  });

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  int _rating = 0;
  String _category = 'general';
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  final _categories = [
    {'id': 'general', 'label': 'General', 'icon': Icons.chat_bubble_outline},
    {'id': 'bug', 'label': 'Bug Report', 'icon': Icons.bug_report_outlined},
    {'id': 'feature', 'label': 'Feature Request', 'icon': Icons.lightbulb_outline},
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a star rating'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write your feedback'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final feedback = FeedbackModel(
        id: '',
        userUid: widget.userUid,
        userName: widget.userName,
        userLocalSathiId: widget.userLocalSathiId,
        rating: _rating,
        message: message,
        category: _category,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('feedback')
          .add(feedback.toFirestore());

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for your feedback! 🙏'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to submit. Please try again.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).viewInsets.top + 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withAlpha(77),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Share Your Feedback',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your feedback helps us build a better Local Sathi',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Star rating
              const Text(
                'How would you rate your experience?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedScale(
                        scale: _rating >= starIndex ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          _rating >= starIndex ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 40,
                          color: _rating >= starIndex ? AppColors.gold : AppColors.textMuted.withAlpha(100),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_rating > 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _ratingLabel(_rating),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _rating >= 4 ? AppColors.green : (_rating >= 3 ? AppColors.orange : AppColors.red),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Category
              const Text(
                'What type of feedback?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _categories.map((cat) {
                  final selected = _category == cat['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _category = cat['id'] as String),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.teal.withAlpha(25) : AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.teal : const Color(0xFFE5E7EB),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 22,
                              color: selected ? AppColors.teal : AppColors.textMuted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected ? AppColors.teal : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Message
              const Text(
                'Tell us more',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: _category == 'bug'
                      ? 'Describe the issue you encountered...'
                      : _category == 'feature'
                          ? 'What feature would you like to see?'
                          : 'Share your thoughts with us...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                  ),
                  fillColor: AppColors.bg,
                ),
              ),
              const SizedBox(height: 16),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Feedback',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Below Average';
      case 3: return 'Average';
      case 4: return 'Good';
      case 5: return 'Excellent!';
      default: return '';
    }
  }
}
