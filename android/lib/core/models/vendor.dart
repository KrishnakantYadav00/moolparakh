// lib/core/models/vendor.dart
//
// Mirrors the backend API shapes from:
//   backend/src/lib/api.ts  (ApiVendor, ApiTrustScore, ApiVerification, etc.)
//   backend/prisma/schema.prisma  (Vendor, TrustScore, VerificationRecord, Document)
//
// All fromJson factories parse the exact JSON the backend returns.

import 'package:equatable/equatable.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Enums (mirror Prisma enums)
// ──────────────────────────────────────────────────────────────────────────────

enum VendorStatus { draft, pendingVerification, verified, flagged, rejected }

extension VendorStatusX on VendorStatus {
  static VendorStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'DRAFT':
        return VendorStatus.draft;
      case 'PENDING_VERIFICATION':
        return VendorStatus.pendingVerification;
      case 'VERIFIED':
        return VendorStatus.verified;
      case 'FLAGGED':
        return VendorStatus.flagged;
      case 'REJECTED':
        return VendorStatus.rejected;
      default:
        return VendorStatus.draft;
    }
  }

  String get label {
    switch (this) {
      case VendorStatus.draft:
        return 'Draft';
      case VendorStatus.pendingVerification:
        return 'Pending';
      case VendorStatus.verified:
        return 'Verified';
      case VendorStatus.flagged:
        return 'Flagged';
      case VendorStatus.rejected:
        return 'Rejected';
    }
  }
}

enum MsmeCategory { micro, small, medium }

extension MsmeCategoryX on MsmeCategory {
  static MsmeCategory fromString(String s) {
    switch (s.toUpperCase()) {
      case 'MICRO':
        return MsmeCategory.micro;
      case 'SMALL':
        return MsmeCategory.small;
      case 'MEDIUM':
        return MsmeCategory.medium;
      default:
        return MsmeCategory.micro;
    }
  }

  String get label {
    switch (this) {
      case MsmeCategory.micro:
        return 'Micro';
      case MsmeCategory.small:
        return 'Small';
      case MsmeCategory.medium:
        return 'Medium';
    }
  }
}

enum VerificationStatus { pending, success, failed, manualReview }

extension VerificationStatusX on VerificationStatus {
  static VerificationStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'SUCCESS':
        return VerificationStatus.success;
      case 'FAILED':
        return VerificationStatus.failed;
      case 'MANUAL_REVIEW':
        return VerificationStatus.manualReview;
      default:
        return VerificationStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.success:
        return 'Verified';
      case VerificationStatus.failed:
        return 'Failed';
      case VerificationStatus.manualReview:
        return 'Review';
    }
  }
}

enum VerificationType { pan, gstin, udyam, cin, bankAccount }

extension VerificationTypeX on VerificationType {
  static VerificationType fromString(String s) {
    switch (s.toUpperCase()) {
      case 'PAN':
        return VerificationType.pan;
      case 'GSTIN':
        return VerificationType.gstin;
      case 'UDYAM':
        return VerificationType.udyam;
      case 'CIN':
        return VerificationType.cin;
      case 'BANK_ACCOUNT':
        return VerificationType.bankAccount;
      default:
        return VerificationType.pan;
    }
  }

  String get label {
    switch (this) {
      case VerificationType.pan:
        return 'PAN';
      case VerificationType.gstin:
        return 'GSTIN';
      case VerificationType.udyam:
        return 'Udyam';
      case VerificationType.cin:
        return 'CIN';
      case VerificationType.bankAccount:
        return 'Bank Account';
    }
  }
}

enum DocumentStatus { uploaded, processingOcr, parsed, failed }

extension DocumentStatusX on DocumentStatus {
  static DocumentStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'UPLOADED':
        return DocumentStatus.uploaded;
      case 'PROCESSING_OCR':
        return DocumentStatus.processingOcr;
      case 'PARSED':
        return DocumentStatus.parsed;
      case 'FAILED':
        return DocumentStatus.failed;
      default:
        return DocumentStatus.uploaded;
    }
  }

  String get label {
    switch (this) {
      case DocumentStatus.uploaded:
        return 'Uploaded';
      case DocumentStatus.processingOcr:
        return 'Processing…';
      case DocumentStatus.parsed:
        return 'Parsed';
      case DocumentStatus.failed:
        return 'Failed';
    }
  }

  bool get isProcessing => this == DocumentStatus.processingOcr;
  bool get isDone =>
      this == DocumentStatus.parsed || this == DocumentStatus.failed;
}

enum RiskLevel { low, medium, high, critical }

extension RiskLevelX on RiskLevel {
  static RiskLevel fromString(String s) {
    switch (s.toUpperCase()) {
      case 'LOW':
        return RiskLevel.low;
      case 'MEDIUM':
        return RiskLevel.medium;
      case 'HIGH':
        return RiskLevel.high;
      case 'CRITICAL':
        return RiskLevel.critical;
      default:
        return RiskLevel.low;
    }
  }

  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.critical:
        return 'Critical';
    }
  }
}

enum VendorEventKind { verification, compliance, risk, trust, rfq, document }

extension VendorEventKindX on VendorEventKind {
  static VendorEventKind fromString(String s) {
    switch (s.toUpperCase()) {
      case 'VERIFICATION':
        return VendorEventKind.verification;
      case 'COMPLIANCE':
        return VendorEventKind.compliance;
      case 'RISK':
        return VendorEventKind.risk;
      case 'TRUST':
        return VendorEventKind.trust;
      case 'RFQ':
        return VendorEventKind.rfq;
      case 'DOCUMENT':
        return VendorEventKind.document;
      default:
        return VendorEventKind.verification;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Models
// ──────────────────────────────────────────────────────────────────────────────

class TrustScore extends Equatable {
  final int overallScore;
  final int verificationCompleteness; // /40
  final int certificationFreshness; // /35
  final int accountAgeActivity; // /15
  final int manualBuyerFlag; // /10
  final RiskLevel riskLevel;

  const TrustScore({
    required this.overallScore,
    required this.verificationCompleteness,
    required this.certificationFreshness,
    required this.accountAgeActivity,
    required this.manualBuyerFlag,
    required this.riskLevel,
  });

  factory TrustScore.fromJson(Map<String, dynamic> j) => TrustScore(
    overallScore: (j['overallScore'] as num?)?.toInt() ??
        (j['overall_score'] as num?)?.toInt() ??
        0,
    verificationCompleteness:
        (j['verificationCompleteness'] as num?)?.toInt() ??
            (j['verification_completeness'] as num?)?.toInt() ??
            0,
    certificationFreshness: (j['certificationFreshness'] as num?)?.toInt() ??
        (j['certification_freshness'] as num?)?.toInt() ??
        0,
    accountAgeActivity: (j['accountAgeActivity'] as num?)?.toInt() ??
        (j['account_age_activity'] as num?)?.toInt() ??
        0,
    manualBuyerFlag: (j['manualBuyerFlag'] as num?)?.toInt() ??
        (j['manual_buyer_flag'] as num?)?.toInt() ??
        0,
    riskLevel: RiskLevelX.fromString(
      (j['riskLevel'] ?? j['risk_level'] ?? 'LOW').toString(),
    ),
  );

  /// Empty/default score when a vendor has no score yet.
  factory TrustScore.empty() => const TrustScore(
    overallScore: 0,
    verificationCompleteness: 0,
    certificationFreshness: 0,
    accountAgeActivity: 0,
    manualBuyerFlag: 0,
    riskLevel: RiskLevel.medium,
  );

  @override
  List<Object?> get props => [
    overallScore,
    verificationCompleteness,
    certificationFreshness,
    accountAgeActivity,
    manualBuyerFlag,
    riskLevel,
  ];
}

class TrustHistoryPoint extends Equatable {
  final int score;
  final DateTime recordedAt;

  const TrustHistoryPoint({required this.score, required this.recordedAt});

  factory TrustHistoryPoint.fromJson(Map<String, dynamic> j) =>
      TrustHistoryPoint(
        score: (j['score'] as num?)?.toInt() ?? 0,
        recordedAt: DateTime.tryParse(
              j['recordedAt']?.toString() ??
                  j['recorded_at']?.toString() ??
                  '',
            ) ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [score, recordedAt];
}

class VerificationRecord extends Equatable {
  final String id;
  final VerificationType type;
  final VerificationStatus status;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const VerificationRecord({
    required this.id,
    required this.type,
    required this.status,
    this.verifiedAt,
    required this.createdAt,
  });

  factory VerificationRecord.fromJson(Map<String, dynamic> j) =>
      VerificationRecord(
        id: j['id']?.toString() ?? '',
        type: VerificationTypeX.fromString(j['type']?.toString() ?? 'PAN'),
        status: VerificationStatusX.fromString(
            j['status']?.toString() ?? 'PENDING'),
        verifiedAt: j['verifiedAt'] != null
            ? DateTime.tryParse(j['verifiedAt'].toString())
            : (j['verified_at'] != null
                ? DateTime.tryParse(j['verified_at'].toString())
                : null),
        createdAt: DateTime.tryParse(
              j['createdAt']?.toString() ?? j['created_at']?.toString() ?? '',
            ) ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [id, type, status, verifiedAt, createdAt];
}

class VendorDocument extends Equatable {
  final String id;
  final String type;
  final DocumentStatus status;
  final String? certificateNumber;
  final String? issuingAuthority;
  final DateTime? issueDate;
  final DateTime? expirationDate;
  final double? confidence;
  final DateTime uploadedAt;

  const VendorDocument({
    required this.id,
    required this.type,
    required this.status,
    this.certificateNumber,
    this.issuingAuthority,
    this.issueDate,
    this.expirationDate,
    this.confidence,
    required this.uploadedAt,
  });

  factory VendorDocument.fromJson(Map<String, dynamic> j) => VendorDocument(
    id: j['id']?.toString() ?? '',
    type: j['type']?.toString() ?? 'Document',
    status: DocumentStatusX.fromString(j['status']?.toString() ?? 'UPLOADED'),
    certificateNumber:
        (j['certificateNumber'] ?? j['certificate_number'])?.toString(),
    issuingAuthority:
        (j['issuingAuthority'] ?? j['issuing_authority'])?.toString(),
    issueDate: j['issueDate'] != null
        ? DateTime.tryParse(j['issueDate'].toString())
        : (j['issue_date'] != null
            ? DateTime.tryParse(j['issue_date'].toString())
            : null),
    expirationDate: j['expirationDate'] != null
        ? DateTime.tryParse(j['expirationDate'].toString())
        : (j['expiration_date'] != null
            ? DateTime.tryParse(j['expiration_date'].toString())
            : null),
    confidence: (j['confidence'] as num?)?.toDouble(),
    uploadedAt: DateTime.tryParse(
          j['uploadedAt']?.toString() ?? j['uploaded_at']?.toString() ?? '',
        ) ??
        DateTime.now(),
  );

  bool get isExpired =>
      expirationDate != null && expirationDate!.isBefore(DateTime.now());

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final diff = expirationDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 90;
  }

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    certificateNumber,
    expirationDate,
  ];
}

class VendorEvent extends Equatable {
  final String id;
  final VendorEventKind kind;
  final String title;
  final String detail;
  final DateTime at;

  const VendorEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.at,
  });

  factory VendorEvent.fromJson(Map<String, dynamic> j) => VendorEvent(
    id: j['id']?.toString() ?? '',
    kind: VendorEventKindX.fromString(j['kind']?.toString() ?? 'VERIFICATION'),
    title: j['title']?.toString() ?? 'Event',
    detail: j['detail']?.toString() ?? '',
    at: DateTime.tryParse(j['at']?.toString() ?? '') ?? DateTime.now(),
  );

  @override
  List<Object?> get props => [id, kind, title, at];
}

/// Full vendor model matching ApiVendor from frontend/src/lib/api.ts
class Vendor extends Equatable {
  final String id;
  final String legalName;
  final String? tradeName;
  final String email;
  final String phone;
  final String? pan;
  final String? gstin;
  final String? cin;
  final String? udyamNumber;
  final MsmeCategory msmeCategory;
  final String city;
  final String state;
  final List<String> categories;
  final String contactName;
  final String contactRole;
  final VendorStatus status;
  final String? buyerFlagNote;
  final DateTime onboardedAt;
  final TrustScore? trustScore;
  final List<TrustHistoryPoint> trustHistory;
  final List<VerificationRecord> verifications;
  final List<VendorDocument> documents;
  final List<VendorEvent> events;

  const Vendor({
    required this.id,
    required this.legalName,
    this.tradeName,
    required this.email,
    required this.phone,
    this.pan,
    this.gstin,
    this.cin,
    this.udyamNumber,
    required this.msmeCategory,
    required this.city,
    required this.state,
    required this.categories,
    required this.contactName,
    required this.contactRole,
    required this.status,
    this.buyerFlagNote,
    required this.onboardedAt,
    this.trustScore,
    required this.trustHistory,
    required this.verifications,
    required this.documents,
    required this.events,
  });

  factory Vendor.fromJson(Map<String, dynamic> j) => Vendor(
    id: j['id']?.toString() ?? '',
    legalName: (j['legalName'] ?? j['legal_name'])?.toString() ?? '',
    tradeName: (j['tradeName'] ?? j['trade_name'])?.toString(),
    email: j['email']?.toString() ?? '',
    phone: j['phone']?.toString() ?? '',
    pan: j['pan']?.toString(),
    gstin: j['gstin']?.toString(),
    cin: j['cin']?.toString(),
    udyamNumber: (j['udyamNumber'] ?? j['udyam_number'])?.toString(),
    msmeCategory: MsmeCategoryX.fromString(
        (j['msmeCategory'] ?? j['msme_category'] ?? 'MICRO').toString()),
    city: j['city'] as String? ?? '',
    state: j['state'] as String? ?? '',
    categories: (j['categories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    contactName:
        (j['contactName'] ?? j['contact_name']) as String? ?? '',
    contactRole:
        (j['contactRole'] ?? j['contact_role']) as String? ?? '',
    status: VendorStatusX.fromString((j['status'] ?? 'DRAFT').toString()),
    buyerFlagNote:
        (j['buyerFlagNote'] ?? j['buyer_flag_note']) as String?,
    onboardedAt: DateTime.tryParse(
          j['onboardedAt']?.toString() ?? j['onboarded_at']?.toString() ?? '',
        ) ??
        DateTime.now(),
    trustScore: j['trustScore'] != null
        ? TrustScore.fromJson(j['trustScore'] as Map<String, dynamic>)
        : (j['trust_score'] != null
            ? TrustScore.fromJson(j['trust_score'] as Map<String, dynamic>)
            : null),
    trustHistory: ((j['trustHistory'] ?? j['trust_history']) as List<dynamic>?)
            ?.map((e) => TrustHistoryPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    verifications: (j['verifications'] as List<dynamic>?)
            ?.map((e) => VerificationRecord.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    documents: (j['documents'] as List<dynamic>?)
            ?.map((e) => VendorDocument.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    events: (j['events'] as List<dynamic>?)
            ?.map((e) => VendorEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  /// Display name — tradeName if set, else legalName.
  String get displayName =>
      tradeName?.isNotEmpty == true ? tradeName! : legalName;

  @override
  List<Object?> get props => [id, legalName, status, trustScore];
}
