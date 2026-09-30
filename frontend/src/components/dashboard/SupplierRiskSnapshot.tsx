import type { RiskLevel, Vendor } from '@/types';
import { Badge, Button, Card, riskHex } from '@/components/ui/Primitives';
import { relativeMinutes } from '@/utils/format';
import type { DisruptionEvent } from '@/types';

const disruptionEvents: DisruptionEvent[] = [];

const LEVELS: RiskLevel[] = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

const levelLabel: Record<RiskLevel, string> = {
  CRITICAL: 'Critical',
  HIGH: 'High',
  MEDIUM: 'Medium',
  LOW: 'Low',
};

export function SupplierRiskSnapshot({
  vendors,
  onOpenIntelligence,
}: {
  vendors: Vendor[];
  onOpenIntelligence: () => void;
}) {
  const counts = LEVELS.map((level) => ({
    level,
    count: vendors.filter((vendor) => vendor.risk === level).length,
  }));
  const total = vendors.length || 1;
  const topEvents = [...disruptionEvents]
    .sort((a, b) => a.detectedMinutesAgo - b.detectedMinutesAgo)
    .slice(0, 3);

  return (
    <Card
      title="Supplier Risk Snapshot"
      subtitle="Risk banding derived from trust score and live disruption matches."
      action={
        <Button size="sm" variant="ghost" onClick={onOpenIntelligence}>
          Open intelligence
        </Button>
      }
    >
      <ul className="space-y-2.5">
        {counts.map(({ level, count }) => (
          <li key={level} className="flex items-center gap-3">
            <span className="w-16 text-sm font-medium text-navy">{levelLabel[level]}</span>
            <div className="h-2 flex-1 overflow-hidden rounded-full bg-hairline/70">
              <div
                className="h-full rounded-full transition-[width] duration-500"
                style={{ width: `${(count / total) * 100}%`, background: riskHex[level] }}
              />
            </div>
            <span className="w-6 text-right text-base font-semibold text-navy tnum">{count}</span>
          </li>
        ))}
      </ul>

      <div className="mt-5 border-t border-hairline pt-4">
        <h3 className="text-sm font-semibold text-navy">Most recent disruptions</h3>
        <ul className="mt-2.5 space-y-2.5">
          {topEvents.map((event) => (
            <li key={event.id} className="flex items-start gap-2.5">
              <Badge
                tone={
                  event.severity === 'CRITICAL'
                    ? 'critical'
                    : event.severity === 'HIGH'
                      ? 'high'
                      : event.severity === 'MEDIUM'
                        ? 'medium'
                        : 'neutral'
                }
              >
                {event.severity}
              </Badge>
              <div className="min-w-0">
                <p className="text-base font-medium text-navy">{event.title}</p>
                <p className="text-xs text-muted">
                  {event.affectedVendorIds.length} suppliers affected ·{' '}
                  {relativeMinutes(event.detectedMinutesAgo)}
                </p>
                <p className="mt-0.5 truncate text-xs text-muted">
                  {event.affectedVendorIds.join(', ')}
                </p>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </Card>
  );
}
