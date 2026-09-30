// src/routes/rfqRoutes.ts
import { Router } from 'express';
import * as rc from '@/controllers/rfqController.js';

const router = Router();

router.get('/', rc.listRfqs);
router.post('/', rc.createRfq);
router.get('/:id', rc.getRfq);
router.post('/:id/bids', rc.submitBid);
router.patch('/:id/award', rc.awardBid);

export default router;
