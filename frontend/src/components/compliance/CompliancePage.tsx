import { useState } from 'react';
import { CalendarCheck } from 'lucide-react';
import type { Vendor } from '@/types';
import {
  Button,
  Card,
  EmptyState,
  ExpiryBadge,
  SegmentedControl,
} from '@/components/ui/Primitives';
import { ComplianceCalendar } from '@/components/compliance/ComplianceCalendar';
import {
  attentionRows,
  certificateRows,
  complianceSummary,
  type CertificateRow,
} from '@/utils/compliance';
import { formatDate } from '@/utils/format';

const VIEWS = ['Calendar', 'Upcoming', 'Expired'] as const;
type View = (typeof VIEWS)[number];

function CertificateTable({
  rows,
  onSelectVendor,
}: {
  rows: CertificateRow[];
  onSelectVendor: (vendorId: string) => void;
}) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[640px] text-base">
        <thead className="border-b border-hairline bg-canvas/50 text-left">
          <tr>
            <th className="table-header-cell">Vendor</th>
            <th className="table-header-cell">Document</th>
            <th className="table-header-cell">Number</th>
            <th className="table-header-cell">Expiry</th>
            <th className="table-header-cell text-right">Days</th>
            <th className="table-header-cell text-right">Status</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-hairline">
          {rows.map((row) => (
            <tr
              key={row.certificate.id}
              className="cursor-pointer transition-colors duration-150 hover:bg-canvas/70"
              onClick={() => onSelectVendor(row.vendor.id)}
            >
              <td className="table-cell font-medium text-navy">{row.vendor.name}</td>
              <td className="table-cell text-muted">{row.certificate.type}</td>
              <td className="table-cell font-mono text-sm text-muted">{row.certificate.number}</td>
              <td className="table-cell text-muted tnum">
                {formatDate(row.certificate.expiresOn)}
              </td>
              <td className="table-cell text-right tnum text-muted">
                {row.days < 0 ? `${Math.abs(row.days)} overdue` : row.days}
              </td>
              <td className="table-cell text-right">
                <ExpiryBadge bucket={row.bucket} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function CompliancePage({
  vendors,
  onSelectVendor,
}: {
  vendors: Vendor[];
  onSelectVendor: (vendorId: string) => void;
}) {
  const [view, setView] = useState<View>('Calendar');
  const rows = certificateRows(vendors);
  const summary = complianceSummary(rows);
  const attention = attentionRows(rows);
  const upcoming = rows.filter((row) => row.days >= 0);
  const expired = rows.filter((row) => row.days < 0);

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-navy">Compliance</h2>
          <p className="mt-0.5 text-base text-muted">
            Stay ahead of vendor certification expiry.
          </p>
        </div>
        <SegmentedControl label="Compliance view" options={VIEWS} value={view} onChange={setView} />
      </div>

      <div className="grid gap-4 lg:grid-cols-[1fr,320px] lg:items-start">
        <Card bodyClassName={view === 'Calendar' ? 'p-4 sm:p-5' : 'p-0'}>
          {view === 'Calendar' && (
            <ComplianceCalendar rows={rows} onSelectVendor={onSelectVendor} />
          )}
          {view === 'Upcoming' &&
            (upcoming.length === 0 ? (
              <EmptyState
                icon={<CalendarCheck size={18} />}
                title="Nothing upcoming"
                description="No certificate on file has a future expiry date."
              />
            ) : (
              <CertificateTable rows={upcoming} onSelectVendor={onSelectVendor} />
            ))}
          {view === 'Expired' &&
            (expired.length === 0 ? (
              <EmptyState
                icon={<CalendarCheck size={18} />}
                title="No expired certificates"
                description="Every document on file is currently valid."
              />
            ) : (
              <CertificateTable rows={expired} onSelectVendor={onSelectVendor} />
            ))}
        </Card>

        <Card title="Attention Required" subtitle="Reminders are sent at 90, 60 and 30 days.">
          <p className="text-3xl font-semibold text-navy tnum">{summary.attention}</p>
          <p className="text-sm text-muted">certifications require attention</p>

          <ul className="mt-4 space-y-2 border-t border-hairline pt-3">
            {[
              ['expired', summary.expired],
              ['within 30 days', summary.within30],
              ['within 60 days', summary.within60],
              ['within 90 days', summary.within90],
            ].map(([label, count]) => (
              <li key={label as string} className="flex items-center justify-between text-base">
                <span className="text-muted">{label}</span>
                <span className="font-semibold text-navy tnum">{count}</span>
              </li>
            ))}
          </ul>

          <div className="mt-4 space-y-2 border-t border-hairline pt-3">
            {attention.slice(0, 5).map((row) => (
              <button
                key={row.certificate.id}
                type="button"
                onClick={() => onSelectVendor(row.vendor.id)}
                className="w-full rounded-md border border-hairline px-3 py-2 text-left
                  transition-colors duration-150 hover:border-teal/40 hover:bg-teal-soft/30"
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="truncate text-sm font-medium text-navy">{row.vendor.name}</span>
                  <ExpiryBadge bucket={row.bucket} />
                </div>
                <span className="text-xs text-muted">
                  {row.certificate.type} · {formatDate(row.certificate.expiresOn)}
                </span>
              </button>
            ))}
          </div>

          <Button
            variant="secondary"
            size="sm"
            className="mt-3 w-full"
            onClick={() => setView('Upcoming')}
          >
            See all upcoming expiries
          </Button>
        </Card>
      </div>
    </div>
  );
}
