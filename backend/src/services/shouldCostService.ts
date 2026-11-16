// src/services/shouldCostService.ts
// Compares bid prices against historical averages & industry benchmarks
// Generates sanity/should-cost warnings when prices deviate >20%

import db from '@/lib/db.js';

export interface PriceSanityResult {
  flag: string | null;
  benchmarkPrice: number;
  deviationPercent: number;
  isAnomalous: boolean;
  benchmarkSource: string;
}

// Industry reference baseline prices for common MSME materials in India (in INR)
const COMMODITY_BENCHMARKS: Record<string, { price: number; unit: string; name: string }> = {
  'mild steel': { price: 62, unit: 'kg', name: 'IS 2062 Mild Steel' },
  'is 2062': { price: 62, unit: 'kg', name: 'IS 2062 Grade B Steel' },
  'crca': { price: 68, unit: 'kg', name: 'CRCA Sheet IS 513' },
  'stainless steel': { price: 240, unit: 'kg', name: 'SS 304 / A2' },
  'bolt': { price: 14, unit: 'pieces', name: 'M8 Hex Bolt Fastener' },
  'hex bolt': { price: 14, unit: 'pieces', name: 'M8 Hex Bolt A2' },
  'fastener': { price: 12, unit: 'pieces', name: 'Industrial Fastener' },
  'o-ring': { price: 8, unit: 'pieces', name: 'Nitrile Rubber O-Ring' },
  'gasket': { price: 25, unit: 'pieces', name: 'EPDM/Nitrile Gasket' },
  'copper cable': { price: 420, unit: 'metres', name: 'Copper Cable IS 694' },
  'cable': { price: 380, unit: 'metres', name: 'Flexible Multi-core Cable' },
  'die cast': { price: 185, unit: 'pieces', name: 'Aluminium Die Cast ADC12' },
  'housing': { price: 190, unit: 'pieces', name: 'Die Cast Housing' },
};

/**
 * Calculates historical or benchmark price for an item/grade and flags bids > 20% off.
 */
export async function evaluatePriceSanity(
  pricePerUnit: number,
  itemDescription?: string,
  grade?: string,
  excludeBidId?: string
): Promise<PriceSanityResult> {
  const queryDesc = `${itemDescription ?? ''} ${grade ?? ''}`.trim().toLowerCase();

  // 1. Check historical bids from database for same or similar item
  let historicalBids: { pricePerUnit: number }[] = [];
  try {
    const rfqs = await db.rfq.findMany({
      select: {
        id: true,
        spec: true,
        bids: {
          select: { id: true, pricePerUnit: true },
          where: excludeBidId ? { NOT: { id: excludeBidId } } : undefined,
        },
      },
    });

    for (const rfq of rfqs) {
      const spec = rfq.spec as Record<string, unknown> | null;
      if (!spec) continue;
      const specItem = String(spec.item ?? '').toLowerCase();
      const specGrade = String(spec.grade ?? '').toLowerCase();

      // If item keywords overlap
      if (
        (queryDesc && (specItem.includes(queryDesc) || queryDesc.includes(specItem))) ||
        (grade && specGrade.includes(grade.toLowerCase()))
      ) {
        historicalBids.push(...rfq.bids);
      }
    }
  } catch (err) {
    console.warn('Failed to query historical bids for should-cost analysis:', err);
  }

  let benchmarkPrice = 0;
  let benchmarkSource = 'Market average';

  if (historicalBids.length >= 2) {
    const sum = historicalBids.reduce((acc, b) => acc + b.pricePerUnit, 0);
    benchmarkPrice = Math.round((sum / historicalBids.length) * 100) / 100;
    benchmarkSource = `Historical bids (${historicalBids.length} past quotes)`;
  } else {
    // Look up fallback standard commodity index
    for (const [key, val] of Object.entries(COMMODITY_BENCHMARKS)) {
      if (queryDesc.includes(key)) {
        benchmarkPrice = val.price;
        benchmarkSource = `Index benchmark (${val.name})`;
        break;
      }
    }

    // Default to the bid itself if nothing is known
    if (benchmarkPrice === 0) {
      benchmarkPrice = pricePerUnit;
      benchmarkSource = 'Single quote baseline';
    }
  }

  if (benchmarkPrice <= 0) {
    return {
      flag: null,
      benchmarkPrice: pricePerUnit,
      deviationPercent: 0,
      isAnomalous: false,
      benchmarkSource,
    };
  }

  const deviationPercent = Math.round(((pricePerUnit - benchmarkPrice) / benchmarkPrice) * 100);
  const targetLabel = itemDescription ? `${itemDescription}${grade ? ` ${grade}` : ''}` : 'market';

  let flag: string | null = null;
  let isAnomalous = false;

  if (deviationPercent <= -20) {
    isAnomalous = true;
    flag = `⚠️ This bid is ${Math.abs(deviationPercent)}% below market average for ${targetLabel} — verify authenticity & raw material grade`;
  } else if (deviationPercent >= 20) {
    isAnomalous = true;
    flag = `⚠️ This bid is ${deviationPercent}% above market average for ${targetLabel}`;
  }

  return {
    flag,
    benchmarkPrice,
    deviationPercent,
    isAnomalous,
    benchmarkSource,
  };
}
