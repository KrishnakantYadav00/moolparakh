/**
 * MoolParakh — domain types.
 * These mirror the shapes a real API would return, so `src/data/mockData.ts`
 * can be swapped for fetch calls without touching components.
 */

export type RiskLevel = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';

export type TrustBand = 'Excellent' | 'Good' | 'Watch' | 'High Risk';

export type VendorStatus = 'Verified' | 'Review' | 'High Risk';

export type MsmeCategory = 'Micro' | 'Small' | 'Medium';

export type VerificationState = 'Verified' | 'Pending' | 'Failed';

export type ComplianceState = 'Compliant' | 'Expiring Soon' | 'Expired' | 'Needs Review';

export type CertificateType =
  | 'GST Certificate'
  | 'Udyam Certificate'
  | 'ISO Certificate'
  | 'ISO / Quality Certificate'
  | 'Insurance Document';

export type ExpiryBucket = '90+ DAYS' | '90 DAYS' | '60 DAYS' | '30 DAYS' | 'EXPIRED';

/** Raw points earned against each weighted component of the Vendor Trust Score. */
export interface TrustComponents {
  /** out of 40 */
  verificationCompleteness: number;
  /** out of 35 */
  certificationFreshness: number;
  /** out of 15 */
  accountAgeActivity: number;
  /** out of 10 */
  manualBuyerFlag: number;
}

export interface TrustComponentRow {
  key: keyof TrustComponents;
  label: string;
  weight: number;
  earned: number;
  max: number;
  note: string;
}

export interface Certificate {
  id: string;
  vendorId: string;
  type: CertificateType;
  number: string;
  issuedOn: string;
  expiresOn: string;
}

export type VendorEventKind =
  | 'verification'
  | 'compliance'
  | 'risk'
  | 'trust'
  | 'rfq'
  | 'document';

export interface VendorEvent {
  id: string;
  at: string;
  kind: VendorEventKind;
  title: string;
  detail: string;
}

export interface VerificationChecks {
  gstin: VerificationState;
  pan: VerificationState;
  udyam: VerificationState;
  cin: VerificationState;
}

export interface TrustPoint {
  date: string;
  score: number;
}

export interface DeliveryPerformance {
  onTimePercent: number;
  ordersLast12Months: number;
  lateBuckets: {
    '0–2 days': number;
    '3–5 days': number;
    '6–10 days': number;
    '10+ days': number;
  };
}

export interface Vendor {
  id: string;
  name: string;
  gstin: string;
  pan: string;
  cin: string;
  udyamNumber: string;
  msmeCategory: MsmeCategory;
  city: string;
  state: string;
  categories: string[];
  contactName: string;
  contactRole: string;
  onboardedOn: string;
  lastVerifiedDays: number;
  status: VendorStatus;
  risk: RiskLevel;
  trust: TrustComponents;
  trustScore: number;
  trustHistory: TrustPoint[];
  verification: VerificationChecks;
  certificates: Certificate[];
  events: VendorEvent[];
  delivery: DeliveryPerformance;
  buyerFlagNote: string;
}

export type DisruptionCategory =
  | 'Port Disruption'
  | 'Tariff'
  | 'Natural Disaster'
  | 'Geopolitical'
  | 'Logistics'
  | 'Regulatory';

export interface DisruptionEvent {
  id: string;
  severity: RiskLevel;
  title: string;
  category: DisruptionCategory;
  region: string;
  detectedMinutesAgo: number;
  summary: string;
  affectedVendorIds: string[];
}

export interface Bid {
  id: string;
  rfqId: string;
  vendorId: string;
  vendorName: string;
  pricePerUnit: number;
  deliveryDays: number;
  trustScore: number;
  submittedHoursAgo: number;
  notes: string;
}

export interface ScoredBid extends Bid {
  priceScore: number;
  deliveryScore: number;
  trustNormalised: number;
  composite: number;
  rank: number;
  contributions: {
    price: number;
    delivery: number;
    trust: number;
  };
}

export interface BidWeights {
  price: number;
  delivery: number;
  trust: number;
}

export type RfqStatus = 'OPEN' | 'DRAFT' | 'COMPLETED';

export interface RfqSpec {
  item: string;
  standard: string;
  grade: string;
  quantity: number;
  unit: string;
  deliveryDays: number;
  deliveryLocation: string;
  qualityNotes: string;
}

export interface Rfq {
  id: string;
  reference: string;
  title: string;
  status: RfqStatus;
  spec: RfqSpec;
  suppliersNotified: number;
  createdOn: string;
  closesInHours: number;
  bids: Bid[];
  awardedVendorId?: string;
  freeText: string;
}

export interface SupplierRelationship {
  id: string;
  type: 'Shared director' | 'Shared bank account' | 'Shared registered address';
  value: string;
  vendorAId: string;
  vendorBId: string;
}

export type NotificationKind = 'HIGH' | 'CRITICAL' | 'COMPLIANCE' | 'RFQ' | 'TRUST';

export interface AppNotification {
  id: string;
  kind: NotificationKind;
  title: string;
  vendorName: string;
  detail: string;
  minutesAgo: number;
  read: boolean;
}

export type ViewKey =
  | 'overview'
  | 'vendors'
  | 'compliance'
  | 'intelligence'
  | 'rfq'
  | 'notifications'
  | 'settings';
