import type { Certificate, ComplianceState, ExpiryBucket, Vendor } from '@/types';
import { daysUntil, expiryBucket } from '@/utils/format';

export interface CertificateRow {
  certificate: Certificate;
  vendor: Vendor;
  days: number;
  bucket: ExpiryBucket;
}

/** Every certificate in the network, joined to its vendor and sorted by urgency. */
export function certificateRows(vendors: Vendor[]): CertificateRow[] {
  return vendors
    .flatMap((vendor) =>
      vendor.certificates.map((certificate) => ({
        certificate,
        vendor,
        days: daysUntil(certificate.expiresOn),
        bucket: expiryBucket(certificate.expiresOn),
      })),
    )
    .sort((a, b) => a.days - b.days);
}

/** The PRD alerts at 90, 60 and 30 days; anything at 60 days or less needs action. */
export function attentionRows(rows: CertificateRow[]): CertificateRow[] {
  return rows.filter((row) => row.days <= 60);
}

export function complianceSummary(rows: CertificateRow[]) {
  const expired = rows.filter((row) => row.days < 0).length;
  const within30 = rows.filter((row) => row.days >= 0 && row.days <= 30).length;
  const within60 = rows.filter((row) => row.days > 30 && row.days <= 60).length;
  const within90 = rows.filter((row) => row.days > 60 && row.days <= 90).length;
  return {
    expired,
    within30,
    within60,
    within90,
    attention: expired + within30 + within60,
  };
}

export function vendorComplianceState(vendor: Vendor): ComplianceState {
  const hasExpired = vendor.certificates.some((c) => daysUntil(c.expiresOn) < 0);
  if (hasExpired) return 'Expired';

  const allVerified = Object.values(vendor.verification).every((v) => v === 'Verified');
  if (!allVerified) return 'Needs Review';

  const expiringSoon = vendor.certificates.some((c) => daysUntil(c.expiresOn) <= 60);
  return expiringSoon ? 'Expiring Soon' : 'Compliant';
}

export function complianceTone(
  state: ComplianceState,
): 'good' | 'medium' | 'critical' | 'high' {
  switch (state) {
    case 'Compliant':
      return 'good';
    case 'Expiring Soon':
      return 'medium';
    case 'Expired':
      return 'critical';
    case 'Needs Review':
      return 'high';
  }
}
