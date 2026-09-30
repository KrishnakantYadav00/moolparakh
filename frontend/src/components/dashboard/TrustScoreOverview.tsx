import { useMemo, useState } from 'react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import type { TrustBand, Vendor } from '@/types';
import { Card, SegmentedControl } from '@/components/ui/Primitives';
import { ChartTooltip, axisStyle, gridStyle } from '@/components/ui/ChartBits';
import { bandDistribution, trustBandColor } from '@/utils/trustScore';
import { formatShortDate } from '@/utils/format';

const VIEWS = ['Distribution', '30-day trend'] as const;
type View = (typeof VIEWS)[number];

export function TrustScoreOverview({ vendors }: { vendors: Vendor[] }) {
  const [view, setView] = useState<View>('Distribution');

  const distribution = useMemo(
    () =>
      bandDistribution(vendors).map((entry) => ({
        band: entry.band,
        vendors: entry.count,
        fill: trustBandColor(entry.band as TrustBand),
      })),
    [vendors],
  );

  const trend = useMemo(() => {
    const length = vendors[0]?.trustHistory.length ?? 0;
    return Array.from({ length }, (_, index) => {
      const total = vendors.reduce((sum, vendor) => sum + vendor.trustHistory[index].score, 0);
      return {
        date: formatShortDate(vendors[0].trustHistory[index].date),
        average: Math.round((total / vendors.length) * 10) / 10,
      };
    });
  }, [vendors]);

  return (
    <Card
      title="Trust Score Overview"
      subtitle="Where your supplier network sits on the 0–100 Vendor Trust Score."
      action={
        <SegmentedControl
          label="Trust score view"
          options={VIEWS}
          value={view}
          onChange={setView}
        />
      }
    >
      <div className="h-[228px]">
        <ResponsiveContainer width="100%" height="100%">
          {view === 'Distribution' ? (
            <BarChart data={distribution} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
              <CartesianGrid {...gridStyle} vertical={false} />
              <XAxis dataKey="band" tick={axisStyle} tickLine={false} axisLine={false} />
              <YAxis tick={axisStyle} tickLine={false} axisLine={false} allowDecimals={false} />
              <Tooltip
                cursor={{ fill: '#F1F5F7' }}
                content={<ChartTooltip valueFormatter={(value) => `${value} vendors`} />}
              />
              <Bar dataKey="vendors" name="Vendors" radius={[3, 3, 0, 0]} maxBarSize={54}>
                {distribution.map((entry) => (
                  <Cell key={entry.band} fill={entry.fill} />
                ))}
              </Bar>
            </BarChart>
          ) : (
            <LineChart data={trend} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
              <CartesianGrid {...gridStyle} vertical={false} />
              <XAxis
                dataKey="date"
                tick={axisStyle}
                tickLine={false}
                axisLine={false}
                interval={5}
              />
              <YAxis
                tick={axisStyle}
                tickLine={false}
                axisLine={false}
                domain={['dataMin - 3', 'dataMax + 3']}
              />
              <Tooltip content={<ChartTooltip />} />
              <Line
                type="monotone"
                dataKey="average"
                name="Network average"
                stroke="#0F8B8D"
                strokeWidth={2}
                dot={false}
                activeDot={{ r: 4, strokeWidth: 0 }}
              />
            </LineChart>
          )}
        </ResponsiveContainer>
      </div>

      <ul className="mt-3 flex flex-wrap items-center gap-x-5 gap-y-1.5 border-t border-hairline pt-3">
        {distribution.map((entry) => (
          <li key={entry.band} className="flex items-center gap-1.5 text-xs text-muted">
            <span className="h-2 w-2 rounded-sm" style={{ background: entry.fill }} />
            {entry.band}
            <span className="font-semibold text-navy tnum">{entry.vendors}</span>
          </li>
        ))}
      </ul>
    </Card>
  );
}
