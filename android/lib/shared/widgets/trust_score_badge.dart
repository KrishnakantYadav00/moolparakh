// lib/shared/widgets/trust_score_badge.dart
//
// Compact circular trust-score indicator.
// Used on vendor cards, RFQ bid rows, and the dashboard summary.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TrustScoreBadge extends StatelessWidget {
  final int score;
  final double size;
  final double strokeWidth;
  final bool showLabel;

  const TrustScoreBadge({
    super.key,
    required this.score,
    this.size = 56,
    this.strokeWidth = 5,
    this.showLabel = true,
  });

  String get _band {
    if (score >= 80) return 'Excellent';
    if (score >= 50) return 'Watch';
    return 'High Risk';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.trustColor(score);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: strokeWidth,
                backgroundColor: color.withAlpha(40),
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round,
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            _band,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

/// Inline pill version — for use in compact list rows.
class TrustScorePill extends StatelessWidget {
  final int score;
  const TrustScorePill({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.trustColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        '$score / 100',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
