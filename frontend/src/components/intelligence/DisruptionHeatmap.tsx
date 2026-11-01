import { useEffect, useState } from 'react';
import { MapPin, Table as TableIcon, AlertTriangle, Layers } from 'lucide-react';
import type { DisruptionCategory } from '@/types';
import { Card, Badge, RiskBadge } from '@/components/ui/Primitives';
import { api, type ApiHeatmapResponse } from '@/lib/api';

const LEVELS = [
  { label: 'No signal', color: '#F1F4F6', text: '#A9B4BC' },
  { label: 'LOW', color: '#E4EEF0', text: '#4A6070' },
  { label: 'MEDIUM', color: '#FBF3DF', text: '#8A6100' },
  { label: 'HIGH', color: '#FDE4CE', text: '#B35309' },
  { label: 'CRITICAL', color: '#F7D3CF', text: '#B3261E' },
];

export function DisruptionHeatmap() {
  const [heatmap, setHeatmap] = useState<ApiHeatmapResponse | null>(null);
  const [viewMode, setViewMode] = useState<'states' | 'matrix'>('states');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.intelligence.heatmap()
      .then((data) => setHeatmap(data))
      .catch((err) => console.error('Failed to load heatmap data:', err))
      .finally(() => setLoading(false));
  }, []);

  const totalExposedVendors = (heatmap?.stateDensity || []).reduce(
    (sum, st) => sum + st.affectedVendorsCount,
    0
  );

  return (
    <Card
      title="India Risk & Disruption Heatmap"
      subtitle="Real-time disruption density by Indian state and category matrix."
      action={
        <div className="flex items-center gap-1.5 rounded-lg border border-hairline bg-canvas p-0.5 text-xs">
          <button
            type="button"
            onClick={() => setViewMode('states')}
            className={`flex items-center gap-1.5 rounded-md px-2.5 py-1 font-medium transition-colors ${
              viewMode === 'states'
                ? 'bg-surface text-navy shadow-sm'
                : 'text-muted hover:text-navy'
            }`}
          >
            <MapPin size={13} />
            State Density
          </button>
          <button
            type="button"
            onClick={() => setViewMode('matrix')}
            className={`flex items-center gap-1.5 rounded-md px-2.5 py-1 font-medium transition-colors ${
              viewMode === 'matrix'
                ? 'bg-surface text-navy shadow-sm'
                : 'text-muted hover:text-navy'
            }`}
          >
            <TableIcon size={13} />
            Regional Matrix
          </button>
        </div>
      }
    >
      {/* Overview Stat Badges */}
      <div className="mb-4 flex flex-wrap items-center gap-3 border-b border-hairline pb-3 text-xs">
        <div className="flex items-center gap-1.5">
          <span className="font-semibold text-navy">
            {heatmap?.totalEvents ?? 0}
          </span>
          <span className="text-muted">Total active disruptions</span>
        </div>
        <span className="text-muted">·</span>
        <div className="flex items-center gap-1.5">
          <span className="font-semibold text-navy tnum">{totalExposedVendors}</span>
          <span className="text-muted">Suppliers currently in impacted zones</span>
        </div>
      </div>

      {loading ? (
        <div className="flex h-48 items-center justify-center text-sm text-muted">
          Loading live disruption density...
        </div>
      ) : viewMode === 'states' ? (
        /* State-Level Density Grid */
        <div className="grid gap-2.5 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
          {(heatmap?.stateDensity || []).map((state) => {
            const levelStyle = LEVELS[state.level] ?? LEVELS[0];
            const hasDisruptions = state.disruptionCount > 0;

            return (
              <div
                key={state.state}
                className="group relative flex flex-col justify-between rounded-lg border border-hairline p-3 transition-all hover:border-teal/50 hover:shadow-sm"
                style={{
                  backgroundColor: hasDisruptions ? `${levelStyle.color}35` : 'transparent',
                }}
              >
                <div>
                  <div className="flex items-start justify-between gap-1">
                    <div>
                      <p className="font-semibold text-navy leading-tight">{state.state}</p>
                      <p className="text-2xs text-muted">{state.region}</p>
                    </div>
                    {hasDisruptions ? (
                      <RiskBadge level={state.maxSeverity as any} />
                    ) : (
                      <span className="rounded bg-surface px-1.5 py-0.5 text-2xs text-muted border border-hairline">
                        Normal
                      </span>
                    )}
                  </div>

                  <div className="mt-2.5 flex items-center justify-between text-2xs">
                    <span className="text-muted">Disruptions:</span>
                    <span className="font-semibold text-navy tnum">
                      {state.disruptionCount}
                    </span>
                  </div>
                  <div className="mt-1 flex items-center justify-between text-2xs">
                    <span className="text-muted">Impacted Suppliers:</span>
                    <span className="font-semibold text-navy tnum">
                      {state.affectedVendorsCount}
                    </span>
                  </div>
                </div>

                {state.topEvents.length > 0 && (
                  <div className="mt-2 border-t border-hairline/60 pt-1.5">
                    <p className="truncate text-2xs text-muted" title={state.topEvents[0].title}>
                      ⚡ {state.topEvents[0].title}
                    </p>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      ) : (
        /* Regional Category Matrix */
        <div className="overflow-x-auto">
          <table className="w-full min-w-[640px] border-separate border-spacing-1">
            <thead>
              <tr>
                <th className="w-40 text-left text-2xs font-semibold uppercase tracking-wide text-muted">
                  Region
                </th>
                {(heatmap?.categories || []).map((category) => (
                  <th
                    key={category}
                    className="px-1 pb-1 text-center text-2xs font-medium leading-tight text-muted"
                  >
                    {category}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {(heatmap?.regions || []).map((region) => (
                <tr key={region}>
                  <th className="py-1 pr-2 text-left text-sm font-medium text-navy">{region}</th>
                  {(heatmap?.categories || []).map((category) => {
                    const level = heatmap?.regionalMatrix?.[region]?.[category] ?? 0;
                    const style = LEVELS[level] ?? LEVELS[0];
                    return (
                      <td key={category} className="p-0">
                        <div
                          className="flex h-10 items-center justify-center rounded text-2xs font-semibold transition-transform hover:scale-105"
                          style={{ background: style.color, color: style.text }}
                          title={`${region} · ${category} · ${style.label}`}
                        >
                          {level > 0 ? style.label : '—'}
                        </div>
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Legend */}
      <ul className="mt-4 flex flex-wrap items-center gap-x-4 gap-y-1.5 border-t border-hairline pt-3">
        {LEVELS.map((level) => (
          <li key={level.label} className="flex items-center gap-1.5 text-xs text-muted">
            <span
              className="h-2.5 w-2.5 rounded-sm border border-hairline"
              style={{ background: level.color }}
            />
            {level.label}
          </li>
        ))}
      </ul>
    </Card>
  );
}
