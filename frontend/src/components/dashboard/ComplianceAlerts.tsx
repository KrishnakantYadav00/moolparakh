import { ShieldCheck } from 'lucide-react';
import type { Vendor } from '@/types';
import { Button, Card, EmptyState, ExpiryBadge } from '@/components/ui/Primitives';
import { attentionRows, certificateRows } from '@/utils/compliance';
import { formatDate } from '@/utils/format';

interface ComplianceAlertsProps {
  vendors: Vendor[];
  onOpenCompliance: () => void;
  onOpenVendor: (vendorId: string) => void;
}

export function ComplianceAlerts({
  vendors,
  onOpenCompliance,
  onOpenVendor,
}: ComplianceAlertsProps) {
  const rows = attentionRows(certificateRows(vendors)).slice(0, 6);

  return (
    <Card
      title="Compliance Alerts"
      subtitle="Certificates due within 60 days, and those already expired."
      action={
        <Button size="sm" variant="ghost" onClick={onOpenCompliance}>
          View calendar
        </Button>
      }
      bodyClassName="p-0"
    >
      {rows.length === 0 ? (
        <EmptyState
          icon={<ShieldCheck size={18} />}
          title="Nothing expiring soon"
          description="No vendor certificate expires in the next 60 days."
        />
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full min-w-[520px] text-base">
            <thead className="border-b border-hairline bg-canvas/50 text-left">
              <tr>
                <th className="table-header-cell">Vendor</th>
                <th className="table-header-cell">Document</th>
                <th className="table-header-cell">Expiry</th>
                <th className="table-header-cell text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-hairline">
              {rows.map((row) => (
                <tr
                  key={row.certificate.id}
                  className="cursor-pointer transition-colors duration-150 hover:bg-canvas/70"
                  onClick={() => onOpenVendor(row.vendor.id)}
                >
                  <td className="table-cell font-medium text-navy">{row.vendor.name}</td>
                  <td className="table-cell text-muted">{row.certificate.type}</td>
                  <td className="table-cell text-muted tnum">
                    {formatDate(row.certificate.expiresOn)}
                  </td>
                  <td className="table-cell text-right">
                    <ExpiryBadge bucket={row.bucket} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}
