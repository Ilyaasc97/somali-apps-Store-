import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_info.dart';

class AppStatsRow extends StatelessWidget {
  final AppInfo appInfo;
  final VoidCallback onRateTap;

  const AppStatsRow({
    super.key,
    required this.appInfo,
    required this.onRateTap,
  });

  @override
  Widget build(BuildContext context) {
    final docId = appInfo.packageName.replaceAll('.', '_');

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('apps')
          .doc(docId)
          .snapshots(),
      builder: (context, snapshot) {
        String downloadCount = '0';
        String rating = appInfo.rating.toString();

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            // Process Downloads
            if (data.containsKey('downloadCount')) {
              int rawCount = data['downloadCount'];
              if (rawCount >= 1000000) {
                downloadCount = '${(rawCount / 1000000).toStringAsFixed(1)}M';
              } else if (rawCount >= 1000) {
                downloadCount = '${(rawCount / 1000).toStringAsFixed(1)}k';
              } else {
                downloadCount = rawCount.toString();
              }
            }
            // Process Rating
            if (data.containsKey('rating')) {
              rating = data['rating'].toStringAsFixed(1);
            }
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: onRateTap,
              child: _buildStatColumn(context, Icons.star, rating, 'Rating'),
            ),
            _buildStatColumn(
              context,
              Icons.download,
              downloadCount,
              'Downloads',
            ),
            _buildStatColumn(context, Icons.data_usage, appInfo.size, 'Size'),
          ],
        );
      },
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
