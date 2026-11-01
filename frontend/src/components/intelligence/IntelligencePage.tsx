import { useEffect, useState } from 'react';
import { RefreshCw, Globe, CheckCircle2 } from 'lucide-react';
import type { Vendor, DisruptionEvent } from '@/types';
import { Button } from '@/components/ui/Primitives';
import { RiskLeaderboard } from '@/components/intelligence/RiskLeaderboard';
import { DisruptionHeatmap } from '@/components/intelligence/DisruptionHeatmap';
import {
  LateDeliveryHistogram,
  SupplierTrustTrends,
} from '@/components/intelligence/IntelligenceCharts';
import { DisruptionFeed } from '@/components/intelligence/DisruptionFeed';
import { api } from '@/lib/api';
import { mapDisruptionEvent } from '@/lib/mappers';

export function IntelligencePage({
  vendors,
  onSelectVendor,
}: {
  vendors: Vendor[];
  onSelectVendor: (vendorId: string) => void;
}) {
  const [minutesSinceUpdate, setMinutesSinceUpdate] = useState(0);
  const [refreshing, setRefreshing] = useState(false);
  const [syncingGdelt, setSyncingGdelt] = useState(false);
  const [syncStatus, setSyncStatus] = useState<string | null>(null);
  const [disruptionEvents, setDisruptionEvents] = useState<DisruptionEvent[]>([]);

  // ─── Load disruption events from backend ────────────────────────────────
  const loadEvents = () => {
    api.intelligence.events()
      .then((data) => {
        setDisruptionEvents(data.map(mapDisruptionEvent));
        setMinutesSinceUpdate(0);
      })
      .catch((err) => console.error('Failed to load disruption events:', err));
  };

  useEffect(() => {
    loadEvents();
  }, []);

  useEffect(() => {
    const timer = window.setInterval(
      () => setMinutesSinceUpdate((minutes) => minutes + 1),
      60_000,
    );
    return () => window.clearInterval(timer);
  }, []);

  const refresh = () => {
    setRefreshing(true);
    loadEvents();
    window.setTimeout(() => setRefreshing(false), 900);
  };

  const handleSyncGdelt = async () => {
    setSyncingGdelt(true);
    setSyncStatus(null);
    try {
      const res = await api.intelligence.syncGdelt();
      loadEvents();
      setSyncStatus(`Synced: ${res.ingested} new events, ${res.affectedVendorsMatched} suppliers linked`);
      window.setTimeout(() => setSyncStatus(null), 5000);
    } catch (err) {
      console.error('Failed to sync GDELT:', err);
    } finally {
      setSyncingGdelt(false);
    }
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-navy">Supplier Intelligence</h2>
          <p className="mt-0.5 text-base text-muted">
            Real-time visibility into supplier disruption and risk via GDELT & live KYB signals.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {syncStatus && (
            <div className="flex items-center gap-1.5 rounded-md bg-teal-soft px-2.5 py-1 text-xs text-navy border border-teal/30">
              <CheckCircle2 size={13} className="text-teal" />
              <span>{syncStatus}</span>
            </div>
          )}

          <div className="flex items-center gap-2 rounded-md border border-hairline bg-surface px-2.5 py-1.5">
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-teal opacity-60" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-teal" />
            </span>
            <span className="text-2xs font-semibold tracking-wide text-teal">LIVE</span>
            <span className="text-xs text-muted">
              {refreshing
                ? 'Refreshing feed...'
                : minutesSinceUpdate === 0
                  ? 'Updated just now'
                  : `Last updated ${minutesSinceUpdate} min ago`}
            </span>
          </div>

          <Button
            size="sm"
            variant="secondary"
            onClick={handleSyncGdelt}
            disabled={syncingGdelt}
            icon={<Globe size={14} className={syncingGdelt ? 'animate-spin' : ''} />}
          >
            {syncingGdelt ? 'Syncing GDELT...' : 'Sync GDELT Feed'}
          </Button>

          <Button
            size="sm"
            variant="secondary"
            onClick={refresh}
            disabled={refreshing}
            icon={<RefreshCw size={14} className={refreshing ? 'animate-spin' : ''} />}
          >
            Refresh
          </Button>
        </div>
      </div>

      <div className="grid gap-4 xl:grid-cols-[1fr,340px] xl:items-start">
        <div className="space-y-4">
          <RiskLeaderboard
            vendors={vendors}
            disruptionEvents={disruptionEvents}
            onSelectVendor={onSelectVendor}
          />
          <DisruptionHeatmap />
          <div className="grid gap-4 lg:grid-cols-2">
            <LateDeliveryHistogram vendors={vendors} />
            <SupplierTrustTrends vendors={vendors} />
          </div>
        </div>

        <DisruptionFeed events={disruptionEvents} onSelectVendor={onSelectVendor} />
      </div>
    </div>
  );
}
