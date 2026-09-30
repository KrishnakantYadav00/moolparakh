// src/routes/relationshipRoutes.ts
import { Router } from 'express';
import * as rc from '@/controllers/relationshipController.js';

const router = Router();

router.get('/', rc.listRelationships);
router.post('/', rc.createRelationship);
router.delete('/:id', rc.deleteRelationship);

export default router;
