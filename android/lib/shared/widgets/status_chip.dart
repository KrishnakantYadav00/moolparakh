// lib/shared/widgets/status_chip.dart
//
// Reusable coloured status chip used for:
//   - VendorStatus  (Verified / Flagged / Draft / etc.)
//   - VerificationStatus (Success / Pending / Failed)
//   - DocumentStatus (Uploaded / Processing / Parsed / Failed)
//   - RiskLevel chips

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusChip.vendorStatus(String status) {
    Color c;
    switch (status.toUpperCase()) {
      case 'VERIFIED':
        c = AppColors.verified;
        break;
      case 'FLAGGED':
      case 'REJECTED':
        c = AppColors.failed;
        break;
      case 'PENDING_VERIFICATION':
        c = AppColors.pending;
        break;
      default:
        c = AppColors.textSecondary;
    }
    return StatusChip(label: _labelFor(status), color: c);
  }

  factory StatusChip.verification(String status) {
    Color c;
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        c = AppColors.verified;
        break;
      case 'FAILED':
        c = AppColors.failed;
        break;
      case 'MANUAL_REVIEW':
        c = AppColors.pending;
        break;
      default:
        c = AppColors.textSecondary;
    }
    return StatusChip(label: _labelFor(status), color: c);
  }

  factory StatusChip.riskLevel(String level) {
    return StatusChip(
      label: _titleCase(level),
      color: AppTheme.riskColor(level),
    );
  }

  factory StatusChip.documentStatus(String status) {
    Color c;
    IconData? icon;
    switch (status.toUpperCase()) {
      case 'PARSED':
        c = AppColors.verified;
        icon = Icons.check_circle_outline;
        break;
      case 'FAILED':
        c = AppColors.failed;
        icon = Icons.error_outline;
        break;
      case 'PROCESSING_OCR':
        c = AppColors.primary;
        icon = Icons.sync;
        break;
      default:
        c = AppColors.textSecondary;
        icon = Icons.upload_outlined;
    }
    return StatusChip(label: _labelFor(status), color: c, icon: icon);
  }

  static String _labelFor(String raw) {
    switch (raw.toUpperCase()) {
      case 'PENDING_VERIFICATION':
        return 'Pending';
      case 'PROCESSING_OCR':
        return 'Processing';
      case 'MANUAL_REVIEW':
        return 'In Review';
      default:
        return _titleCase(raw);
    }
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
