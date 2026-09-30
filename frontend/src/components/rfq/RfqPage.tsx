import { useState } from 'react';
import { ChevronRight, FileText, Plus } from 'lucide-react';
import type { Rfq, RfqStatus } from '@/types';
import { Badge, Button, EmptyState, SegmentedControl } from '@/components/ui/Primitives';
import { formatDate, formatHoursRemaining } from '@/utils/format';

const VIEWS = ['Open RFQs', 'Drafts', 'Completed'] as const;
type View = (typeof VIEWS)[number];

const viewStatus: Record<View, RfqStatus> = {
  'Open RFQs': 'OPEN',
  Drafts: 'DRAFT',
  Completed: 'COMPLETED',
};

const statusTone = {
  OPEN: 'teal',
  DRAFT: 'neutral',
  COMPLETED: 'good',
} as const;

export function RfqPage({
  rfqs,
  onOpenRfq,
  onCreateRfq,
}: {
  rfqs: Rfq[];
  onOpenRfq: (rfqId: string) => void;
  onCreateRfq: () => void;
}) {
  const [view, setView] = useState<View>('Open RFQs');
  const filtered = rfqs.filter((rfq) => rfq.status === viewStatus[view]);

  const counts = {
    'Open RFQs': rfqs.filter((rfq) => rfq.status === 'OPEN').length,
    Drafts: rfqs.filter((rfq) => rfq.status === 'DRAFT').length,
    Completed: rfqs.filter((rfq) => rfq.status === 'COMPLETED').length,
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-navy">RFQs &amp; Bids</h2>
          <p className="mt-0.5 text-base text-muted">
            Collect quotes, compare bids on price, delivery and trust, then award.
          </p>
        </div>
        <Button variant="primary" icon={<Plus size={16} />} onClick={onCreateRfq}>
          Create RFQ
        </Button>
      </div>

      <SegmentedControl
        label="RFQ status"
        options={VIEWS}
        value={view}
        onChange={setView}
        counts={counts}
      />

      {filtered.length === 0 ? (
        <div className="surface-card">
          <EmptyState
            icon={<FileText size={18} />}
            title={view === 'Open RFQs' ? 'No active RFQs' : `No ${view.toLowerCase()}`}
            description="Create your first RFQ to start collecting supplier bids."
            action={
              <Button variant="primary" icon={<Plus size={16} />} onClick={onCreateRfq}>
                Create RFQ
              </Button>
            }
          />
        </div>
      ) : (
        <>
          <div className="surface-card hidden overflow-x-auto md:block">
            <table className="w-full min-w-[860px] text-base">
              <thead className="border-b border-hairline bg-canvas/50 text-left">
                <tr>
                  <th className="table-header-cell">RFQ</th>
                  <th className="table-header-cell">Item</th>
                  <th className="table-header-cell text-right">Suppliers</th>
                  <th className="table-header-cell text-right">Bids</th>
                  <th className="table-header-cell text-right">Time Remaining</th>
                  <th className="table-header-cell">Status</th>
                  <th className="table-header-cell text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-hairline">
                {filtered.map((rfq) => (
                  <tr
                    key={rfq.id}
                    className="cursor-pointer transition-colors duration-150 hover:bg-canvas/70"
                    onClick={() => onOpenRfq(rfq.id)}
                  >
                    <td className="table-cell">
                      <p className="font-medium text-navy">{rfq.title}</p>
                      <p className="text-xs text-muted">
                        {rfq.reference} · created {formatDate(rfq.createdOn)}
                      </p>
                    </td>
                    <td className="table-cell text-muted">
                      {rfq.spec.quantity} {rfq.spec.unit} · {rfq.spec.grade}
                    </td>
                    <td className="table-cell text-right tnum text-muted">
                      {rfq.suppliersNotified}
                    </td>
                    <td className="table-cell text-right tnum text-navy">{rfq.bids.length}</td>
                    <td className="table-cell text-right text-muted">
                      {rfq.status === 'OPEN' ? formatHoursRemaining(rfq.closesInHours) : '—'}
                    </td>
                    <td className="table-cell">
                      <Badge tone={statusTone[rfq.status]}>{rfq.status}</Badge>
                      {rfq.awardedVendorId && (
                        <p className="mt-1 text-xs text-muted">
                          Awarded to {rfq.awardedVendorId}
                        </p>
                      )}
                    </td>
                    <td className="table-cell text-right">
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={(event) => {
                          event.stopPropagation();
                          onOpenRfq(rfq.id);
                        }}
                      >
                        {rfq.bids.length > 0 ? 'Compare bids' : 'Open'}
                        <ChevronRight size={14} />
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <ul className="space-y-3 md:hidden">
            {filtered.map((rfq) => (
              <li key={rfq.id}>
                <button
                  type="button"
                  onClick={() => onOpenRfq(rfq.id)}
                  className="surface-card w-full p-4 text-left transition-colors duration-150 hover:border-teal/40"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="truncate font-medium text-navy">{rfq.title}</p>
                      <p className="text-xs text-muted">{rfq.reference}</p>
                    </div>
                    <Badge tone={statusTone[rfq.status]}>{rfq.status}</Badge>
                  </div>
                  <div className="mt-2.5 flex flex-wrap gap-x-4 gap-y-1 text-sm text-muted">
                    <span>{rfq.suppliersNotified} suppliers</span>
                    <span className="text-navy font-medium">{rfq.bids.length} bids</span>
                    {rfq.status === 'OPEN' && (
                      <span>{formatHoursRemaining(rfq.closesInHours)}</span>
                    )}
                  </div>
                </button>
              </li>
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
