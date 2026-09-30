import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import type { BidWeights, ScoredBid } from '@/types';
import { SlideOver } from '@/components/ui/Overlays';
import { ChartTooltip, axisStyle } from '@/components/ui/ChartBits';
import { explainBid } from '@/utils/bidEvaluation';
import { formatRupees } from '@/utils/format';

const CRITERION_COLORS = {
  Price: '#0F8B8D',
  Delivery: '#17324D',
  Trust: '#7CC3C3',
};

export function ExplainabilityPanel({
  bid,
  bids,
  weights,
  onClose,
}: {
  bid: ScoredBid | null;
  bids: ScoredBid[];
  weights: BidWeights;
  onClose: () => void;
}) {
  if (!bid) return null;

  const data = [
    {
      name: bid.vendorName,
      Price: Number(bid.contributions.price.toFixed(3)),
      Delivery: Number(bid.contributions.delivery.toFixed(3)),
      Trust: Number(bid.contributions.trust.toFixed(3)),
    },
  ];

  const rows = [
    {
      label: 'Price',
      raw: `${formatRupees(bid.pricePerUnit)}/unit`,
      score: bid.priceScore,
      weight: weights.price,
      contribution: bid.contributions.price,
    },
    {
      label: 'Delivery',
      raw: `${bid.deliveryDays} days`,
      score: bid.deliveryScore,
      weight: weights.delivery,
      contribution: bid.contributions.delivery,
    },
    {
      label: 'Trust',
      raw: `${bid.trustScore} / 100`,
      score: bid.trustNormalised,
      weight: weights.trust,
      contribution: bid.contributions.trust,
    },
  ];

  return (
    <SlideOver
      open
      onClose={onClose}
      title="Bid Recommendation Explained"
      description={`${bid.vendorName} · rank #${bid.rank}`}
    >
      <div className="h-[130px]">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} layout="vertical" margin={{ top: 4, right: 8, left: 0, bottom: 0 }}>
            <XAxis
              type="number"
              domain={[0, 1]}
              tick={axisStyle}
              tickLine={false}
              axisLine={false}
            />
            <YAxis type="category" dataKey="name" hide />
            <Tooltip
              cursor={{ fill: '#F1F5F7' }}
              content={<ChartTooltip valueFormatter={(value) => Number(value).toFixed(3)} />}
            />
            <Bar dataKey="Price" stackId="a" fill={CRITERION_COLORS.Price} barSize={40} />
            <Bar dataKey="Delivery" stackId="a" fill={CRITERION_COLORS.Delivery} barSize={40} />
            <Bar
              dataKey="Trust"
              stackId="a"
              fill={CRITERION_COLORS.Trust}
              barSize={40}
              radius={[0, 3, 3, 0]}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>

      <ul className="flex flex-wrap gap-x-4 gap-y-1.5">
        {Object.entries(CRITERION_COLORS).map(([label, color]) => (
          <li key={label} className="flex items-center gap-1.5 text-xs text-muted">
            <span className="h-2 w-2 rounded-sm" style={{ background: color }} />
            {label}
          </li>
        ))}
      </ul>

      <table className="mt-4 w-full text-sm">
        <thead>
          <tr className="border-b border-hairline text-left">
            <th className="pb-1.5 text-2xs font-semibold uppercase tracking-wide text-muted">
              Criterion
            </th>
            <th className="pb-1.5 text-2xs font-semibold uppercase tracking-wide text-muted">
              Bid
            </th>
            <th className="pb-1.5 text-right text-2xs font-semibold uppercase tracking-wide text-muted">
              Score
            </th>
            <th className="pb-1.5 text-right text-2xs font-semibold uppercase tracking-wide text-muted">
              Weight
            </th>
            <th className="pb-1.5 text-right text-2xs font-semibold uppercase tracking-wide text-muted">
              Contribution
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-hairline">
          {rows.map((row) => (
            <tr key={row.label}>
              <td className="py-2 font-medium text-navy">{row.label}</td>
              <td className="py-2 text-muted tnum">{row.raw}</td>
              <td className="py-2 text-right text-navy tnum">{row.score.toFixed(2)}</td>
              <td className="py-2 text-right text-muted tnum">{row.weight}%</td>
              <td className="py-2 text-right font-semibold text-navy tnum">
                {row.contribution.toFixed(3)}
              </td>
            </tr>
          ))}
          <tr>
            <td className="py-2 font-semibold text-navy" colSpan={4}>
              Composite score
            </td>
            <td className="py-2 text-right font-semibold text-teal tnum">
              {bid.composite.toFixed(3)}
            </td>
          </tr>
        </tbody>
      </table>

      <div className="mt-4 rounded-md border border-hairline bg-canvas/70 p-3.5">
        <h3 className="text-base font-semibold text-navy">
          Why this bid ranks {bid.rank === 1 ? 'first' : `#${bid.rank}`}
        </h3>
        <p className="mt-1.5 text-base leading-relaxed text-navy/85">{explainBid(bid, bids)}</p>
        <p className="mt-2.5 text-xs text-muted">
          This explanation is generated from the scores above, not from an external model.
        </p>
      </div>
    </SlideOver>
  );
}
