import { useEffect, useState } from 'react';
import { ArrowLeft, ShieldCheck, Shuffle, MapPin, ExternalLink, AlertTriangle } from 'lucide-react';
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import type { Vendor, DisruptionEvent } from '@/types';
import { Badge, Button, Card, RiskBadge } from '@/components/ui/Primitives';
import { ChartTooltip, axisStyle, gridStyle } from '@/components/ui/ChartBits';
import { TrustRing } from '@/components/ui/TrustVisuals';
import { ChartCardTitle } from '@/components/ui/ChartCardTitle';
import { formatShortDate, relativeMinutes } from '@/utils/format';
import { trustBand, trustBandColor } from '@/utils/trustScore';
import { api, type ApiAlternateSupplier } from '@/lib/api';
import { mapDisruptionEvent } from '@/lib/mappers';

export function SupplierDrilldown({
  vendor,
  onBack,
  onOpenProfile,
  onSelectAlternate,
}: {
  vendor: Vendor;
  onBack: () => void;
  onOpenProfile: () => void;
  onSelectAlternate?: (alternateId: string) => void;
}) {
  const [events, setEvents] = useState<DisruptionEvent[]>([]);
  const [alternates, setAlternates] = useState<ApiAlternateSupplier[]>([]);
  const [loadingAlternates, setLoadingAlternates] = useState(true);

  useEffect(() => {
    // 1. Fetch live disruption events for this vendor
    api.intelligence.eventsForVendor(vendor.id)
      .then((data) => setEvents(data.map(mapDisruptionEvent)))
      .catch((err) => console.error('Failed to load vendor events:', err));

    // 2. Fetch pre-qualified alternate suppliers in other regions
    api.vendors.alternates(vendor.id)
      .then((data) => setAlternates(data.alternates || []))
      .catch((err) => console.error('Failed to load alternate suppliers:', err))
      .finally(() => setLoadingAlternates(false));
  }, [vendor.id]);

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
        {/* Left Column: Trust & KPIs */}
        <div className="space-y-4">
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

        {/* Right Column: Timeline & Alternate Sourcing */}
        <div className="space-y-4">
          {/* Alternate Sourcing Suggestions (Requirement 2.2) */}
          <Card
            title="Alternate Sourcing Suggestions"
            subtitle={
              events.length > 0
                ? `Active disruption risk on ${vendor.name}. Pre-qualified backup suppliers found in unaffected regions:`
                : 'Pre-qualified backup suppliers with matching capabilities in other geographical regions:'
            }
          >
            {loadingAlternates ? (
              <p className="text-sm text-muted">Finding pre-qualified alternates...</p>
            ) : alternates.length === 0 ? (
              <div className="rounded-md border border-hairline p-4 text-center text-sm text-muted">
                No matching alternate suppliers in other regions found for categories:{' '}
                {vendor.categories.join(', ')}
              </div>
            ) : (
              <div className="space-y-3">
                <div className="rounded-md bg-teal-soft/60 border border-teal/20 px-3 py-2 text-xs text-navy font-medium flex items-center gap-2">
                  <Shuffle size={14} className="text-teal shrink-0" />
                  <span>
                    {alternates.length} pre-qualified alternates found in different regions —{' '}
                    {alternates
                      .slice(0, 3)
                      .map((a) => `${a.legalName} (Trust: ${a.trustScore})`)
                      .join(', ')}
                  </span>
                </div>

                <ul className="divide-y divide-hairline">
                  {alternates.map((alt) => {
                    const band = trustBand(alt.trustScore);
                    return (
                      <li
                        key={alt.id}
                        className="flex flex-wrap items-center justify-between gap-3 py-3 first:pt-1 last:pb-1"
                      >
                        <div className="space-y-1">
                          <div className="flex items-center gap-2">
                            <p className="text-base font-semibold text-navy">{alt.legalName}</p>
                            <span className="flex items-center gap-1 text-2xs text-muted">
                              <MapPin size={11} /> {alt.city}, {alt.state}
                            </span>
                            <RiskBadge level={alt.riskLevel} />
                          </div>
                          <p className="text-xs text-muted max-w-xl">{alt.recommendationReason}</p>
                          <div className="flex flex-wrap items-center gap-1.5 pt-0.5">
                            <span className="text-2xs text-muted">Categories:</span>
                            {alt.sharedCategories.map((c) => (
                              <span
                                key={c}
                                className="rounded bg-canvas px-1.5 py-0.5 text-2xs font-medium text-navy border border-hairline"
                              >
                                {c}
                              </span>
                            ))}
                          </div>
                        </div>

                        <div className="flex items-center gap-3">
                          <div className="text-right">
                            <p className="text-xs text-muted">Trust Score</p>
                            <p
                              className="text-lg font-bold leading-tight"
                              style={{ color: trustBandColor(band) }}
                            >
                              {alt.trustScore}
                            </p>
                          </div>
                          {onSelectAlternate && (
                            <Button
                              size="sm"
                              variant="secondary"
                              onClick={() => onSelectAlternate(alt.id)}
                              icon={<ExternalLink size={13} />}
                            >
                              View
                            </Button>
                          )}
                        </div>
                      </li>
                    );
                  })}
                </ul>
              </div>
            )}
          </Card>

          {/* Historical Trust Movement */}
          <Card>
            <ChartCardTitle
              title="Trust score history"
              subtitle="Score movement over the last 30 days."
            />
            <div className="h-[200px]">
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

          {/* Disruption Events Timeline */}
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
        </div>
      </div>
    </div>
  );
}
