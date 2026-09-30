import { ArrowLeft } from 'lucide-react';
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import type { Vendor } from '@/types';
import { Badge, Button, Card, RiskBadge } from '@/components/ui/Primitives';
import { ChartTooltip, axisStyle, gridStyle } from '@/components/ui/ChartBits';
import { TrustRing } from '@/components/ui/TrustVisuals';
import { ChartCardTitle } from '@/components/ui/ChartCardTitle';
import { formatShortDate, relativeMinutes } from '@/utils/format';
import type { DisruptionEvent } from '@/types';

const disruptionEvents: DisruptionEvent[] = [];

export function SupplierDrilldown({
  vendor,
  onBack,
  onOpenProfile,
}: {
  vendor: Vendor;
  onBack: () => void;
  onOpenProfile: () => void;
}) {
  const events = disruptionEvents
    .filter((event) => event.affectedVendorIds.includes(vendor.id))
    .sort((a, b) => a.detectedMinutesAgo - b.detectedMinutesAgo);

  const history = vendor.trustHistory.map((point) => ({
    date: formatShortDate(point.date),
    score: point.score,
  }));

  const delta =
    vendor.trustHistory.length >= 8
      ? Math.round(
          (vendor.trustHistory[vendor.trustHistory.length - 1].score -
            vendor.trustHistory[vendor.trustHistory.length - 8].score) *
            10,
        ) / 10
      : 0;

  return (
    <div className="space-y-5">
      <Button variant="ghost" size="sm" icon={<ArrowLeft size={15} />} onClick={onBack}>
        Supplier Intelligence
      </Button>

      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-navy">Supplier Risk Detail</h2>
          <p className="mt-0.5 text-base text-muted">
            {vendor.name} · {vendor.city}, {vendor.state}
          </p>
        </div>
        <Button variant="secondary" onClick={onOpenProfile}>
          Open vendor profile
        </Button>
      </div>

      <div className="grid gap-4 lg:grid-cols-[300px,1fr] lg:items-start">
        <Card title="Current trust score">
          <div className="flex flex-col items-center">
            <TrustRing components={vendor.trust} size={156} stroke={13} />
            <div className="mt-3 flex items-center gap-2">
              <RiskBadge level={vendor.risk} />
              <Badge tone={delta < 0 ? 'critical' : delta > 0 ? 'good' : 'neutral'}>
                {delta > 0 ? '+' : ''}
                {delta.toFixed(1)} in 7 days
              </Badge>
            </div>
            <div className="mt-4 w-full space-y-1.5 border-t border-hairline pt-3 text-sm">
              <div className="flex justify-between">
                <span className="text-muted">On-time delivery</span>
                <span className="font-semibold text-navy tnum">
                  {vendor.delivery.onTimePercent}%
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted">Orders, 12 months</span>
                <span className="font-semibold text-navy tnum">
                  {vendor.delivery.ordersLast12Months}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted">Matched events</span>
                <span className="font-semibold text-navy tnum">{events.length}</span>
              </div>
            </div>
          </div>
        </Card>

        <div className="space-y-4">
          <Card>
            <ChartCardTitle
              title="Trust score history"
              subtitle="Score movement over the last 30 days."
            />
            <div className="h-[220px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={history} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
                  <defs>
                    <linearGradient id="trustFill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#0F8B8D" stopOpacity={0.22} />
                      <stop offset="100%" stopColor="#0F8B8D" stopOpacity={0.02} />
                    </linearGradient>
                  </defs>
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
                    domain={['dataMin - 5', 'dataMax + 5']}
                  />
                  <Tooltip content={<ChartTooltip />} />
                  <Area
                    type="monotone"
                    dataKey="score"
                    name="Trust score"
                    stroke="#0F8B8D"
                    strokeWidth={2}
                    fill="url(#trustFill)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </Card>

          <Card
            title="Event timeline"
            subtitle="Disruption events matched to this supplier, most recent first."
          >
            {events.length === 0 ? (
              <p className="text-base text-muted">
                No disruption events matched to this supplier in the current window.
              </p>
            ) : (
              <ol className="relative space-y-4 border-l border-hairline pl-5">
                {events.map((event) => (
                  <li key={event.id} className="relative">
                    <span className="absolute -left-[26px] top-1.5 h-2.5 w-2.5 rounded-full border-2 border-surface bg-teal" />
                    <div className="flex flex-wrap items-center gap-2">
                      <RiskBadge level={event.severity} />
                      <p className="text-base font-medium text-navy">{event.title}</p>
                    </div>
                    <p className="text-sm text-muted">{event.summary}</p>
                    <p className="mt-0.5 text-xs text-muted">
                      {event.category} · {event.region} ·{' '}
                      {relativeMinutes(event.detectedMinutesAgo)}
                    </p>
                  </li>
                ))}
              </ol>
            )}
          </Card>

          <Card
            title="Affected categories"
            subtitle="Supply categories exposed if this supplier is disrupted."
          >
            <div className="flex flex-wrap gap-2">
              {vendor.categories.map((category) => (
                <Badge key={category} tone="navy">
                  {category}
                </Badge>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
