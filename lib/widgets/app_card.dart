import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/app_info.dart';
import '../screens/app_details_screen.dart';
import '../repositories/app_repository.dart';
import 'package:shimmer/shimmer.dart';

import 'package:flutter_animate/flutter_animate.dart';

class AppCard extends StatelessWidget {
  final AppInfo appInfo;

  const AppCard({super.key, required this.appInfo});

  @override
  Widget build(BuildContext context) {
    final appRepo = Provider.of<AppRepository>(context, listen: false);

    return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppDetailsScreen(appInfo: appInfo),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Hero(
                        tag: appInfo.packageName,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: appInfo.iconUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                              highlightColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[600]!
                                  : Colors.grey[100]!,
                              child: Container(
                                width: 80,
                                height: 80,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.android,
                              size: 40,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Text Area
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appInfo.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appInfo.description,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Rating / Download Tag
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appInfo.rating.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.download_rounded,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).iconTheme.color?.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          StreamBuilder<DocumentSnapshot>(
                            stream: appRepo.getAppStats(appInfo.packageName),
                            builder: (context, snapshot) {
                              String count = '0';
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final data =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>?;
                                if (data != null &&
                                    data.containsKey('downloadCount')) {
                                  int rawCount = data['downloadCount'];
                                  if (rawCount >= 1000000) {
                                    count =
                                        '${(rawCount / 1000000).toStringAsFixed(1)}M';
                                  } else if (rawCount >= 1000) {
                                    count =
                                        '${(rawCount / 1000).toStringAsFixed(1)}k';
                                  } else {
                                    count = rawCount.toString();
                                  }
                                }
                              }
                              return Text(
                                count,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(duration: 500.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.fastOutSlowIn,
        );
  }
}
