import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RatingSelector extends StatefulWidget {
  final Function(double) onRatingSelected;
  final double initialRating;

  const RatingSelector({
    super.key,
    required this.onRatingSelected,
    this.initialRating = 0,
  });

  @override
  State<RatingSelector> createState() => _RatingSelectorState();
}

class _RatingSelectorState extends State<RatingSelector> {
  double _currentRating = 0;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getRatingText(_currentRating),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ).animate(key: ValueKey(_currentRating)).fadeIn().scale(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFull = starIndex <= (_hoveredIndex ?? _currentRating);

            return GestureDetector(
              onTapDown: (_) =>
                  setState(() => _currentRating = starIndex.toDouble()),
              onTap: () => widget.onRatingSelected(_currentRating),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = starIndex),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child:
                      Icon(
                            isFull
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 44,
                            color: isFull
                                ? Colors.amber[700]
                                : Colors.grey[400],
                          )
                          .animate(target: isFull ? 1 : 0)
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            duration: 200.ms,
                          )
                          .tint(
                            color: isFull
                                ? Colors.amber[700]
                                : Colors.grey[400],
                          ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _getRatingText(double rating) {
    if (rating == 0) return 'كيف تقيم هذا التطبيق؟';
    if (rating <= 1) return 'سيء جداً 😞';
    if (rating <= 2) return 'سيء ☹️';
    if (rating <= 3) return 'مقبول 😐';
    if (rating <= 4) return 'جيد جداً 🙂';
    return 'رائع ومميز! 🤩';
  }
}
