import { TriangleAlert } from 'lucide-react';
import type { SupplierRelationship } from '@/types';
import { Button } from '@/components/ui/Primitives';
import { Modal } from '@/components/ui/Overlays';

export function RelationshipModal({
  relationship,
  onClose,
}: {
  relationship: SupplierRelationship | null;
  onClose: () => void;
}) {
  if (!relationship) return null;

  return (
    <Modal
      open
      onClose={onClose}
      title="Potential Supplier Relationship"
      description="Detected by matching registration details across bidders."
      footer={
        <Button variant="secondary" onClick={onClose}>
          Close
        </Button>
      }
    >
      <div className="flex items-start gap-3 rounded-md border border-risk-medium/30 bg-risk-medium-bg px-3.5 py-3">
        <TriangleAlert size={17} className="mt-0.5 shrink-0 text-risk-medium" />
        <p className="text-sm text-navy">
          These suppliers share a registration attribute. Bids from related suppliers may not be
          independent. Review before awarding.
        </p>
      </div>

      <dl className="mt-4 space-y-3">
        <div>
          <dt className="text-xs text-muted">{relationship.type}</dt>
          <dd className="text-md font-semibold text-navy">{relationship.value}</dd>
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          <div className="rounded-md border border-hairline p-3">
            <dt className="text-xs text-muted">Supplier A</dt>
            <dd className="text-base font-medium text-navy">
              {relationship.vendorAId}
            </dd>
          </div>
          <div className="rounded-md border border-hairline p-3">
            <dt className="text-xs text-muted">Supplier B</dt>
            <dd className="text-base font-medium text-navy">
              {relationship.vendorBId}
            </dd>
          </div>
        </div>
      </dl>
    </Modal>
  );
}
