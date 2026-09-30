import type { DisruptionEvent } from '@/types';
import { Card, RiskBadge } from '@/components/ui/Primitives';
import { relativeMinutes } from '@/utils/format';

export function DisruptionFeed({
  events,
  onSelectVendor,
}: {
  events: DisruptionEvent[];
  onSelectVendor: (vendorId: string) => void;
}) {
  return (
    <Card
      title="Live Disruption Feed"
      subtitle="Events matched to your suppliers from the monitored news corpus."
      bodyClassName="p-3 sm:p-3"
    >
      <ul className="space-y-2.5 max-h-[560px] overflow-y-auto pr-1">
        {events.map((event) => (
          <li key={event.id} className="rounded-md border border-hairline p-3">
            <div className="flex items-center justify-between gap-2">
              <RiskBadge level={event.severity} />
              <span className="text-2xs text-muted">
                Detected {relativeMinutes(event.detectedMinutesAgo)}
              </span>
            </div>
            <p className="mt-2 text-base font-semibold text-navy">{event.title}</p>
            <p className="mt-0.5 text-sm text-muted">{event.summary}</p>
            <p className="mt-1.5 text-xs text-muted">
              {event.category} · {event.region}
            </p>

            <div className="mt-2.5 border-t border-hairline pt-2">
              <p className="text-xs text-muted">
                Affected suppliers:{' '}
                <span className="font-semibold text-navy tnum">
                  {event.affectedVendorIds.length}
                </span>
              </p>
              <div className="mt-1.5 flex flex-wrap gap-1.5">
                {event.affectedVendorIds.map((vendorId) => (
                  <button
                    key={vendorId}
                    type="button"
                    onClick={() => onSelectVendor(vendorId)}
                    className="rounded border border-hairline px-1.5 py-0.5 text-2xs text-navy
                      transition-colors duration-150 hover:border-teal/40 hover:bg-teal-soft"
                  >
                    {vendorId}
                  </button>
                ))}
              </div>
            </div>
          </li>
        ))}
      </ul>
    </Card>
  );
}
