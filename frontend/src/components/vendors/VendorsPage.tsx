import { useMemo, useState } from 'react';
import { Building2, ChevronRight, Plus, Search } from 'lucide-react';
import type { Vendor } from '@/types';
import {
  Badge,
  Button,
  EmptyState,
  SegmentedControl,
} from '@/components/ui/Primitives';
import { TrustCell, TrustMeter } from '@/components/ui/TrustVisuals';
import { complianceTone, vendorComplianceState } from '@/utils/compliance';
import { relativeDays } from '@/utils/format';
import { trustBand, trustBandColor } from '@/utils/trustScore';

const FILTERS = ['All', 'Verified', 'Needs Review', 'High Risk', 'Expired'] as const;
type Filter = (typeof FILTERS)[number];

function matchesFilter(vendor: Vendor, filter: Filter): boolean {
  switch (filter) {
    case 'All':
      return true;
    case 'Verified':
      return vendor.status === 'Verified';
    case 'Needs Review':
      return vendor.status === 'Review';
    case 'High Risk':
      return vendor.status === 'High Risk';
    case 'Expired':
      return vendorComplianceState(vendor) === 'Expired';
  }
}

const statusTone = {
  Verified: 'good',
  Review: 'high',
  'High Risk': 'critical',
} as const;

interface VendorsPageProps {
  vendors: Vendor[];
  onOpenVendor: (vendorId: string) => void;
  onAddVendor: () => void;
}

export function VendorsPage({ vendors, onOpenVendor, onAddVendor }: VendorsPageProps) {
  const [filter, setFilter] = useState<Filter>('All');
  const [query, setQuery] = useState('');

  const counts = useMemo(() => {
    const result: Partial<Record<Filter, number>> = {};
    FILTERS.forEach((f) => {
      result[f] = vendors.filter((vendor) => matchesFilter(vendor, f)).length;
    });
    return result;
  }, [vendors]);

  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return vendors.filter((vendor) => {
      if (!matchesFilter(vendor, filter)) return false;
      if (!needle) return true;
      return (
        vendor.name.toLowerCase().includes(needle) ||
        vendor.gstin.toLowerCase().includes(needle) ||
        vendor.city.toLowerCase().includes(needle) ||
        vendor.categories.some((category) => category.toLowerCase().includes(needle))
      );
    });
  }, [vendors, filter, query]);

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-navy">Vendors</h2>
          <p className="mt-0.5 text-base text-muted">
            Manage verification, trust and compliance across your supplier network.
          </p>
        </div>
        <Button variant="primary" icon={<Plus size={16} />} onClick={onAddVendor}>
          Add Vendor
        </Button>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <div className="relative min-w-[220px] flex-1 max-w-sm">
          <Search
            size={15}
            className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-muted"
          />
          <input
            type="search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Search vendors..."
            aria-label="Search vendors"
            className="field-input pl-9"
          />
        </div>
        <SegmentedControl
          label="Filter vendors"
          options={FILTERS}
          value={filter}
          onChange={setFilter}
          counts={counts}
        />
      </div>

      {filtered.length === 0 ? (
        <div className="surface-card">
          <EmptyState
            icon={<Building2 size={18} />}
            title="No vendors match this view"
            description="Adjust the search term or filter, or onboard a new supplier."
            action={
              <Button variant="primary" icon={<Plus size={16} />} onClick={onAddVendor}>
                Add Vendor
              </Button>
            }
          />
        </div>
      ) : (
        <>
          {/* Desktop table */}
          <div className="surface-card hidden overflow-x-auto md:block">
            <table className="w-full min-w-[980px] text-base">
              <thead className="border-b border-hairline bg-canvas/50 text-left">
                <tr>
                  <th className="table-header-cell">Vendor</th>
                  <th className="table-header-cell">GSTIN</th>
                  <th className="table-header-cell">MSME Category</th>
                  <th className="table-header-cell">Trust Score</th>
                  <th className="table-header-cell">Compliance</th>
                  <th className="table-header-cell">Last Verified</th>
                  <th className="table-header-cell">Status</th>
                  <th className="table-header-cell text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-hairline">
                {filtered.map((vendor) => {
                  const compliance = vendorComplianceState(vendor);
                  return (
                    <tr
                      key={vendor.id}
                      className="cursor-pointer transition-colors duration-150 hover:bg-canvas/70"
                      onClick={() => onOpenVendor(vendor.id)}
                    >
                      <td className="table-cell">
                        <p className="font-medium text-navy">{vendor.name}</p>
                        <p className="text-xs text-muted">
                          {vendor.city}, {vendor.state}
                        </p>
                      </td>
                      <td className="table-cell font-mono text-sm text-muted">{vendor.gstin}</td>
                      <td className="table-cell text-muted">{vendor.msmeCategory}</td>
                      <td className="table-cell">
                        <TrustCell components={vendor.trust} />
                      </td>
                      <td className="table-cell">
                        <Badge tone={complianceTone(compliance)}>{compliance}</Badge>
                      </td>
                      <td className="table-cell text-muted">
                        {relativeDays(vendor.lastVerifiedDays)}
                      </td>
                      <td className="table-cell">
                        <Badge tone={statusTone[vendor.status]}>{vendor.status}</Badge>
                      </td>
                      <td className="table-cell text-right">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={(event) => {
                            event.stopPropagation();
                            onOpenVendor(vendor.id);
                          }}
                        >
                          View
                          <ChevronRight size={14} />
                        </Button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Mobile cards */}
          <ul className="space-y-3 md:hidden">
            {filtered.map((vendor) => {
              const compliance = vendorComplianceState(vendor);
              const band = trustBand(vendor.trustScore);
              return (
                <li key={vendor.id}>
                  <button
                    type="button"
                    onClick={() => onOpenVendor(vendor.id)}
                    className="surface-card w-full p-4 text-left transition-colors duration-150 hover:border-teal/40"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <p className="truncate font-medium text-navy">{vendor.name}</p>
                        <p className="font-mono text-xs text-muted">{vendor.gstin}</p>
                      </div>
                      <div className="text-right">
                        <span className="text-xl font-semibold text-navy tnum">
                          {vendor.trustScore}
                        </span>
                        <span
                          className="block text-2xs font-medium"
                          style={{ color: trustBandColor(band) }}
                        >
                          {band}
                        </span>
                      </div>
                    </div>
                    <div className="mt-2.5">
                      <TrustMeter components={vendor.trust} width={140} />
                    </div>
                    <div className="mt-3 flex flex-wrap items-center gap-2">
                      <Badge tone={statusTone[vendor.status]}>{vendor.status}</Badge>
                      <Badge tone={complianceTone(compliance)}>{compliance}</Badge>
                      <span className="text-xs text-muted">
                        {vendor.msmeCategory} · verified {relativeDays(vendor.lastVerifiedDays)}
                      </span>
                    </div>
                  </button>
                </li>
              );
            })}
          </ul>
        </>
      )}
    </div>
  );
}
