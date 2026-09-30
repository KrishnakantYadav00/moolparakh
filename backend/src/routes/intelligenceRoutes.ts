// src/routes/intelligenceRoutes.ts
import { Router } from 'express';
import * as ic from '@/controllers/intelligenceController.js';

const router = Router();

router.get('/events', ic.listEvents);
router.get('/events/:vendorId', ic.eventsForVendor);
router.post('/events', ic.createEvent);

export default router;
