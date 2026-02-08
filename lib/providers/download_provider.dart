import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../utils/security_utils.dart';

class DownloadTask {
  final String packageName;
  double progress;
  String status;
  bool isDownloading;
  String? savePath;

  DownloadTask({
    required this.packageName,
    this.progress = 0.0,
    this.status = '',
    this.isDownloading = false,
    this.savePath,
  });
}

class DownloadProvider extends ChangeNotifier {
  final Map<String, DownloadTask> _tasks = {};
  final Dio _dio = Dio();

  Map<String, DownloadTask> get tasks => _tasks;

  DownloadTask? getTask(String packageName) => _tasks[packageName];

  Future<void> startDownload(
    String packageName,
    String url,
    String appName,
  ) async {
    if (_tasks[packageName]?.isDownloading ?? false) return;

    // الأمن أولاً
    if (!SecurityUtils.isUrlSafe(url)) {
      throw Exception('Insecure download URL');
    }

    final task = DownloadTask(
      packageName: packageName,
      isDownloading: true,
      status: 'Downloading...',
    );
    _tasks[packageName] = task;
    notifyListeners();

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) throw Exception('Storage not accessible');

      final String fileName = packageName.isNotEmpty ? packageName : appName;
      final String savePath =
          '${dir.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.apk';
      task.savePath = savePath;

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            task.progress = received / total;
            task.status = '${(task.progress * 100).toStringAsFixed(0)}%';
            notifyListeners();
          }
        },
      );

      task.isDownloading = false;
      task.status = 'Ready to Install';
      notifyListeners();

      // محاولة التثبيت تلقائياً عند الانتهاء
      await installApp(packageName);
    } catch (e) {
      task.isDownloading = false;
      task.status = 'Error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> installApp(String packageName) async {
    final task = _tasks[packageName];
    if (task == null || task.savePath == null) return;

    final result = await OpenFile.open(task.savePath!);
    if (result.type != ResultType.done) {
      task.status = 'Install Failed';
      notifyListeners();
      throw Exception(result.message);
    }
  }

  void clearTask(String packageName) {
    _tasks.remove(packageName);
    notifyListeners();
  }
}
