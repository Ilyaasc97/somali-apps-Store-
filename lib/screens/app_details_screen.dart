import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:share_plus/share_plus.dart';
import 'package:device_apps/device_apps.dart';
import '../models/app_info.dart';
import '../widgets/app_details/app_header.dart';
import '../widgets/app_details/app_stats_row.dart';
import '../widgets/app_details/app_action_buttons.dart';
import '../widgets/app_details/app_screenshots.dart';
import '../widgets/installation_guide_dialog.dart';
import 'package:provider/provider.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_details/rating_selector.dart';
import '../utils/security_utils.dart';
import '../providers/download_provider.dart';

class AppDetailsScreen extends StatefulWidget {
  final AppInfo appInfo;

  const AppDetailsScreen({super.key, required this.appInfo});

  @override
  State<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends State<AppDetailsScreen>
    with WidgetsBindingObserver {
  // App Management States
  bool _isInstalled = false;
  bool _isUpdateAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppStatus();
    }
  }

  Future<void> _checkAppStatus() async {
    if (widget.appInfo.packageName.isEmpty) return;

    bool isInstalled = await DeviceApps.isAppInstalled(
      widget.appInfo.packageName,
    );

    bool isUpdate = false;
    String? installedVer = '';

    if (isInstalled) {
      Application? app = await DeviceApps.getApp(
        widget.appInfo.packageName,
        true,
      );
      if (app is ApplicationWithIcon) {
        installedVer = app.versionName;

        // تحسين مقارنة الإصدارات باستخدام تطهير شامل للنصوص
        String serverVer = _normalizeVersion(widget.appInfo.version);
        String localVer = _normalizeVersion(installedVer!);

        if (serverVer != localVer && serverVer.isNotEmpty) {
          isUpdate = true;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isInstalled = isInstalled;
        _isUpdateAvailable = isUpdate;
      });
    }
  }

  Future<void> _incrementDownloadCount() async {
    try {
      final docId = widget.appInfo.packageName.replaceAll('.', '_');
      final docRef = FirebaseFirestore.instance.collection('apps').doc(docId);
      await docRef.set({
        'name': widget.appInfo.name,
        'downloadCount': FieldValue.increment(1),
        'lastDownload': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating count: $e');
    }
  }

  Future<void> _handleMainButtonAction() async {
    if (_isInstalled && !_isUpdateAvailable) {
      // Action: Open
      await DeviceApps.openApp(widget.appInfo.packageName);
    } else {
      // Action: Install or Update
      await _downloadAndInstall();
    }
  }

  Future<void> _downloadAndInstall() async {
    final downloadProvider = Provider.of<DownloadProvider>(
      context,
      listen: false,
    );

    // Permission checks...
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => const InstallationGuideDialog(),
          );
        }
        // Check again after coming back from settings
        if (await Permission.requestInstallPackages.status.isDenied) return;
      }
    }
    // Storage permission check for Android < 13
    if (Platform.isAndroid && await Permission.storage.request().isDenied) {
      // On Android 13+, this might be always denied but not needed for app-specific dirs. Proceeding.
    }

    try {
      // التحقق من أمان الرابط قبل البدء
      if (!SecurityUtils.isUrlSafe(widget.appInfo.downloadUrl)) {
        throw Exception('Insecure or untrusted download URL detected');
      }

      _incrementDownloadCount();
      await downloadProvider.startDownload(
        widget.appInfo.packageName,
        widget.appInfo.downloadUrl,
        widget.appInfo.name,
      );
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _shareApp() {
    Share.share(
      'Check out ${widget.appInfo.name} on Somali Apps Store!\nDownload here: ${widget.appInfo.downloadUrl}',
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final docId = widget.appInfo.packageName.replaceAll('.', '_');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          AppHeader(appInfo: widget.appInfo),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Center(
                    child: Text(
                      widget.appInfo.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  AppStatsRow(
                    appInfo: widget.appInfo,
                    onRateTap: () => _showRatingDialog(context, docId),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Consumer<DownloadProvider>(
                    builder: (context, downloadProvider, child) {
                      final task = downloadProvider.getTask(
                        widget.appInfo.packageName,
                      );

                      bool isDownloading = task?.isDownloading ?? false;
                      double downloadProgress = task?.progress ?? 0.0;

                      String displayStatus = 'Install';
                      if (isDownloading) {
                        displayStatus =
                            '${(downloadProgress * 100).toStringAsFixed(0)}%';
                      } else if (task != null &&
                          task.status == 'Ready to Install') {
                        displayStatus = 'Install';
                      } else if (_isInstalled) {
                        displayStatus = _isUpdateAvailable ? 'Update' : 'Open';
                      }

                      return AppActionButtons(
                        isInstalled: _isInstalled,
                        isUpdateAvailable: _isUpdateAvailable,
                        isDownloading: isDownloading,
                        progress: downloadProgress,
                        statusMessage: displayStatus,
                        packageName: widget.appInfo.packageName,
                        onMainAction: _handleMainButtonAction,
                        onRateAction: () => _showRatingDialog(context, docId),
                        onShareAction: _shareApp,
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developer',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            widget.appInfo.developer,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Version',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            widget.appInfo.version,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  const Text(
                    'About this app',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.appInfo.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Screenshots Section
                  AppScreenshots(screenshots: widget.appInfo.screenshots),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog(BuildContext context, String docId) async {
    final appRepo = Provider.of<AppRepository>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Rate this App',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: RatingSelector(
          onRatingSelected: (rating) async {
            Navigator.pop(context);
            await _updateRating(appRepo, rating);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Maybe Later',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRating(AppRepository appRepo, double newRating) async {
    try {
      await appRepo.updateAppRating(widget.appInfo.packageName, newRating);
      _showSnackBar('Thanks for rating! ($newRating stars)');
    } catch (e) {
      debugPrint('Error rating: $e');
      _showSnackBar('Failed to submit rating');
    }
  }

  String _normalizeVersion(String v) {
    // إزالة 'v' من البداية، والمسافات، وأي نصوص غير رقمية محتملة
    return v.toLowerCase().trim().replaceAll(RegExp(r'^v'), '').trim();
  }
}
