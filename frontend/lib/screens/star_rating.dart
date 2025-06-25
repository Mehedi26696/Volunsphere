import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final int maxRating;
  final ValueChanged<int>? onRatingChanged;   
  final Color filledStarColor;
  final Color unfilledStarColor;
  final double size;

  const StarRating({
    Key? key,
    required this.rating,
    this.onRatingChanged,   
    this.maxRating = 5,
    this.filledStarColor = Colors.amber,
    this.unfilledStarColor = Colors.grey,
    this.size = 30,
  }) : super(key: key);

  Widget _buildStar(int index) {
    return GestureDetector(
      onTap: onRatingChanged == null
          ? null
          : () => onRatingChanged!(index + 1),
      child: Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: index < rating ? filledStarColor : unfilledStarColor,
        size: size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, _buildStar),
    );
  }
}
