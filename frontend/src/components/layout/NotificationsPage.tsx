import { useState } from 'react';
import { BellOff } from 'lucide-react';
import type { AppNotification } from '@/types';
import { Button, EmptyState, SegmentedControl } from '@/components/ui/Primitives';
import { NotificationRow } from '@/components/layout/Notifications';

const VIEWS = ['All', 'Unread'] as const;
type View = (typeof VIEWS)[number];

export function NotificationsPage({
  notifications,
  onRead,
  onReadAll,
}: {
  notifications: AppNotification[];
  onRead: (id: string) => void;
  onReadAll: () => void;
}) {
  const [view, setView] = useState<View>('All');
  const filtered = view === 'All' ? notifications : notifications.filter((n) => !n.read);
  const unread = notifications.filter((n) => !n.read).length;

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight text-navy">Notifications</h2>
          <p className="mt-0.5 text-base text-muted">
            Compliance, disruption and bid activity across your supplier network.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <SegmentedControl
            label="Notification filter"
            options={VIEWS}
            value={view}
            onChange={setView}
            counts={{ All: notifications.length, Unread: unread }}
          />
          <Button variant="secondary" size="sm" onClick={onReadAll} disabled={unread === 0}>
            Mark all as read
          </Button>
        </div>
      </div>

      {filtered.length === 0 ? (
        <div className="surface-card">
          <EmptyState
            icon={<BellOff size={18} />}
            title="Nothing to read"
            description="New alerts will appear here as certificates approach expiry and disruptions are matched."
          />
        </div>
      ) : (
        <ul className="max-w-3xl space-y-2">
          {filtered.map((notification) => (
            <NotificationRow key={notification.id} notification={notification} onRead={onRead} />
          ))}
        </ul>
      )}
    </div>
  );
}
