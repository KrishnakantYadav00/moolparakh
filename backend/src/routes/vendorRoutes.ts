// src/routes/vendorRoutes.ts
import { Router } from 'express';
import * as vc from '@/controllers/vendorController.js';

const router = Router();

router.get('/', vc.listVendors);
router.post('/', vc.createVendor);
router.get('/:id', vc.getVendor);
router.patch('/:id', vc.updateVendor);
router.post('/:id/verify', vc.triggerVendorVerification);
router.get('/:id/relationships', vc.getRelationships);

export default router;
