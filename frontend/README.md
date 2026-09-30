# MoolParakh

**Know Your Vendor. Before the Invoice.**

An India-first procurement intelligence dashboard for MSME buyers: vendor verification,
a transparent Vendor Trust Score, compliance expiry tracking, supplier disruption
monitoring, and explainable bid evaluation.

This is an authenticated buyer portal — not a marketing site. It opens directly into the
product.

## Running it

```bash
npm install
npm run dev
```

Then open the URL Vite prints (default `http://localhost:5173`).

Other scripts: `npm run typecheck`, `npm run build`, `npm run preview`.

## Stack

React 18 · TypeScript · Vite · Tailwind CSS 3 · lucide-react · Recharts.
No router (single-page view switching), no UI kit, no backend. Path alias `@ → /src`.

## Screens

| Nav item | What it does |
|---|---|
| Overview | Four KPIs, trust score distribution/trend, compliance alerts, supplier risk snapshot |
| Vendors | Searchable table with filters, 3-step Add Vendor wizard, full vendor profile with 5 tabs |
| Compliance | Expiry calendar, upcoming and expired lists, Attention Required panel |
| Supplier Intelligence | Risk leaderboard, disruption heatmap, late-delivery histogram, trust trends, live feed, supplier drilldown |
| RFQs & Bids | Open/Draft/Completed lists, 3-step RFQ wizard, bid comparison with adjustable weights and award flow |
| Notifications | Full alert list; the bell in the top bar opens the same data as a drawer |
| Settings | Organisation profile, reminder thresholds, scoring weights, verification sources |

## The two formulas

**Vendor Trust Score (0–100)** — `src/utils/trustScore.ts`

| Component | Weight |
|---|---|
| Verification Completeness | 40% |
| Certification Freshness | 35% |
| Account Age & Activity | 15% |
| Manual Buyer Flag | 10% |

The score ring on the vendor profile draws each component as a separate arc, so the
number is always traceable back to its parts. The same four segments appear as a compact
meter in every table.

**Bid composite score** — `src/utils/bidEvaluation.ts`

```
composite = priceScore × w_price + deliveryScore × w_delivery + trustScore × w_trust
```

Defaults are 45 / 30 / 25. Price and delivery are "lower is better", so each bid is
normalised against the best bid received (best = 1.00); trust is the vendor score ÷ 100.
The three sliders always total 100% — moving one redistributes the difference across the
other two — and the ranking recalculates client-side on every change.

The "Why this bid?" explanation is assembled deterministically from each bid's rank on
each criterion. No language model is called at runtime.

## Mock data

Everything lives in `src/data/mockData.ts`: 18 synthetic vendors with certificates,
30-day trust histories, event timelines and delivery records, plus disruption events,
RFQs with bids, supplier relationships and notifications. Company names, GSTINs, PANs,
CINs and people are invented.

Two things worth knowing:

- **Fixed demo clock.** `DEMO_NOW` in `src/utils/format.ts` is pinned to 25 Aug 2026 so
  every expiry countdown, calendar position and "x days ago" label stays stable during a
  demo. Change it to `new Date()` when the API is live.
- **KPI values are derived from the data**, not hardcoded, so the numbers on the Overview
  match what you find when you click into Vendors and Compliance. The month-on-month
  deltas (↑8.4%, +2.1) remain mock trend constants in `kpiTrends`.

To connect a real backend, replace the exported constants in `mockData.ts` with fetch
calls returning the shapes in `src/types/index.ts`. No component reads data any other way.

## Structure

```
src/
  types/index.ts           domain types
  data/mockData.ts         synthetic dataset
  utils/                   trustScore, bidEvaluation, compliance, format (+ demo clock)
  components/
    ui/                    Button, Card, Badge, Modal, SlideOver, trust visuals, chart bits
    layout/                AppShell, Sidebar, TopBar, Notifications, Settings
    dashboard/             Overview and its panels
    vendors/               list, detail, onboarding wizard, relationship modal
    compliance/            calendar and compliance page
    intelligence/          leaderboard, heatmap, charts, feed, drilldown
    rfq/                   RFQ list, wizard, bid comparison, explainability panel
```

## Notes

- Loading, empty and error states are implemented (the Overview skeletons on mount; the
  Add Vendor wizard shows a verification error state if the GSTIN format fails).
- Modals and the slide-over trap focus, close on Escape, restore focus on close, and lock
  body scroll.
- Below `md`, tables become cards, the sidebar becomes a drawer, and wizards go
  single-column.
- Collusion detection is a synthetic demonstration only: two supplier pairs share a
  director or a registered address. It flags bids for review; it never accuses anyone.
