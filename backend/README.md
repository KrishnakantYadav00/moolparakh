# MoolParakh — TI4 Backend

Express + TypeScript + Prisma + PostgreSQL + Cloudflare R2.

## Prerequisites

- Node.js 20+
- Docker Desktop (for the local Postgres container)

## Quick Start

```bash
# 1. Start Postgres
docker compose up -d

# 2. Install dependencies
npm install

# 3. Copy env and edit if needed
copy .env.example .env

# 4. Run migrations
npx prisma migrate dev --name init

# 5. Start the dev server
npm run dev:server
```

The server runs on **http://localhost:5000**.

## Health Check

```
GET /health
```
Returns `{ status, db, r2, timestamp }`.  
`db: "connected"` means Postgres is reachable.  
`r2: "not configured"` is expected during dev if you haven't set R2 credentials.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/vendors` | List all vendors |
| `POST` | `/api/vendors` | Create vendor |
| `GET` | `/api/vendors/:id` | Vendor detail |
| `PATCH` | `/api/vendors/:id` | Update vendor |
| `GET` | `/api/vendors/:id/relationships` | Supplier relationships for vendor |
| `POST` | `/api/documents/presign` | Get R2 pre-signed PUT URL |
| `POST` | `/api/documents` | Record document after upload |
| `GET` | `/api/documents/:vendorId` | List vendor documents |
| `PATCH` | `/api/documents/:id/status` | Update document/OCR status |
| `GET` | `/api/rfqs` | List RFQs |
| `POST` | `/api/rfqs` | Create RFQ |
| `GET` | `/api/rfqs/:id` | RFQ + bids |
| `POST` | `/api/rfqs/:id/bids` | Submit bid |
| `PATCH` | `/api/rfqs/:id/award` | Award RFQ to vendor |
| `GET` | `/api/notifications` | All notifications |
| `POST` | `/api/notifications` | Create notification |
| `PATCH` | `/api/notifications/:id/read` | Mark one read |
| `PATCH` | `/api/notifications/read-all` | Mark all read |
| `GET` | `/api/intelligence/events` | All disruption events |
| `GET` | `/api/intelligence/events/:vendorId` | Events for a vendor |
| `POST` | `/api/intelligence/events` | Create disruption event |
| `GET` | `/api/relationships` | All supplier relationships |
| `POST` | `/api/relationships` | Create relationship |
| `DELETE` | `/api/relationships/:id` | Delete relationship |

## Cloudflare R2 (optional in dev)

Set `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME` in `.env`.  
Without these, `POST /api/documents/presign` returns `503`. All other endpoints work normally.
