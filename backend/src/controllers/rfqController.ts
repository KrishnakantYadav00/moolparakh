// src/controllers/rfqController.ts
import type { Request, Response } from 'express';
import db from '@/lib/db.js';
import { evaluatePriceSanity } from '@/services/shouldCostService.js';
import { parseRfqRequirement } from '@/services/specParserService.js';

// ─── POST /api/rfqs/parse-spec ──────────────────────────────────────────────
export async function parseSpec(req: Request, res: Response) {
  try {
    const { freeText } = req.body as { freeText?: string };
    const spec = await parseRfqRequirement(freeText ?? '');
    res.json({ spec });
  } catch (err) {
    console.error('parseSpec error:', err);
    res.status(500).json({ error: 'Failed to parse RFQ requirement' });
  }
}

// ─── GET /api/rfqs ──────────────────────────────────────────────────────────
export async function listRfqs(_req: Request, res: Response) {
  try {
    const rfqs = await db.rfq.findMany({
      include: {
        bids: {
          include: {
            vendor: {
              select: {
                id: true,
                legalName: true,
                trustScore: { select: { overallScore: true } },
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Attach price sanity checks and live trust scores to all bids
    const enrichedRfqs = await Promise.all(
      rfqs.map(async (rfq) => {
        const spec = rfq.spec as Record<string, string> | null;
        const enrichedBids = await Promise.all(
          rfq.bids.map(async (bid) => {
            const priceSanity = await evaluatePriceSanity(
              bid.pricePerUnit,
              spec?.item,
              spec?.grade,
              bid.id
            );
            return {
              ...bid,
              trustScoreAtBid: bid.vendor?.trustScore?.overallScore ?? bid.trustScoreAtBid,
              priceSanity,
            };
          })
        );
        return {
          ...rfq,
          bids: enrichedBids,
        };
      })
    );

    res.json(enrichedRfqs);
  } catch (err) {
    console.error('listRfqs error:', err);
    res.status(500).json({ error: 'Failed to fetch RFQs' });
  }
}

// ─── GET /api/rfqs/:id ──────────────────────────────────────────────────────
export async function getRfq(req: Request, res: Response) {
  try {
    const id = String(req.params.id);
    const rfq = await db.rfq.findUnique({
      where: { id },
      include: {
        bids: {
          include: {
            vendor: {
              select: {
                id: true,
                legalName: true,
                trustScore: { select: { overallScore: true } },
              },
            },
          },
          orderBy: { submittedAt: 'asc' },
        },
      },
    });
    if (!rfq) {
      res.status(404).json({ error: 'RFQ not found' });
      return;
    }

    const spec = rfq.spec as Record<string, string> | null;
    const enrichedBids = await Promise.all(
      rfq.bids.map(async (bid) => {
        const priceSanity = await evaluatePriceSanity(
          bid.pricePerUnit,
          spec?.item,
          spec?.grade,
          bid.id
        );
        return {
          ...bid,
          trustScoreAtBid: bid.vendor?.trustScore?.overallScore ?? bid.trustScoreAtBid,
          priceSanity,
        };
      })
    );

    res.json({ ...rfq, bids: enrichedBids });
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

    const rfqId = String(req.params.id);
    const rfq = await db.rfq.findUnique({
      where: { id: rfqId },
      select: { id: true, spec: true },
    });
    if (!rfq) {
      res.status(404).json({ error: 'RFQ not found' });
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

    // Evaluate price sanity
    const spec = rfq.spec as Record<string, string> | null;
    const priceSanity = await evaluatePriceSanity(
      Number(pricePerUnit),
      spec?.item,
      spec?.grade
    );

    let finalNotes = notes as string | undefined;
    if (priceSanity.isAnomalous && priceSanity.flag) {
      finalNotes = finalNotes ? `${finalNotes} | ${priceSanity.flag}` : priceSanity.flag;
    }

    const bid = await db.bid.create({
      data: {
        rfqId,
        vendorId: vendorId as string,
        vendorName: vendor.legalName,
        pricePerUnit: Number(pricePerUnit),
        deliveryDays: Number(deliveryDays),
        trustScoreAtBid: vendor.trustScore?.overallScore ?? 0,
        notes: finalNotes,
      },
    });

    res.status(201).json({ ...bid, priceSanity });
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

    const id = String(req.params.id);
    const rfq = await db.rfq.update({
      where: { id },
      data: { status: 'COMPLETED', awardedVendorId: vendorId },
    });
    res.json(rfq);
  } catch (err) {
    console.error('awardBid error:', err);
    res.status(500).json({ error: 'Failed to award RFQ' });
  }
}
