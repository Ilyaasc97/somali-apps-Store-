import 'package:flutter/material.dart';

class AppActionButtons extends StatelessWidget {
  final bool isInstalled;
  final bool isUpdateAvailable;
  final bool isDownloading;
  final double progress;
  final String statusMessage;
  final String packageName;
  final VoidCallback onMainAction;
  final VoidCallback onRateAction;
  final VoidCallback onShareAction;

  const AppActionButtons({
    super.key,
    required this.isInstalled,
    required this.isUpdateAvailable,
    required this.isDownloading,
    required this.progress,
    required this.statusMessage,
    required this.packageName,
    required this.onMainAction,
    required this.onRateAction,
    required this.onShareAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main Action Button (Install / Open / Update)
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isDownloading ? null : onMainAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isInstalled && !isUpdateAvailable
                    ? Colors.green
                    : Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isDownloading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            value: progress > 0 ? progress : null,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(statusMessage),
                      ],
                    )
                  : Text(
                      statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(width: 12),
        // Rate Button
        SizedBox(
          height: 50,
          width: 50,
          child: IconButton(
            onPressed: onRateAction,
            icon: const Icon(Icons.star_border),
            color: Colors.amber[700],
            style: IconButton.styleFrom(
              backgroundColor: Colors.amber.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'Rate App',
          ),
        ),

        const SizedBox(width: 12),
        // Share Button
        SizedBox(
          height: 50,
          width: 50,
          child: IconButton(
            onPressed: onShareAction,
            icon: const Icon(Icons.share),
            color: Colors.indigo,
            style: IconButton.styleFrom(
              backgroundColor: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
