// src/routes/authRoutes.ts

import { Router } from 'express';
import { login, me } from '@/controllers/authController.js';
import { requireAuth } from '@/middleware/auth.js';

const router = Router();

// POST /api/auth/login — public
router.post('/login', login);

// GET /api/auth/me — protected (verify token still valid)
router.get('/me', requireAuth, me);

export default router;
