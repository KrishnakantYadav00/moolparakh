import { useState } from 'react';
import {
  ArrowLeft,
  CircleAlert,
  CircleCheck,
  CircleDashed,
  Link2,
} from 'lucide-react';
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import type { Vendor, VerificationState, DisruptionEvent, SupplierRelationship } from '@/types';
import {
  Badge,
  Button,
  Card,
  ExpiryBadge,
  RiskBadge,
  SegmentedControl,
} from '@/components/ui/Primitives';
import { ChartTooltip, axisStyle, gridStyle } from '@/components/ui/ChartBits';
import { TrustScorePanel } from '@/components/vendors/TrustScorePanel';
import { ChartCardTitle } from '@/components/ui/ChartCardTitle';
import { complianceTone, vendorComplianceState } from '@/utils/compliance';
import { expiryBucket, formatDate, formatShortDate, relativeDays } from '@/utils/format';
import { trustBand, trustBandColor } from '@/utils/trustScore';

const disruptionEvents: DisruptionEvent[] = [];
const relationshipsForVendor = (_id: string): SupplierRelationship[] => [];

const TABS = ['Overview', 'Verification', 'Compliance', 'Risk History', 'Activity'] as const;
type Tab = (typeof TABS)[number];

const verificationIcon = (state: VerificationState) => {
  if (state === 'Verified') return <CircleCheck size={16} className="text-teal" />;
  if (state === 'Pending') return <CircleDashed size={16} className="text-risk-medium" />;
  return <CircleAlert size={16} className="text-risk-critical" />;
};

const verificationTone = (state: VerificationState) =>
  state === 'Verified' ? 'good' : state === 'Pending' ? 'medium' : 'critical';

interface VendorDetailProps {
  vendor: Vendor;
  onBack: () => void;
  onViewRelationship: (vendorId: string) => void;
}

export function VendorDetail({ vendor, onBack, onViewRelationship }: VendorDetailProps) {
  const [tab, setTab] = useState<Tab>('Overview');
  const compliance = vendorComplianceState(vendor);
  const band = trustBand(vendor.trustScore);
  const relationships = relationshipsForVendor(vendor.id);
  const events = disruptionEvents.filter((event) =>
    event.affectedVendorIds.includes(vendor.id),
  );

  const history = vendor.trustHistory.map((point) => ({
    date: formatShortDate(point.date),
    score: point.score,
  }));

  return (
    <div className="space-y-5">
      <Button variant="ghost" size="sm" icon={<ArrowLeft size={15} />} onClick={onBack}>
        All vendors
      </Button>

      <div className="surface-card p-5">
        <div className="flex flex-wrap items-start justify-between gap-5">
          <div>
            <h2 className="text-2xl font-semibold tracking-tight text-navy">{vendor.name}</h2>
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <Badge tone={vendor.status === 'Verified' ? 'good' : 'high'}>
                {vendor.status === 'Verified' ? 'Verified Vendor' : vendor.status}
              </Badge>
              <Badge tone={complianceTone(compliance)}>{compliance}</Badge>
              <RiskBadge level={vendor.risk} />
            </div>
            <p className="mt-2.5 font-mono text-sm text-muted">GSTIN: {vendor.gstin || 'N/A'}</p>
            <p className="text-sm text-muted">
              {vendor.msmeCategory} enterprise · {vendor.city}, {vendor.state} · onboarded{' '}
              {formatDate(vendor.onboardedOn)}
            </p>
          </div>

          <div className="text-right">
            <p className="text-xs font-medium text-muted">Trust Score</p>
            <p className="text-5xl font-semibold tracking-tight text-navy tnum leading-none">
              {vendor.trustScore}
            </p>
            <p className="mt-1 text-sm font-semibold" style={{ color: trustBandColor(band) }}>
              {band}
            </p>
          </div>
        </div>

        {relationships.length > 0 && (
          <div className="mt-4 flex flex-wrap items-center gap-2 rounded-md border border-risk-medium/30 bg-risk-medium-bg px-3 py-2">
            <Link2 size={15} className="text-risk-medium" />
            <p className="text-sm text-navy">
              Potential relationship with{' '}
              <span className="font-semibold">
                {relationships
                  .map((rel) =>
                    rel.vendorAId === vendor.id ? rel.vendorBId : rel.vendorAId,
                  )
                  .join(', ')}
              </span>{' '}
              — {relationships[0].type.toLowerCase()}.
            </p>
            <Button
              size="sm"
              variant="ghost"
              onClick={() => onViewRelationship(vendor.id)}
              className="ml-auto"
            >
              View relationship
            </Button>
          </div>
        )}
      </div>

      <div className="overflow-x-auto pb-1">
        <SegmentedControl label="Vendor sections" options={TABS} value={tab} onChange={setTab} />
      </div>

      {tab === 'Overview' && (
        <div className="space-y-4">
          <Card title="Vendor Trust Score" subtitle="Four weighted components, 0–100.">
            <TrustScorePanel components={vendor.trust} note={vendor.buyerFlagNote} />
          </Card>

          <div className="grid gap-4 lg:grid-cols-2">
            <Card title="Vendor information">
              <dl className="grid gap-x-6 gap-y-3 sm:grid-cols-2">
                {[
                  ['GSTIN', vendor.gstin || 'N/A'],
                  ['PAN', vendor.pan || 'N/A'],
                  ['CIN', vendor.cin || 'N/A'],
                  ['Udyam', vendor.udyamNumber || 'N/A'],
                  ['MSME category', vendor.msmeCategory],
                  ['Location', `${vendor.city}, ${vendor.state}`],
                  ['Primary contact', `${vendor.contactName} · ${vendor.contactRole}`],
                  ['Supply categories', vendor.categories.join(', ') || 'N/A'],
                  ['Last verified', relativeDays(vendor.lastVerifiedDays)],
                  [
                    'Delivery performance',
                    vendor.delivery
                      ? `${vendor.delivery.onTimePercent}% on time · ${vendor.delivery.ordersLast12Months} orders`
                      : 'No delivery history',
                  ],
                ].map(([label, value]) => (
                  <div key={label}>
                    <dt className="text-xs text-muted">{label}</dt>
                    <dd className="text-base text-navy">{value}</dd>
                  </div>
                ))}
              </dl>
            </Card>

            <Card title="Recent events" subtitle="Latest activity recorded against this vendor.">
              {vendor.events.length === 0 ? (
                <p className="text-sm text-muted">No recent events recorded for this vendor.</p>
              ) : (
                <ul className="space-y-3">
                  {vendor.events.slice(0, 5).map((event) => (
                    <li key={event.id} className="flex gap-3">
                      <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-teal" />
                      <div>
                        <p className="text-base font-medium text-navy">{event.title}</p>
                        <p className="text-sm text-muted">{event.detail}</p>
                        <p className="text-xs text-muted">{formatDate(event.at)}</p>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </Card>
          </div>
        </div>
      )}

      {tab === 'Verification' && (
        <Card
          title="Verification"
          subtitle="Identity checks returned by the KYB service on the last run."
        >
          <ul className="divide-y divide-hairline">
            {(
              [
                ['GSTIN', vendor.gstin, vendor.verification.gstin],
                ['PAN', vendor.pan, vendor.verification.pan],
                ['Udyam', vendor.udyamNumber, vendor.verification.udyam],
                ['CIN', vendor.cin, vendor.verification.cin],
              ] as [string, string, VerificationState][]
            ).map(([label, value, state]) => (
              <li key={label} className="flex items-center justify-between gap-4 py-3 first:pt-0">
                <div className="flex items-center gap-3">
                  {verificationIcon(state)}
                  <div>
                    <p className="text-base font-medium text-navy">{label}</p>
                    <p className="font-mono text-sm text-muted">{value}</p>
                  </div>
                </div>
                <Badge tone={verificationTone(state)}>{state}</Badge>
              </li>
            ))}
          </ul>
        </Card>
      )}

      {tab === 'Compliance' && (
        <Card
          title="Compliance"
          subtitle="Documents on file and their expiry position."
          bodyClassName="p-0"
        >
          {vendor.certificates.length === 0 ? (
            <div className="p-6 text-center text-muted">
              No compliance certificates on file for this vendor.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[560px] text-base">
                <thead className="border-b border-hairline bg-canvas/50 text-left">
                  <tr>
                    <th className="table-header-cell">Document</th>
                    <th className="table-header-cell">Number</th>
                    <th className="table-header-cell">Issued</th>
                    <th className="table-header-cell">Expiry</th>
                    <th className="table-header-cell text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-hairline">
                  {vendor.certificates.map((certificate) => (
                    <tr key={certificate.id}>
                      <td className="table-cell font-medium text-navy">{certificate.type}</td>
                      <td className="table-cell font-mono text-sm text-muted">
                        {certificate.number}
                      </td>
                      <td className="table-cell text-muted tnum">
                        {formatDate(certificate.issuedOn)}
                      </td>
                      <td className="table-cell text-muted tnum">
                        {formatDate(certificate.expiresOn)}
                      </td>
                      <td className="table-cell text-right">
                        <ExpiryBadge bucket={expiryBucket(certificate.expiresOn)} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      )}

      {tab === 'Risk History' && (
        <div className="space-y-4">
          <Card>
            <ChartCardTitle
              title="Trust score, last 30 days"
              subtitle="Recalculated nightly and on every verification or disruption event."
            />
            <div className="h-[240px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={history} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
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
                  <Line
                    type="monotone"
                    dataKey="score"
                    name="Trust score"
                    stroke="#0F8B8D"
                    strokeWidth={2}
                    dot={false}
                    activeDot={{ r: 4, strokeWidth: 0 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </Card>

          <Card
            title="Matched disruption events"
            subtitle="Events from the supplier intelligence feed linked to this vendor."
          >
            {events.length === 0 ? (
              <p className="text-base text-muted">
                No disruption events currently matched to this vendor.
              </p>
            ) : (
              <ul className="space-y-3">
                {events.map((event) => (
                  <li key={event.id} className="flex items-start gap-3">
                    <RiskBadge level={event.severity} />
                    <div>
                      <p className="text-base font-medium text-navy">{event.title}</p>
                      <p className="text-sm text-muted">{event.summary}</p>
                      <p className="text-xs text-muted">
                        {event.category} · {event.region}
                      </p>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </Card>
        </div>
      )}

      {tab === 'Activity' && (
        <Card title="Activity" subtitle="Full event timeline for this vendor.">
          {vendor.events.length === 0 ? (
            <p className="text-sm text-muted">No activity timeline records found for this vendor.</p>
          ) : (
            <ol className="relative space-y-5 border-l border-hairline pl-5">
              {vendor.events.map((event) => (
                <li key={event.id} className="relative">
                  <span className="absolute -left-[26px] top-1.5 h-2.5 w-2.5 rounded-full border-2 border-surface bg-teal" />
                  <p className="text-base font-medium text-navy">{event.title}</p>
                  <p className="text-sm text-muted">{event.detail}</p>
                  <p className="mt-0.5 text-xs text-muted">{formatDate(event.at)}</p>
                </li>
              ))}
            </ol>
          )}
        </Card>
      )}
    </div>
  );
}
