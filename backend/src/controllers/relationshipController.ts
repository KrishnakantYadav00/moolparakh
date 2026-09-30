// src/controllers/relationshipController.ts
import type { Request, Response } from 'express';
import db from '@/lib/db.js';

// ─── GET /api/relationships ──────────────────────────────────────────────────
export async function listRelationships(_req: Request, res: Response) {
  try {
    const relationships = await db.supplierRelationship.findMany({
      include: {
        vendorA: { select: { id: true, legalName: true } },
        vendorB: { select: { id: true, legalName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(relationships);
  } catch (err) {
    console.error('listRelationships error:', err);
    res.status(500).json({ error: 'Failed to fetch relationships' });
  }
}

// ─── POST /api/relationships ─────────────────────────────────────────────────
// Body: { vendorAId, vendorBId, type, value }
export async function createRelationship(req: Request, res: Response) {
  try {
    const { vendorAId, vendorBId, type, value } = req.body as Record<string, string>;

    if (!vendorAId || !vendorBId || !type || !value) {
      res.status(400).json({ error: 'vendorAId, vendorBId, type, and value are required' });
      return;
    }

    const relationship = await db.supplierRelationship.create({
      data: {
        vendorAId,
        vendorBId,
        type: type as 'SHARED_DIRECTOR' | 'SHARED_BANK_ACCOUNT' | 'SHARED_ADDRESS',
        value,
      },
      include: {
        vendorA: { select: { id: true, legalName: true } },
        vendorB: { select: { id: true, legalName: true } },
      },
    });

    res.status(201).json(relationship);
  } catch (err) {
    console.error('createRelationship error:', err);
    res.status(500).json({ error: 'Failed to create relationship' });
  }
}

// ─── DELETE /api/relationships/:id ──────────────────────────────────────────
export async function deleteRelationship(req: Request, res: Response) {
  try {
    await db.supplierRelationship.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch (err) {
    console.error('deleteRelationship error:', err);
    res.status(500).json({ error: 'Failed to delete relationship' });
  }
}
