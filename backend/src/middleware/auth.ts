// src/middleware/auth.ts
// Express middleware — requires a valid Bearer JWT on all protected routes

import type { Request, Response, NextFunction } from 'express';
import { verifyToken } from '@/lib/auth.js';

export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  // Allow pre-flight CORS requests through without auth
  if (req.method === 'OPTIONS') {
    next();
    return;
  }

  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized — missing Bearer token' });
    return;
  }

  const token = header.slice(7);
  try {
    const payload = verifyToken(token);
    (req as Request & { user: unknown }).user = payload;
    next();
  } catch {
    res.status(401).json({ error: 'Unauthorized — invalid or expired token' });
  }
}
