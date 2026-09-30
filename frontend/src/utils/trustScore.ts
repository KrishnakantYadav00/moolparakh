import type {
  Certificate,
  RiskLevel,
  TrustBand,
  TrustComponentRow,
  TrustComponents,
  Vendor,
} from '@/types';
import { daysUntil } from '@/utils/format';

/**
 * Vendor Trust Score — transparent 0–100 score.
 * Four weighted components, exactly as defined in the PRD.
 */
export const TRUST_WEIGHTS: Record<keyof TrustComponents, number> = {
  verificationCompleteness: 40,
  certificationFreshness: 35,
  accountAgeActivity: 15,
  manualBuyerFlag: 10,
};

export const TRUST_LABELS: Record<keyof TrustComponents, string> = {
  verificationCompleteness: 'Verification Completeness',
  certificationFreshness: 'Certification Freshness',
  accountAgeActivity: 'Account Age & Activity',
  manualBuyerFlag: 'Manual Buyer Flag',
};

const TRUST_NOTES: Record<keyof TrustComponents, string> = {
  verificationCompleteness: 'GSTIN, PAN linkage, Udyam and CIN checks returned by the KYB service.',
  certificationFreshness: 'How much validity is left on GST, Udyam, ISO and insurance documents.',
  accountAgeActivity: 'Time on the network, order volume and delivery performance.',
  manualBuyerFlag: 'Adjustment applied by your procurement team after a review.',
};

export function totalTrustScore(components: TrustComponents): number {
  return Math.round(
    components.verificationCompleteness +
      components.certificationFreshness +
      components.accountAgeActivity +
      components.manualBuyerFlag,
  );
}

export function trustBand(score: number): TrustBand {
  if (score >= 85) return 'Excellent';
  if (score >= 70) return 'Good';
  if (score >= 50) return 'Watch';
  return 'High Risk';
}

export function trustBandColor(band: TrustBand): string {
  switch (band) {
    case 'Excellent':
      return '#0F8B8D';
    case 'Good':
      return '#3AA3A4';
    case 'Watch':
      return '#B35309';
    case 'High Risk':
      return '#B3261E';
  }
}

/** Ordered breakdown rows used by the trust score panel and tooltips. */
export function trustBreakdown(components: TrustComponents): TrustComponentRow[] {
  return (Object.keys(TRUST_WEIGHTS) as (keyof TrustComponents)[]).map((key) => ({
    key,
    label: TRUST_LABELS[key],
    weight: TRUST_WEIGHTS[key],
    earned: components[key],
    max: TRUST_WEIGHTS[key],
    note: TRUST_NOTES[key],
  }));
}

/**
 * Certification freshness recomputed from live certificate expiry dates.
 * Full marks while every document has more than 90 days left; the score
 * decays as documents approach expiry and is halved once one has lapsed.
 */
export function certificationFreshnessScore(certificates: Certificate[]): number {
  if (certificates.length === 0) return 0;
  const perDoc = TRUST_WEIGHTS.certificationFreshness / certificates.length;
  const earned = certificates.reduce((sum, cert) => {
    const days = daysUntil(cert.expiresOn);
    if (days < 0) return sum;
    if (days >= 90) return sum + perDoc;
    if (days >= 60) return sum + perDoc * 0.9;
    if (days >= 30) return sum + perDoc * 0.75;
    return sum + perDoc * 0.5;
  }, 0);
  return Math.round(earned * 10) / 10;
}

export function riskFromTrust(score: number): RiskLevel {
  if (score < 50) return 'CRITICAL';
  if (score < 65) return 'HIGH';
  if (score < 80) return 'MEDIUM';
  return 'LOW';
}

export function bandDistribution(vendors: Vendor[]): { band: TrustBand; count: number }[] {
  const bands: TrustBand[] = ['Excellent', 'Good', 'Watch', 'High Risk'];
  return bands.map((band) => ({
    band,
    count: vendors.filter((v) => trustBand(v.trustScore) === band).length,
  }));
}

export function averageTrust(vendors: Vendor[]): number {
  if (vendors.length === 0) return 0;
  const total = vendors.reduce((sum, v) => sum + v.trustScore, 0);
  return Math.round((total / vendors.length) * 10) / 10;
}
