import { useEffect, useRef, useState } from 'react';
import { Bell, Check, ChevronDown, Menu } from 'lucide-react';
import { organisation } from '@/lib/constants';

interface TopBarProps {
  title: string;
  subtitle: string;
  unreadCount: number;
  onOpenNotifications: () => void;
  onOpenNav: () => void;
}

export function TopBar({
  title,
  subtitle,
  unreadCount,
  onOpenNotifications,
  onOpenNav,
}: TopBarProps) {
  const [orgOpen, setOrgOpen] = useState(false);
  const [plant, setPlant] = useState(organisation.plants[0]);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!orgOpen) return;
    const onClick = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setOrgOpen(false);
      }
    };
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setOrgOpen(false);
    };
    document.addEventListener('mousedown', onClick);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('mousedown', onClick);
      document.removeEventListener('keydown', onKey);
    };
  }, [orgOpen]);

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b border-hairline bg-surface/95 px-4 backdrop-blur sm:px-6">
      <button
        type="button"
        onClick={onOpenNav}
        aria-label="Open navigation"
        className="lg:hidden -ml-1 rounded-md p-2 text-navy hover:bg-canvas transition-colors duration-150"
      >
        <Menu size={20} />
      </button>

      <div className="min-w-0 flex-1">
        <h1 className="truncate text-lg font-semibold text-navy">{title}</h1>
        <p className="truncate text-xs text-muted">{subtitle}</p>
      </div>

      <button
        type="button"
        onClick={onOpenNotifications}
        aria-label={`Notifications, ${unreadCount} unread`}
        className="relative rounded-md p-2 text-navy/80 hover:bg-canvas hover:text-navy transition-colors duration-150"
      >
        <Bell size={18} />
        {unreadCount > 0 && (
          <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-risk-critical ring-2 ring-surface" />
        )}
      </button>

      <div className="relative hidden sm:block" ref={menuRef}>
        <button
          type="button"
          onClick={() => setOrgOpen((open) => !open)}
          aria-haspopup="menu"
          aria-expanded={orgOpen}
          className="flex h-9 items-center gap-2 rounded-md border border-hairline px-3 text-sm
            font-medium text-navy hover:bg-canvas transition-colors duration-150"
        >
          <span className="max-w-[190px] truncate">{plant}</span>
          <ChevronDown size={15} className="text-muted" />
        </button>
        {orgOpen && (
          <div
            role="menu"
            className="absolute right-0 z-40 mt-1.5 w-64 rounded-md border border-hairline bg-surface p-1 shadow-raised animate-scaleIn"
          >
            {organisation.plants.map((option) => (
              <button
                key={option}
                type="button"
                role="menuitemradio"
                aria-checked={option === plant}
                onClick={() => {
                  setPlant(option);
                  setOrgOpen(false);
                }}
                className="flex w-full items-center justify-between gap-2 rounded px-2.5 py-2 text-left text-sm
                  text-navy hover:bg-teal-soft transition-colors duration-150"
              >
                <span className="truncate">{option}</span>
                {option === plant && <Check size={14} className="text-teal shrink-0" />}
              </button>
            ))}
          </div>
        )}
      </div>

      <div
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-navy text-sm font-semibold text-white"
        title={`${organisation.user} · ${organisation.role}`}
      >
        RI
      </div>
    </header>
  );
}
