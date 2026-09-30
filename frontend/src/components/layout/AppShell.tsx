import { useEffect, type ReactNode } from 'react';
import { X } from 'lucide-react';
import type { ViewKey } from '@/types';
import { Sidebar } from '@/components/layout/Sidebar';
import { TopBar } from '@/components/layout/TopBar';

interface AppShellProps {
  view: ViewKey;
  onNavigate: (view: ViewKey) => void;
  title: string;
  subtitle: string;
  unreadCount: number;
  onOpenNotifications: () => void;
  mobileNavOpen: boolean;
  setMobileNavOpen: (open: boolean) => void;
  children: ReactNode;
}

export function AppShell({
  view,
  onNavigate,
  title,
  subtitle,
  unreadCount,
  onOpenNotifications,
  mobileNavOpen,
  setMobileNavOpen,
  children,
}: AppShellProps) {
  useEffect(() => {
    if (!mobileNavOpen) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setMobileNavOpen(false);
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [mobileNavOpen, setMobileNavOpen]);

  return (
    <div className="flex min-h-screen bg-canvas">
      <aside className="hidden w-[264px] shrink-0 lg:block">
        <div className="fixed inset-y-0 left-0 w-[264px]">
          <Sidebar view={view} onNavigate={onNavigate} unreadCount={unreadCount} />
        </div>
      </aside>

      {mobileNavOpen && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div
            className="absolute inset-0 bg-navy-deep/45 animate-fadeIn"
            onClick={() => setMobileNavOpen(false)}
            aria-hidden="true"
          />
          <div className="relative h-full w-[270px] animate-slideInRight">
            <button
              type="button"
              onClick={() => setMobileNavOpen(false)}
              aria-label="Close navigation"
              className="absolute right-2 top-4 z-10 rounded-md p-1.5 text-muted hover:bg-canvas"
            >
              <X size={18} />
            </button>
            <Sidebar
              view={view}
              onNavigate={(next) => {
                onNavigate(next);
                setMobileNavOpen(false);
              }}
              unreadCount={unreadCount}
            />
          </div>
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <TopBar
          title={title}
          subtitle={subtitle}
          unreadCount={unreadCount}
          onOpenNotifications={onOpenNotifications}
          onOpenNav={() => setMobileNavOpen(true)}
        />
        <main className="flex-1 px-4 py-5 sm:px-6 sm:py-6">{children}</main>
      </div>
    </div>
  );
}
