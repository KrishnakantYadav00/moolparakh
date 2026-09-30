import type { TrustComponents } from '@/types';
import { totalTrustScore, trustBand, trustBandColor } from '@/utils/trustScore';

/**
 * The four trust components are drawn as consecutive arcs of one ring, so the
 * score is never a black box: the length of each arc is the number of points
 * that component actually contributed.
 */
export const COMPONENT_COLORS: Record<keyof TrustComponents, string> = {
  verificationCompleteness: '#0F8B8D',
  certificationFreshness: '#3AA3A4',
  accountAgeActivity: '#7CC3C3',
  manualBuyerFlag: '#B7DEDD',
};

const ORDER: (keyof TrustComponents)[] = [
  'verificationCompleteness',
  'certificationFreshness',
  'accountAgeActivity',
  'manualBuyerFlag',
];

interface TrustRingProps {
  components: TrustComponents;
  size?: number;
  stroke?: number;
  showBand?: boolean;
}

export function TrustRing({
  components,
  size = 168,
  stroke = 14,
  showBand = true,
}: TrustRingProps) {
  const score = totalTrustScore(components);
  const band = trustBand(score);
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const gap = 1.5;

  let offset = 0;
  const arcs = ORDER.map((key) => {
    const value = components[key];
    const length = Math.max(0, (value / 100) * circumference - gap);
    const arc = {
      key,
      color: COMPONENT_COLORS[key],
      dash: `${length} ${circumference - length}`,
      dashOffset: -offset,
    };
    offset += (value / 100) * circumference;
    return arc;
  });

  return (
    <div className="relative inline-flex items-center justify-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} role="img" aria-label={`Vendor Trust Score ${score} out of 100`}>
        <g transform={`rotate(-90 ${size / 2} ${size / 2})`}>
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            fill="none"
            stroke="#EDF1F4"
            strokeWidth={stroke}
          />
          {arcs.map((arc) => (
            <circle
              key={arc.key}
              cx={size / 2}
              cy={size / 2}
              r={radius}
              fill="none"
              stroke={arc.color}
              strokeWidth={stroke}
              strokeDasharray={arc.dash}
              strokeDashoffset={arc.dashOffset}
              strokeLinecap="butt"
            />
          ))}
        </g>
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <div className="flex items-baseline gap-0.5">
          <span className="text-4xl font-semibold text-navy tnum leading-none">{score}</span>
          <span className="text-sm text-muted">/100</span>
        </div>
        {showBand && (
          <span
            className="mt-1 text-xs font-semibold"
            style={{ color: trustBandColor(band) }}
          >
            {band}
          </span>
        )}
      </div>
    </div>
  );
}

/** Compact four-segment meter used inside dense tables. */
export function TrustMeter({ components, width = 68 }: { components: TrustComponents; width?: number }) {
  return (
    <div className="flex h-1.5 rounded-full overflow-hidden bg-hairline/80" style={{ width }} aria-hidden="true">
      {ORDER.map((key) => (
        <div
          key={key}
          style={{
            width: `${components[key]}%`,
            background: COMPONENT_COLORS[key],
          }}
        />
      ))}
    </div>
  );
}

export function TrustCell({ components }: { components: TrustComponents }) {
  const score = totalTrustScore(components);
  const band = trustBand(score);
  return (
    <div className="flex items-center gap-2.5">
      <span className="tnum text-base font-semibold text-navy w-6">{score}</span>
      <div>
        <TrustMeter components={components} />
        <span className="block mt-1 text-2xs" style={{ color: trustBandColor(band) }}>
          {band}
        </span>
      </div>
    </div>
  );
}
