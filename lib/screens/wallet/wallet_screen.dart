import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/wallet_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _firestoreService = FirestoreService();
  final _paymentService = PaymentService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _paymentService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Gradient header with wallet balance
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00897B), Color(0xFF26A69A), Color(0xFF4DB6AC)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      // App bar
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(40),
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Sathi Wallet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 38),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Money Balance card
                      StreamBuilder<DocumentSnapshot>(
                        stream: _firestore.collection('wallets').doc(user.uid).snapshots(),
                        builder: (context, snapshot) {
                          double moneyBalance = 0;
                          int pointsBalance = 0;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final paise = (data?['moneyBalance'] ?? 0) as int;
                            moneyBalance = paise / 100.0;
                            pointsBalance = (data?['balance'] ?? 0) as int;
                          }
                          return Column(
                            children: [
                              // Money balance
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withAlpha(60)),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Wallet Balance',
                                      style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\u20B9${moneyBalance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Points badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(30),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.stars_rounded, size: 16, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$pointsBalance Sathi Points',
                                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          _walletActionBtn(Icons.add_circle_outline, 'Add Money', () => _showDepositSheet(context)),
                          const SizedBox(width: 10),
                          _walletActionBtn(Icons.arrow_upward, 'Withdraw', () => _showWithdrawSheet(context)),
                          const SizedBox(width: 10),
                          _walletActionBtn(Icons.swap_horiz, 'Transfer', () => _showTransferSheet(context)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tab bar for transaction types
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Money'),
                    Tab(text: 'Points'),
                  ],
                ),
              ),
            ),
          ),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _tabController.index == 0 ? AppColors.teal : AppColors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _tabController.index == 0 ? 'Money Transactions' : 'Points History',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                  ),
                ],
              ),
            ),
          ),

          // Transaction list
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('wallets')
                .doc(user.uid)
                .collection('transactions')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(child: _emptyState());
              }

              final allTx = snapshot.data!.docs.map((d) => WalletTransaction.fromFirestore(d)).toList();

              // Filter based on tab
              final transactions = _tabController.index == 0
                  ? allTx.where((tx) => [
                        WalletTransactionType.deposit,
                        WalletTransactionType.withdraw,
                        WalletTransactionType.transferIn,
                        WalletTransactionType.transferOut,
                      ].contains(tx.type)).toList()
                  : allTx.where((tx) => [
                        WalletTransactionType.earned,
                        WalletTransactionType.redeemed,
                        WalletTransactionType.bonus,
                      ].contains(tx.type)).toList();

              if (transactions.isEmpty) {
                return SliverToBoxAdapter(child: _emptyState());
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _transactionTile(transactions[index], index == transactions.length - 1),
                  childCount: transactions.length,
                ),
              );
            },
          ),

          // Earn points section (only show on points tab)
          if (_tabController.index == 1) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    const Text('How to Earn Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _earnCard(Icons.person_add, '+${SathiPoints.registration}', 'Sign Up', AppColors.teal),
                    _earnCard(Icons.article, '+${SathiPoints.firstPost}', 'Post', AppColors.blue),
                    _earnCard(Icons.star, '+${SathiPoints.review}', 'Review', AppColors.gold),
                    _earnCard(Icons.people, '+${SathiPoints.referral}', 'Refer', AppColors.orange),
                    _earnCard(Icons.login, '+${SathiPoints.dailyLogin}', 'Daily Login', AppColors.green),
                    _earnCard(Icons.verified, '+${SathiPoints.verificationApproved}', 'Get Verified', AppColors.tealDark),
                  ],
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _walletActionBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(60)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionTile(WalletTransaction tx, bool isLast) {
    final isCredit = tx.type == WalletTransactionType.deposit ||
        tx.type == WalletTransactionType.transferIn ||
        tx.type == WalletTransactionType.earned ||
        tx.type == WalletTransactionType.bonus;
    final isMoney = tx.amount != null && tx.amount! > 0;

    IconData icon;
    Color bgColor;
    Color iconColor;
    switch (tx.type) {
      case WalletTransactionType.deposit:
        icon = Icons.add_circle;
        bgColor = AppColors.greenLight;
        iconColor = AppColors.green;
        break;
      case WalletTransactionType.withdraw:
        icon = Icons.arrow_upward;
        bgColor = AppColors.redLight;
        iconColor = AppColors.red;
        break;
      case WalletTransactionType.transferIn:
        icon = Icons.call_received;
        bgColor = AppColors.greenLight;
        iconColor = AppColors.green;
        break;
      case WalletTransactionType.transferOut:
        icon = Icons.call_made;
        bgColor = AppColors.redLight;
        iconColor = AppColors.red;
        break;
      case WalletTransactionType.earned:
      case WalletTransactionType.bonus:
        icon = Icons.stars_rounded;
        bgColor = const Color(0xFFFFF3E0);
        iconColor = AppColors.orange;
        break;
      case WalletTransactionType.redeemed:
        icon = Icons.redeem;
        bgColor = AppColors.redLight;
        iconColor = AppColors.red;
        break;
    }

    String amountText;
    if (isMoney) {
      amountText = '${isCredit ? '+' : '-'}\u20B9${tx.amount!.toStringAsFixed(0)}';
    } else {
      amountText = '${isCredit ? '+' : '-'}${tx.points} pts';
    }

    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, isLast ? 20 : 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                Row(
                  children: [
                    Text(_formatTime(tx.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    if (tx.status == 'pending') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Pending', style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isCredit ? AppColors.green : AppColors.red),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('No transactions yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            _tabController.index == 0 ? 'Add money to start using your wallet!' : 'Start earning points by using Local Sathi!',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===== DEPOSIT BOTTOM SHEET =====
  void _showDepositSheet(BuildContext context) {
    final amountController = TextEditingController();
    final user = context.read<AppProvider>().currentUser!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Add Money', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 4),
            const Text('Add money to your Sathi Wallet via UPI, Card or Net Banking', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: '\u20B9 ',
                prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
                hintText: '0',
                hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.grey.shade300),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 12),
            // Quick amount chips
            Wrap(
              spacing: 8,
              children: [100, 200, 500, 1000, 2000].map((amt) {
                return GestureDetector(
                  onTap: () => amountController.text = '$amt',
                  child: Chip(
                    label: Text('\u20B9$amt', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    backgroundColor: AppColors.teal.withAlpha(20),
                    side: BorderSide(color: AppColors.teal.withAlpha(60)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum deposit is \u20B910')));
                    return;
                  }
                  Navigator.pop(ctx);
                  _processDeposit(amount, user.uid, user.name, user.phone);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Add Money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processDeposit(double amount, String uid, String name, String phone) {
    _paymentService.payForWalletDeposit(
      amount: amount,
      userName: name,
      userPhone: phone,
      userUid: uid,
      onSuccess: (paymentId) async {
        await _firestoreService.walletDeposit(uid, amount, paymentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('\u20B9${amount.toStringAsFixed(0)} added to wallet!'), backgroundColor: AppColors.green),
          );
        }
      },
      onFailure: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $msg'), backgroundColor: AppColors.red));
        }
      },
    );
  }

  // ===== WITHDRAW BOTTOM SHEET =====
  void _showWithdrawSheet(BuildContext context) {
    final amountController = TextEditingController();
    final upiController = TextEditingController();
    final user = context.read<AppProvider>().currentUser!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Withdraw Money', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 4),
            const Text('Money will be sent to your UPI ID within 24 hours', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: '\u20B9 ',
                prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
                hintText: '0',
                hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.grey.shade300),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upiController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter UPI ID (e.g. name@paytm)',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.account_balance, color: AppColors.teal),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  final upi = upiController.text.trim();
                  if (amount < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is \u20B910')));
                    return;
                  }
                  if (!upi.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid UPI ID')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await _firestoreService.walletWithdrawRequest(user.uid, user.name, amount, upi);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Withdrawal of \u20B9${amount.toStringAsFixed(0)} requested! Will be processed within 24 hours.'), backgroundColor: AppColors.teal),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.red));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Request Withdrawal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== TRANSFER BOTTOM SHEET =====
  void _showTransferSheet(BuildContext context) {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    final user = context.read<AppProvider>().currentUser!;
    String? recipientName;
    String? recipientUid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Transfer Money', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 4),
              const Text('Send money to another Local Sathi user', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              // Phone number
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                onChanged: (val) async {
                  if (val.length == 10) {
                    final result = await _firestoreService.findUserByPhone('+91$val');
                    setSheetState(() {
                      recipientName = result?['name'];
                      recipientUid = result?['uid'];
                    });
                  } else {
                    setSheetState(() {
                      recipientName = null;
                      recipientUid = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Enter 10-digit phone number',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.phone, color: AppColors.teal),
                  prefixText: '+91 ',
                  prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
              if (recipientName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(recipientName!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.green)),
                    ],
                  ),
                ),
              if (phoneController.text.length == 10 && recipientName == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.red, size: 18),
                      SizedBox(width: 6),
                      Text('User not found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // Amount
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: '\u20B9 ',
                  prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
                  hintText: '0',
                  hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.grey.shade300),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: recipientUid == null
                      ? null
                      : () async {
                          final amount = double.tryParse(amountController.text) ?? 0;
                          if (amount < 1) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                            return;
                          }
                          if (recipientUid == user.uid) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot transfer to yourself')));
                            return;
                          }
                          Navigator.pop(ctx);
                          final success = await _firestoreService.walletTransfer(
                            user.uid, user.name, recipientUid!, recipientName!, amount,
                          );
                          if (mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('\u20B9${amount.toStringAsFixed(0)} sent to $recipientName!'), backgroundColor: AppColors.green),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Insufficient wallet balance'), backgroundColor: AppColors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Send Money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _earnCard(IconData icon, String points, String label, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(points, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
