import { useState } from 'react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import type { Vendor } from '@/types';
import { Card } from '@/components/ui/Primitives';
import { ChartTooltip, axisStyle, gridStyle } from '@/components/ui/ChartBits';
import { formatShortDate } from '@/utils/format';

const BUCKETS = ['0–2 days', '3–5 days', '6–10 days', '10+ days'] as const;

export function LateDeliveryHistogram({ vendors }: { vendors: Vendor[] }) {
  const data = BUCKETS.map((bucket) => ({
    bucket,
    deliveries: vendors.reduce((sum, vendor) => sum + vendor.delivery.lateBuckets[bucket], 0),
  }));

  return (
    <Card
      title="Late Delivery Distribution"
      subtitle="How far behind schedule late deliveries have run across the network."
    >
      <div className="h-[220px]">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
            <CartesianGrid {...gridStyle} vertical={false} />
            <XAxis dataKey="bucket" tick={axisStyle} tickLine={false} axisLine={false} />
            <YAxis tick={axisStyle} tickLine={false} axisLine={false} allowDecimals={false} />
            <Tooltip
              cursor={{ fill: '#F1F5F7' }}
              content={<ChartTooltip valueFormatter={(value) => `${value} deliveries`} />}
            />
            <Bar
              dataKey="deliveries"
              name="Late deliveries"
              fill="#17324D"
              radius={[3, 3, 0, 0]}
              maxBarSize={56}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
}

const SERIES_COLORS = ['#0F8B8D', '#17324D', '#B35309', '#7CC3C3'];

export function SupplierTrustTrends({ vendors }: { vendors: Vendor[] }) {
  const [selected, setSelected] = useState<string[]>(
    vendors.slice(0, 3).map((vendor) => vendor.id),
  );

  const toggle = (id: string) => {
    setSelected((current) =>
      current.includes(id)
        ? current.filter((value) => value !== id)
        : current.length >= 4
          ? current
          : [...current, id],
    );
  };

  const chosen = vendors.filter((vendor) => selected.includes(vendor.id));
  const length = vendors[0]?.trustHistory.length ?? 0;

  const data = Array.from({ length }, (_, index) => {
    const row: Record<string, string | number> = {
      date: formatShortDate(vendors[0].trustHistory[index].date),
    };
    chosen.forEach((vendor) => {
      row[vendor.name] = vendor.trustHistory[index].score;
    });
    return row;
  });

  return (
    <Card
      title="Supplier Trust Trends"
      subtitle="30-day trust score movement. Select up to four suppliers."
    >
      <div className="h-[220px]">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
            <CartesianGrid {...gridStyle} vertical={false} />
            <XAxis
              dataKey="date"
              tick={axisStyle}
              tickLine={false}
              axisLine={false}
              interval={5}
            />
            <YAxis tick={axisStyle} tickLine={false} axisLine={false} domain={[30, 100]} />
            <Tooltip content={<ChartTooltip />} />
            {chosen.map((vendor, index) => (
              <Line
                key={vendor.id}
                type="monotone"
                dataKey={vendor.name}
                stroke={SERIES_COLORS[index % SERIES_COLORS.length]}
                strokeWidth={2}
                dot={false}
                activeDot={{ r: 4, strokeWidth: 0 }}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div className="mt-3 flex flex-wrap gap-1.5 border-t border-hairline pt-3">
        {vendors.slice(0, 8).map((vendor) => {
          const index = chosen.findIndex((item) => item.id === vendor.id);
          const active = index >= 0;
          return (
            <button
              key={vendor.id}
              type="button"
              onClick={() => toggle(vendor.id)}
              aria-pressed={active}
              className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs
                transition-colors duration-150
                ${
                  active
                    ? 'border-teal/40 bg-teal-soft text-navy'
                    : 'border-hairline text-muted hover:border-teal/30 hover:text-navy'
                }`}
            >
              <span
                className="h-2 w-2 rounded-full"
                style={{
                  background: active
                    ? SERIES_COLORS[index % SERIES_COLORS.length]
                    : '#C6D1DA',
                }}
              />
              {vendor.name}
            </button>
          );
        })}
      </div>
    </Card>
  );
}
