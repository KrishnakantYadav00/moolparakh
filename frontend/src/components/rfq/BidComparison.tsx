import { useMemo, useState } from 'react';
import { ArrowLeft, CheckCircle2, Inbox, TriangleAlert } from 'lucide-react';
import type { BidWeights, Rfq, ScoredBid, SupplierRelationship } from '@/types';
import { Badge, Button, Card, EmptyState } from '@/components/ui/Primitives';
import { Modal } from '@/components/ui/Overlays';
import { ExplainabilityPanel } from '@/components/rfq/ExplainabilityPanel';
import { RelationshipModal } from '@/components/vendors/RelationshipModal';
import { DEFAULT_WEIGHTS, rebalanceWeights, scoreBids } from '@/utils/bidEvaluation';
import { formatRupees } from '@/utils/format';
import type { SupplierRelationship as SR } from '@/types';

// Relationship data will be wired to /api/relationships in a future step
const supplierRelationships: SR[] = [];


interface BidComparisonProps {
  rfq: Rfq;
  onBack: () => void;
  onAward: (rfqId: string, vendorId: string) => void;
}

export function BidComparison({ rfq, onBack, onAward }: BidComparisonProps) {
  const [weights, setWeights] = useState<BidWeights>(DEFAULT_WEIGHTS);
  const [explainBidId, setExplainBidId] = useState<string | null>(null);
  const [relationship, setRelationship] = useState<SupplierRelationship | null>(null);
  const [awardCandidate, setAwardCandidate] = useState<ScoredBid | null>(null);
  const [awardedId, setAwardedId] = useState<string | null>(rfq.awardedVendorId ?? null);

  const scored = useMemo(() => scoreBids(rfq.bids, weights), [rfq.bids, weights]);

  /** Relationships that link two suppliers bidding on this same RFQ. */
  const bidderRelationships = useMemo(() => {
    const bidderIds = new Set(rfq.bids.map((bid) => bid.vendorId));
    return supplierRelationships.filter(
      (rel) => bidderIds.has(rel.vendorAId) && bidderIds.has(rel.vendorBId),
    );
  }, [rfq.bids]);

  const relationshipFor = (vendorId: string) =>
    bidderRelationships.find(
      (rel) => rel.vendorAId === vendorId || rel.vendorBId === vendorId,
    ) ?? null;

  const setWeight = (key: keyof BidWeights, value: number) =>
    setWeights((current) => rebalanceWeights(current, key, value));

  if (rfq.bids.length === 0) {
    return (
      <div className="space-y-5">
        <Button variant="ghost" size="sm" icon={<ArrowLeft size={15} />} onClick={onBack}>
          RFQs &amp; Bids
        </Button>
        <div className="surface-card">
          <EmptyState
            icon={<Inbox size={18} />}
            title="No bids yet"
            description={`${rfq.suppliersNotified} suppliers were notified. Bids will appear here as they are submitted.`}
          />
        </div>
      </div>
    );
  }

  const sliders: { key: keyof BidWeights; label: string }[] = [
    { key: 'price', label: 'Price' },
    { key: 'delivery', label: 'Delivery' },
    { key: 'trust', label: 'Trust' },
  ];

  return (
    <div className="space-y-5">
      <Button variant="ghost" size="sm" icon={<ArrowLeft size={15} />} onClick={onBack}>
        RFQs &amp; Bids
      </Button>

      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-navy">{rfq.title}</h2>
          <p className="mt-0.5 text-base text-muted">
            Bid Comparison · {rfq.bids.length} bids received · {rfq.reference}
          </p>
        </div>
        {awardedId && (
          <Badge tone="good" className="text-xs">
            <CheckCircle2 size={13} /> Bid Awarded
          </Badge>
        )}
      </div>

      <Card
        title="Evaluation weights"
        subtitle="Composite = (price × weight) + (delivery × weight) + (trust × weight). Ranking recalculates instantly."
      >
        <div className="grid gap-5 sm:grid-cols-3">
          {sliders.map((slider) => (
            <div key={slider.key}>
              <div className="flex items-baseline justify-between">
                <label
                  className="text-base font-medium text-navy"
                  htmlFor={`weight-${slider.key}`}
                >
                  {slider.label}
                </label>
                <span className="text-base font-semibold text-teal tnum">
                  {weights[slider.key]}%
                </span>
              </div>
              <input
                id={`weight-${slider.key}`}
                type="range"
                min={0}
                max={100}
                step={5}
                value={weights[slider.key]}
                onChange={(event) => setWeight(slider.key, Number(event.target.value))}
                className="mt-2 w-full accent-teal"
                aria-valuetext={`${weights[slider.key]} percent`}
              />
            </div>
          ))}
        </div>
        <div className="mt-4 flex flex-wrap items-center justify-between gap-2 border-t border-hairline pt-3">
          <p className="text-sm text-muted">
            Weights always total{' '}
            <span className="font-semibold text-navy tnum">
              {weights.price + weights.delivery + weights.trust}%
            </span>
            .
          </p>
          <Button size="sm" variant="ghost" onClick={() => setWeights(DEFAULT_WEIGHTS)}>
            Reset to 45 / 30 / 25
          </Button>
        </div>
      </Card>

      <Card bodyClassName="p-0">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[980px] text-base">
            <thead className="border-b border-hairline bg-canvas/50 text-left">
              <tr>
                <th className="table-header-cell">Supplier</th>
                <th className="table-header-cell text-right">Price</th>
                <th className="table-header-cell text-right">Delivery</th>
                <th className="table-header-cell text-right">Trust</th>
                <th className="table-header-cell text-right">Price Score</th>
                <th className="table-header-cell text-right">Delivery Score</th>
                <th className="table-header-cell text-right">Trust Score</th>
                <th className="table-header-cell text-right">Composite</th>
                <th className="table-header-cell text-right">Rank</th>
                <th className="table-header-cell text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-hairline">
              {scored.map((bid) => {
                const related = relationshipFor(bid.vendorId);
                const recommended = bid.rank === 1;
                const awarded = awardedId === bid.vendorId;
                return (
                  <tr
                    key={bid.id}
                    className={`transition-colors duration-150 ${
                      recommended ? 'bg-teal-soft/45' : 'hover:bg-canvas/70'
                    }`}
                  >
                    <td className="table-cell">
                      <div className="flex items-center gap-2">
                        <p className="font-medium text-navy">{bid.vendorName}</p>
                        {recommended && <Badge tone="teal">Recommended</Badge>}
                        {awarded && <Badge tone="good">Awarded</Badge>}
                      </div>
                      <p className="text-xs text-muted">{bid.notes}</p>
                      {related && (
                        <button
                          type="button"
                          onClick={() => setRelationship(related)}
                          className="mt-1 inline-flex items-center gap-1 rounded border border-risk-medium/30
                            bg-risk-medium-bg px-1.5 py-0.5 text-2xs font-semibold text-risk-medium
                            transition-colors duration-150 hover:bg-risk-medium/15"
                        >
                          <TriangleAlert size={11} /> Potential Relationship
                        </button>
                      )}
                    </td>
                    <td className="table-cell text-right tnum text-navy">
                      {formatRupees(bid.pricePerUnit)}/unit
                    </td>
                    <td className="table-cell text-right tnum text-navy">{bid.deliveryDays} days</td>
                    <td className="table-cell text-right tnum text-navy">{bid.trustScore}</td>
                    <td className="table-cell text-right tnum text-muted">
                      {bid.priceScore.toFixed(2)}
                    </td>
                    <td className="table-cell text-right tnum text-muted">
                      {bid.deliveryScore.toFixed(2)}
                    </td>
                    <td className="table-cell text-right tnum text-muted">
                      {bid.trustNormalised.toFixed(2)}
                    </td>
                    <td className="table-cell text-right tnum font-semibold text-navy">
                      {bid.composite.toFixed(2)}
                    </td>
                    <td className="table-cell text-right tnum font-semibold text-navy">
                      #{bid.rank}
                    </td>
                    <td className="table-cell text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <Button size="sm" variant="ghost" onClick={() => setExplainBidId(bid.id)}>
                          Why this bid?
                        </Button>
                        <Button
                          size="sm"
                          variant={recommended ? 'primary' : 'secondary'}
                          onClick={() => setAwardCandidate(bid)}
                          disabled={Boolean(awardedId)}
                        >
                          Award Bid
                        </Button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </Card>

      {awardedId && (
        <div className="flex items-start gap-3 rounded-card border border-risk-good/30 bg-risk-good-bg px-4 py-3">
          <CheckCircle2 size={18} className="mt-0.5 shrink-0 text-risk-good" />
          <div>
            <p className="text-base font-semibold text-navy">Bid Awarded</p>
            <p className="text-sm text-muted">
              Delivery confirmation scheduled. The outcome will feed back into supplier performance
              and trust re-scoring.
            </p>
          </div>
        </div>
      )}

      <ExplainabilityPanel
        bid={scored.find((bid) => bid.id === explainBidId) ?? null}
        bids={scored}
        weights={weights}
        onClose={() => setExplainBidId(null)}
      />

      <RelationshipModal relationship={relationship} onClose={() => setRelationship(null)} />

      <Modal
        open={Boolean(awardCandidate)}
        onClose={() => setAwardCandidate(null)}
        title="Award this supplier?"
        description="The supplier is notified and the RFQ closes."
        footer={
          <>
            <Button variant="ghost" onClick={() => setAwardCandidate(null)}>
              Cancel
            </Button>
            <Button
              variant="primary"
              onClick={() => {
                if (!awardCandidate) return;
                setAwardedId(awardCandidate.vendorId);
                onAward(rfq.id, awardCandidate.vendorId);
                setAwardCandidate(null);
              }}
            >
              Award Bid
            </Button>
          </>
        }
      >
        {awardCandidate && (
          <dl className="space-y-3">
            {[
              ['Supplier', awardCandidate.vendorName],
              ['Price', `${formatRupees(awardCandidate.pricePerUnit)}/unit`],
              ['Delivery', `${awardCandidate.deliveryDays} days`],
              ['Trust Score', String(awardCandidate.trustScore)],
            ].map(([label, value]) => (
              <div key={label} className="flex items-center justify-between gap-4">
                <dt className="text-sm text-muted">{label}</dt>
                <dd className="text-base font-medium text-navy">{value}</dd>
              </div>
            ))}
            {relationshipFor(awardCandidate.vendorId) && (
              <p className="rounded-md border border-risk-medium/30 bg-risk-medium-bg px-3 py-2 text-sm text-navy">
                This supplier shares a registration attribute with another bidder on this RFQ.
              </p>
            )}
          </dl>
        )}
      </Modal>
    </div>
  );
}
