// src/server.ts
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import db from '@/lib/db.js';
import { r2Enabled } from '@/lib/r2.js';

import vendorRoutes from '@/routes/vendorRoutes.js';
import documentRoutes from '@/routes/documentRoutes.js';
import rfqRoutes from '@/routes/rfqRoutes.js';
import notificationRoutes from '@/routes/notificationRoutes.js';
import intelligenceRoutes from '@/routes/intelligenceRoutes.js';
import relationshipRoutes from '@/routes/relationshipRoutes.js';

const app = express();
const PORT = Number(process.env.PORT ?? 5000);

// ─── Middleware ──────────────────────────────────────────────────────────────
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());

// ─── API Routes ──────────────────────────────────────────────────────────────
app.use('/api/vendors', vendorRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/rfqs', rfqRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/intelligence', intelligenceRoutes);
app.use('/api/relationships', relationshipRoutes);

// ─── Health Check ─────────────────────────────────────────────────────────────
app.get('/health', async (_req, res) => {
  try {
    await db.$queryRaw`SELECT 1`;
    res.json({
      status: 'healthy',
      db: 'connected',
      r2: r2Enabled ? 'configured' : 'not configured (uploads disabled)',
      timestamp: new Date().toISOString(),
    });
  } catch {
    res.status(503).json({ status: 'unhealthy', db: 'disconnected' });
  }
});

// ─── SPA Static Fallback (optional, for when frontend is built) ───────────────
const candidateDistPaths = [
  path.resolve(process.cwd(), '../frontend/dist'),
  path.resolve(process.cwd(), './dist/public'),
  path.resolve(process.cwd(), './public'),
];

const distPath = candidateDistPaths.find((p) => fs.existsSync(path.join(p, 'index.html')));

if (distPath) {
  console.log(`📦 Serving compiled frontend from: ${distPath}`);
  app.use(express.static(distPath));
  app.use((req, res, next) => {
    if (
      req.method === 'GET' &&
      !req.path.startsWith('/api') &&
      req.path !== '/health'
    ) {
      return res.sendFile(path.join(distPath, 'index.html'));
    }
    next();
  });
} else {
  console.log('ℹ️  Running in API-only mode (no frontend dist found)');
}

// ─── Start ───────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🚀 MoolParakh API running on http://localhost:${PORT}`);
  console.log(`   Health: http://localhost:${PORT}/health`);
  console.log(`   R2:     ${r2Enabled ? '✅ configured' : '⚠️  not configured (set R2_* vars to enable uploads)'}\n`);
});
