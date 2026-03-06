import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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
      // Use external storage for better APK installer access
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getTemporaryDirectory();

      final v = version ?? widget.versionInfo.currentVersion;
      final filePath = '${dir.path}/local_sathi_$v.apk';

      // Delete old file if exists
      final oldFile = File(filePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      // Download with progress - follow redirects (GitHub releases redirect)
      final dio = Dio(BaseOptions(
        followRedirects: true,
        maxRedirects: 5,
        receiveTimeout: const Duration(minutes: 5),
      ));

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

      // Verify file was downloaded
      final downloadedFile = File(filePath);
      if (!await downloadedFile.exists() || await downloadedFile.length() < 1000) {
        throw Exception('Download incomplete');
      }

      setState(() {
        _statusText = 'Installing update...';
        _progress = 1.0;
      });

      // Open APK with explicit MIME type for reliable installation
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('OpenFilex result: ${result.type} - ${result.message}');

      if (result.type == ResultType.done) {
        if (mounted) Navigator.pop(context);
      } else {
        // Show install instruction instead of silently opening browser
        if (mounted) {
          setState(() {
            _downloading = false;
            _progress = 1.0;
            _statusText = 'Download complete! If installer did not open, tap below.';
          });
          _showInstallHelp(filePath, downloadUrl);
        }
      }
    } catch (e) {
      debugPrint('Update download error: $e');
      if (mounted) {
        setState(() {
          _downloading = false;
          _progress = 0;
          _statusText = '';
        });
        _showDownloadError(downloadUrl);
      }
    }
  }

  void _showInstallHelp(String filePath, String downloadUrl) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 40, color: AppColors.teal),
            const SizedBox(height: 12),
            const Text(
              'APK Downloaded Successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'If the installer did not open automatically, you may need to enable "Install from unknown sources" in your phone settings for this app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
                },
                icon: const Icon(Icons.install_mobile, size: 20),
                label: const Text('Try Install Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _launchUrl(downloadUrl);
              },
              child: const Text('Open in Browser Instead', style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadError(String downloadUrl) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Download failed. Please check your internet connection.'),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Open in Browser',
          textColor: Colors.white,
          onPressed: () => _launchUrl(downloadUrl),
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
