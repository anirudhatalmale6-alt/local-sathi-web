class AppConstants {
  static const String appName = 'Local Sathi';
  static const String taglineHindi = 'अपना शहर का अपना नेटवर्क';
  static const String taglineEnglish = 'your community companion';

  // Featured categories shown on home screen grid (9 items)
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Electrician', 'icon': '⚡', 'color': 0xFFE3F2FD},
    {'name': 'Plumber', 'icon': '🔧', 'color': 0xFFE0F2F1},
    {'name': 'Cleaner', 'icon': '🧹', 'color': 0xFFF3E5F5},
    {'name': 'Cook / Maid', 'icon': '🍳', 'color': 0xFFFFF3E0},
    {'name': 'Carpenter', 'icon': '🪚', 'color': 0xFFEFEBE9},
    {'name': 'AC Repair', 'icon': '❄️', 'color': 0xFFE1F5FE},
    {'name': 'Home Tutor', 'icon': '📚', 'color': 0xFFFFF8E1},
    {'name': 'Beauty', 'icon': '💄', 'color': 0xFFFCE4EC},
    {'name': 'More', 'icon': '➕', 'color': 0xFFF5F5F5},
  ];

  // Full category list for registration, search, and admin
  static const List<String> allCategories = [
    // Existing
    'Electrician', 'Plumber', 'Carpenter', 'Painter', 'AC Repair', 'Driver',
    // Home Services
    'House Cleaning', 'Cook / Maid', 'Babysitter', 'Elderly Care', 'Laundry / Iron Service',
    // Repair Services
    'Mobile Repair', 'Laptop / Computer Repair', 'TV Repair',
    'Fridge / Washing Machine Repair', 'RO Water Purifier Service',
    // Transport
    'Taxi / Cab', 'Bike Taxi', 'Goods Transport / Pickup', 'Packers & Movers',
    // Outdoor
    'Gardener', 'Security Guard', 'Pest Control', 'CCTV Installation',
    // Education
    'Home Tutor', 'Yoga Teacher', 'Dance Teacher', 'Music Teacher',
    // Personal Services
    'Beauty Parlour at Home', 'Mehndi Artist', 'Tailor / Stitching', 'Makeup Artist',
  ];

  static const int maxPostLength = 280;
  static const String idPrefix = 'LS-';
  static const int startingId = 100001;

  /// Phone numbers that automatically get admin role on registration
  /// Add the owner's phone number here (without +91)
  static const List<String> adminPhones = [];

  /// Commission slabs: [maxAmount, commissionPercent]
  /// Applied based on booking value
  static const List<List<num>> commissionSlabs = [
    [499, 15],    // 0-499: 15%
    [1999, 10],   // 500-1999: 10%
    [4999, 7],    // 2000-4999: 7%
    [99999999, 5], // 5000+: 5%
  ];

  /// Provider Pro subscribers get this % discount on commission
  static const int proCommissionDiscount = 2;

  /// Calculate commission based on tiered slabs
  /// [isProProvider] - if true, reduces rate by proCommissionDiscount
  /// [isFirstBooking] - if true, returns 0 (growth hack)
  static double calculateCommission(double price, {bool isProProvider = false, bool isFirstBooking = false}) {
    if (isFirstBooking) return 0;
    final rate = getCommissionRate(price, isProProvider: isProProvider);
    return price * rate / 100;
  }

  /// Get commission rate for a given price
  static double getCommissionRate(double price, {bool isProProvider = false}) {
    double rate = 5.0;
    for (final slab in commissionSlabs) {
      if (price <= slab[0]) {
        rate = slab[1].toDouble();
        break;
      }
    }
    if (isProProvider) {
      rate = (rate - proCommissionDiscount).clamp(1, 100);
    }
    return rate;
  }
}
