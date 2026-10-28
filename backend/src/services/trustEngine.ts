// src/services/trustEngine.ts
// Live Trust Score calculation engine based on MoolParakh's 4-component model

import db from '@/lib/db.js';

export interface TrustScoreBreakdown {
  overallScore: number;
  verificationCompleteness: number; // max 40
  certificationFreshness: number;   // max 35
  accountAgeActivity: number;       // max 15
  manualBuyerFlag: number;          // max 10
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  factors: Record<string, unknown>;
}

/**
 * Recalculate trust score for a specific vendor from live DB records
 */
export async function recalculateTrustScore(vendorId: string): Promise<TrustScoreBreakdown> {
  const vendor = await db.vendor.findUnique({
    where: { id: vendorId },
    include: {
      verifications: true,
      documents: {
        where: { expirationDate: { not: null } },
        orderBy: { expirationDate: 'asc' },
      },
      bids: true,
      alerts: { where: { isResolved: false } },
    },
  });

  if (!vendor) {
    throw new Error(`Vendor ${vendorId} not found`);
  }

  const now = new Date();

  // ─── 1. Verification Completeness (/40) ───────────────────────────────────
  let verificationCompleteness = 0;
  const verifications = vendor.verifications || [];
  const totalVerifs = verifications.length;
  const successVerifs = verifications.filter((v) => v.status === 'SUCCESS').length;
  const failedVerifs = verifications.filter((v) => v.status === 'FAILED').length;

  if (totalVerifs > 0) {
    verificationCompleteness = Math.round((successVerifs / totalVerifs) * 40);
  }

  // ─── 2. Certification Freshness (/35) ─────────────────────────────────────
  let certificationFreshness = 0;
  const docsWithExpiry = vendor.documents || [];

  if (docsWithExpiry.length === 0) {
    // If no certificates are uploaded yet, award a neutral baseline if newly onboarded
    certificationFreshness = 10;
  } else {
    // Find earliest expiration date
    const earliestDoc = docsWithExpiry[0];
    const expiryTime = new Date(earliestDoc.expirationDate!).getTime();
    const diffDays = Math.floor((expiryTime - now.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays < 0) {
      // Expired document!
      certificationFreshness = 0;
    } else if (diffDays <= 30) {
      certificationFreshness = 12; // Expiring soon (<30 days)
    } else if (diffDays <= 60) {
      certificationFreshness = 20; // 30-60 days
    } else if (diffDays <= 180) {
      certificationFreshness = 28; // 60-180 days
    } else {
      certificationFreshness = 35; // >180 days fresh
    }
  }

  // ─── 3. Account Age & Activity (/15) ──────────────────────────────────────
  const onboardedDate = new Date(vendor.onboardedAt);
  const daysSinceOnboard = Math.max(0, Math.floor((now.getTime() - onboardedDate.getTime()) / (1000 * 60 * 60 * 24)));

  let ageScore = 2;
  if (daysSinceOnboard > 365) ageScore = 8;
  else if (daysSinceOnboard > 180) ageScore = 6;
  else if (daysSinceOnboard > 60) ageScore = 4;
  else if (daysSinceOnboard > 14) ageScore = 3;

  const bidCount = vendor.bids ? vendor.bids.length : 0;
  let bidScore = 1;
  if (bidCount >= 5) bidScore = 7;
  else if (bidCount >= 3) bidScore = 5;
  else if (bidCount >= 1) bidScore = 3;

  const accountAgeActivity = Math.min(15, ageScore + bidScore);

  // ─── 4. Manual Buyer Flag (/10) ───────────────────────────────────────────
  let manualBuyerFlag = 10;
  const note = (vendor.buyerFlagNote || '').trim().toLowerCase();

  if (note.length > 0) {
    if (
      note.includes('fraud') ||
      note.includes('disqualified') ||
      note.includes('suspended') ||
      note.includes('shell') ||
      note.includes('investigation')
    ) {
      manualBuyerFlag = 0;
    } else if (note.includes('mismatch') || note.includes('review') || note.includes('shared')) {
      manualBuyerFlag = 4;
    } else {
      manualBuyerFlag = 6;
    }
  }

  // ─── 5. Composite Score & Risk Classification ─────────────────────────────
  const overallScore = Math.min(
    100,
    Math.max(0, verificationCompleteness + certificationFreshness + accountAgeActivity + manualBuyerFlag)
  );

  let riskLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL' = 'LOW';
  if (overallScore < 35 || failedVerifs >= 2 || manualBuyerFlag === 0) {
    riskLevel = 'CRITICAL';
  } else if (overallScore < 55 || failedVerifs === 1) {
    riskLevel = 'HIGH';
  } else if (overallScore < 75) {
    riskLevel = 'MEDIUM';
  } else {
    riskLevel = 'LOW';
  }

  const factors = {
    verifications: {
      total: totalVerifs,
      success: successVerifs,
      failed: failedVerifs,
      completenessScore: verificationCompleteness,
    },
    certificates: {
      totalWithExpiry: docsWithExpiry.length,
      earliestExpiry: docsWithExpiry[0]?.expirationDate ?? null,
      freshnessScore: certificationFreshness,
    },
    activity: {
      daysSinceOnboard,
      ageScore,
      bidCount,
      bidScore,
      totalActivityScore: accountAgeActivity,
    },
    buyerFlag: {
      hasNote: Boolean(note),
      flagScore: manualBuyerFlag,
    },
  };

  // ─── 6. Persist to DB ─────────────────────────────────────────────────────
  await db.trustScore.upsert({
    where: { vendorId },
    update: {
      overallScore,
      verificationCompleteness,
      certificationFreshness,
      accountAgeActivity,
      manualBuyerFlag,
      riskLevel,
      scoringFactors: factors,
      lastCalculatedAt: now,
    },
    create: {
      vendorId,
      overallScore,
      verificationCompleteness,
      certificationFreshness,
      accountAgeActivity,
      manualBuyerFlag,
      riskLevel,
      scoringFactors: factors,
      lastCalculatedAt: now,
    },
  });

  // Record point in trustHistory
  await db.trustHistoryPoint.create({
    data: {
      vendorId,
      score: overallScore,
      recordedAt: now,
    },
  });

  // Auto-update vendor status based on verification outcome
  if (vendor.status === 'DRAFT' || vendor.status === 'PENDING_VERIFICATION') {
    if (totalVerifs > 0 && failedVerifs === 0 && overallScore >= 60) {
      await db.vendor.update({
        where: { id: vendorId },
        data: { status: 'VERIFIED' },
      });
    } else if (failedVerifs > 0 || riskLevel === 'CRITICAL') {
      await db.vendor.update({
        where: { id: vendorId },
        data: { status: 'FLAGGED' },
      });
    }
  }

  return {
    overallScore,
    verificationCompleteness,
    certificationFreshness,
    accountAgeActivity,
    manualBuyerFlag,
    riskLevel,
    factors,
  };
}
