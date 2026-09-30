// src/routes/notificationRoutes.ts
import { Router } from 'express';
import * as nc from '@/controllers/notificationController.js';

const router = Router();

router.get('/', nc.listNotifications);
router.patch('/read-all', nc.markAllRead);        // must come before /:id
router.patch('/:id/read', nc.markRead);
router.post('/', nc.createNotification);

export default router;
