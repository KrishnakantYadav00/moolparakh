import type { DisruptionCategory } from '@/types';
import { Card } from '@/components/ui/Primitives';
import { disruptionCategories, disruptionRegions, heatmapMatrix } from '@/lib/constants';

const LEVELS = [
  { label: 'No signal', color: '#F1F4F6', text: '#A9B4BC' },
  { label: 'LOW', color: '#E4EEF0', text: '#4A6070' },
  { label: 'MEDIUM', color: '#FBF3DF', text: '#8A6100' },
  { label: 'HIGH', color: '#FDE4CE', text: '#B35309' },
  { label: 'CRITICAL', color: '#F7D3CF', text: '#B3261E' },
];

export function DisruptionHeatmap() {
  return (
    <Card
      title="Disruption Heatmap"
      subtitle="Signal density by region and event type over the last 30 days."
    >
      <div className="overflow-x-auto">
        <table className="w-full min-w-[640px] border-separate border-spacing-1">
          <thead>
            <tr>
              <th className="w-40 text-left text-2xs font-semibold uppercase tracking-wide text-muted">
                Region
              </th>
              {disruptionCategories.map((category) => (
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
            {disruptionRegions.map((region) => (
              <tr key={region}>
                <th className="py-1 pr-2 text-left text-sm font-medium text-navy">{region}</th>
                {disruptionCategories.map((category: DisruptionCategory) => {
                  const level = heatmapMatrix[region]?.[category] ?? 0;
                  const style = LEVELS[level] ?? LEVELS[0];
                  return (
                    <td key={category} className="p-0">
                      <div
                        className="flex h-10 items-center justify-center rounded text-2xs font-semibold"
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

      <ul className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1.5 border-t border-hairline pt-3">
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
