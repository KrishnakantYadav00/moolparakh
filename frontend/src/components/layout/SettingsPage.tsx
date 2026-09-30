import { useState } from 'react';
import { Card } from '@/components/ui/Primitives';
import { DEFAULT_WEIGHTS } from '@/utils/bidEvaluation';
import { TRUST_LABELS, TRUST_WEIGHTS } from '@/utils/trustScore';
import type { TrustComponents } from '@/types';
import { organisation } from '@/lib/constants';

function Toggle({
  id,
  label,
  description,
  checked,
  onChange,
}: {
  id: string;
  label: string;
  description: string;
  checked: boolean;
  onChange: (next: boolean) => void;
}) {
  return (
    <div className="flex items-start justify-between gap-4 py-3">
      <div>
        <label htmlFor={id} className="text-base font-medium text-navy">
          {label}
        </label>
        <p className="text-sm text-muted">{description}</p>
      </div>
      <button
        id={id}
        type="button"
        role="switch"
        aria-checked={checked}
        aria-label={label}
        onClick={() => onChange(!checked)}
        className={`relative mt-0.5 h-5 w-9 shrink-0 rounded-full transition-colors duration-150
          ${checked ? 'bg-teal' : 'bg-hairline'}`}
      >
        <span
          className={`absolute top-0.5 h-4 w-4 rounded-full bg-white shadow-card transition-all duration-150
            ${checked ? 'left-[18px]' : 'left-0.5'}`}
        />
      </button>
    </div>
  );
}

export function SettingsPage() {
  const [reminders, setReminders] = useState({ d90: true, d60: true, d30: true });

  return (
    <div className="max-w-3xl space-y-5">
      <div>
        <h2 className="text-2xl font-semibold tracking-tight text-navy">Settings</h2>
        <p className="mt-0.5 text-base text-muted">
          Organisation profile and the rules behind scoring and alerts.
        </p>
      </div>

      <Card title="Organisation" subtitle="Managed by your account administrator.">
        <dl className="grid gap-x-6 gap-y-3 sm:grid-cols-2">
          {[
            ['Legal name', organisation.name],
            ['Signed-in user', organisation.user],
            ['Role', organisation.role],
            ['Plants', String(organisation.plants.length)],
          ].map(([label, value]) => (
            <div key={label}>
              <dt className="text-xs text-muted">{label}</dt>
              <dd className="text-base text-navy">{value}</dd>
            </div>
          ))}
        </dl>
      </Card>

      <Card
        title="Compliance reminders"
        subtitle="When to alert your team before a vendor document expires."
        bodyClassName="px-4 sm:px-5 py-1"
      >
        <div className="divide-y divide-hairline">
          <Toggle
            id="reminder-90"
            label="90 days before expiry"
            description="Early notice so the vendor has time to renew."
            checked={reminders.d90}
            onChange={(next) => setReminders({ ...reminders, d90: next })}
          />
          <Toggle
            id="reminder-60"
            label="60 days before expiry"
            description="Moves the certificate into the Attention Required panel."
            checked={reminders.d60}
            onChange={(next) => setReminders({ ...reminders, d60: next })}
          />
          <Toggle
            id="reminder-30"
            label="30 days before expiry"
            description="Final reminder before certification freshness starts to drop."
            checked={reminders.d30}
            onChange={(next) => setReminders({ ...reminders, d30: next })}
          />
        </div>
      </Card>

      <Card
        title="Vendor Trust Score weighting"
        subtitle="The formula applied to every vendor on the network."
      >
        <ul className="divide-y divide-hairline">
          {(Object.keys(TRUST_WEIGHTS) as (keyof TrustComponents)[]).map((key) => (
            <li key={key} className="flex items-center justify-between py-2.5 first:pt-0">
              <span className="text-base text-navy">{TRUST_LABELS[key]}</span>
              <span className="text-base font-semibold text-navy tnum">{TRUST_WEIGHTS[key]}%</span>
            </li>
          ))}
        </ul>
      </Card>

      <Card
        title="Default bid weights"
        subtitle="Starting position for every bid comparison. Buyers can adjust per RFQ."
      >
        <ul className="divide-y divide-hairline">
          {[
            ['Price', DEFAULT_WEIGHTS.price],
            ['Delivery', DEFAULT_WEIGHTS.delivery],
            ['Trust', DEFAULT_WEIGHTS.trust],
          ].map(([label, value]) => (
            <li key={String(label)} className="flex items-center justify-between py-2.5 first:pt-0">
              <span className="text-base text-navy">{label}</span>
              <span className="text-base font-semibold text-navy tnum">{value}%</span>
            </li>
          ))}
        </ul>
      </Card>

      <Card title="Verification data sources" subtitle="Used during vendor onboarding and re-checks.">
        <ul className="space-y-2">
          {[
            ['GSTIN status and filing history', 'GST Network'],
            ['PAN linkage', 'Income Tax verification service'],
            ['Udyam registration and MSME category', 'Udyam portal'],
            ['CIN and director details', 'MCA registry'],
          ].map(([what, source]) => (
            <li key={what} className="flex items-center justify-between gap-4">
              <span className="text-base text-navy">{what}</span>
              <span className="text-sm text-muted">{source}</span>
            </li>
          ))}
        </ul>
      </Card>
    </div>
  );
}
