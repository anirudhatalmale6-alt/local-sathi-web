import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../provider_detail/provider_detail_screen.dart';

class EmergencySheet extends StatelessWidget {
  const EmergencySheet({super.key});

  static const List<Map<String, dynamic>> _emergencyNumbers = [
    {'name': 'Police', 'number': '100', 'icon': Icons.local_police, 'color': 0xFF1565C0},
    {'name': 'Fire', 'number': '101', 'icon': Icons.local_fire_department, 'color': 0xFFE53935},
    {'name': 'Ambulance', 'number': '102', 'icon': Icons.local_hospital, 'color': 0xFF43A047},
    {'name': 'Emergency', 'number': '112', 'icon': Icons.emergency, 'color': 0xFFF57C00},
    {'name': 'Women Help', 'number': '1091', 'icon': Icons.woman, 'color': 0xFFAD1457},
    {'name': 'Child Help', 'number': '1098', 'icon': Icons.child_care, 'color': 0xFF00897B},
  ];

  static const List<Map<String, dynamic>> _emergencyServices = [
    {'name': 'Electrician', 'icon': Icons.electrical_services, 'emoji': '\u26A1', 'desc': 'Power failure / sparking', 'color': 0xFFE3F2FD},
    {'name': 'Plumber', 'icon': Icons.plumbing, 'emoji': '\u{1F527}', 'desc': 'Water leak / pipe burst', 'color': 0xFFE0F2F1},
    {'name': 'AC Repair', 'icon': Icons.ac_unit, 'emoji': '\u2744\uFE0F', 'desc': 'AC breakdown', 'color': 0xFFE1F5FE},
    {'name': 'Pest Control', 'icon': Icons.pest_control, 'emoji': '\u{1F41B}', 'desc': 'Pest infestation', 'color': 0xFFFFF3E0},
    {'name': 'Security Guard', 'icon': Icons.security, 'emoji': '\u{1F6E1}\uFE0F', 'desc': 'Security emergency', 'color': 0xFFF3E5F5},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFFF5252)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.emergency, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Help',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Quick access to emergency services',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency Numbers
                  const Text(
                    'Emergency Helplines',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _emergencyNumbers.length,
                    itemBuilder: (context, index) {
                      final item = _emergencyNumbers[index];
                      return _EmergencyNumberTile(
                        name: item['name'] as String,
                        number: item['number'] as String,
                        icon: item['icon'] as IconData,
                        color: Color(item['color'] as int),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Emergency Service Providers
                  const Text(
                    'Urgent Service Needed?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find nearby verified providers for urgent issues',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_emergencyServices.length, (index) {
                    final svc = _emergencyServices[index];
                    return _EmergencyServiceTile(
                      name: svc['name'] as String,
                      desc: svc['desc'] as String,
                      icon: svc['icon'] as IconData,
                      color: Color(svc['color'] as int),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyNumberTile extends StatelessWidget {
  final String name;
  final String number;
  final IconData icon;
  final Color color;

  const _EmergencyNumberTile({
    required this.name,
    required this.number,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _dialNumber(number),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _EmergencyServiceTile extends StatelessWidget {
  final String name;
  final String desc;
  final IconData icon;
  final Color color;

  const _EmergencyServiceTile({
    required this.name,
    required this.desc,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _findNearbyProviders(context, name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.bg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: AppColors.text.withAlpha(180)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 14, color: AppColors.red),
                  SizedBox(width: 4),
                  Text(
                    'Find',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
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

  Future<void> _findNearbyProviders(BuildContext context, String category) async {
    Navigator.pop(context); // Close emergency sheet

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestoreService = FirestoreService();
      final providers = await firestoreService.searchProviders(category: category).first;

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (providers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No verified $category providers found yet'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      // Show the first available provider
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderDetailScreen(provider: providers.first),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not search providers'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
