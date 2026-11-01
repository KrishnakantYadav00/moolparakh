// src/lib/auth.ts
// JWT sign/verify utilities

import jwt from 'jsonwebtoken';

export const JWT_SECRET = process.env.JWT_SECRET ?? 'moolparakh-dev-secret-change-in-prod';
const EXPIRES_IN = '7d';

export function signToken(payload: object): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: EXPIRES_IN });
}

export function verifyToken(token: string): jwt.JwtPayload | string {
  return jwt.verify(token, JWT_SECRET);
}
