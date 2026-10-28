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
  if (events.length === 0) {
    return (
      <Card
        title="Live Disruption Feed"
        subtitle="Events matched to your suppliers from the monitored news corpus."
        bodyClassName="p-3 sm:p-3"
      >
        <div className="flex h-32 items-center justify-center text-sm text-muted">
          No disruption events yet. Events will appear here as they are detected.
        </div>
      </Card>
    );
  }

  return (
    <Card
      title="Live Disruption Feed"
      subtitle="Events matched to your suppliers from the monitored news corpus."
      bodyClassName="p-3 sm:p-3"
    >
      <ul className="space-y-2.5 max-h-[560px] overflow-y-auto pr-1">
        {events.map((event) => {
          // Use enriched vendor objects if available, otherwise fallback to IDs
          const affectedVendors = event.affectedVendors ?? event.affectedVendorIds.map(id => ({ id, name: id }));

          return (
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
                    {affectedVendors.length}
                  </span>
                </p>
                <div className="mt-1.5 flex flex-wrap gap-1.5">
                  {affectedVendors.map((v) => (
                    <button
                      key={v.id}
                      type="button"
                      onClick={() => onSelectVendor(v.id)}
                      className="rounded border border-hairline px-1.5 py-0.5 text-2xs text-navy
                        transition-colors duration-150 hover:border-teal/40 hover:bg-teal-soft"
                    >
                      {v.name}
                    </button>
                  ))}
                </div>
              </div>
            </li>
          );
        })}
      </ul>
    </Card>
  );
}
