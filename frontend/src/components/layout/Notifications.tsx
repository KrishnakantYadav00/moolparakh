import { BellOff } from 'lucide-react';
import type { AppNotification, NotificationKind } from '@/types';
import { Badge, Button, EmptyState } from '@/components/ui/Primitives';
import { SlideOver } from '@/components/ui/Overlays';
import { relativeMinutes } from '@/utils/format';

const kindTone: Record<NotificationKind, 'critical' | 'high' | 'medium' | 'teal' | 'navy'> = {
  CRITICAL: 'critical',
  HIGH: 'high',
  COMPLIANCE: 'medium',
  RFQ: 'teal',
  TRUST: 'navy',
};

export function NotificationRow({
  notification,
  onRead,
}: {
  notification: AppNotification;
  onRead: (id: string) => void;
}) {
  return (
    <li>
      <button
        type="button"
        onClick={() => onRead(notification.id)}
        className={`w-full rounded-md border px-3.5 py-3 text-left transition-colors duration-150
          ${
            notification.read
              ? 'border-hairline bg-surface hover:bg-canvas'
              : 'border-teal/25 bg-teal-soft/40 hover:bg-teal-soft/70'
          }`}
      >
        <div className="flex items-center justify-between gap-2">
          <Badge tone={kindTone[notification.kind]}>{notification.kind}</Badge>
          <span className="text-2xs text-muted">{relativeMinutes(notification.minutesAgo)}</span>
        </div>
        <p className="mt-2 text-base font-semibold text-navy">{notification.title}</p>
        <p className="text-sm font-medium text-navy/80">{notification.vendorName}</p>
        <p className="mt-0.5 text-sm text-muted">{notification.detail}</p>
      </button>
    </li>
  );
}

interface NotificationDrawerProps {
  open: boolean;
  onClose: () => void;
  notifications: AppNotification[];
  onRead: (id: string) => void;
  onReadAll: () => void;
  onSeeAll: () => void;
}

export function NotificationDrawer({
  open,
  onClose,
  notifications,
  onRead,
  onReadAll,
  onSeeAll,
}: NotificationDrawerProps) {
  const unread = notifications.filter((n) => !n.read).length;

  return (
    <SlideOver
      open={open}
      onClose={onClose}
      title="Notifications"
      description={unread > 0 ? `${unread} unread` : 'All caught up'}
      footer={
        <div className="flex items-center justify-between gap-2">
          <Button variant="ghost" size="sm" onClick={onReadAll} disabled={unread === 0}>
            Mark all as read
          </Button>
          <Button
            variant="secondary"
            size="sm"
            onClick={() => {
              onSeeAll();
              onClose();
            }}
          >
            Open notifications page
          </Button>
        </div>
      }
    >
      {notifications.length === 0 ? (
        <EmptyState
          icon={<BellOff size={18} />}
          title="No notifications"
          description="Compliance, disruption and bid alerts will appear here."
        />
      ) : (
        <ul className="space-y-2">
          {notifications.map((notification) => (
            <NotificationRow key={notification.id} notification={notification} onRead={onRead} />
          ))}
        </ul>
      )}
    </SlideOver>
  );
}
