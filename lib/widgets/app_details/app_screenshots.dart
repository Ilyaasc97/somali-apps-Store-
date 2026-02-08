import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppScreenshots extends StatelessWidget {
  final List<String> screenshots;

  const AppScreenshots({super.key, required this.screenshots});

  @override
  Widget build(BuildContext context) {
    if (screenshots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250, // Increased height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: screenshots.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: screenshots[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 140, // Increased width
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 140,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
