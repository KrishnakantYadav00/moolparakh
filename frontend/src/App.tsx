import { useEffect, useMemo, useState } from 'react';
import type { AppNotification, Rfq, SupplierRelationship, Vendor, ViewKey } from '@/types';
import { AppShell } from '@/components/layout/AppShell';
import { NotificationDrawer } from '@/components/layout/Notifications';
import { NotificationsPage } from '@/components/layout/NotificationsPage';
import { SettingsPage } from '@/components/layout/SettingsPage';
import { OverviewPage } from '@/components/dashboard/OverviewPage';
import { VendorsPage } from '@/components/vendors/VendorsPage';
import { VendorDetail } from '@/components/vendors/VendorDetail';
import { AddVendorWizard } from '@/components/vendors/AddVendorWizard';
import { RelationshipModal } from '@/components/vendors/RelationshipModal';
import { CompliancePage } from '@/components/compliance/CompliancePage';
import { IntelligencePage } from '@/components/intelligence/IntelligencePage';
import { SupplierDrilldown } from '@/components/intelligence/SupplierDrilldown';
import { RfqPage } from '@/components/rfq/RfqPage';
import { RfqWizard } from '@/components/rfq/RfqWizard';
import { BidComparison } from '@/components/rfq/BidComparison';
import { api } from '@/lib/api';
import { mapVendor, mapRfq, mapNotification } from '@/lib/mappers';

const PAGE_META: Record<ViewKey, { title: string; subtitle: string }> = {
  overview: { title: 'Overview', subtitle: 'Procurement dashboard' },
  vendors: { title: 'Vendors', subtitle: 'Verification, trust and compliance' },
  compliance: { title: 'Compliance', subtitle: 'Certificate expiry tracking' },
  intelligence: {
    title: 'Supplier Intelligence',
    subtitle: 'Real-time supplier risk monitoring',
  },
  rfq: { title: 'RFQs & Bids', subtitle: 'Quote collection and bid evaluation' },
  notifications: { title: 'Notifications', subtitle: 'Alerts across your supplier network' },
  settings: { title: 'Settings', subtitle: 'Organisation and scoring rules' },
};

export default function App() {
  const [view, setView] = useState<ViewKey>('overview');
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [rfqs, setRfqs] = useState<Rfq[]>([]);
  const [notifications, setNotifications] = useState<AppNotification[]>([]);

  // ─── Load real data from backend on mount ──────────────────────────────────
  useEffect(() => {
    api.vendors.list()
      .then(data => setVendors(data.map(mapVendor)))
      .catch(err => console.error('Failed to load vendors:', err));

    api.rfqs.list()
      .then(data => setRfqs(data.map(mapRfq)))
      .catch(err => console.error('Failed to load RFQs:', err));

    api.notifications.list()
      .then(data => setNotifications(data.map(mapNotification)))
      .catch(err => console.error('Failed to load notifications:', err));
  }, []);

  const [selectedVendorId, setSelectedVendorId] = useState<string | null>(null);
  const [drilldownVendorId, setDrilldownVendorId] = useState<string | null>(null);
  const [activeRfqId, setActiveRfqId] = useState<string | null>(null);

  const [addVendorOpen, setAddVendorOpen] = useState(false);
  const [rfqWizardOpen, setRfqWizardOpen] = useState(false);
  const [relationship, setRelationship] = useState<SupplierRelationship | null>(null);
  const [notifOpen, setNotifOpen] = useState(false);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  const unreadCount = notifications.filter((notification) => !notification.read).length;

  const selectedVendor = useMemo(
    () => vendors.find((vendor) => vendor.id === selectedVendorId) ?? null,
    [vendors, selectedVendorId],
  );
  const drilldownVendor = useMemo(
    () => vendors.find((vendor) => vendor.id === drilldownVendorId) ?? null,
    [vendors, drilldownVendorId],
  );
  const activeRfq = useMemo(
    () => rfqs.find((rfq) => rfq.id === activeRfqId) ?? null,
    [rfqs, activeRfqId],
  );

  const navigate = (next: ViewKey) => {
    setView(next);
    setSelectedVendorId(null);
    setDrilldownVendorId(null);
    setActiveRfqId(null);
  };

  const openVendor = (vendorId: string) => {
    setView('vendors');
    setDrilldownVendorId(null);
    setActiveRfqId(null);
    setSelectedVendorId(vendorId);
  };

  const markRead = (id: string) =>
    setNotifications((current) =>
      current.map((notification) =>
        notification.id === id ? { ...notification, read: true } : notification,
      ),
    );

  const markAllRead = () =>
    setNotifications((current) =>
      current.map((notification) => ({ ...notification, read: true })),
    );

  const awardBid = (rfqId: string, vendorId: string) =>
    setRfqs((current) =>
      current.map((rfq) =>
        rfq.id === rfqId
          ? { ...rfq, status: 'COMPLETED', closesInHours: 0, awardedVendorId: vendorId }
          : rfq,
      ),
    );

  const meta = (() => {
    if (view === 'vendors' && selectedVendor) {
      return { title: selectedVendor.name, subtitle: 'Vendor profile' };
    }
    if (view === 'intelligence' && drilldownVendor) {
      return { title: 'Supplier Risk Detail', subtitle: drilldownVendor.name };
    }
    if (view === 'rfq' && activeRfq) {
      return { title: activeRfq.title, subtitle: `Bid comparison · ${activeRfq.reference}` };
    }
    return PAGE_META[view];
  })();

  const renderView = () => {
    switch (view) {
      case 'overview':
        return (
          <OverviewPage
            vendors={vendors}
            rfqs={rfqs}
            onNavigate={navigate}
            onOpenVendor={openVendor}
          />
        );

      case 'vendors':
        return selectedVendor ? (
          <VendorDetail
            vendor={selectedVendor}
            onBack={() => setSelectedVendorId(null)}
            onViewRelationship={() =>
              setRelationship(null)  // relationships loaded per-vendor via API when needed
            }
          />
        ) : (
          <VendorsPage
            vendors={vendors}
            onOpenVendor={setSelectedVendorId}
            onAddVendor={() => setAddVendorOpen(true)}
          />
        );

      case 'compliance':
        return <CompliancePage vendors={vendors} onSelectVendor={openVendor} />;

      case 'intelligence':
        return drilldownVendor ? (
          <SupplierDrilldown
            vendor={drilldownVendor}
            onBack={() => setDrilldownVendorId(null)}
            onOpenProfile={() => openVendor(drilldownVendor.id)}
          />
        ) : (
          <IntelligencePage vendors={vendors} onSelectVendor={setDrilldownVendorId} />
        );

      case 'rfq':
        return activeRfq ? (
          <BidComparison
            rfq={activeRfq}
            onBack={() => setActiveRfqId(null)}
            onAward={awardBid}
          />
        ) : (
          <RfqPage
            rfqs={rfqs}
            onOpenRfq={setActiveRfqId}
            onCreateRfq={() => setRfqWizardOpen(true)}
          />
        );

      case 'notifications':
        return (
          <NotificationsPage
            notifications={notifications}
            onRead={markRead}
            onReadAll={markAllRead}
          />
        );

      case 'settings':
        return <SettingsPage />;
    }
  };

  return (
    <>
      <AppShell
        view={view}
        onNavigate={navigate}
        title={meta.title}
        subtitle={meta.subtitle}
        unreadCount={unreadCount}
        onOpenNotifications={() => setNotifOpen(true)}
        mobileNavOpen={mobileNavOpen}
        setMobileNavOpen={setMobileNavOpen}
      >
        {renderView()}
      </AppShell>

      <AddVendorWizard
        open={addVendorOpen}
        onClose={() => setAddVendorOpen(false)}
        onCreate={(vendor) => {
          setVendors((current) => [vendor, ...current]);
          setSelectedVendorId(vendor.id);
          setView('vendors');
        }}
      />

      <RfqWizard
        open={rfqWizardOpen}
        onClose={() => setRfqWizardOpen(false)}
        vendors={vendors}
        onCreate={(rfq) => setRfqs((current) => [rfq, ...current])}
      />

      <RelationshipModal relationship={relationship} onClose={() => setRelationship(null)} />

      <NotificationDrawer
        open={notifOpen}
        onClose={() => setNotifOpen(false)}
        notifications={notifications}
        onRead={markRead}
        onReadAll={markAllRead}
        onSeeAll={() => navigate('notifications')}
      />
    </>
  );
}
