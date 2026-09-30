import type { Bid, BidWeights, ScoredBid } from '@/types';

/** PRD default criterion weights. */
export const DEFAULT_WEIGHTS: BidWeights = { price: 45, delivery: 30, trust: 25 };

/**
 * Normalisation: price and delivery are "lower is better", so each bid is
 * scored against the best bid received (best = 1.00). Trust is already a
 * 0–100 scale, so it is divided by 100. Every score lands in (0, 1].
 */
export function scoreBids(bids: Bid[], weights: BidWeights): ScoredBid[] {
  if (bids.length === 0) return [];

  const bestPrice = Math.min(...bids.map((b) => b.pricePerUnit));
  const bestDelivery = Math.min(...bids.map((b) => b.deliveryDays));

  const w = {
    price: weights.price / 100,
    delivery: weights.delivery / 100,
    trust: weights.trust / 100,
  };

  const scored = bids.map((bid) => {
    const priceScore = bestPrice / bid.pricePerUnit;
    const deliveryScore = bestDelivery / bid.deliveryDays;
    const trustNormalised = bid.trustScore / 100;
    const contributions = {
      price: priceScore * w.price,
      delivery: deliveryScore * w.delivery,
      trust: trustNormalised * w.trust,
    };
    return {
      ...bid,
      priceScore,
      deliveryScore,
      trustNormalised,
      contributions,
      composite:
        contributions.price + contributions.delivery + contributions.trust,
      rank: 0,
    };
  });

  return scored
    .sort((a, b) => b.composite - a.composite)
    .map((bid, index) => ({ ...bid, rank: index + 1 }));
}

/**
 * Keeps the three sliders summing to exactly 100 by redistributing the delta
 * across the other two criteria in proportion to their current weight.
 */
export function rebalanceWeights(
  weights: BidWeights,
  changed: keyof BidWeights,
  nextValue: number,
): BidWeights {
  const value = Math.max(0, Math.min(100, Math.round(nextValue)));
  const others = (Object.keys(weights) as (keyof BidWeights)[]).filter(
    (k) => k !== changed,
  );
  const remaining = 100 - value;
  const othersTotal = others.reduce((sum, k) => sum + weights[k], 0);

  const next: BidWeights = { ...weights, [changed]: value };

  if (othersTotal === 0) {
    next[others[0]] = Math.round(remaining / 2);
    next[others[1]] = remaining - next[others[0]];
    return next;
  }

  next[others[0]] = Math.round((weights[others[0]] / othersTotal) * remaining);
  next[others[1]] = remaining - next[others[0]];
  return next;
}

function ordinal(rank: number): string {
  const words = ['first', 'second', 'third', 'fourth', 'fifth'];
  return words[rank - 1] ?? `${rank}th`;
}

/**
 * Natural-language explanation generated deterministically from the numbers.
 * No language model is involved — the sentence is assembled from the bid's
 * rank on each individual criterion.
 */
export function explainBid(bid: ScoredBid, all: ScoredBid[]): string {
  const rankBy = (key: 'pricePerUnit' | 'deliveryDays' | 'trustScore') => {
    const sorted = [...all].sort((a, b) =>
      key === 'trustScore' ? b[key] - a[key] : a[key] - b[key],
    );
    return sorted.findIndex((b) => b.id === bid.id) + 1;
  };

  const priceRank = rankBy('pricePerUnit');
  const deliveryRank = rankBy('deliveryDays');
  const trustRank = rankBy('trustScore');

  const strengths: string[] = [];
  if (trustRank === 1) strengths.push('the highest Vendor Trust Score in this RFQ');
  else if (trustRank <= 2) strengths.push('one of the two strongest trust scores');

  if (deliveryRank === 1) strengths.push('the fastest committed delivery');
  else if (deliveryRank <= 2) strengths.push('near-fastest delivery');

  if (priceRank === 1) strengths.push('the lowest unit price');
  else if (priceRank <= 2) strengths.push('competitive pricing');

  const tradeoffs: string[] = [];
  if (priceRank > 2)
    tradeoffs.push(
      `its unit price is ${priceRank === all.length ? 'the highest' : `${ordinal(priceRank)}-lowest`} of the ${all.length} bids`,
    );
  if (deliveryRank > 2)
    tradeoffs.push(`its delivery window is longer than ${deliveryRank - 1} other bids`);
  if (trustRank > 2) tradeoffs.push(`${trustRank - 1} bidders carry a higher trust score`);

  const lead =
    strengths.length > 0
      ? `This supplier ranks ${ordinal(bid.rank)} because it combines ${listPhrase(strengths)}.`
      : `This supplier ranks ${ordinal(bid.rank)} on the current weighting.`;

  const counter =
    tradeoffs.length > 0
      ? ` The trade-off is that ${listPhrase(tradeoffs)}.`
      : '';

  const dominant = dominantCriterion(bid);
  const closing = ` Under the current weighting, ${dominant} contributes the most to its composite score of ${bid.composite.toFixed(2)}.`;

  return lead + counter + closing;
}

function dominantCriterion(bid: ScoredBid): string {
  const entries: [string, number][] = [
    ['price', bid.contributions.price],
    ['delivery', bid.contributions.delivery],
    ['trust', bid.contributions.trust],
  ];
  entries.sort((a, b) => b[1] - a[1]);
  return entries[0][0];
}

function listPhrase(items: string[]): string {
  if (items.length === 1) return items[0];
  if (items.length === 2) return `${items[0]} and ${items[1]}`;
  return `${items.slice(0, -1).join(', ')} and ${items[items.length - 1]}`;
}
