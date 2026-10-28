// lib/core/models/relationship.dart
import 'package:equatable/equatable.dart';

enum RelationshipType { sharedDirector, sharedBankAccount, sharedAddress }

extension RelationshipTypeX on RelationshipType {
  static RelationshipType fromString(String s) {
    switch (s.toUpperCase()) {
      case 'SHARED_DIRECTOR':
        return RelationshipType.sharedDirector;
      case 'SHARED_BANK_ACCOUNT':
        return RelationshipType.sharedBankAccount;
      case 'SHARED_ADDRESS':
        return RelationshipType.sharedAddress;
      default:
        return RelationshipType.sharedDirector;
    }
  }

  String get label {
    switch (this) {
      case RelationshipType.sharedDirector:
        return 'Shared Director';
      case RelationshipType.sharedBankAccount:
        return 'Shared Bank Account';
      case RelationshipType.sharedAddress:
        return 'Shared Address';
    }
  }
}

class SupplierRelationship extends Equatable {
  final String id;
  final String vendorAId;
  final String vendorBId;
  final RelationshipType type;
  final String value;
  final String? vendorAName;
  final String? vendorBName;
  final DateTime createdAt;

  const SupplierRelationship({
    required this.id,
    required this.vendorAId,
    required this.vendorBId,
    required this.type,
    required this.value,
    this.vendorAName,
    this.vendorBName,
    required this.createdAt,
  });

  factory SupplierRelationship.fromJson(Map<String, dynamic> j) =>
      SupplierRelationship(
        id: j['id'] as String,
        vendorAId: j['vendorAId'] as String,
        vendorBId: j['vendorBId'] as String,
        type: RelationshipTypeX.fromString(j['type'] as String),
        value: j['value'] as String,
        vendorAName: (j['vendorA'] is Map)
            ? (j['vendorA'] as Map)['legalName'] as String?
            : null,
        vendorBName: (j['vendorB'] is Map)
            ? (j['vendorB'] as Map)['legalName'] as String?
            : null,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [id, vendorAId, vendorBId, type, value];
}
