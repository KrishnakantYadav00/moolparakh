import { useEffect, useState } from 'react';
import { AlertTriangle, BadgeCheck, FileText, Gauge } from 'lucide-react';
import type { Rfq, Vendor } from '@/types';
import { KpiCard } from '@/components/dashboard/KpiCard';
import { TrustScoreOverview } from '@/components/dashboard/TrustScoreOverview';
import { ComplianceAlerts } from '@/components/dashboard/ComplianceAlerts';
import { SupplierRiskSnapshot } from '@/components/dashboard/SupplierRiskSnapshot';
import { SkeletonCard, Skeleton } from '@/components/ui/Primitives';
import { certificateRows, complianceSummary } from '@/utils/compliance';
import { averageTrust } from '@/utils/trustScore';
import { kpiTrends } from '@/lib/constants';

interface OverviewPageProps {
  vendors: Vendor[];
  rfqs: Rfq[];
  onNavigate: (view: 'vendors' | 'compliance' | 'intelligence' | 'rfq') => void;
  onOpenVendor: (vendorId: string) => void;
}

export function OverviewPage({ vendors, rfqs, onNavigate, onOpenVendor }: OverviewPageProps) {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const timer = window.setTimeout(() => setLoading(false), 550);
    return () => window.clearTimeout(timer);
  }, []);

  const verifiedCount = vendors.filter((vendor) => vendor.status === 'Verified').length;
  const summary = complianceSummary(certificateRows(vendors));
  const openRfqs = rfqs.filter((rfq) => rfq.status === 'OPEN');
  const closingThisWeek = openRfqs.filter((rfq) => rfq.closesInHours <= 168).length;

  return (
    <div className="space-y-5">
      <div>
        <h2 className="text-2xl font-semibold tracking-tight text-navy">
          Good morning, Procurement Team
        </h2>
        <p className="mt-0.5 text-base text-muted">Your supplier network at a glance.</p>
      </div>

      {loading ? (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <SkeletonCard />
          <SkeletonCard />
          <SkeletonCard />
          <SkeletonCard />
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <KpiCard
            label="Verified Vendors"
            value={String(verifiedCount)}
            subtitle="vendors verified"
            delta={{ value: `${kpiTrends.verifiedVendorsChangePercent}%`, direction: 'up' }}
            accent="teal"
            icon={<BadgeCheck size={15} />}
            onClick={() => onNavigate('vendors')}
          />
          <KpiCard
            label="Average Trust Score"
            value={averageTrust(vendors).toFixed(1)}
            subtitle="across the active network"
            delta={{ value: `${kpiTrends.averageTrustChange} this month`, direction: 'up' }}
            accent="teal"
            icon={<Gauge size={15} />}
            onClick={() => onNavigate('vendors')}
          />
          <KpiCard
            label="Compliance At Risk"
            value={String(summary.attention)}
            subtitle="certifications need attention"
            accent="warning"
            icon={<AlertTriangle size={15} />}
            onClick={() => onNavigate('compliance')}
          />
          <KpiCard
            label="Active RFQs"
            value={String(openRfqs.length)}
            subtitle={`${closingThisWeek} closing this week`}
            icon={<FileText size={15} />}
            onClick={() => onNavigate('rfq')}
          />
        </div>
      )}

      {loading ? (
        <div className="grid gap-4 xl:grid-cols-3">
          <div className="surface-card p-5 xl:col-span-2 space-y-3">
            <Skeleton className="h-3 w-40" />
            <Skeleton className="h-[220px] w-full" />
          </div>
          <div className="surface-card p-5 space-y-3">
            <Skeleton className="h-3 w-32" />
            <Skeleton className="h-[220px] w-full" />
          </div>
        </div>
      ) : (
        <>
          <div className="grid gap-4 xl:grid-cols-3">
            <div className="xl:col-span-2">
              <TrustScoreOverview vendors={vendors} />
            </div>
            <SupplierRiskSnapshot
              vendors={vendors}
              onOpenIntelligence={() => onNavigate('intelligence')}
            />
          </div>

          <ComplianceAlerts
            vendors={vendors}
            onOpenCompliance={() => onNavigate('compliance')}
            onOpenVendor={onOpenVendor}
          />
        </>
      )}
    </div>
  );
}
