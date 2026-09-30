import { useState } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import type { ExpiryBucket } from '@/types';
import { Button } from '@/components/ui/Primitives';
import type { CertificateRow } from '@/utils/compliance';
import { DEMO_NOW } from '@/utils/format';

const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const bucketDot: Record<ExpiryBucket, string> = {
  EXPIRED: '#B3261E',
  '30 DAYS': '#B35309',
  '60 DAYS': '#8A6100',
  '90 DAYS': '#687681',
  '90+ DAYS': '#A9B4BC',
};

export function ComplianceCalendar({
  rows,
  onSelectVendor,
}: {
  rows: CertificateRow[];
  onSelectVendor: (vendorId: string) => void;
}) {
  const [monthOffset, setMonthOffset] = useState(0);

  const cursor = new Date(DEMO_NOW.getFullYear(), DEMO_NOW.getMonth() + monthOffset, 1);
  const year = cursor.getFullYear();
  const month = cursor.getMonth();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const leading = (new Date(year, month, 1).getDay() + 6) % 7;

  const byDay = new Map<number, CertificateRow[]>();
  rows.forEach((row) => {
    const date = new Date(`${row.certificate.expiresOn}T00:00:00+05:30`);
    if (date.getFullYear() === year && date.getMonth() === month) {
      const day = date.getDate();
      byDay.set(day, [...(byDay.get(day) ?? []), row]);
    }
  });

  const isCurrentMonth =
    year === DEMO_NOW.getFullYear() && month === DEMO_NOW.getMonth();

  return (
    <div>
      <div className="mb-3 flex items-center justify-between">
        <h3 className="text-md font-semibold text-navy">
          {cursor.toLocaleDateString('en-IN', { month: 'long', year: 'numeric' })}
        </h3>
        <div className="flex items-center gap-1">
          <Button
            size="sm"
            variant="ghost"
            aria-label="Previous month"
            onClick={() => setMonthOffset((offset) => offset - 1)}
          >
            <ChevronLeft size={16} />
          </Button>
          <Button size="sm" variant="ghost" onClick={() => setMonthOffset(0)}>
            Today
          </Button>
          <Button
            size="sm"
            variant="ghost"
            aria-label="Next month"
            onClick={() => setMonthOffset((offset) => offset + 1)}
          >
            <ChevronRight size={16} />
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-7 gap-px overflow-hidden rounded-md border border-hairline bg-hairline">
        {WEEKDAYS.map((day) => (
          <div
            key={day}
            className="bg-canvas px-2 py-1.5 text-center text-2xs font-semibold text-muted"
          >
            {day}
          </div>
        ))}

        {Array.from({ length: leading }).map((_, index) => (
          <div key={`lead-${index}`} className="min-h-[86px] bg-canvas/40" />
        ))}

        {Array.from({ length: daysInMonth }, (_, index) => {
          const day = index + 1;
          const items = byDay.get(day) ?? [];
          const isToday = isCurrentMonth && day === DEMO_NOW.getDate();
          return (
            <div
              key={day}
              className={`min-h-[86px] bg-surface p-1.5 ${isToday ? 'ring-1 ring-inset ring-teal' : ''}`}
            >
              <span
                className={`text-2xs tnum ${isToday ? 'font-semibold text-teal' : 'text-muted'}`}
              >
                {day}
              </span>
              <ul className="mt-1 space-y-1">
                {items.slice(0, 2).map((row) => (
                  <li key={row.certificate.id}>
                    <button
                      type="button"
                      onClick={() => onSelectVendor(row.vendor.id)}
                      className="flex w-full items-start gap-1 rounded px-1 py-0.5 text-left text-2xs
                        text-navy transition-colors duration-150 hover:bg-canvas"
                    >
                      <span
                        className="mt-1 h-1.5 w-1.5 shrink-0 rounded-full"
                        style={{ background: bucketDot[row.bucket] }}
                      />
                      <span className="truncate leading-tight">{row.vendor.name}</span>
                    </button>
                  </li>
                ))}
                {items.length > 2 && (
                  <li className="px-1 text-2xs text-muted">+{items.length - 2} more</li>
                )}
              </ul>
            </div>
          );
        })}
      </div>

      <ul className="mt-3 flex flex-wrap gap-x-4 gap-y-1.5">
        {(Object.keys(bucketDot) as ExpiryBucket[]).map((bucket) => (
          <li key={bucket} className="flex items-center gap-1.5 text-xs text-muted">
            <span className="h-2 w-2 rounded-full" style={{ background: bucketDot[bucket] }} />
            {bucket}
          </li>
        ))}
      </ul>
    </div>
  );
}
