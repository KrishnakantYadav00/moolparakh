import { useMemo, useState } from 'react';
import { ArrowDown, ArrowUp, Minus } from 'lucide-react';
import type { Vendor } from '@/types';
import { Card, RiskBadge } from '@/components/ui/Primitives';
import { TrustMeter } from '@/components/ui/TrustVisuals';
import type { DisruptionEvent } from '@/types';

const disruptionEvents: DisruptionEvent[] = [];

type SortKey = 'trust' | 'risk' | 'disruptions' | 'trend';

const RISK_ORDER = { CRITICAL: 0, HIGH: 1, MEDIUM: 2, LOW: 3 } as const;

function trendDelta(vendor: Vendor): number {
  const history = vendor.trustHistory;
  if (history.length < 8) return 0;
  const latest = history[history.length - 1].score;
  const weekAgo = history[history.length - 8].score;
  return Math.round((latest - weekAgo) * 10) / 10;
}

export function RiskLeaderboard({
  vendors,
  onSelectVendor,
}: {
  vendors: Vendor[];
  onSelectVendor: (vendorId: string) => void;
}) {
  const [sortKey, setSortKey] = useState<SortKey>('risk');

  const rows = useMemo(() => {
    const enriched = vendors.map((vendor) => ({
      vendor,
      disruptions: disruptionEvents.filter((event) =>
        event.affectedVendorIds.includes(vendor.id),
      ).length,
      delta: trendDelta(vendor),
    }));

    return enriched.sort((a, b) => {
      switch (sortKey) {
        case 'trust':
          return a.vendor.trustScore - b.vendor.trustScore;
        case 'disruptions':
          return b.disruptions - a.disruptions;
        case 'trend':
          return a.delta - b.delta;
        case 'risk':
        default:
          return (
            RISK_ORDER[a.vendor.risk] - RISK_ORDER[b.vendor.risk] ||
            a.vendor.trustScore - b.vendor.trustScore
          );
      }
    });
  }, [vendors, sortKey]);

  const header = (label: string, key?: SortKey, align: 'left' | 'right' = 'left') => (
    <th className={`table-header-cell ${align === 'right' ? 'text-right' : ''}`}>
      {key ? (
        <button
          type="button"
          onClick={() => setSortKey(key)}
          aria-pressed={sortKey === key}
          className={`uppercase tracking-wide transition-colors duration-150
            ${sortKey === key ? 'text-teal' : 'hover:text-navy'}`}
        >
          {label}
        </button>
      ) : (
        label
      )}
    </th>
  );

  return (
    <Card
      title="Risk Leaderboard"
      subtitle="Suppliers ranked by current risk exposure. Sort by any column."
      bodyClassName="p-0"
    >
      <div className="overflow-x-auto">
        <table className="w-full min-w-[720px] text-base">
          <thead className="border-b border-hairline bg-canvas/50 text-left">
            <tr>
              {header('Rank')}
              {header('Vendor')}
              {header('Trust Score', 'trust')}
              {header('Risk', 'risk')}
              {header('Recent Disruptions', 'disruptions', 'right')}
              {header('Trend', 'trend', 'right')}
            </tr>
          </thead>
          <tbody className="divide-y divide-hairline">
            {rows.slice(0, 10).map((row, index) => (
              <tr
                key={row.vendor.id}
                className="cursor-pointer transition-colors duration-150 hover:bg-canvas/70"
                onClick={() => onSelectVendor(row.vendor.id)}
              >
                <td className="table-cell text-muted tnum">{index + 1}</td>
                <td className="table-cell">
                  <p className="font-medium text-navy">{row.vendor.name}</p>
                  <p className="text-xs text-muted">
                    {row.vendor.city}, {row.vendor.state}
                  </p>
                </td>
                <td className="table-cell">
                  <div className="flex items-center gap-2.5">
                    <span className="w-6 font-semibold text-navy tnum">
                      {row.vendor.trustScore}
                    </span>
                    <TrustMeter components={row.vendor.trust} width={60} />
                  </div>
                </td>
                <td className="table-cell">
                  <RiskBadge level={row.vendor.risk} />
                </td>
                <td className="table-cell text-right tnum text-muted">{row.disruptions}</td>
                <td className="table-cell text-right">
                  <span
                    className={`inline-flex items-center gap-1 text-sm font-semibold tnum
                      ${
                        row.delta > 0
                          ? 'text-risk-good'
                          : row.delta < 0
                            ? 'text-risk-critical'
                            : 'text-muted'
                      }`}
                  >
                    {row.delta > 0 ? (
                      <ArrowUp size={13} />
                    ) : row.delta < 0 ? (
                      <ArrowDown size={13} />
                    ) : (
                      <Minus size={13} />
                    )}
                    {Math.abs(row.delta).toFixed(1)}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  );
}
