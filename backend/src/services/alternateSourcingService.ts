// src/services/alternateSourcingService.ts
// Intelligent Alternate Sourcing Engine: Finds pre-qualified backup suppliers in different regions

import db from '@/lib/db.js';

export interface AlternateSupplier {
  id: string;
  legalName: string;
  state: string;
  city: string;
  msmeCategory: string;
  status: string;
  trustScore: number;
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  sharedCategories: string[];
  activeDisruptionCount: number;
  recommendationReason: string;
}

export interface AlternateSourcingResult {
  targetVendor: {
    id: string;
    legalName: string;
    state: string;
    city: string;
    categories: string[];
    trustScore: number;
    riskLevel: string;
  };
  disruptionsCount: number;
  alternates: AlternateSupplier[];
}

// Category affinity clusters to match related MSME capabilities
const CATEGORY_CLUSTERS: Record<string, string[]> = {
  metal: ['steel', 'iron', 'fabrication', 'forging', 'sheet metal', 'cnc', 'machining', 'mechanical', 'tools', 'welding', 'valves', 'hardware'],
  textiles: ['textile', 'fabrics', 'woven', 'cotton', 'uniform', 'handloom', 'silk', 'ppe', 'apparel', 'garment'],
  packaging: ['packaging', 'printing', 'carton', 'labels', 'blister', 'boxes', 'corrugated'],
  chemicals: ['chemical', 'polymer', 'adhesive', 'gases', 'industrial gases'],
  electrical: ['electrical', 'control panel', 'switchgear', 'motor', 'pumps', 'equipment'],
  logistics: ['logistics', 'warehousing', 'transport', '3pl', 'freight'],
};

function matchesKeyword(text: string, keyword: string): boolean {
  const words = text.toLowerCase().split(/[\s,/-]+/);
  // If keyword is multi-word, check if text includes it as phrase
  if (keyword.includes(' ')) {
    return text.toLowerCase().includes(keyword);
  }
  return words.some((w) => w === keyword || (w.startsWith(keyword) && keyword.length >= 5));
}

function getClusterMatches(targetCategories: string[], candidateCategories: string[]): string[] {
  const matches = new Set<string>();

  for (const tc of targetCategories) {
    for (const [_clusterKey, keywords] of Object.entries(CATEGORY_CLUSTERS)) {
      if (keywords.some((k) => matchesKeyword(tc, k))) {
        for (const cc of candidateCategories) {
          if (keywords.some((k) => matchesKeyword(cc, k))) {
            matches.add(cc);
          }
        }
      }
    }
  }

  return Array.from(matches);
}

/**
 * Find pre-qualified alternate suppliers in different geographical regions
 * for a disrupted vendor.
 */
export async function findAlternateSuppliers(
  vendorId: string,
  limit = 3
): Promise<AlternateSourcingResult> {
  const targetVendor = await db.vendor.findUnique({
    where: { id: vendorId },
    include: {
      trustScore: true,
      disruptionTargets: {
        include: { event: true },
      },
    },
  });

  if (!targetVendor) {
    throw new Error(`Vendor ${vendorId} not found`);
  }

  const targetCategories = targetVendor.categories || [];
  const targetState = targetVendor.state || '';

  // Query all qualified vendors in different states (pre-qualified with trust score >= 50 and not flagged)
  const allCandidates = await db.vendor.findMany({
    where: {
      id: { not: vendorId },
      state: { not: targetState },
      status: { not: 'FLAGGED' },
      trustScore: {
        overallScore: { gte: 50 },
      },
    },
    include: {
      trustScore: true,
      verifications: true,
      disruptionTargets: {
        include: { event: true },
      },
    },
  });

  // Score each candidate
  const evaluated = allCandidates.map((candidate) => {
    // 1. Direct category matches
    const exactMatches = candidate.categories.filter((c) =>
      targetCategories.some((tc) => tc.toLowerCase() === c.toLowerCase())
    );

    // 2. Semantic/Cluster capability matches
    const clusterMatches = getClusterMatches(targetCategories, candidate.categories);
    const combinedMatches = Array.from(new Set([...exactMatches, ...clusterMatches]));

    // 3. Active disruption count
    const activeDisruptions = candidate.disruptionTargets.filter(
      (dt) => dt.event.severity === 'CRITICAL' || dt.event.severity === 'HIGH'
    ).length;

    const score = candidate.trustScore?.overallScore ?? 0;
    const risk = candidate.trustScore?.riskLevel ?? 'LOW';

    let matchWeight = 0;
    if (exactMatches.length > 0) matchWeight += 100 * exactMatches.length;
    else if (combinedMatches.length > 0) matchWeight += 50 * combinedMatches.length;

    // Trust score bonus
    matchWeight += score;

    // Penalty for active disruptions
    matchWeight -= activeDisruptions * 80;

    // Explanations
    let recommendationReason = `Pre-qualified alternate in ${candidate.state} (${candidate.city}), geographically diversified from ${targetState}. Trust score: ${score}/100.`;
    if (exactMatches.length > 0) {
      recommendationReason += ` Direct category match: ${exactMatches.join(', ')}.`;
    } else if (combinedMatches.length > 0) {
      recommendationReason += ` Related capability: ${combinedMatches.join(', ')}.`;
    }
    if (candidate.status === 'VERIFIED') {
      recommendationReason += ' Verified KYB status.';
    }
    if (activeDisruptions === 0) {
      recommendationReason += ' Clear of regional disruptions.';
    }

    return {
      supplier: {
        id: candidate.id,
        legalName: candidate.legalName,
        state: candidate.state,
        city: candidate.city,
        msmeCategory: candidate.msmeCategory,
        status: candidate.status,
        trustScore: score,
        riskLevel: risk,
        sharedCategories: combinedMatches.length > 0 ? combinedMatches : candidate.categories.slice(0, 2),
        activeDisruptionCount: candidate.disruptionTargets.length,
        recommendationReason,
      },
      matchWeight,
    };
  });

  // Sort by calculated match weight
  const sorted = evaluated
    .sort((a, b) => b.matchWeight - a.matchWeight)
    .map((e) => e.supplier)
    .slice(0, limit);

  return {
    targetVendor: {
      id: targetVendor.id,
      legalName: targetVendor.legalName,
      state: targetVendor.state,
      city: targetVendor.city,
      categories: targetVendor.categories,
      trustScore: targetVendor.trustScore?.overallScore ?? 0,
      riskLevel: targetVendor.trustScore?.riskLevel ?? 'LOW',
    },
    disruptionsCount: targetVendor.disruptionTargets.length,
    alternates: sorted,
  };
}
