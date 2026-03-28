import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../models/subscription_model.dart';
import '../../providers/app_provider.dart';
import '../../services/ad_service.dart';
import '../../services/payment_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionModel? _currentSub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final uid = context.read<AppProvider>().currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(uid)
          .get();
      if (doc.exists) {
        _currentSub = SubscriptionModel.fromFirestore(doc);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final user = context.read<AppProvider>().currentUser;
    if (user == null) return;

    final info = SubscriptionModel.planInfo(plan);
    final price = (info['price'] as int).toDouble();

    // Trigger Razorpay payment
    PaymentService().payForSubscription(
      amount: price,
      planName: info['name'] as String,
      userName: user.name,
      userPhone: user.phone,
      userUid: user.uid,
      onSuccess: (paymentId) async {
        setState(() => _loading = true);

        final now = DateTime.now();
        final sub = SubscriptionModel(
          uid: user.uid,
          plan: plan,
          isActive: true,
          startedAt: now,
          expiresAt: now.add(const Duration(days: 30)),
          amountPaid: price,
          paymentId: paymentId,
        );

        try {
          await FirebaseFirestore.instance
              .collection('subscriptions')
              .doc(user.uid)
              .set(sub.toFirestore());

          // Record payment
          await PaymentService.recordPayment(
            paymentId: paymentId,
            type: 'subscription',
            userUid: user.uid,
            amount: price,
            commission: 0,
            metadata: {'plan': plan.name},
          );

          // Update ad service
          await AdService().checkSubscriptionStatus();

          _currentSub = sub;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${info['name']} plan activated!'),
                backgroundColor: AppColors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment received but activation failed: $e'),
                backgroundColor: AppColors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }

        if (mounted) setState(() => _loading = false);
      },
      onFailure: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: $msg'),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final isProvider = user?.isProvider == true;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current plan banner
                  if (_currentSub != null && _currentSub!.isActiveNow) ...[
                    _currentPlanBanner(),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remove ads and unlock premium features',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Plan cards
                  _planCard(SubscriptionPlan.free),
                  const SizedBox(height: 14),
                  _planCard(SubscriptionPlan.basic),
                  const SizedBox(height: 14),
                  _planCard(SubscriptionPlan.premium),
                  if (isProvider) ...[
                    const SizedBox(height: 14),
                    _planCard(SubscriptionPlan.providerPremium),
                  ],

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.teal, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Payments are processed securely via Razorpay. Subscriptions auto-renew every 30 days.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _currentPlanBanner() {
    final info = SubscriptionModel.planInfo(_currentSub!.plan);
    final daysLeft = _currentSub!.expiresAt.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(info['color'] as int), Color(info['color'] as int).withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info['name']} Plan Active',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$daysLeft days remaining',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(SubscriptionPlan plan) {
    final info = SubscriptionModel.planInfo(plan);
    final isCurrent = _currentSub?.plan == plan && _currentSub?.isActiveNow == true;
    final color = Color(info['color'] as int);
    final features = info['features'] as List<String>;
    final tag = info['tag'] as String?;
    final isHighlighted = tag != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(isHighlighted ? 22 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? color : (isHighlighted ? color : Colors.transparent),
              width: isHighlighted ? 2 : (isCurrent ? 2 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: isHighlighted ? color.withOpacity(0.12) : Colors.black.withOpacity(0.04),
                blurRadius: isHighlighted ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      plan == SubscriptionPlan.free
                          ? Icons.person_outline
                          : plan == SubscriptionPlan.providerPremium
                              ? Icons.rocket_launch
                              : plan == SubscriptionPlan.premium
                                  ? Icons.diamond
                                  : Icons.star_outline,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info['name'] as String,
                          style: TextStyle(
                            fontSize: isHighlighted ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          info['price'] == 0 ? 'Free forever' : '\u20B9${info['priceLabel']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Features
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  )),

              if (plan != SubscriptionPlan.free && !isCurrent) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _subscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: EdgeInsets.symmetric(vertical: isHighlighted ? 16 : 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isHighlighted ? 'Get Provider Pro' : 'Subscribe',
                      style: TextStyle(fontSize: isHighlighted ? 16 : 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // "Most Popular" tag
        if (isHighlighted)
          Positioned(
            top: -10,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                tag,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
