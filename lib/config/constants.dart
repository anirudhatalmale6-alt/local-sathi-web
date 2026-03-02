class AppConstants {
  static const String appName = 'Local Sathi';
  static const String taglineHindi = 'अपना शहर का अपना नेटवर्क';
  static const String taglineEnglish = 'your community companion';

  static const List<Map<String, dynamic>> categories = [
    {'name': 'Electrician', 'icon': '⚡', 'color': 0xFFE3F2FD},
    {'name': 'Plumber', 'icon': '🔧', 'color': 0xFFE0F2F1},
    {'name': 'Tutor', 'icon': '📚', 'color': 0xFFFFF3E0},
    {'name': 'Carpenter', 'icon': '🪚', 'color': 0xFFEFEBE9},
    {'name': 'Painter', 'icon': '🎨', 'color': 0xFFFCE4EC},
    {'name': 'AC Repair', 'icon': '❄️', 'color': 0xFFE1F5FE},
    {'name': 'Cleaner', 'icon': '🧹', 'color': 0xFFF3E5F5},
    {'name': 'Driver', 'icon': '🚗', 'color': 0xFFE8F5E9},
    {'name': 'More', 'icon': '➕', 'color': 0xFFF5F5F5},
  ];

  static const int maxPostLength = 280;
  static const String idPrefix = 'LS-';
  static const int startingId = 100001;
}
