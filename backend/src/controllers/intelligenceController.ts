// src/controllers/intelligenceController.ts
import type { Request, Response } from 'express';
import db from '@/lib/db.js';

// ─── GET /api/intelligence/events ───────────────────────────────────────────
export async function listEvents(_req: Request, res: Response) {
  try {
    const events = await db.disruptionEvent.findMany({
      include: {
        affectedVendors: {
          include: { vendor: { select: { id: true, legalName: true } } },
        },
      },
      orderBy: { detectedAt: 'desc' },
    });
    res.json(events);
  } catch (err) {
    console.error('listEvents error:', err);
    res.status(500).json({ error: 'Failed to fetch disruption events' });
  }
}

// ─── GET /api/intelligence/events/:vendorId ──────────────────────────────────
export async function eventsForVendor(req: Request, res: Response) {
  try {
    const targets = await db.disruptionTarget.findMany({
      where: { vendorId: req.params.vendorId },
      include: { event: true },
      orderBy: { event: { detectedAt: 'desc' } },
    });
    res.json(targets.map((t: { event: object }) => t.event));
  } catch (err) {
    console.error('eventsForVendor error:', err);
    res.status(500).json({ error: 'Failed to fetch vendor disruption events' });
  }
}

// ─── POST /api/intelligence/events ──────────────────────────────────────────
// Body: { severity, title, category, region, summary, affectedVendorIds?, sourceUrl? }
export async function createEvent(req: Request, res: Response) {
  try {
    const { severity, title, category, region, summary, affectedVendorIds, sourceUrl } =
      req.body as Record<string, unknown>;

    if (!severity || !title || !category || !region || !summary) {
      res.status(400).json({ error: 'severity, title, category, region, and summary are required' });
      return;
    }

    const ids = Array.isArray(affectedVendorIds) ? (affectedVendorIds as string[]) : [];

    const event = await db.disruptionEvent.create({
      data: {
        severity: severity as 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL',
        title: title as string,
        category: category as 'PORT_DISRUPTION' | 'TARIFF' | 'NATURAL_DISASTER' | 'GEOPOLITICAL' | 'LOGISTICS' | 'REGULATORY',
        region: region as string,
        summary: summary as string,
        sourceUrl: sourceUrl as string | undefined,
        affectedVendors: {
          create: ids.map((vid) => ({ vendorId: vid })),
        },
      },
      include: { affectedVendors: true },
    });

    res.status(201).json(event);
  } catch (err) {
    console.error('createEvent error:', err);
    res.status(500).json({ error: 'Failed to create disruption event' });
  }
}
