// src/controllers/authController.ts
// Single-buyer login — returns a JWT on success

import type { Request, Response } from 'express';
import { signToken } from '@/lib/auth.js';

export async function login(req: Request, res: Response): Promise<void> {
  const { email, password } = req.body as { email?: string; password?: string };

  if (!email || !password) {
    res.status(400).json({ error: 'email and password are required' });
    return;
  }

  const validEmail = process.env.BUYER_EMAIL ?? 'admin@moolparakh.in';
  const validPassword = process.env.BUYER_PASSWORD ?? 'MoolParakh@2026';

  if (email !== validEmail || password !== validPassword) {
    res.status(401).json({ error: 'Invalid credentials' });
    return;
  }

  const token = signToken({ email, role: 'buyer' });
  res.json({ token, email, role: 'buyer' });
}

export async function me(req: Request, res: Response): Promise<void> {
  // req.user is set by requireAuth middleware
  res.json((req as Request & { user: unknown }).user);
}
