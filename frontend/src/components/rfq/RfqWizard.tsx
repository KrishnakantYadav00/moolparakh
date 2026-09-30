import { useEffect, useRef, useState } from 'react';
import { Check, Loader2, Send, Sparkle } from 'lucide-react';
import type { Rfq, RfqSpec, Vendor } from '@/types';
import { Badge, Button } from '@/components/ui/Primitives';
import { Modal } from '@/components/ui/Overlays';
import { DEMO_NOW } from '@/utils/format';

const EXAMPLE =
  'I need 500 M8 hex bolts, A2 grade stainless steel,\nrequired within 14 days at Pune.';

const ITEM_RULES: { match: RegExp; spec: Partial<RfqSpec> }[] = [
  {
    match: /bolt|fastener|screw/i,
    spec: { item: 'M8 Hex Bolt', standard: 'ISO 4017', grade: 'A2', unit: 'pieces' },
  },
  {
    match: /sheet|crca|plate/i,
    spec: { item: 'CRCA Sheet', standard: 'IS 513', grade: 'D', unit: 'kg' },
  },
  {
    match: /o-ring|gasket|seal|rubber/i,
    spec: { item: 'Nitrile O-Ring', standard: 'IS 5382', grade: 'Shore 70A', unit: 'pieces' },
  },
  {
    match: /cable|wire|harness/i,
    spec: { item: 'Copper Cable', standard: 'IS 694', grade: 'Cu, 1100 V', unit: 'metres' },
  },
  {
    match: /casting|housing/i,
    spec: { item: 'Die Cast Housing', standard: 'IS 3965', grade: 'ADC12', unit: 'pieces' },
  },
];

const CITIES = [
  'Pune',
  'Chakan',
  'Bengaluru',
  'Chennai',
  'Coimbatore',
  'Indore',
  'Noida',
  'Ludhiana',
  'Kochi',
  'Nashik',
  'Hyderabad',
];

/** Deterministic requirement parser standing in for the LLM extraction service. */
function parseRequirement(text: string): RfqSpec {
  const rule = ITEM_RULES.find((entry) => entry.match.test(text));
  const quantityMatch = text.match(/(\d[\d,]*)\s*(pieces|pcs|nos|units|kg|tonnes|sets|metres)?/i);
  const daysMatch = text.match(/(\d+)\s*days?/i);
  const city = CITIES.find((option) => new RegExp(`\\b${option}\\b`, 'i').test(text));

  return {
    item: rule?.spec.item ?? 'Custom item',
    standard: rule?.spec.standard ?? 'To be confirmed',
    grade: rule?.spec.grade ?? 'To be confirmed',
    quantity: quantityMatch ? Number(quantityMatch[1].replace(/,/g, '')) : 100,
    unit: rule?.spec.unit ?? 'pieces',
    deliveryDays: daysMatch ? Number(daysMatch[1]) : 21,
    deliveryLocation: city ?? 'Pune',
    qualityNotes: /test certificate|mtc|mill test/i.test(text)
      ? 'Mill test certificate required with dispatch.'
      : 'Standard incoming inspection applies.',
  };
}

function matchSuppliers(spec: RfqSpec, vendors: Vendor[]): Vendor[] {
  const keyword = spec.item.split(' ').pop()?.toLowerCase() ?? '';
  const matched = vendors.filter(
    (vendor) =>
      vendor.status !== 'High Risk' &&
      vendor.categories.some(
        (category) =>
          category.toLowerCase().includes(keyword) ||
          keyword.includes(category.toLowerCase().split(' ')[0]),
      ),
  );
  return matched.length >= 3 ? matched : vendors.filter((v) => v.status === 'Verified').slice(0, 8);
}

interface RfqWizardProps {
  open: boolean;
  onClose: () => void;
  vendors: Vendor[];
  onCreate: (rfq: Rfq) => void;
}

export function RfqWizard({ open, onClose, vendors, onCreate }: RfqWizardProps) {
  const [step, setStep] = useState(1);
  const [text, setText] = useState('');
  const [parsing, setParsing] = useState(false);
  const [spec, setSpec] = useState<RfqSpec | null>(null);
  const [broadcasting, setBroadcasting] = useState(false);
  const [sent, setSent] = useState(false);
  const timers = useRef<number[]>([]);

  useEffect(() => {
    if (open) return;
    setStep(1);
    setText('');
    setParsing(false);
    setSpec(null);
    setBroadcasting(false);
    setSent(false);
  }, [open]);

  useEffect(
    () => () => {
      timers.current.forEach((id) => window.clearTimeout(id));
    },
    [],
  );

  const matched = spec ? matchSuppliers(spec, vendors) : [];

  const runParse = () => {
    setParsing(true);
    timers.current.push(
      window.setTimeout(() => {
        setSpec(parseRequirement(text));
        setParsing(false);
        setStep(2);
      }, 1200),
    );
  };

  const broadcast = () => {
    if (!spec) return;
    setBroadcasting(true);
    timers.current.push(
      window.setTimeout(() => {
        setBroadcasting(false);
        setSent(true);
        const id = `rfq-${Date.now()}`;
        onCreate({
          id,
          reference: `RFQ-2026-${String(Math.floor(Math.random() * 900) + 100)}`,
          title: `${spec.quantity} ${spec.unit} · ${spec.item}`,
          status: 'OPEN',
          freeText: text,
          spec,
          suppliersNotified: matched.length,
          createdOn: DEMO_NOW.toISOString().slice(0, 10),
          closesInHours: 96,
          bids: [],
        });
      }, 1200),
    );
  };

  const updateSpec = (key: keyof RfqSpec, value: string) => {
    if (!spec) return;
    setSpec({
      ...spec,
      [key]: key === 'quantity' || key === 'deliveryDays' ? Number(value) || 0 : value,
    });
  };

  const specFields: { key: keyof RfqSpec; label: string; type?: string }[] = [
    { key: 'item', label: 'Item' },
    { key: 'standard', label: 'Standard' },
    { key: 'grade', label: 'Grade' },
    { key: 'quantity', label: 'Quantity', type: 'number' },
    { key: 'unit', label: 'Unit' },
    { key: 'deliveryDays', label: 'Delivery Days', type: 'number' },
    { key: 'deliveryLocation', label: 'Delivery Location' },
    { key: 'qualityNotes', label: 'Quality Notes' },
  ];

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Create RFQ"
      description={
        step === 1
          ? 'Step 1 of 3 — Describe Requirement'
          : step === 2
            ? 'Step 2 of 3 — Structured Specification'
            : 'Step 3 of 3 — Confirm & Broadcast'
      }
      width="max-w-2xl"
      footer={
        sent ? (
          <Button variant="primary" onClick={onClose}>
            Done
          </Button>
        ) : (
          <>
            {step > 1 && (
              <Button variant="ghost" onClick={() => setStep((s) => s - 1)}>
                Back
              </Button>
            )}
            {step === 1 && (
              <Button
                variant="primary"
                onClick={runParse}
                disabled={text.trim().length < 8 || parsing}
                icon={
                  parsing ? (
                    <Loader2 size={15} className="animate-spin" />
                  ) : (
                    <Sparkle size={15} />
                  )
                }
              >
                {parsing ? 'Parsing requirement...' : 'Parse Requirement'}
              </Button>
            )}
            {step === 2 && (
              <Button variant="primary" onClick={() => setStep(3)}>
                Continue
              </Button>
            )}
            {step === 3 && (
              <Button
                variant="primary"
                onClick={broadcast}
                disabled={broadcasting}
                icon={
                  broadcasting ? <Loader2 size={15} className="animate-spin" /> : <Send size={15} />
                }
              >
                {broadcasting ? 'Broadcasting RFQ...' : 'Broadcast RFQ'}
              </Button>
            )}
          </>
        )
      }
    >
      {sent ? (
        <div className="py-6 text-center">
          <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-teal-soft text-teal">
            <Check size={22} />
          </div>
          <h3 className="mt-3 text-md font-semibold text-navy">RFQ successfully sent</h3>
          <p className="mt-1 text-base text-muted">
            {matched.length} suppliers notified. Bids will appear under Open RFQs.
          </p>
        </div>
      ) : (
        <>
          {step === 1 && (
            <div>
              <label className="field-label" htmlFor="rfq-text">
                Describe what you need
              </label>
              <textarea
                id="rfq-text"
                data-autofocus
                rows={5}
                className="field-textarea"
                placeholder={EXAMPLE}
                value={text}
                onChange={(event) => setText(event.target.value)}
              />
              <div className="mt-2 flex items-center justify-between gap-3">
                <p className="text-xs text-muted">
                  Write it the way you would to a supplier. Quantity, grade, timeline and location
                  are extracted into a structured specification.
                </p>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => setText(EXAMPLE.replace('\n', ' '))}
                >
                  Use example
                </Button>
              </div>
            </div>
          )}

          {step === 2 && spec && (
            <div>
              <p className="mb-3 text-sm text-muted">
                Review the extracted specification. Every field is editable before broadcast.
              </p>
              <div className="grid gap-3 sm:grid-cols-2">
                {specFields.map((field) => (
                  <div
                    key={field.key}
                    className={field.key === 'qualityNotes' ? 'sm:col-span-2' : ''}
                  >
                    <label className="field-label" htmlFor={`spec-${field.key}`}>
                      {field.label}
                    </label>
                    <input
                      id={`spec-${field.key}`}
                      type={field.type ?? 'text'}
                      className="field-input"
                      value={String(spec[field.key])}
                      onChange={(event) => updateSpec(field.key, event.target.value)}
                    />
                  </div>
                ))}
              </div>
            </div>
          )}

          {step === 3 && spec && (
            <div>
              <div className="rounded-md border border-hairline bg-canvas/60 p-4">
                <h3 className="text-base font-semibold text-navy">Requirement</h3>
                <p className="mt-1 text-base text-navy/85">
                  {spec.quantity} {spec.unit} · {spec.item} · {spec.grade} · {spec.standard}
                </p>
                <p className="text-sm text-muted">
                  Delivery within {spec.deliveryDays} days at {spec.deliveryLocation}
                </p>
                <p className="mt-1 text-sm text-muted">{spec.qualityNotes}</p>
              </div>

              <div className="mt-4">
                <h3 className="text-base font-semibold text-navy">Matched Suppliers</h3>
                <p className="text-sm text-muted">
                  {matched.length} suppliers match this requirement
                </p>
                <ul className="mt-2.5 space-y-1.5">
                  {matched.slice(0, 6).map((vendor) => (
                    <li
                      key={vendor.id}
                      className="flex items-center justify-between gap-3 rounded-md border border-hairline px-3 py-2"
                    >
                      <span className="text-base text-navy">{vendor.name}</span>
                      <div className="flex items-center gap-2">
                        <Badge tone="navy">{vendor.categories[0]}</Badge>
                        <span className="text-sm font-semibold text-navy tnum">
                          {vendor.trustScore}
                        </span>
                      </div>
                    </li>
                  ))}
                </ul>
                {matched.length > 6 && (
                  <p className="mt-2 text-xs text-muted">
                    +{matched.length - 6} more suppliers will be notified.
                  </p>
                )}
              </div>
            </div>
          )}
        </>
      )}
    </Modal>
  );
}
