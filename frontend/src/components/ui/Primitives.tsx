import type { ButtonHTMLAttributes, ReactNode } from 'react';
import type { ExpiryBucket, RiskLevel } from '@/types';

/* -------------------------------------------------- Button */

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
type ButtonSize = 'sm' | 'md';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  icon?: ReactNode;
}

const buttonVariants: Record<ButtonVariant, string> = {
  primary:
    'bg-teal text-white border border-teal hover:bg-[#0c7576] active:bg-[#0a6667] disabled:bg-teal/50 disabled:border-teal/50',
  secondary:
    'bg-surface text-navy border border-hairline hover:bg-canvas hover:border-[#c6d1da] active:bg-[#eef2f5]',
  ghost: 'bg-transparent text-muted border border-transparent hover:bg-canvas hover:text-navy',
  danger:
    'bg-risk-critical text-white border border-risk-critical hover:bg-[#94201a] active:bg-[#7d1b16]',
};

const buttonSizes: Record<ButtonSize, string> = {
  sm: 'h-8 px-3 text-sm gap-1.5',
  md: 'h-9 px-4 text-base gap-2',
};

export function Button({
  variant = 'secondary',
  size = 'md',
  icon,
  className = '',
  children,
  ...rest
}: ButtonProps) {
  return (
    <button
      type="button"
      className={`inline-flex items-center justify-center rounded-md font-medium
        transition-colors duration-150 disabled:cursor-not-allowed disabled:opacity-60
        ${buttonVariants[variant]} ${buttonSizes[size]} ${className}`}
      {...rest}
    >
      {icon}
      {children}
    </button>
  );
}

/* -------------------------------------------------- Card */

interface CardProps {
  title?: string;
  subtitle?: string;
  action?: ReactNode;
  children: ReactNode;
  className?: string;
  bodyClassName?: string;
}

export function Card({
  title,
  subtitle,
  action,
  children,
  className = '',
  bodyClassName = 'p-4 sm:p-5',
}: CardProps) {
  return (
    <section className={`surface-card ${className}`}>
      {(title || action) && (
        <header className="flex items-start justify-between gap-3 px-4 sm:px-5 pt-4 pb-3 border-b border-hairline">
          <div className="min-w-0">
            {title && <h2 className="text-md font-semibold text-navy truncate">{title}</h2>}
            {subtitle && <p className="text-xs text-muted mt-0.5">{subtitle}</p>}
          </div>
          {action && <div className="shrink-0">{action}</div>}
        </header>
      )}
      <div className={bodyClassName}>{children}</div>
    </section>
  );
}

/* -------------------------------------------------- Badge */

type BadgeTone = 'neutral' | 'teal' | 'good' | 'medium' | 'high' | 'critical' | 'navy';

const badgeTones: Record<BadgeTone, string> = {
  neutral: 'bg-risk-low-bg text-muted border-hairline',
  teal: 'bg-teal-soft text-teal border-teal/25',
  good: 'bg-risk-good-bg text-risk-good border-risk-good/25',
  medium: 'bg-risk-medium-bg text-risk-medium border-risk-medium/25',
  high: 'bg-risk-high-bg text-risk-high border-risk-high/25',
  critical: 'bg-risk-critical-bg text-risk-critical border-risk-critical/25',
  navy: 'bg-navy/5 text-navy border-navy/15',
};

export function Badge({
  tone = 'neutral',
  children,
  className = '',
}: {
  tone?: BadgeTone;
  children: ReactNode;
  className?: string;
}) {
  return (
    <span
      className={`inline-flex items-center gap-1 rounded border px-1.5 py-0.5 text-2xs font-semibold
        whitespace-nowrap ${badgeTones[tone]} ${className}`}
    >
      {children}
    </span>
  );
}

export const riskTone: Record<RiskLevel, BadgeTone> = {
  CRITICAL: 'critical',
  HIGH: 'high',
  MEDIUM: 'medium',
  LOW: 'neutral',
};

export const riskHex: Record<RiskLevel, string> = {
  CRITICAL: '#B3261E',
  HIGH: '#B35309',
  MEDIUM: '#8A6100',
  LOW: '#8B98A2',
};

export function RiskBadge({ level }: { level: RiskLevel }) {
  return <Badge tone={riskTone[level]}>{level}</Badge>;
}

const bucketTone: Record<ExpiryBucket, BadgeTone> = {
  EXPIRED: 'critical',
  '30 DAYS': 'high',
  '60 DAYS': 'medium',
  '90 DAYS': 'neutral',
  '90+ DAYS': 'neutral',
};

export function ExpiryBadge({ bucket }: { bucket: ExpiryBucket }) {
  return <Badge tone={bucketTone[bucket]}>{bucket}</Badge>;
}

/* -------------------------------------------------- Segmented control */

interface SegmentedControlProps<T extends string> {
  options: readonly T[];
  value: T;
  onChange: (value: T) => void;
  label: string;
  counts?: Partial<Record<T, number>>;
}

export function SegmentedControl<T extends string>({
  options,
  value,
  onChange,
  label,
  counts,
}: SegmentedControlProps<T>) {
  return (
    <div
      role="tablist"
      aria-label={label}
      className="inline-flex items-center gap-0.5 p-0.5 rounded-md border border-hairline bg-canvas"
    >
      {options.map((option) => {
        const active = option === value;
        return (
          <button
            key={option}
            type="button"
            role="tab"
            aria-selected={active}
            onClick={() => onChange(option)}
            className={`h-7 px-2.5 rounded text-sm font-medium transition-colors duration-150
              ${active ? 'bg-surface text-navy shadow-card' : 'text-muted hover:text-navy'}`}
          >
            {option}
            {counts?.[option] !== undefined && (
              <span className={`ml-1.5 tnum ${active ? 'text-teal' : 'text-muted/70'}`}>
                {counts[option]}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
}

/* -------------------------------------------------- Skeleton */

export function Skeleton({ className = '' }: { className?: string }) {
  return <div className={`skeleton ${className}`} aria-hidden="true" />;
}

export function SkeletonCard() {
  return (
    <div className="surface-card p-5 space-y-3">
      <Skeleton className="h-3 w-28" />
      <Skeleton className="h-8 w-20" />
      <Skeleton className="h-3 w-36" />
    </div>
  );
}

/* -------------------------------------------------- Empty & error states */

export function EmptyState({
  icon,
  title,
  description,
  action,
}: {
  icon: ReactNode;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center text-center py-14 px-6">
      <div className="flex h-11 w-11 items-center justify-center rounded-full bg-teal-soft text-teal">
        {icon}
      </div>
      <h3 className="mt-3 text-md font-semibold text-navy">{title}</h3>
      <p className="mt-1 text-base text-muted max-w-sm">{description}</p>
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

export function ErrorState({
  title,
  description,
  onRetry,
}: {
  title: string;
  description: string;
  onRetry: () => void;
}) {
  return (
    <div className="flex flex-col items-center justify-center text-center py-10 px-6">
      <div className="flex h-11 w-11 items-center justify-center rounded-full bg-risk-critical-bg text-risk-critical">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path
            d="M12 8v5m0 3.5h.01M10.3 3.9 2.6 17.2A2 2 0 0 0 4.3 20.2h15.4a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z"
            stroke="currentColor"
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </div>
      <h3 className="mt-3 text-md font-semibold text-navy">{title}</h3>
      <p className="mt-1 text-base text-muted max-w-sm">{description}</p>
      <Button variant="secondary" className="mt-4" onClick={onRetry}>
        Retry
      </Button>
    </div>
  );
}

/* -------------------------------------------------- Progress line */

export function MeterBar({
  value,
  max,
  color = '#0F8B8D',
  height = 6,
}: {
  value: number;
  max: number;
  color?: string;
  height?: number;
}) {
  const pct = max === 0 ? 0 : Math.min(100, (value / max) * 100);
  return (
    <div
      className="w-full rounded-full bg-hairline/80 overflow-hidden"
      style={{ height }}
      role="presentation"
    >
      <div
        className="h-full rounded-full transition-[width] duration-300 ease-out"
        style={{ width: `${pct}%`, background: color }}
      />
    </div>
  );
}
