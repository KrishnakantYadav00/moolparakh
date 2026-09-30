import { useEffect, useRef, useState } from 'react';
import { Check, FileUp, Loader2, ShieldCheck } from 'lucide-react';
import type { CertificateType, TrustComponents, Vendor } from '@/types';
import { Badge, Button, ErrorState, MeterBar } from '@/components/ui/Primitives';
import { Modal } from '@/components/ui/Overlays';
import { TrustRing } from '@/components/ui/TrustVisuals';
import { TRUST_LABELS, trustBreakdown } from '@/utils/trustScore';
import { DEMO_NOW } from '@/utils/format';

const GSTIN_PATTERN = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]Z[0-9A-Z]$/i;

type VerifyState = 'idle' | 'verifying' | 'verified' | 'error';
type DocState = 'empty' | 'Uploading' | 'Processing' | 'Extracting fields' | 'Verified';

const DOCUMENTS: { type: CertificateType; extracted: [string, string][] }[] = [
  {
    type: 'GST Certificate',
    extracted: [
      ['Registration type', 'Regular'],
      ['Valid from', '01 Apr 2026'],
    ],
  },
  {
    type: 'Udyam Certificate',
    extracted: [
      ['Enterprise type', 'Small'],
      ['Registered on', '12 Mar 2024'],
    ],
  },
  {
    type: 'ISO / Quality Certificate',
    extracted: [
      ['Standard', 'ISO 9001:2015'],
      ['Expiry', '18 Feb 2029'],
    ],
  },
  {
    type: 'Insurance Document',
    extracted: [
      ['Cover', '₹50,00,000'],
      ['Expiry', '31 Mar 2027'],
    ],
  },
];

const NEW_VENDOR_TRUST: TrustComponents = {
  verificationCompleteness: 38,
  certificationFreshness: 34,
  accountAgeActivity: 12,
  manualBuyerFlag: 8,
};

interface AddVendorWizardProps {
  open: boolean;
  onClose: () => void;
  onCreate: (vendor: Vendor) => void;
}

export function AddVendorWizard({ open, onClose, onCreate }: AddVendorWizardProps) {
  const [step, setStep] = useState(1);
  const [form, setForm] = useState({ name: '', gstin: '', pan: '', cin: '' });
  const [verifyState, setVerifyState] = useState<VerifyState>('idle');
  const [docs, setDocs] = useState<Record<string, DocState>>({});
  const [submitting, setSubmitting] = useState(false);
  const timers = useRef<number[]>([]);

  useEffect(() => {
    if (open) return;
    // Reset when the dialog closes so the next onboarding starts clean.
    setStep(1);
    setForm({ name: '', gstin: '', pan: '', cin: '' });
    setVerifyState('idle');
    setDocs({});
    setSubmitting(false);
  }, [open]);

  useEffect(
    () => () => {
      timers.current.forEach((id) => window.clearTimeout(id));
    },
    [],
  );

  const schedule = (fn: () => void, delay: number) => {
    timers.current.push(window.setTimeout(fn, delay));
  };

  const startVerification = () => {
    if (!GSTIN_PATTERN.test(form.gstin.trim())) {
      setVerifyState('error');
      return;
    }
    setVerifyState('verifying');
    schedule(() => setVerifyState('verified'), 1500);
  };

  const uploadDocument = (type: string) => {
    setDocs((prev) => ({ ...prev, [type]: 'Uploading' }));
    schedule(() => setDocs((prev) => ({ ...prev, [type]: 'Processing' })), 650);
    schedule(() => setDocs((prev) => ({ ...prev, [type]: 'Extracting fields' })), 1350);
    schedule(() => setDocs((prev) => ({ ...prev, [type]: 'Verified' })), 2200);
  };

  const verifiedDocs = DOCUMENTS.filter((doc) => docs[doc.type] === 'Verified').length;

  const createVendor = () => {
    setSubmitting(true);
    schedule(() => {
      const id = `v-new-${Date.now()}`;
      const today = DEMO_NOW.toISOString().slice(0, 10);
      const vendor: Vendor = {
        id,
        name: form.name.trim() || 'New Vendor Pvt. Ltd.',
        gstin: form.gstin.trim().toUpperCase(),
        pan: form.pan.trim().toUpperCase() || form.gstin.slice(2, 12).toUpperCase(),
        cin: form.cin.trim().toUpperCase() || 'Not provided',
        udyamNumber: 'UDYAM-XX-00-0000000',
        msmeCategory: 'Small',
        city: 'Pune',
        state: 'Maharashtra',
        categories: ['Newly onboarded'],
        contactName: 'Primary contact',
        contactRole: 'Authorised signatory',
        onboardedOn: today,
        lastVerifiedDays: 0,
        status: 'Verified',
        risk: 'LOW',
        trust: NEW_VENDOR_TRUST,
        trustScore: 92,
        trustHistory: Array.from({ length: 30 }, (_, index) => ({
          date: new Date(DEMO_NOW.getTime() - (29 - index) * 86_400_000)
            .toISOString()
            .slice(0, 10),
          score: 92,
        })),
        verification: {
          gstin: 'Verified',
          pan: 'Verified',
          udyam: 'Verified',
          cin: 'Verified',
        },
        certificates: [
          {
            id: `${id}-c0`,
            vendorId: id,
            type: 'GST Certificate',
            number: 'GST/2026/00001',
            issuedOn: today,
            expiresOn: '2027-03-31',
          },
          {
            id: `${id}-c1`,
            vendorId: id,
            type: 'Udyam Certificate',
            number: 'UDY/2026/00001',
            issuedOn: today,
            expiresOn: '2029-03-11',
          },
        ],
        events: [
          {
            id: `${id}-ev0`,
            at: today,
            kind: 'verification',
            title: 'Vendor onboarded',
            detail: 'GSTIN, PAN, Udyam and CIN checks completed through the KYB service.',
          },
        ],
        delivery: {
          onTimePercent: 0,
          ordersLast12Months: 0,
          lateBuckets: { '0–2 days': 0, '3–5 days': 0, '6–10 days': 0, '10+ days': 0 },
        },
        buyerFlagNote: 'No manual adjustment recorded.',
      };
      onCreate(vendor);
      onClose();
    }, 900);
  };

  const stepTitles = ['Vendor Identity', 'Compliance Documents', 'Verification Summary'];

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Add Vendor"
      description={`Step ${step} of 3 — ${stepTitles[step - 1]}`}
      width="max-w-2xl"
      footer={
        <>
          {step > 1 && (
            <Button variant="ghost" onClick={() => setStep((s) => s - 1)}>
              Back
            </Button>
          )}
          {step === 1 && (
            <Button
              variant="primary"
              disabled={verifyState !== 'verified'}
              onClick={() => setStep(2)}
            >
              Continue
            </Button>
          )}
          {step === 2 && (
            <Button variant="primary" disabled={verifiedDocs === 0} onClick={() => setStep(3)}>
              Continue
            </Button>
          )}
          {step === 3 && (
            <Button
              variant="primary"
              onClick={createVendor}
              disabled={submitting}
              icon={submitting ? <Loader2 size={15} className="animate-spin" /> : undefined}
            >
              {submitting ? 'Adding vendor...' : 'Add Vendor'}
            </Button>
          )}
        </>
      }
    >
      <ol className="mb-5 flex items-center gap-2" aria-label="Onboarding progress">
        {stepTitles.map((title, index) => {
          const number = index + 1;
          const state = number < step ? 'done' : number === step ? 'current' : 'todo';
          return (
            <li key={title} className="flex flex-1 items-center gap-2">
              <span
                className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-2xs font-semibold
                  ${
                    state === 'done'
                      ? 'bg-teal text-white'
                      : state === 'current'
                        ? 'bg-teal-soft text-teal ring-1 ring-teal/40'
                        : 'bg-canvas text-muted ring-1 ring-hairline'
                  }`}
              >
                {state === 'done' ? <Check size={13} /> : number}
              </span>
              <span
                className={`hidden text-sm sm:block ${state === 'todo' ? 'text-muted' : 'text-navy font-medium'}`}
              >
                {title}
              </span>
              {number < 3 && <span className="h-px flex-1 bg-hairline" aria-hidden="true" />}
            </li>
          );
        })}
      </ol>

      {step === 1 && (
        <div>
          {verifyState === 'error' ? (
            <ErrorState
              title="Verification unavailable"
              description="We couldn't reach the verification service, or the GSTIN format is invalid. Check the number and try again."
              onRetry={() => setVerifyState('idle')}
            />
          ) : (
            <>
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="sm:col-span-2">
                  <label className="field-label" htmlFor="vendor-name">
                    Vendor Legal Name
                  </label>
                  <input
                    id="vendor-name"
                    data-autofocus
                    className="field-input"
                    value={form.name}
                    placeholder="Registered name as on the GST certificate"
                    onChange={(event) => setForm({ ...form, name: event.target.value })}
                  />
                </div>
                <div>
                  <label className="field-label" htmlFor="vendor-gstin">
                    GSTIN
                  </label>
                  <input
                    id="vendor-gstin"
                    className="field-input font-mono uppercase"
                    value={form.gstin}
                    placeholder="27ABCDE1234F1Z5"
                    onChange={(event) => setForm({ ...form, gstin: event.target.value })}
                  />
                </div>
                <div>
                  <label className="field-label" htmlFor="vendor-pan">
                    PAN
                  </label>
                  <input
                    id="vendor-pan"
                    className="field-input font-mono uppercase"
                    value={form.pan}
                    placeholder="ABCDE1234F"
                    onChange={(event) => setForm({ ...form, pan: event.target.value })}
                  />
                </div>
                <div className="sm:col-span-2">
                  <label className="field-label" htmlFor="vendor-cin">
                    CIN
                  </label>
                  <input
                    id="vendor-cin"
                    className="field-input font-mono uppercase"
                    value={form.cin}
                    placeholder="U28910MH2011PTC221408"
                    onChange={(event) => setForm({ ...form, cin: event.target.value })}
                  />
                </div>
              </div>

              <div className="mt-4 flex items-center gap-3">
                <Button
                  variant="primary"
                  onClick={startVerification}
                  disabled={verifyState === 'verifying'}
                  icon={
                    verifyState === 'verifying' ? (
                      <Loader2 size={15} className="animate-spin" />
                    ) : (
                      <ShieldCheck size={15} />
                    )
                  }
                >
                  {verifyState === 'verifying' ? 'Verifying GSTIN...' : 'Verify Vendor'}
                </Button>
                {verifyState === 'idle' && (
                  <p className="text-xs text-muted">
                    Checks GSTIN status, PAN linkage, Udyam category and CIN against the KYB service.
                  </p>
                )}
              </div>

              {verifyState === 'verified' && (
                <div className="mt-4 rounded-md border border-teal/25 bg-teal-soft/50 p-4 animate-fadeIn">
                  <div className="flex items-center gap-2">
                    <Check size={16} className="text-teal" />
                    <p className="text-base font-semibold text-navy">GSTIN Verified</p>
                    <Badge tone="good">Active</Badge>
                  </div>
                  <dl className="mt-3 grid gap-x-6 gap-y-2 sm:grid-cols-2">
                    {[
                      ['GSTIN status', 'Active'],
                      ['PAN linkage', 'Matched'],
                      ['Udyam category', 'Small'],
                      ['CIN status', 'Active'],
                    ].map(([label, value]) => (
                      <div key={label} className="flex items-center justify-between gap-3">
                        <dt className="text-sm text-muted">{label}</dt>
                        <dd className="text-sm font-medium text-navy">{value}</dd>
                      </div>
                    ))}
                  </dl>
                </div>
              )}
            </>
          )}
        </div>
      )}

      {step === 2 && (
        <div className="space-y-3">
          <p className="text-sm text-muted">
            Upload each document once. Fields are extracted automatically and used for certification
            freshness scoring.
          </p>
          {DOCUMENTS.map((doc) => {
            const state = docs[doc.type] ?? 'empty';
            const progress =
              state === 'Uploading'
                ? 25
                : state === 'Processing'
                  ? 55
                  : state === 'Extracting fields'
                    ? 80
                    : state === 'Verified'
                      ? 100
                      : 0;
            return (
              <div key={doc.type} className="rounded-md border border-hairline p-3.5">
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2.5">
                    <span
                      className={`flex h-8 w-8 items-center justify-center rounded-md
                        ${state === 'Verified' ? 'bg-teal-soft text-teal' : 'bg-canvas text-muted'}`}
                    >
                      {state === 'Verified' ? <Check size={16} /> : <FileUp size={16} />}
                    </span>
                    <div>
                      <p className="text-base font-medium text-navy">{doc.type}</p>
                      <p className="text-xs text-muted">
                        {state === 'empty' ? 'PDF or image, up to 10 MB' : state}
                      </p>
                    </div>
                  </div>
                  <Button
                    size="sm"
                    variant={state === 'Verified' ? 'ghost' : 'secondary'}
                    onClick={() => uploadDocument(doc.type)}
                    disabled={state !== 'empty' && state !== 'Verified'}
                  >
                    {state === 'Verified' ? 'Replace' : 'Upload'}
                  </Button>
                </div>

                {state !== 'empty' && (
                  <div className="mt-3">
                    <MeterBar value={progress} max={100} height={4} />
                  </div>
                )}

                {state === 'Verified' && (
                  <dl className="mt-3 flex flex-wrap gap-x-6 gap-y-1 border-t border-hairline pt-2.5 animate-fadeIn">
                    {doc.extracted.map(([label, value]) => (
                      <div key={label} className="flex items-center gap-1.5">
                        <dt className="text-xs text-muted">{label}</dt>
                        <dd className="text-xs font-medium text-navy">{value}</dd>
                      </div>
                    ))}
                  </dl>
                )}
              </div>
            );
          })}
        </div>
      )}

      {step === 3 && (
        <div className="grid gap-5 sm:grid-cols-[auto,1fr] sm:items-start">
          <div className="flex justify-center">
            <TrustRing components={NEW_VENDOR_TRUST} size={150} stroke={13} />
          </div>
          <div>
            <h3 className="text-base font-semibold text-navy">Vendor Verification</h3>
            <ul className="mt-2 space-y-1.5">
              {[
                'GSTIN verified',
                'PAN linked',
                'Udyam verified',
                'CIN active',
                `Documents processed (${verifiedDocs} of ${DOCUMENTS.length})`,
              ].map((line) => (
                <li key={line} className="flex items-center gap-2 text-base text-navy">
                  <Check size={15} className="text-teal shrink-0" />
                  {line}
                </li>
              ))}
            </ul>

            <h3 className="mt-4 text-base font-semibold text-navy">Vendor Trust Score</h3>
            <ul className="mt-2 space-y-2">
              {trustBreakdown(NEW_VENDOR_TRUST).map((row) => (
                <li key={row.key}>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">{TRUST_LABELS[row.key]}</span>
                    <span className="font-semibold text-navy tnum">
                      {row.earned} / {row.max}
                    </span>
                  </div>
                  <div className="mt-1">
                    <MeterBar value={row.earned} max={row.max} height={4} />
                  </div>
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}
    </Modal>
  );
}
