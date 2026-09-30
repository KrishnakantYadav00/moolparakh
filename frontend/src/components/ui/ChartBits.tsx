export interface TooltipEntry {
  name?: string | number;
  value?: string | number;
  color?: string;
  dataKey?: string | number;
  payload?: Record<string, unknown>;
}

export interface ChartTooltipProps {
  active?: boolean;
  payload?: TooltipEntry[];
  label?: string | number;
  labelSuffix?: string;
  valueFormatter?: (value: string | number, entry: TooltipEntry) => string;
}

export function ChartTooltip({
  active,
  payload,
  label,
  labelSuffix = '',
  valueFormatter,
}: ChartTooltipProps) {
  if (!active || !payload || payload.length === 0) return null;

  return (
    <div className="rounded-md border border-hairline bg-surface px-3 py-2 shadow-raised">
      {label !== undefined && (
        <p className="text-2xs font-semibold text-muted">
          {label}
          {labelSuffix}
        </p>
      )}
      <ul className="mt-1 space-y-0.5">
        {payload.map((entry, index) => (
          <li key={index} className="flex items-center gap-2 text-sm text-navy">
            <span
              className="h-2 w-2 shrink-0 rounded-sm"
              style={{ background: entry.color ?? '#0F8B8D' }}
            />
            <span className="text-muted">{entry.name}</span>
            <span className="ml-auto font-semibold tnum">
              {valueFormatter && entry.value !== undefined
                ? valueFormatter(entry.value, entry)
                : entry.value}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}

export const axisStyle = {
  fontSize: 11,
  fill: '#687681',
} as const;

export const gridStyle = {
  stroke: '#E7ECF0',
  strokeDasharray: '3 3',
} as const;
