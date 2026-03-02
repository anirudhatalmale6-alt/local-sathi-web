import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateType updateType;
  final AppVersionInfo versionInfo;

  const UpdateDialog({
    super.key,
    required this.updateType,
    required this.versionInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isForced = updateType == UpdateType.forced;

    return PopScope(
      canPop: !isForced,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isForced ? AppColors.redLight : AppColors.tealLight,
                ),
                child: Icon(
                  isForced ? Icons.system_update : Icons.update,
                  size: 32,
                  color: isForced ? AppColors.red : AppColors.tealDark,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isForced ? 'Update Required' : 'Update Available',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),

              // Version info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'v${versionInfo.currentVersion}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Release notes
              Text(
                versionInfo.releaseNotes,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _launchUrl(versionInfo.updateUrl),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Update Now',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              // Beta button
              if (versionInfo.betaEnabled &&
                  versionInfo.betaVersion != null &&
                  versionInfo.betaUrl != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _launchUrl(versionInfo.betaUrl!),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Try Beta v${versionInfo.betaVersion}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
              ],

              // Skip button (only for optional updates)
              if (!isForced) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
