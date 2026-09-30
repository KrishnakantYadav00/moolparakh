// src/controllers/documentController.ts
import type { Request, Response } from 'express';
import { randomUUID } from 'crypto';
import db from '@/lib/db.js';
import { generatePresignedUploadUrl, r2Enabled } from '@/lib/r2.js';

// ─── POST /api/documents/presign ────────────────────────────────────────────
// Returns a pre-signed R2 PUT URL.
// Body: { vendorId, fileName, mimeType, documentType }
export async function presignUpload(req: Request, res: Response) {
  if (!r2Enabled) {
    res.status(503).json({
      error: 'R2 is not configured. Set R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME in .env',
    });
    return;
  }

  const { vendorId, fileName, mimeType, documentType } = req.body as Record<string, string>;

  if (!vendorId || !fileName || !mimeType || !documentType) {
    res.status(400).json({ error: 'vendorId, fileName, mimeType, and documentType are required' });
    return;
  }

  try {
    const ext = fileName.split('.').pop() ?? 'bin';
    const key = `vendors/${vendorId}/${documentType.toLowerCase()}/${randomUUID()}.${ext}`;
    const presignedUrl = await generatePresignedUploadUrl(key, mimeType);

    res.json({ presignedUrl, key });
  } catch (err) {
    console.error('presignUpload error:', err);
    res.status(500).json({ error: 'Failed to generate upload URL' });
  }
}

// ─── POST /api/documents ─────────────────────────────────────────────────────
// Record document metadata after the client has PUT to R2.
// Body: { vendorId, fileKey, mimeType, fileSize, type }
export async function recordDocument(req: Request, res: Response) {
  const { vendorId, fileKey, mimeType, fileSize, type } = req.body as Record<string, unknown>;

  if (!vendorId || !fileKey || !mimeType || !fileSize || !type) {
    res.status(400).json({ error: 'vendorId, fileKey, mimeType, fileSize, and type are required' });
    return;
  }

  try {
    const doc = await db.document.create({
      data: {
        vendorId: vendorId as string,
        fileKey: fileKey as string,
        mimeType: mimeType as string,
        fileSize: Number(fileSize),
        type: type as 'PAN_CARD' | 'GST_CERTIFICATE' | 'UDYAM_CERTIFICATE' | 'BANK_STATEMENT' | 'CANCELLED_CHEQUE' | 'ISO_CERTIFICATE' | 'INSURANCE_DOCUMENT' | 'OTHER',
        status: 'UPLOADED',
      },
    });

    // Audit event
    await db.vendorEvent.create({
      data: {
        vendorId: vendorId as string,
        kind: 'DOCUMENT',
        title: 'Document uploaded',
        detail: `Document of type ${type} uploaded (key: ${fileKey}).`,
      },
    });

    res.status(201).json(doc);
  } catch (err) {
    console.error('recordDocument error:', err);
    res.status(500).json({ error: 'Failed to record document' });
  }
}

// ─── GET /api/documents/:vendorId ────────────────────────────────────────────
export async function listDocuments(req: Request, res: Response) {
  try {
    const docs = await db.document.findMany({
      where: { vendorId: req.params.vendorId },
      orderBy: { uploadedAt: 'desc' },
    });
    res.json(docs);
  } catch (err) {
    console.error('listDocuments error:', err);
    res.status(500).json({ error: 'Failed to fetch documents' });
  }
}

// ─── PATCH /api/documents/:id/status ─────────────────────────────────────────
// Body: { status, certificateNumber?, issuingAuthority?, issueDate?, expirationDate?, confidence?, rawOcrText?, extractedData? }
export async function updateDocumentStatus(req: Request, res: Response) {
  try {
    const {
      status,
      certificateNumber,
      issuingAuthority,
      issueDate,
      expirationDate,
      confidence,
      rawOcrText,
      extractedData,
    } = req.body as Record<string, unknown>;

    const doc = await db.document.update({
      where: { id: req.params.id },
      data: {
        status: status as 'UPLOADED' | 'PROCESSING_OCR' | 'PARSED' | 'FAILED',
        certificateNumber: certificateNumber as string | undefined,
        issuingAuthority: issuingAuthority as string | undefined,
        issueDate: issueDate ? new Date(issueDate as string) : undefined,
        expirationDate: expirationDate ? new Date(expirationDate as string) : undefined,
        confidence: confidence as number | undefined,
        rawOcrText: rawOcrText as string | undefined,
        extractedData: extractedData as object | undefined,
      },
    });

    res.json(doc);
  } catch (err) {
    console.error('updateDocumentStatus error:', err);
    res.status(500).json({ error: 'Failed to update document status' });
  }
}
