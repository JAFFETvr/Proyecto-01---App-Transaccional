import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';

/// Muestra una calificación (puede ser fraccionaria, ej. 4.5) como estrellas.
class ReviewStars extends StatelessWidget {
  final double rating;
  final double size;

  const ReviewStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating > i && rating < i + 1;
        return Icon(
          half
              ? Icons.star_half_rounded
              : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
          size: size,
          color: AppColors.amber,
        );
      }),
    );
  }
}

/// Selector de calificación (1-5 estrellas) para que el usuario elija.
class ReviewStarsInput extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  const ReviewStarsInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        return IconButton(
          onPressed: () => onChanged(i + 1),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: AppColors.amber,
          ),
        );
      }),
    );
  }
}
