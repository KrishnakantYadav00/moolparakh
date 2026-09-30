import type { TrustComponents } from '@/types';
import { TrustRing, COMPONENT_COLORS } from '@/components/ui/TrustVisuals';
import { MeterBar } from '@/components/ui/Primitives';
import { trustBreakdown } from '@/utils/trustScore';

export function TrustScorePanel({
  components,
  note,
}: {
  components: TrustComponents;
  note?: string;
}) {
  const rows = trustBreakdown(components);

  return (
    <div className="grid gap-6 lg:grid-cols-[176px,1fr] lg:items-start">
      <div className="flex justify-center">
        <TrustRing components={components} />
      </div>

      <div>
        <p className="text-sm text-muted">
          Every point is traceable. Each arc of the ring is one weighted component of the score.
        </p>
        <ul className="mt-3 space-y-3">
          {rows.map((row) => (
            <li key={row.key}>
              <div className="flex items-baseline justify-between gap-3">
                <span className="flex items-center gap-2 text-base font-medium text-navy">
                  <span
                    className="h-2.5 w-2.5 rounded-sm"
                    style={{ background: COMPONENT_COLORS[row.key] }}
                  />
                  {row.label}
                  <span className="text-xs font-normal text-muted">{row.weight}%</span>
                </span>
                <span className="text-base font-semibold text-navy tnum">
                  {row.earned} / {row.max}
                </span>
              </div>
              <div className="mt-1.5">
                <MeterBar
                  value={row.earned}
                  max={row.max}
                  height={5}
                  color={COMPONENT_COLORS[row.key]}
                />
              </div>
              <p className="mt-1 text-xs text-muted">{row.note}</p>
            </li>
          ))}
        </ul>

        {note && (
          <p className="mt-4 rounded-md border border-hairline bg-canvas/70 px-3 py-2 text-sm text-muted">
            {note}
          </p>
        )}
      </div>
    </div>
  );
}
