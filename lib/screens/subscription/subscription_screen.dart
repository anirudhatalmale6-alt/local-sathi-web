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

          await PaymentService.recordPayment(
            paymentId: paymentId,
            type: 'subscription',
            userUid: user.uid,
            amount: price,
            commission: 0,
            metadata: {'plan': plan.name},
          );

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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.text),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Current plan banner
                      if (_currentSub != null && _currentSub!.isActiveNow)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: _currentPlanBanner(),
                        ),

                      // Hero section
                      _heroSection(),

                      const SizedBox(height: 8),

                      // Monthly plans label
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_month, size: 16, color: AppColors.teal),
                                  SizedBox(width: 6),
                                  Text(
                                    'Monthly Plans',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Plan cards - Provider Pro FIRST (highlighted)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _proCard(),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _premiumCard(),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _basicCard(),
                      ),

                      const SizedBox(height: 28),

                      // Comparison nudge
                      _comparisonSection(),

                      const SizedBox(height: 20),

                      // Trust section
                      _trustSection(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _heroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.teal.withOpacity(0.08),
            AppColors.gold.withOpacity(0.06),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF00897B)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Go PRO with Local Sathi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Get more visibility, more bookings & zero ads',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ₹199 Provider Pro - THE MONEY MAKER
  Widget _proCard() {
    final plan = SubscriptionPlan.providerPremium;
    final isCurrent = _currentSub?.plan == plan && _currentSub?.isActiveNow == true;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFFB300)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.rocket_launch, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Provider Pro',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '\u20B9199',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFE65100)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4, left: 2),
                              child: Text('/month', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Features with icons
              _featureRow(Icons.block, 'No Ads', 'Clean, distraction-free experience'),
              _featureRow(Icons.trending_up, 'Top Search Placement', 'Be the first provider customers see'),
              _featureRow(Icons.star, 'Featured Listing', 'Stand out with a highlighted profile'),
              _featureRow(Icons.people, 'More Customer Leads', 'Get shown to more users first'),
              _featureRow(Icons.percent, 'Lower Commission', '2% less on every booking'),
              _featureRow(Icons.bar_chart, 'Basic Analytics', 'Track views & bookings'),

              const SizedBox(height: 14),

              // Value proposition
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('\u{1F4B0}', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Earn \u20B91,000+ extra monthly with more bookings',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!isCurrent) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _subscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: const Color(0xFFE65100).withOpacity(0.4),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get More Customers',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 8),
                        Text('\u{1F680}', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // "MOST POPULAR" floating tag
        Positioned(
          top: -12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFE65100)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE65100).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('\u2B50 ', style: TextStyle(fontSize: 13)),
                  Text(
                    'MOST POPULAR',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ₹99 Premium
  Widget _premiumCard() {
    final plan = SubscriptionPlan.premium;
    final isCurrent = _currentSub?.plan == plan && _currentSub?.isActiveNow == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent ? Border.all(color: AppColors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.diamond, color: AppColors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Premium', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.text)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('\u20B999', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.blue)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3, left: 2),
                          child: Text('/month', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _featureRowSimple(Icons.block, 'No Ads', AppColors.blue),
          _featureRowSimple(Icons.verified, 'Verified Badge', AppColors.blue),
          _featureRowSimple(Icons.visibility, 'Better Visibility', AppColors.blue),
          _featureRowSimple(Icons.category, 'Priority Listing', AppColors.blue),
          if (!isCurrent) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _subscribe(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Get Premium', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ₹49 Basic - entry level, kept minimal
  Widget _basicCard() {
    final plan = SubscriptionPlan.basic;
    final isCurrent = _currentSub?.plan == plan && _currentSub?.isActiveNow == true;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCurrent ? Border.all(color: AppColors.green, width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_outline, color: AppColors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Basic', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('\u20B949', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.green)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2, left: 2),
                          child: Text('/month', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _featureRowSimple(Icons.block, 'No Ads', AppColors.green),
          _featureRowSimple(Icons.speed, 'Smooth Experience', AppColors.green),
          if (!isCurrent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _subscribe(plan),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Get Basic', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Feature row with icon + title + subtitle (for Pro card)
  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFE65100)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simple feature row with icon + text (for Basic/Premium)
  Widget _featureRowSimple(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _comparisonSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.teal.withOpacity(0.06), AppColors.teal.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.teal.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Text('\u{1F4CA}', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Did you know?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text('Free Users', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text('Standard visibility', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const Icon(Icons.trending_flat, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('vs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text('Pro Users', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFE65100))),
                        const SizedBox(height: 4),
                        const Text('3x more bookings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                        const Icon(Icons.trending_up, color: Color(0xFFE65100), size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trustSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _trustItem(Icons.lock_outline, 'Secure\nPayments'),
          _trustItem(Icons.cancel_outlined, 'Cancel\nAnytime'),
          _trustItem(Icons.headset_mic_outlined, 'Support\nAvailable'),
        ],
      ),
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.teal, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _currentPlanBanner() {
    final info = SubscriptionModel.planInfo(_currentSub!.plan);
    final daysLeft = _currentSub!.expiresAt.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(info['color'] as int), Color(info['color'] as int).withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info['name']} Plan Active',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  '$daysLeft days remaining',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
