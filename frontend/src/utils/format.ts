import type { ExpiryBucket } from '@/types';

/**
 * The prototype runs against a fixed reference date so that every expiry
 * countdown, chart and "x days ago" label is stable during a demo.
 * Replace with `new Date()` once the API is live.
 */
export const DEMO_NOW = new Date('2026-08-25T09:20:00+05:30');

const MS_PER_DAY = 86_400_000;

export function daysUntil(isoDate: string, from: Date = DEMO_NOW): number {
  const target = new Date(`${isoDate}T00:00:00+05:30`).getTime();
  const base = new Date(
    from.getFullYear(),
    from.getMonth(),
    from.getDate(),
  ).getTime();
  return Math.round((target - base) / MS_PER_DAY);
}

export function expiryBucket(isoDate: string): ExpiryBucket {
  const days = daysUntil(isoDate);
  if (days < 0) return 'EXPIRED';
  if (days <= 30) return '30 DAYS';
  if (days <= 60) return '60 DAYS';
  if (days <= 90) return '90 DAYS';
  return '90+ DAYS';
}

export function formatDate(isoDate: string): string {
  const d = new Date(`${isoDate}T00:00:00+05:30`);
  return d.toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

export function formatShortDate(isoDate: string): string {
  const d = new Date(`${isoDate}T00:00:00+05:30`);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });
}

export function relativeDays(days: number): string {
  if (days <= 0) return 'today';
  if (days === 1) return 'yesterday';
  return `${days} days ago`;
}

export function relativeMinutes(minutes: number): string {
  if (minutes < 1) return 'just now';
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return hours === 1 ? '1 hr ago' : `${hours} hrs ago`;
  const days = Math.floor(hours / 24);
  return days === 1 ? '1 day ago' : `${days} days ago`;
}

export function formatHoursRemaining(hours: number): string {
  if (hours <= 0) return 'Closed';
  const d = Math.floor(hours / 24);
  const h = hours % 24;
  if (d === 0) return `${h}h remaining`;
  return `${d}d ${h}h remaining`;
}

export function formatRupees(value: number, fractionDigits = 0): string {
  return `₹${value.toLocaleString('en-IN', {
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  })}`;
}

export function formatScore(value: number, digits = 2): string {
  return value.toFixed(digits);
}

/** Percentage of a bar/segment, clamped for safe rendering. */
export function clamp(value: number, min = 0, max = 100): number {
  return Math.min(max, Math.max(min, value));
}

export function initials(name: string): string {
  return name
    .replace(/(Pvt\.?|Ltd\.?|LLP|Private|Limited|&)/gi, '')
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((w) => w[0]?.toUpperCase() ?? '')
    .join('');
}
