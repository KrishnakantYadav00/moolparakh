// src/controllers/rfqController.ts
import type { Request, Response } from 'express';
import db from '@/lib/db.js';

// ─── GET /api/rfqs ──────────────────────────────────────────────────────────
export async function listRfqs(_req: Request, res: Response) {
  try {
    const rfqs = await db.rfq.findMany({
      include: {
        bids: {
          include: { vendor: { select: { id: true, legalName: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(rfqs);
  } catch (err) {
    console.error('listRfqs error:', err);
    res.status(500).json({ error: 'Failed to fetch RFQs' });
  }
}

// ─── GET /api/rfqs/:id ──────────────────────────────────────────────────────
export async function getRfq(req: Request, res: Response) {
  try {
    const rfq = await db.rfq.findUnique({
      where: { id: req.params.id },
      include: {
        bids: {
          include: { vendor: { select: { id: true, legalName: true, trustScore: true } } },
          orderBy: { submittedAt: 'asc' },
        },
      },
    });
    if (!rfq) {
      res.status(404).json({ error: 'RFQ not found' });
      return;
    }
    res.json(rfq);
  } catch (err) {
    console.error('getRfq error:', err);
    res.status(500).json({ error: 'Failed to fetch RFQ' });
  }
}

// ─── POST /api/rfqs ─────────────────────────────────────────────────────────
// Body: { reference, title, spec, freeText?, closesAt, suppliersNotified? }
export async function createRfq(req: Request, res: Response) {
  try {
    const { reference, title, spec, freeText, closesAt, suppliersNotified } =
      req.body as Record<string, unknown>;

    if (!reference || !title || !spec || !closesAt) {
      res.status(400).json({ error: 'reference, title, spec, and closesAt are required' });
      return;
    }

    const rfq = await db.rfq.create({
      data: {
        reference: reference as string,
        title: title as string,
        spec: spec as object,
        freeText: freeText as string | undefined,
        closesAt: new Date(closesAt as string),
        suppliersNotified: Number(suppliersNotified ?? 0),
        status: 'OPEN',
      },
    });
    res.status(201).json(rfq);
  } catch (err: unknown) {
    console.error('createRfq error:', err);
    const msg = err instanceof Error ? err.message : '';
    if (msg.includes('Unique constraint')) {
      res.status(409).json({ error: 'An RFQ with that reference already exists' });
      return;
    }
    res.status(500).json({ error: 'Failed to create RFQ' });
  }
}

// ─── POST /api/rfqs/:id/bids ─────────────────────────────────────────────────
// Body: { vendorId, pricePerUnit, deliveryDays, notes? }
export async function submitBid(req: Request, res: Response) {
  try {
    const { vendorId, pricePerUnit, deliveryDays, notes } =
      req.body as Record<string, unknown>;

    if (!vendorId || pricePerUnit === undefined || deliveryDays === undefined) {
      res.status(400).json({ error: 'vendorId, pricePerUnit, and deliveryDays are required' });
      return;
    }

    // Fetch current trust score for denormalisation
    const vendor = await db.vendor.findUnique({
      where: { id: vendorId as string },
      select: { legalName: true, trustScore: { select: { overallScore: true } } },
    });
    if (!vendor) {
      res.status(404).json({ error: 'Vendor not found' });
      return;
    }

    const bid = await db.bid.create({
      data: {
        rfqId: req.params.id,
        vendorId: vendorId as string,
        vendorName: vendor.legalName,
        pricePerUnit: Number(pricePerUnit),
        deliveryDays: Number(deliveryDays),
        trustScoreAtBid: vendor.trustScore?.overallScore ?? 0,
        notes: notes as string | undefined,
      },
    });
    res.status(201).json(bid);
  } catch (err: unknown) {
    console.error('submitBid error:', err);
    const msg = err instanceof Error ? err.message : '';
    if (msg.includes('Unique constraint')) {
      res.status(409).json({ error: 'This vendor has already submitted a bid for this RFQ' });
      return;
    }
    res.status(500).json({ error: 'Failed to submit bid' });
  }
}

// ─── PATCH /api/rfqs/:id/award ───────────────────────────────────────────────
// Body: { vendorId }
export async function awardBid(req: Request, res: Response) {
  try {
    const { vendorId } = req.body as { vendorId: string };
    if (!vendorId) {
      res.status(400).json({ error: 'vendorId is required' });
      return;
    }

    const rfq = await db.rfq.update({
      where: { id: req.params.id },
      data: { status: 'COMPLETED', awardedVendorId: vendorId },
    });
    res.json(rfq);
  } catch (err) {
    console.error('awardBid error:', err);
    res.status(500).json({ error: 'Failed to award RFQ' });
  }
}
