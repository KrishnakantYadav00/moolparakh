// src/routes/documentRoutes.ts
import { Router } from 'express';
import * as dc from '@/controllers/documentController.js';

const router = Router();

router.post('/presign', dc.presignUpload);
router.post('/', dc.recordDocument);
router.get('/:vendorId', dc.listDocuments);
router.patch('/:id/status', dc.updateDocumentStatus);

export default router;
