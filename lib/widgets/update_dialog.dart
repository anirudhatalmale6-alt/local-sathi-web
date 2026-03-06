import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../config/theme.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateType updateType;
  final AppVersionInfo versionInfo;

  const UpdateDialog({
    super.key,
    required this.updateType,
    required this.versionInfo,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0.0;
  String _statusText = '';

  @override
  Widget build(BuildContext context) {
    final isForced = widget.updateType == UpdateType.forced;

    return PopScope(
      canPop: !isForced && !_downloading,
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
                child: _downloading
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              value: _progress > 0 ? _progress : null,
                              strokeWidth: 3,
                              color: AppColors.teal,
                              backgroundColor: AppColors.bg,
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tealDark,
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        isForced ? Icons.system_update : Icons.update,
                        size: 32,
                        color: isForced ? AppColors.red : AppColors.tealDark,
                      ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                _downloading
                    ? 'Downloading Update...'
                    : isForced
                        ? 'Update Required'
                        : 'Update Available',
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
                  'v${widget.versionInfo.currentVersion}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status or release notes
              Text(
                _downloading
                    ? _statusText
                    : widget.versionInfo.releaseNotes,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              // Download progress bar
              if (_downloading) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 6,
                    backgroundColor: AppColors.bg,
                    color: AppColors.teal,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Update button
              if (!_downloading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadAndInstall(),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text(
                      'Download & Install',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

              // Beta button
              if (!_downloading &&
                  widget.versionInfo.betaEnabled &&
                  widget.versionInfo.betaVersion != null &&
                  widget.versionInfo.betaUrl != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _downloadAndInstall(
                      url: widget.versionInfo.betaUrl!,
                      version: widget.versionInfo.betaVersion!,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Try Beta v${widget.versionInfo.betaVersion}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
              ],

              // Skip button (only for optional updates, not during download)
              if (!isForced && !_downloading) ...[
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

  Future<void> _downloadAndInstall({String? url, String? version}) async {
    final downloadUrl = url ?? widget.versionInfo.updateUrl;

    // On web, just launch URL
    if (kIsWeb) {
      _launchUrl(downloadUrl);
      return;
    }

    setState(() {
      _downloading = true;
      _progress = 0;
      _statusText = 'Starting download...';
    });

    try {
      // Get temp directory
      final dir = await getTemporaryDirectory();
      final v = version ?? widget.versionInfo.currentVersion;
      final filePath = '${dir.path}/local_sathi_$v.apk';

      // Download with progress
      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              final mb = (received / 1024 / 1024).toStringAsFixed(1);
              final totalMb = (total / 1024 / 1024).toStringAsFixed(1);
              _statusText = 'Downloading $mb / $totalMb MB';
            });
          } else {
            setState(() {
              final mb = (received / 1024 / 1024).toStringAsFixed(1);
              _statusText = 'Downloaded $mb MB...';
            });
          }
        },
      );

      setState(() {
        _statusText = 'Opening installer...';
        _progress = 1.0;
      });

      // Open APK for installation
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && mounted) {
        // Fallback: open URL in browser
        _launchUrl(downloadUrl);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _progress = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Download failed. Opening in browser...'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // Fallback to browser
        _launchUrl(downloadUrl);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
