// src/controllers/vendorController.ts
import type { Request, Response } from 'express';
import db from '@/lib/db.js';
import { runVendorVerificationPipeline } from '@/services/verificationService.js';
import { recalculateTrustScore } from '@/services/trustEngine.js';

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
    const id = String(req.params.id);
    const vendor = await db.vendor.findUnique({
      where: { id },
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
        pan: pan ? (pan as string).trim().toUpperCase() : undefined,
        gstin: gstin ? (gstin as string).trim().toUpperCase() : undefined,
        cin: cin ? (cin as string).trim().toUpperCase() : undefined,
        udyamNumber: udyamNumber ? (udyamNumber as string).trim().toUpperCase() : undefined,
        msmeCategory: (msmeCategory as 'MICRO' | 'SMALL' | 'MEDIUM') ?? 'MICRO',
        city: (city as string) ?? '',
        state: (state as string) ?? '',
        categories: (categories as string[]) ?? [],
        contactName: (contactName as string) ?? '',
        contactRole: (contactRole as string) ?? '',
        address: address as object | undefined,
        buyerFlagNote: buyerFlagNote as string | undefined,
        status: 'PENDING_VERIFICATION',
      },
    });

    // Create a default PENDING verification record for each known identifier
    const verificationTypes: Array<'GSTIN' | 'PAN' | 'UDYAM' | 'CIN'> = [];
    if (vendor.gstin) verificationTypes.push('GSTIN');
    if (vendor.pan) verificationTypes.push('PAN');
    if (vendor.udyamNumber) verificationTypes.push('UDYAM');
    if (vendor.cin) verificationTypes.push('CIN');

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
        detail: `${vendor.legalName} added to MoolParakh. Verification pipeline triggered.`,
      },
    });

    // Run verification pipeline (Phase 1: calls KYB, updates verifications, auto-populates fields, recalculates trust score)
    try {
      const verifiedVendor = await runVendorVerificationPipeline(vendor.id);
      res.status(201).json(verifiedVendor ?? vendor);
      return;
    } catch (pipelineErr) {
      console.error('Verification pipeline error after vendor creation:', pipelineErr);
      // Fallback: recalculate initial baseline trust score
      await recalculateTrustScore(vendor.id);
      res.status(201).json(vendor);
      return;
    }
  } catch (err: unknown) {
    console.error('createVendor error:', err);
    const msg = err instanceof Error ? err.message : 'Unknown error';
    if (msg.includes('Unique constraint')) {
      res.status(409).json({ error: 'A vendor with those identifiers already exists' });
      return;
    }
    res.status(500).json({ error: 'Failed to create vendor' });
  }
}

// ─── POST /api/vendors/:id/verify ───────────────────────────────────────────
// Manually triggers or re-runs the full verification pipeline for a vendor
export async function triggerVendorVerification(req: Request, res: Response) {
  try {
    const id = String(req.params.id);
    const existing = await db.vendor.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ error: 'Vendor not found' });
      return;
    }

    const updatedVendor = await runVendorVerificationPipeline(id);
    res.json(updatedVendor);
  } catch (err) {
    console.error('triggerVendorVerification error:', err);
    res.status(500).json({ error: 'Failed to run vendor verification pipeline' });
  }
}

// ─── PATCH /api/vendors/:id ─────────────────────────────────────────────────
export async function updateVendor(req: Request, res: Response) {
  try {
    const id = String(req.params.id);
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
      where: { id },
      data,
    });

    // If buyer flag or status changed, recalculate trust score
    if ('buyerFlagNote' in req.body || 'status' in req.body) {
      await recalculateTrustScore(id);
    }

    res.json(vendor);
  } catch (err) {
    console.error('updateVendor error:', err);
    res.status(500).json({ error: 'Failed to update vendor' });
  }
}

// ─── GET /api/vendors/:id/relationships ─────────────────────────────────────
export async function getRelationships(req: Request, res: Response) {
  try {
    const id = String(req.params.id);
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
