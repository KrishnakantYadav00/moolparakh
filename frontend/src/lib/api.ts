// src/lib/api.ts
// Typed fetch client — every route matches backend src/routes/*

const BASE = (import.meta.env.VITE_API_BASE_URL as string) ?? 'http://localhost:5000/api';

async function req<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...init?.headers },
    ...init,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error((err as { error: string }).error ?? res.statusText);
  }
  return res.json() as Promise<T>;
}

// ─── Raw shapes returned by the backend ─────────────────────────────────────

export interface ApiTrustScore {
  overallScore: number;
  verificationCompleteness: number;
  certificationFreshness: number;
  accountAgeActivity: number;
  manualBuyerFlag: number;
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
}

export interface ApiVerification {
  id: string;
  type: 'PAN' | 'GSTIN' | 'UDYAM' | 'CIN' | 'BANK_ACCOUNT';
  status: 'PENDING' | 'SUCCESS' | 'FAILED' | 'MANUAL_REVIEW';
  createdAt: string;
}

export interface ApiDocument {
  id: string;
  type: string;
  status: string;
  certificateNumber: string | null;
  issuingAuthority: string | null;
  issueDate: string | null;
  expirationDate: string | null;
  uploadedAt: string;
}

export interface ApiVendorEvent {
  id: string;
  kind: string;
  title: string;
  detail: string;
  at: string;
}

export interface ApiTrustPoint {
  score: number;
  recordedAt: string;
}

export interface ApiVendor {
  id: string;
  legalName: string;
  tradeName: string | null;
  email: string;
  phone: string;
  pan: string | null;
  gstin: string | null;
  cin: string | null;
  udyamNumber: string | null;
  msmeCategory: 'MICRO' | 'SMALL' | 'MEDIUM';
  city: string;
  state: string;
  categories: string[];
  contactName: string;
  contactRole: string;
  status: 'DRAFT' | 'PENDING_VERIFICATION' | 'VERIFIED' | 'FLAGGED' | 'REJECTED';
  buyerFlagNote: string | null;
  onboardedAt: string;
  createdAt: string;
  trustScore: ApiTrustScore | null;
  trustHistory: ApiTrustPoint[];
  verifications: ApiVerification[];
  documents: ApiDocument[];
  alerts: unknown[];
  events: ApiVendorEvent[];
}

export interface ApiBid {
  id: string;
  rfqId: string;
  vendorId: string;
  vendorName: string;
  pricePerUnit: number;
  deliveryDays: number;
  trustScoreAtBid: number;
  notes: string | null;
  submittedAt: string;
}

export interface ApiRfq {
  id: string;
  reference: string;
  title: string;
  status: 'DRAFT' | 'OPEN' | 'COMPLETED' | 'CANCELLED';
  spec: Record<string, unknown>;
  freeText: string | null;
  suppliersNotified: number;
  closesAt: string;
  awardedVendorId: string | null;
  createdAt: string;
  bids: ApiBid[];
}

export interface ApiNotification {
  id: string;
  kind: 'HIGH' | 'CRITICAL' | 'COMPLIANCE' | 'RFQ' | 'TRUST';
  title: string;
  vendorName: string;
  detail: string;
  read: boolean;
  createdAt: string;
}

// ─── API methods ─────────────────────────────────────────────────────────────

export const api = {
  vendors: {
    list: () => req<ApiVendor[]>('/vendors'),
    get: (id: string) => req<ApiVendor>(`/vendors/${id}`),
    create: (body: Record<string, unknown>) =>
      req<ApiVendor>('/vendors', { method: 'POST', body: JSON.stringify(body) }),
    update: (id: string, body: Record<string, unknown>) =>
      req<ApiVendor>(`/vendors/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),
  },

  rfqs: {
    list: () => req<ApiRfq[]>('/rfqs'),
    get: (id: string) => req<ApiRfq>(`/rfqs/${id}`),
    create: (body: Record<string, unknown>) =>
      req<ApiRfq>('/rfqs', { method: 'POST', body: JSON.stringify(body) }),
    submitBid: (rfqId: string, body: Record<string, unknown>) =>
      req<ApiBid>(`/rfqs/${rfqId}/bids`, { method: 'POST', body: JSON.stringify(body) }),
    award: (rfqId: string, vendorId: string) =>
      req<ApiRfq>(`/rfqs/${rfqId}/award`, { method: 'PATCH', body: JSON.stringify({ vendorId }) }),
  },

  notifications: {
    list: () => req<ApiNotification[]>('/notifications'),
    markRead: (id: string) =>
      req<ApiNotification>(`/notifications/${id}/read`, { method: 'PATCH' }),
    markAllRead: () =>
      req<{ ok: boolean }>('/notifications/read-all', { method: 'PATCH' }),
    create: (body: Record<string, unknown>) =>
      req<ApiNotification>('/notifications', { method: 'POST', body: JSON.stringify(body) }),
  },
};
