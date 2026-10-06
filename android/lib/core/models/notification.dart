// lib/core/models/notification.dart
//
// Mirrors backend:
//   prisma/schema.prisma → Notification, NotificationKind
//   frontend/src/lib/api.ts → ApiNotification

import 'package:equatable/equatable.dart';

enum NotificationKind { high, critical, compliance, rfq, trust }

extension NotificationKindX on NotificationKind {
  static NotificationKind fromString(String s) {
    switch (s.toUpperCase()) {
      case 'HIGH':
        return NotificationKind.high;
      case 'CRITICAL':
        return NotificationKind.critical;
      case 'COMPLIANCE':
        return NotificationKind.compliance;
      case 'RFQ':
        return NotificationKind.rfq;
      case 'TRUST':
        return NotificationKind.trust;
      default:
        return NotificationKind.high;
    }
  }

  String get label {
    switch (this) {
      case NotificationKind.high:
        return 'High';
      case NotificationKind.critical:
        return 'Critical';
      case NotificationKind.compliance:
        return 'Compliance';
      case NotificationKind.rfq:
        return 'RFQ';
      case NotificationKind.trust:
        return 'Trust';
    }
  }
}

class AppNotification extends Equatable {
  final String id;
  final NotificationKind kind;
  final String title;
  final String vendorName;
  final String detail;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.vendorName,
    required this.detail,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        kind: NotificationKindX.fromString(j['kind'] as String),
        title: j['title'] as String,
        vendorName: j['vendorName'] as String,
        detail: j['detail'] as String,
        read: j['read'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Duration get age => DateTime.now().difference(createdAt);

  String get ageLabel {
    final m = age.inMinutes;
    if (m < 1) return 'Just now';
    if (m < 60) return '${m}m ago';
    final h = age.inHours;
    if (h < 24) return '${h}h ago';
    return '${age.inDays}d ago';
  }

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        kind: kind,
        title: title,
        vendorName: vendorName,
        detail: detail,
        read: read ?? this.read,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, read, createdAt];
}
