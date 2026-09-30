import type { ReactNode } from 'react';
import { ArrowDownRight, ArrowUpRight } from 'lucide-react';

interface KpiCardProps {
  label: string;
  value: string;
  subtitle: string;
  delta?: { value: string; direction: 'up' | 'down' | 'flat' };
  accent?: 'teal' | 'warning' | 'neutral';
  icon: ReactNode;
  onClick?: () => void;
}

export function KpiCard({
  label,
  value,
  subtitle,
  delta,
  accent = 'neutral',
  icon,
  onClick,
}: KpiCardProps) {
  const accentClass =accent === 'teal'? 'bg-teal-soft text-teal': accent === 'warning'? 'bg-risk-high-bg text-risk-high'  : 'bg-canvas text-navy/70';

  const deltaClass =
    delta?.direction === 'up'
      ? 'text-risk-good'
      : delta?.direction === 'down'
        ? 'text-risk-critical'
        : 'text-muted';

  const body = (
    <>
      <div className="flex items-start justify-between gap-3">
        <p className="text-xs font-medium text-muted">{label}</p>
        <span className={`flex h-7 w-7 items-center justify-center rounded-md ${accentClass}`}>
          {icon}
        </span>
      </div>
      <div className="mt-2.5 flex items-baseline gap-2">
        <span className="text-3xl font-semibold tracking-tight text-navy tnum">{value}</span>
        {delta && (
          <span className={`inline-flex items-center gap-0.5 text-xs font-semibold ${deltaClass}`}>
            {delta.direction === 'up' && <ArrowUpRight size={13} />}
            {delta.direction === 'down' && <ArrowDownRight size={13} />}
            {delta.value}
          </span>
        )}
      </div>
      <p className="mt-1 text-xs text-muted">{subtitle}</p>
    </>
  );

  const base = 'surface-card w-full p-4 text-left transition-colors duration-150';

  if (!onClick) return <div className={base}>{body}</div>;

  return (
    <button
      type="button"
      onClick={onClick}
      className={`${base} hover:border-teal/40 hover:bg-teal-soft/20`}
    >
      {body}
    </button>
  );
}
