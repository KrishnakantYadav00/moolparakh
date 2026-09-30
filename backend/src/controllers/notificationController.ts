// src/controllers/notificationController.ts
import type { Request, Response } from 'express';
import db from '@/lib/db.js';

// ─── GET /api/notifications ──────────────────────────────────────────────────
export async function listNotifications(_req: Request, res: Response) {
  try {
    const notifications = await db.notification.findMany({
      orderBy: { createdAt: 'desc' },
    });
    res.json(notifications);
  } catch (err) {
    console.error('listNotifications error:', err);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
}

// ─── PATCH /api/notifications/:id/read ──────────────────────────────────────
export async function markRead(req: Request, res: Response) {
  try {
    const notification = await db.notification.update({
      where: { id: req.params.id },
      data: { read: true },
    });
    res.json(notification);
  } catch (err) {
    console.error('markRead error:', err);
    res.status(500).json({ error: 'Failed to mark notification as read' });
  }
}

// ─── PATCH /api/notifications/read-all ──────────────────────────────────────
export async function markAllRead(_req: Request, res: Response) {
  try {
    await db.notification.updateMany({ where: { read: false }, data: { read: true } });
    res.json({ ok: true });
  } catch (err) {
    console.error('markAllRead error:', err);
    res.status(500).json({ error: 'Failed to mark all notifications as read' });
  }
}

// ─── POST /api/notifications ─────────────────────────────────────────────────
// Body: { kind, title, vendorName, detail, vendorId? }
export async function createNotification(req: Request, res: Response) {
  try {
    const { kind, title, vendorName, detail, vendorId } =
      req.body as Record<string, string | undefined>;

    if (!kind || !title || !vendorName || !detail) {
      res.status(400).json({ error: 'kind, title, vendorName, and detail are required' });
      return;
    }

    const notification = await db.notification.create({
      data: {
        kind: kind as 'HIGH' | 'CRITICAL' | 'COMPLIANCE' | 'RFQ' | 'TRUST',
        title,
        vendorName,
        detail,
        vendorId: vendorId ?? null,
      },
    });
    res.status(201).json(notification);
  } catch (err) {
    console.error('createNotification error:', err);
    res.status(500).json({ error: 'Failed to create notification' });
  }
}
