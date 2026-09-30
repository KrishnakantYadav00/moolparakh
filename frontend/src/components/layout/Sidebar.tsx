import {
  Activity,
  Bell,
  Building2,
  FileText,
  LayoutDashboard,
  Settings,
  ShieldCheck,
} from 'lucide-react';
import type { ViewKey } from '@/types';
import { organisation } from '@/lib/constants';

interface NavItem {
  key: ViewKey;
  label: string;
  icon: typeof LayoutDashboard;
}

const primaryNav: NavItem[] = [
  { key: 'overview', label: 'Overview', icon: LayoutDashboard },
  { key: 'vendors', label: 'Vendors', icon: Building2 },
  { key: 'compliance', label: 'Compliance', icon: ShieldCheck },
  { key: 'intelligence', label: 'Supplier Intelligence', icon: Activity },
  { key: 'rfq', label: 'RFQs & Bids', icon: FileText },
];

const systemNav: NavItem[] = [
  { key: 'notifications', label: 'Notifications', icon: Bell },
  { key: 'settings', label: 'Settings', icon: Settings },
];

/** Root-inspired mark: one node branching into three roots. */
function BrandMark() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <rect x="0.5" y="0.5" width="23" height="23" rx="6" fill="#17324D" />
      <path
        d="M12 5.5v5m0 0c0 2.4-2.2 2.9-2.2 5.2M12 10.5c0 2.4 2.2 2.9 2.2 5.2M12 10.5v6.5"
        stroke="#0F8B8D"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
      <circle cx="12" cy="5.5" r="1.6" fill="#E8F5F4" />
    </svg>
  );
}

interface SidebarProps {
  view: ViewKey;
  onNavigate: (view: ViewKey) => void;
  unreadCount: number;
}

export function Sidebar({ view, onNavigate, unreadCount }: SidebarProps) {
  const renderItem = (item: NavItem) => {
    const Icon = item.icon;
    const active = view === item.key;
    return (
      <li key={item.key}>
        <button
          type="button"
          onClick={() => onNavigate(item.key)}
          aria-current={active ? 'page' : undefined}
          className={`group relative flex w-full items-center gap-2.5 rounded-md px-2.5 py-2 text-base
            font-medium transition-colors duration-150
            ${
              active
                ? 'bg-teal-soft text-teal'
                : 'text-navy/70 hover:bg-teal-soft/60 hover:text-navy'
            }`}
        >
          {active && (
            <span
              className="absolute left-0 top-1.5 bottom-1.5 w-[3px] rounded-r bg-teal"
              aria-hidden="true"
            />
          )}
          <Icon size={17} strokeWidth={active ? 2.1 : 1.8} className="shrink-0" />
          <span className="truncate">{item.label}</span>
          {item.key === 'notifications' && unreadCount > 0 && (
            <span className="ml-auto tnum rounded-full bg-risk-critical px-1.5 py-0.5 text-2xs font-semibold text-white">
              {unreadCount}
            </span>
          )}
        </button>
      </li>
    );
  };

  return (
    <div className="flex h-full flex-col bg-surface border-r border-hairline">
      <div className="px-4 pt-5 pb-4">
        <div className="flex items-center gap-2.5">
          <BrandMark />
          <span className="text-md font-semibold tracking-tight text-navy">MoolParakh</span>
        </div>
        <p className="mt-2 pl-0.5 text-2xs font-semibold uppercase tracking-[0.14em] text-muted">
          Procurement
        </p>
      </div>

      <nav className="flex-1 overflow-y-auto px-2.5" aria-label="Main">
        <ul className="space-y-0.5">{primaryNav.map(renderItem)}</ul>

        <p className="mt-6 mb-1.5 px-2.5 text-2xs font-semibold uppercase tracking-[0.14em] text-muted">
          System
        </p>
        <ul className="space-y-0.5">{systemNav.map(renderItem)}</ul>
      </nav>

      <div className="border-t border-hairline px-4 py-3.5">
        <p className="text-sm font-semibold text-navy truncate">{organisation.name}</p>
        <p className="text-xs text-muted">{organisation.role}</p>
      </div>
    </div>
  );
}
