import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  final String currentVersion;
  final String minVersion;
  final String updateUrl;
  final String releaseNotes;
  final String? betaVersion;
  final String? betaUrl;
  final String? betaNotes;
  final bool betaEnabled;

  AppVersionInfo({
    required this.currentVersion,
    required this.minVersion,
    required this.updateUrl,
    required this.releaseNotes,
    this.betaVersion,
    this.betaUrl,
    this.betaNotes,
    this.betaEnabled = false,
  });

  factory AppVersionInfo.fromFirestore(Map<String, dynamic> data) {
    return AppVersionInfo(
      currentVersion: data['currentVersion'] ?? '1.0.0',
      minVersion: data['minVersion'] ?? '1.0.0',
      updateUrl: data['updateUrl'] ?? '',
      releaseNotes: data['releaseNotes'] ?? '',
      betaVersion: data['betaVersion'],
      betaUrl: data['betaUrl'],
      betaNotes: data['betaNotes'],
      betaEnabled: data['betaEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'currentVersion': currentVersion,
        'minVersion': minVersion,
        'updateUrl': updateUrl,
        'releaseNotes': releaseNotes,
        'betaVersion': betaVersion,
        'betaUrl': betaUrl,
        'betaNotes': betaNotes,
        'betaEnabled': betaEnabled,
      };
}

enum UpdateType { none, optional, forced, beta }

class UpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<({UpdateType type, AppVersionInfo? info})> checkForUpdate() async {
    try {
      final doc =
          await _firestore.collection('app_config').doc('version').get();
      if (!doc.exists) return (type: UpdateType.none, info: null);

      final versionInfo = AppVersionInfo.fromFirestore(doc.data()!);
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Check if force update needed (below minimum version)
      if (_isVersionLower(currentVersion, versionInfo.minVersion)) {
        return (type: UpdateType.forced, info: versionInfo);
      }

      // Check if optional update available
      if (_isVersionLower(currentVersion, versionInfo.currentVersion)) {
        return (type: UpdateType.optional, info: versionInfo);
      }

      return (type: UpdateType.none, info: versionInfo);
    } catch (e) {
      return (type: UpdateType.none, info: null);
    }
  }

  // Save version config (admin)
  Future<void> updateVersionConfig(AppVersionInfo info) async {
    await _firestore
        .collection('app_config')
        .doc('version')
        .set(info.toFirestore());
  }

  // Get current version config stream (admin)
  Stream<AppVersionInfo?> getVersionConfig() {
    return _firestore
        .collection('app_config')
        .doc('version')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return AppVersionInfo.fromFirestore(doc.data()!);
    });
  }

  /// Compare semver versions: returns true if v1 < v2
  bool _isVersionLower(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);

    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return true;
      if (parts1[i] > parts2[i]) return false;
    }
    return false;
  }
}
