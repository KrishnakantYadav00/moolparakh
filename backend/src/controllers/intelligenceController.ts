// src/controllers/intelligenceController.ts
import type { Request, Response } from 'express';
import db from '@/lib/db.js';
import { runGdeltPipeline } from '@/services/gdeltService.js';

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
    const vendorId = String(req.params.vendorId);
    const targets = await db.disruptionTarget.findMany({
      where: { vendorId },
      include: { event: true },
      orderBy: { event: { detectedAt: 'desc' } },
    });
    res.json(targets.map((t) => t.event));
  } catch (err) {
    console.error('eventsForVendor error:', err);
    res.status(500).json({ error: 'Failed to fetch vendor disruption events' });
  }
}

// ─── GET /api/intelligence/risk-leaderboard ──────────────────────────────────
// Returns vendors ranked by trust score (ascending = worst first for risk view)
export async function riskLeaderboard(_req: Request, res: Response) {
  try {
    const vendors = await db.vendor.findMany({
      include: {
        trustScore: true,
        verifications: { orderBy: { createdAt: 'desc' }, take: 5 },
        documents: {
          where: { expirationDate: { not: null } },
          orderBy: { expirationDate: 'asc' },
          take: 3,
        },
      },
      orderBy: [
        { trustScore: { overallScore: 'asc' } },
      ],
    });
    res.json(vendors);
  } catch (err) {
    console.error('riskLeaderboard error:', err);
    res.status(500).json({ error: 'Failed to fetch risk leaderboard' });
  }
}

// ─── GET /api/intelligence/heatmap ──────────────────────────────────────────
// Computes real live disruption density for Indian states and regional matrix
export async function getHeatmapData(_req: Request, res: Response) {
  try {
    const events = await db.disruptionEvent.findMany({
      include: {
        affectedVendors: {
          include: { vendor: { select: { id: true, state: true, legalName: true } } },
        },
      },
    });

    // Indian States tracking
    const STATES_META = [
      { name: 'Maharashtra', region: 'Western India', code: 'MH' },
      { name: 'Gujarat', region: 'Western India', code: 'GJ' },
      { name: 'Tamil Nadu', region: 'Southern India', code: 'TN' },
      { name: 'Karnataka', region: 'Southern India', code: 'KA' },
      { name: 'Kerala', region: 'Southern India', code: 'KL' },
      { name: 'Telangana', region: 'Southern India', code: 'TG' },
      { name: 'Rajasthan', region: 'Northern India', code: 'RJ' },
      { name: 'Punjab', region: 'Northern India', code: 'PB' },
      { name: 'Haryana', region: 'Northern India', code: 'HR' },
      { name: 'Uttar Pradesh', region: 'Northern India', code: 'UP' },
      { name: 'West Bengal', region: 'Eastern India', code: 'WB' },
      { name: 'Madhya Pradesh', region: 'Central India', code: 'MP' },
    ];

    const SEV_MAP: Record<string, number> = { LOW: 1, MEDIUM: 2, HIGH: 3, CRITICAL: 4 };

    // 1. Compute State-Level Density
    const stateDensity = STATES_META.map((st) => {
      const matchingEvents = events.filter((e) => {
        const text = `${e.region} ${e.title} ${e.summary}`.toLowerCase();
        const hasStateMention = text.includes(st.name.toLowerCase());
        const hasVendorInState = e.affectedVendors.some(
          (av) => av.vendor.state.toLowerCase() === st.name.toLowerCase()
        );
        return hasStateMention || hasVendorInState;
      });

      let maxSeverityRank = 0;
      let maxSeverity = 'NONE';
      const affectedVendorIds = new Set<string>();

      for (const ev of matchingEvents) {
        const rank = SEV_MAP[ev.severity] || 0;
        if (rank > maxSeverityRank) {
          maxSeverityRank = rank;
          maxSeverity = ev.severity;
        }
        for (const av of ev.affectedVendors) {
          if (av.vendor.state.toLowerCase() === st.name.toLowerCase()) {
            affectedVendorIds.add(av.vendor.id);
          }
        }
      }

      return {
        state: st.name,
        code: st.code,
        region: st.region,
        disruptionCount: matchingEvents.length,
        maxSeverity,
        level: maxSeverityRank,
        affectedVendorsCount: affectedVendorIds.size,
        topEvents: matchingEvents.slice(0, 3).map((e) => ({
          title: e.title,
          severity: e.severity,
          category: e.category,
        })),
      };
    });

    // 2. Compute Regional Disruption Matrix (Category x Region)
    const REGIONS = ['Western India', 'Southern India', 'Northern India', 'Eastern India', 'Central India', 'Pan India'];
    const CATEGORIES = ['Port Disruption', 'Tariff', 'Natural Disaster', 'Geopolitical', 'Logistics', 'Regulatory'];

    const CATEGORY_MAP: Record<string, string> = {
      PORT_DISRUPTION: 'Port Disruption',
      TARIFF: 'Tariff',
      NATURAL_DISASTER: 'Natural Disaster',
      GEOPOLITICAL: 'Geopolitical',
      LOGISTICS: 'Logistics',
      REGULATORY: 'Regulatory',
    };

    const regionalMatrix: Record<string, Record<string, number>> = {};
    for (const reg of REGIONS) {
      regionalMatrix[reg] = {};
      for (const cat of CATEGORIES) {
        regionalMatrix[reg][cat] = 0;
      }
    }

    for (const ev of events) {
      const displayCat = CATEGORY_MAP[ev.category] || 'Logistics';
      const evRegionText = `${ev.region}`.toLowerCase();

      let targetRegion = 'Pan India';
      if (evRegionText.includes('mumbai') || evRegionText.includes('pune') || evRegionText.includes('gujarat') || evRegionText.includes('maharashtra') || evRegionText.includes('western')) {
        targetRegion = 'Western India';
      } else if (evRegionText.includes('chennai') || evRegionText.includes('tamil') || evRegionText.includes('karnataka') || evRegionText.includes('bengaluru') || evRegionText.includes('kochi') || evRegionText.includes('southern')) {
        targetRegion = 'Southern India';
      } else if (evRegionText.includes('delhi') || evRegionText.includes('punjab') || evRegionText.includes('rajasthan') || evRegionText.includes('haryana') || evRegionText.includes('northern')) {
        targetRegion = 'Northern India';
      } else if (evRegionText.includes('kolkata') || evRegionText.includes('bengal') || evRegionText.includes('eastern')) {
        targetRegion = 'Eastern India';
      } else if (evRegionText.includes('madhya') || evRegionText.includes('bhopal') || evRegionText.includes('indore') || evRegionText.includes('central')) {
        targetRegion = 'Central India';
      }

      const score = SEV_MAP[ev.severity] || 1;
      if (regionalMatrix[targetRegion] && regionalMatrix[targetRegion][displayCat] !== undefined) {
        regionalMatrix[targetRegion][displayCat] = Math.max(regionalMatrix[targetRegion][displayCat], score);
      }
    }

    res.json({
      totalEvents: events.length,
      stateDensity,
      regionalMatrix,
      categories: CATEGORIES,
      regions: REGIONS,
    });
  } catch (err) {
    console.error('getHeatmapData error:', err);
    res.status(500).json({ error: 'Failed to calculate disruption heatmap data' });
  }
}

// ─── POST /api/intelligence/sync-gdelt ───────────────────────────────────────
// Manual trigger to pull fresh GDELT news events & classify them
export async function triggerGdeltSync(_req: Request, res: Response) {
  try {
    const result = await runGdeltPipeline();
    res.json({
      success: true,
      message: `GDELT sync completed: ${result.ingested} new events, ${result.affectedVendorsMatched} vendor links created`,
      ...result,
    });
  } catch (err) {
    console.error('triggerGdeltSync error:', err);
    res.status(500).json({ error: 'Failed to sync GDELT events' });
  }
}

// ─── POST /api/intelligence/events ──────────────────────────────────────────
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
