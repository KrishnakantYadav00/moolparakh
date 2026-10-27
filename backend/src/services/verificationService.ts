// src/services/verificationService.ts
// Pipeline orchestrator for KYB checks, auto-fill, alerts, and trust score recalculation

import db from '@/lib/db.js';
import {
  verifyGstin,
  verifyPan,
  verifyUdyam,
  verifyCin,
  verifyBankAccount,
  type KybCheckResult,
} from '@/lib/kyb.js';
import { recalculateTrustScore } from '@/services/trustEngine.js';

export async function runVendorVerificationPipeline(vendorId: string) {
  const vendor = await db.vendor.findUnique({
    where: { id: vendorId },
    include: { verifications: true },
  });

  if (!vendor) {
    throw new Error(`Vendor ${vendorId} not found`);
  }

  const tasks: Array<{
    type: 'GSTIN' | 'PAN' | 'UDYAM' | 'CIN';
    identifier: string;
    runner: () => Promise<KybCheckResult>;
  }> = [];

  if (vendor.gstin) {
    tasks.push({
      type: 'GSTIN',
      identifier: vendor.gstin,
      runner: () => verifyGstin(vendor.gstin!),
    });
  }

  if (vendor.pan) {
    tasks.push({
      type: 'PAN',
      identifier: vendor.pan,
      runner: () => verifyPan(vendor.pan!, vendor.legalName),
    });
  }

  if (vendor.udyamNumber) {
    tasks.push({
      type: 'UDYAM',
      identifier: vendor.udyamNumber,
      runner: () => verifyUdyam(vendor.udyamNumber!),
    });
  }

  if (vendor.cin) {
    tasks.push({
      type: 'CIN',
      identifier: vendor.cin,
      runner: () => verifyCin(vendor.cin!),
    });
  }

  const results: Record<string, KybCheckResult> = {};
  const vendorUpdates: Record<string, unknown> = {};

  for (const task of tasks) {
    try {
      const result = await task.runner();
      results[task.type] = result;

      // Update or create verification record in database
      const existingRecord = await db.verificationRecord.findFirst({
        where: { vendorId: vendor.id, type: task.type },
      });

      if (result.success) {
        if (existingRecord) {
          await db.verificationRecord.update({
            where: { id: existingRecord.id },
            data: {
              status: 'SUCCESS',
              source: result.source,
              responsePayload: (result.data as any) ?? {},
              verifiedAt: new Date(),
              failureReason: null,
            },
          });
        } else {
          await db.verificationRecord.create({
            data: {
              vendorId: vendor.id,
              type: task.type,
              status: 'SUCCESS',
              source: result.source,
              responsePayload: (result.data as any) ?? {},
              verifiedAt: new Date(),
            },
          });
        }

        // Auto-populate fields from verified response (Requirement 1.3)
        if (task.type === 'GSTIN' && result.autoFill) {
          if (result.autoFill.legalName && (!vendor.legalName || vendor.legalName.startsWith('New Vendor'))) {
            vendorUpdates.legalName = result.autoFill.legalName;
          }
          if (result.autoFill.tradeName && !vendor.tradeName) {
            vendorUpdates.tradeName = result.autoFill.tradeName;
          }
          if (result.autoFill.state && (!vendor.state || vendor.state === '')) {
            vendorUpdates.state = result.autoFill.state;
          }
          if (result.autoFill.city && (!vendor.city || vendor.city === '')) {
            vendorUpdates.city = result.autoFill.city;
          }
          if (result.autoFill.address && !vendor.address) {
            vendorUpdates.address = result.autoFill.address;
          }
          if (result.autoFill.pan && !vendor.pan) {
            vendorUpdates.pan = result.autoFill.pan;
          }
        }

        if (task.type === 'UDYAM' && result.autoFill?.msmeCategory) {
          vendorUpdates.msmeCategory = result.autoFill.msmeCategory;
        }

        // Create success event
        await db.vendorEvent.create({
          data: {
            vendorId: vendor.id,
            kind: 'VERIFICATION',
            title: `${task.type} verified successfully`,
            detail: `${task.type} check passed via ${result.source}. Identifier: ${task.identifier}`,
          },
        });
      } else {
        // Verification failed!
        const reason = result.failureReason || `${task.type} verification failed`;
        if (existingRecord) {
          await db.verificationRecord.update({
            where: { id: existingRecord.id },
            data: {
              status: 'FAILED',
              source: result.source,
              failureReason: reason,
              responsePayload: (result.data as any) ?? {},
            },
          });
        } else {
          await db.verificationRecord.create({
            data: {
              vendorId: vendor.id,
              type: task.type,
              status: 'FAILED',
              source: result.source,
              failureReason: reason,
              responsePayload: (result.data as any) ?? {},
            },
          });
        }

        // Create Alert
        await db.alert.create({
          data: {
            vendorId: vendor.id,
            title: `${task.type} verification failure`,
            description: reason,
            severity: 'CRITICAL',
          },
        });

        // Create VendorEvent
        await db.vendorEvent.create({
          data: {
            vendorId: vendor.id,
            kind: 'VERIFICATION',
            title: `${task.type} check failed`,
            detail: reason,
          },
        });

        // Create Notification
        await db.notification.create({
          data: {
            vendorId: vendor.id,
            vendorName: vendor.legalName,
            kind: 'CRITICAL',
            title: `${task.type} verification failed for ${vendor.legalName}`,
            detail: reason,
            read: false,
          },
        });
      }
    } catch (err: any) {
      console.error(`Verification error for ${task.type}:`, err);
    }
  }

  // Apply auto-populated updates to vendor if any were extracted
  if (Object.keys(vendorUpdates).length > 0) {
    await db.vendor.update({
      where: { id: vendor.id },
      data: vendorUpdates,
    });
  }

  // Recalculate trust score (Requirement 1.4)
  const trustBreakdown = await recalculateTrustScore(vendor.id);

  // Vendor audit event for trust recalculation
  await db.vendorEvent.create({
    data: {
      vendorId: vendor.id,
      kind: 'TRUST',
      title: 'Trust score recalculated',
      detail: `Score updated to ${trustBreakdown.overallScore}/100. Risk level: ${trustBreakdown.riskLevel}. (Verification: ${trustBreakdown.verificationCompleteness}/40, Freshness: ${trustBreakdown.certificationFreshness}/35, Activity: ${trustBreakdown.accountAgeActivity}/15, Flag: ${trustBreakdown.manualBuyerFlag}/10)`,
    },
  });

  // Return the refreshed vendor record
  return db.vendor.findUnique({
    where: { id: vendor.id },
    include: {
      trustScore: true,
      verifications: true,
      documents: true,
      alerts: true,
    },
  });
}

/**
 * Bank verification pipeline trigger (called when bank document uploaded)
 */
export async function runBankVerification(vendorId: string, accountNumber: string, ifsc: string) {
  const result = await verifyBankAccount(accountNumber, ifsc);

  const existingRecord = await db.verificationRecord.findFirst({
    where: { vendorId, type: 'BANK_ACCOUNT' },
  });

  if (result.success) {
    if (existingRecord) {
      await db.verificationRecord.update({
        where: { id: existingRecord.id },
        data: {
          status: 'SUCCESS',
          source: result.source,
          verifiedAt: new Date(),
          failureReason: null,
          responsePayload: (result.data as any) ?? {},
        },
      });
    } else {
      await db.verificationRecord.create({
        data: {
          vendorId,
          type: 'BANK_ACCOUNT',
          status: 'SUCCESS',
          source: result.source,
          verifiedAt: new Date(),
          responsePayload: (result.data as any) ?? {},
        },
      });
    }

    await db.vendorEvent.create({
      data: {
        vendorId,
        kind: 'VERIFICATION',
        title: 'Bank account verified',
        detail: `Bank account (${accountNumber.slice(-4)}) verified successfully.`,
      },
    });
  } else {
    const reason = result.failureReason || 'Bank account verification failed';
    if (existingRecord) {
      await db.verificationRecord.update({
        where: { id: existingRecord.id },
        data: {
          status: 'FAILED',
          source: result.source,
          failureReason: reason,
        },
      });
    } else {
      await db.verificationRecord.create({
        data: {
          vendorId,
          type: 'BANK_ACCOUNT',
          status: 'FAILED',
          source: result.source,
          failureReason: reason,
        },
      });
    }

    await db.alert.create({
      data: {
        vendorId,
        title: 'Bank account verification failed',
        description: reason,
        severity: 'CRITICAL',
      },
    });
  }

  // Recalculate trust score
  return recalculateTrustScore(vendorId);
}
