// src/controllers/vendorController.ts
import type { Request, Response } from 'express';
import db from '@/lib/db.js';

// ─── GET /api/vendors ───────────────────────────────────────────────────────
export async function listVendors(_req: Request, res: Response) {
  try {
    const vendors = await db.vendor.findMany({
      include: {
        trustScore: true,
        verifications: { orderBy: { createdAt: 'desc' } },
        documents: {
          where: { expirationDate: { not: null } },
          orderBy: { expirationDate: 'asc' },
          take: 5,
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(vendors);
  } catch (err) {
    console.error('listVendors error:', err);
    res.status(500).json({ error: 'Failed to fetch vendors' });
  }
}

// ─── GET /api/vendors/:id ───────────────────────────────────────────────────
export async function getVendor(req: Request, res: Response) {
  try {
    const vendor = await db.vendor.findUnique({
      where: { id: req.params.id },
      include: {
        trustScore: true,
        trustHistory: { orderBy: { recordedAt: 'asc' } },
        verifications: { orderBy: { createdAt: 'desc' } },
        documents: { orderBy: { uploadedAt: 'desc' } },
        alerts: { where: { isResolved: false }, orderBy: { createdAt: 'desc' } },
        events: { orderBy: { at: 'desc' }, take: 50 },
        bids: {
          include: { rfq: { select: { title: true, reference: true, status: true } } },
          orderBy: { submittedAt: 'desc' },
          take: 20,
        },
      },
    });

    if (!vendor) {
      res.status(404).json({ error: 'Vendor not found' });
      return;
    }

    res.json(vendor);
  } catch (err) {
    console.error('getVendor error:', err);
    res.status(500).json({ error: 'Failed to fetch vendor' });
  }
}

// ─── POST /api/vendors ──────────────────────────────────────────────────────
export async function createVendor(req: Request, res: Response) {
  try {
    const {
      legalName,
      tradeName,
      email,
      phone,
      pan,
      gstin,
      cin,
      udyamNumber,
      msmeCategory,
      city,
      state,
      categories,
      contactName,
      contactRole,
      address,
      buyerFlagNote,
    } = req.body as Record<string, unknown>;

    if (!legalName || !email || !phone) {
      res.status(400).json({ error: 'legalName, email, and phone are required' });
      return;
    }

    const vendor = await db.vendor.create({
      data: {
        legalName: legalName as string,
        tradeName: tradeName as string | undefined,
        email: email as string,
        phone: phone as string,
        pan: pan as string | undefined,
        gstin: gstin as string | undefined,
        cin: cin as string | undefined,
        udyamNumber: udyamNumber as string | undefined,
        msmeCategory: (msmeCategory as 'MICRO' | 'SMALL' | 'MEDIUM') ?? 'MICRO',
        city: (city as string) ?? '',
        state: (state as string) ?? '',
        categories: (categories as string[]) ?? [],
        contactName: (contactName as string) ?? '',
        contactRole: (contactRole as string) ?? '',
        address: address as object | undefined,
        buyerFlagNote: buyerFlagNote as string | undefined,
      },
    });

    // Create a default PENDING verification record for each known identifier
    const verificationTypes: Array<'GSTIN' | 'PAN' | 'UDYAM' | 'CIN'> = [];
    if (gstin) verificationTypes.push('GSTIN');
    if (pan) verificationTypes.push('PAN');
    if (udyamNumber) verificationTypes.push('UDYAM');
    if (cin) verificationTypes.push('CIN');

    if (verificationTypes.length > 0) {
      await db.verificationRecord.createMany({
        data: verificationTypes.map((t) => ({ vendorId: vendor.id, type: t })),
      });
    }

    // Log the creation event
    await db.vendorEvent.create({
      data: {
        vendorId: vendor.id,
        kind: 'VERIFICATION',
        title: 'Vendor onboarded',
        detail: `${vendor.legalName} added to MoolParakh. Status: DRAFT.`,
      },
    });

    res.status(201).json(vendor);
  } catch (err: unknown) {
    console.error('createVendor error:', err);
    const msg = err instanceof Error ? err.message : 'Unknown error';
    // Prisma unique constraint violation code
    if (msg.includes('Unique constraint')) {
      res.status(409).json({ error: 'A vendor with those identifiers already exists' });
      return;
    }
    res.status(500).json({ error: 'Failed to create vendor' });
  }
}

// ─── PATCH /api/vendors/:id ─────────────────────────────────────────────────
export async function updateVendor(req: Request, res: Response) {
  try {
    const allowedFields = [
      'tradeName', 'phone', 'city', 'state', 'categories',
      'contactName', 'contactRole', 'address', 'buyerFlagNote',
      'status', 'msmeCategory',
    ];

    const data: Record<string, unknown> = {};
    for (const field of allowedFields) {
      if (field in req.body) {
        data[field] = (req.body as Record<string, unknown>)[field];
      }
    }

    const vendor = await db.vendor.update({
      where: { id: req.params.id },
      data,
    });

    res.json(vendor);
  } catch (err) {
    console.error('updateVendor error:', err);
    res.status(500).json({ error: 'Failed to update vendor' });
  }
}

// ─── GET /api/vendors/:id/relationships ─────────────────────────────────────
export async function getRelationships(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const relationships = await db.supplierRelationship.findMany({
      where: {
        OR: [{ vendorAId: id }, { vendorBId: id }],
      },
      include: {
        vendorA: { select: { id: true, legalName: true } },
        vendorB: { select: { id: true, legalName: true } },
      },
    });
    res.json(relationships);
  } catch (err) {
    console.error('getRelationships error:', err);
    res.status(500).json({ error: 'Failed to fetch relationships' });
  }
}
