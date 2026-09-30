// src/lib/mappers.ts
// Adapts raw backend shapes → frontend domain types (src/types/index.ts)

import type {
  Vendor, Rfq, Bid, AppNotification,
  VendorStatus, RiskLevel, MsmeCategory,
  VerificationChecks, VerificationState,
  TrustComponents, TrustPoint, VendorEvent, VendorEventKind,
} from '@/types';
import type { ApiVendor, ApiRfq, ApiBid, ApiNotification } from './api';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function minutesAgo(iso: string): number {
  return Math.round((Date.now() - new Date(iso).getTime()) / 60_000);
}

function hoursAgo(iso: string): number {
  return Math.round((Date.now() - new Date(iso).getTime()) / 3_600_000);
}

function daysSince(iso: string): number {
  return Math.round((Date.now() - new Date(iso).getTime()) / 86_400_000);
}

function isoDate(iso: string | null | undefined): string {
  if (!iso) return '';
  return new Date(iso).toISOString().slice(0, 10);
}

// ─── Vendor status mapping ────────────────────────────────────────────────────

function mapVendorStatus(
  dbStatus: ApiVendor['status'],
  riskLevel: string,
): VendorStatus {
  if (dbStatus === 'VERIFIED') return 'Verified';
  if (dbStatus === 'FLAGGED' || dbStatus === 'REJECTED') return 'High Risk';
  if (riskLevel === 'CRITICAL' || riskLevel === 'HIGH') return 'High Risk';
  return 'Review';
}

function mapRisk(level: string | undefined): RiskLevel {
  if (level === 'CRITICAL') return 'CRITICAL';
  if (level === 'HIGH') return 'HIGH';
  if (level === 'MEDIUM') return 'MEDIUM';
  return 'LOW';
}

function mapMsme(cat: string): MsmeCategory {
  if (cat === 'SMALL') return 'Small';
  if (cat === 'MEDIUM') return 'Medium';
  return 'Micro';
}

function mapVerificationState(status: string): VerificationState {
  if (status === 'SUCCESS') return 'Verified';
  if (status === 'FAILED') return 'Failed';
  return 'Pending';
}

// ─── Main mappers ─────────────────────────────────────────────────────────────

export function mapVendor(raw: ApiVendor): Vendor {
  const ts = raw.trustScore;
  const riskLevel = ts?.riskLevel ?? 'LOW';

  const trust: TrustComponents = {
    verificationCompleteness: ts?.verificationCompleteness ?? 0,
    certificationFreshness:   ts?.certificationFreshness   ?? 0,
    accountAgeActivity:       ts?.accountAgeActivity       ?? 0,
    manualBuyerFlag:          ts?.manualBuyerFlag          ?? 0,
  };

  // Build verification checks from the verifications array
  const verif = raw.verifications ?? [];
  const findState = (type: string): VerificationState =>
    mapVerificationState(verif.find(v => v.type === type)?.status ?? 'PENDING');

  const verification: VerificationChecks = {
    gstin: raw.gstin ? findState('GSTIN') : 'Pending',
    pan:   raw.pan   ? findState('PAN')   : 'Pending',
    udyam: raw.udyamNumber ? findState('UDYAM') : 'Pending',
    cin:   raw.cin   ? findState('CIN')   : 'Pending',
  };

  // Trust history sparkline
  const trustHistory: TrustPoint[] = (raw.trustHistory ?? []).map(p => ({
    date:  isoDate(p.recordedAt),
    score: p.score,
  }));

  // Events
  const events: VendorEvent[] = (raw.events ?? []).map(e => ({
    id:     e.id,
    at:     e.at,
    kind:   e.kind.toLowerCase() as VendorEventKind,
    title:  e.title,
    detail: e.detail,
  }));

  // Certificates from documents that have expiry info
  const certificates = (raw.documents ?? [])
    .filter(d => d.expirationDate)
    .map(d => ({
      id:        d.id,
      vendorId:  raw.id,
      type:      d.type as import('@/types').CertificateType,
      number:    d.certificateNumber ?? '',
      issuedOn:  isoDate(d.issueDate),
      expiresOn: isoDate(d.expirationDate),
    }));

  // Last verified: most recent SUCCESS verification
  const lastSuccess = raw.verifications
    ?.filter(v => v.status === 'SUCCESS')
    .map(v => new Date(v.createdAt).getTime())
    .sort((a, b) => b - a)[0];

  return {
    id:              raw.id,
    name:            raw.legalName,
    gstin:           raw.gstin           ?? '',
    pan:             raw.pan             ?? '',
    cin:             raw.cin             ?? '',
    udyamNumber:     raw.udyamNumber     ?? '',
    msmeCategory:    mapMsme(raw.msmeCategory),
    city:            raw.city,
    state:           raw.state,
    categories:      raw.categories,
    contactName:     raw.contactName,
    contactRole:     raw.contactRole,
    onboardedOn:     isoDate(raw.onboardedAt),
    lastVerifiedDays: lastSuccess ? daysSince(new Date(lastSuccess).toISOString()) : daysSince(raw.onboardedAt),
    status:          mapVendorStatus(raw.status, riskLevel as never),
    risk:            mapRisk(riskLevel),
    trust,
    trustScore:      ts?.overallScore ?? 0,
    trustHistory,
    verification,
    certificates,
    events,
    delivery: {
      onTimePercent:       0,
      ordersLast12Months:  0,
      lateBuckets: { '0–2 days': 0, '3–5 days': 0, '6–10 days': 0, '10+ days': 0 },
    },
    buyerFlagNote: raw.buyerFlagNote ?? '',
  };
}

export function mapBid(raw: ApiBid): Bid {
  return {
    id:               raw.id,
    rfqId:            raw.rfqId,
    vendorId:         raw.vendorId,
    vendorName:       raw.vendorName,
    pricePerUnit:     raw.pricePerUnit,
    deliveryDays:     raw.deliveryDays,
    trustScore:       raw.trustScoreAtBid,
    submittedHoursAgo: hoursAgo(raw.submittedAt),
    notes:            raw.notes ?? '',
  };
}

export function mapRfq(raw: ApiRfq): Rfq {
  const spec = raw.spec as Record<string, unknown>;
  return {
    id:                 raw.id,
    reference:          raw.reference,
    title:              raw.title,
    status:             raw.status as import('@/types').RfqStatus,
    spec: {
      item:             String(spec.item             ?? ''),
      standard:         String(spec.standard         ?? ''),
      grade:            String(spec.grade            ?? ''),
      quantity:         Number(spec.quantity         ?? 0),
      unit:             String(spec.unit             ?? ''),
      deliveryDays:     Number(spec.deliveryDays     ?? 0),
      deliveryLocation: String(spec.deliveryLocation ?? ''),
      qualityNotes:     String(spec.qualityNotes     ?? ''),
    },
    suppliersNotified:  raw.suppliersNotified,
    createdOn:          isoDate(raw.createdAt),
    closesInHours:      hoursAgo(raw.closesAt) * -1, // positive = time remaining
    bids:               (raw.bids ?? []).map(mapBid),
    awardedVendorId:    raw.awardedVendorId ?? undefined,
    freeText:           raw.freeText ?? '',
  };
}

export function mapNotification(raw: ApiNotification): AppNotification {
  return {
    id:          raw.id,
    kind:        raw.kind,
    title:       raw.title,
    vendorName:  raw.vendorName,
    detail:      raw.detail,
    minutesAgo:  minutesAgo(raw.createdAt),
    read:        raw.read,
  };
}
