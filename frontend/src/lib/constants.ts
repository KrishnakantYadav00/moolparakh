// src/lib/constants.ts
// Static app-level constants — replaces the deleted mockData exports

import type { DisruptionCategory } from '@/types';

export const organisation = {
  name: 'Apex Components Pvt. Ltd.',
  role: 'Procurement Admin',
  user: 'R. Iyer',
  plants: ['Apex Components Pvt. Ltd.', 'Apex Components — Chakan Plant'],
};

export const kpiTrends = {
  verifiedVendorsChangePercent: 8.4,
  averageTrustChange: 2.1,
  rfqsClosingThisWeek: 4,
};

export const disruptionCategories: DisruptionCategory[] = [
  'Port Disruption',
  'Tariff',
  'Natural Disaster',
  'Geopolitical',
  'Logistics',
  'Regulatory',
];

export const disruptionRegions = [
  'Western India',
  'Southern India',
  'Northern India',
  'Eastern India',
  'South-East Asia',
  'Gulf & Middle East',
];

export const heatmapMatrix: Record<string, Record<DisruptionCategory, number>> = {
  'Western India':    { 'Port Disruption': 3, Tariff: 2, 'Natural Disaster': 2, Geopolitical: 1, Logistics: 2, Regulatory: 1 },
  'Southern India':   { 'Port Disruption': 1, Tariff: 2, 'Natural Disaster': 0, Geopolitical: 0, Logistics: 3, Regulatory: 1 },
  'Northern India':   { 'Port Disruption': 0, Tariff: 1, 'Natural Disaster': 1, Geopolitical: 2, Logistics: 1, Regulatory: 2 },
  'Eastern India':    { 'Port Disruption': 2, Tariff: 1, 'Natural Disaster': 2, Geopolitical: 1, Logistics: 4, Regulatory: 0 },
  'South-East Asia':  { 'Port Disruption': 2, Tariff: 3, 'Natural Disaster': 1, Geopolitical: 2, Logistics: 1, Regulatory: 1 },
  'Gulf & Middle East':{ 'Port Disruption': 1, Tariff: 1, 'Natural Disaster': 0, Geopolitical: 3, Logistics: 2, Regulatory: 0 },
};
