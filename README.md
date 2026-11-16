# MoolParakh — Supplier Intelligence Platform

A B2B supplier management platform for Indian MSMEs with trust scoring, KYB verification, RFQ management, GDELT disruption intelligence, and JWT auth.

## Project Structure

```
code_part/
├── android/        # Flutter mobile app (supplier-side)
├── backend/        # Express + TypeScript + Prisma + PostgreSQL API
├── frontend/       # React + Vite + Tailwind web dashboard
├── nginx/          # Nginx reverse-proxy config (for production EC2)
├── scripts/        # EC2 setup, DB backup, cron install scripts
├── Dockerfile      # Production multi-stage build (frontend + backend)
└── docker-compose.yml  # Production deployment
```

---

## 🚀 Quick Start (Development)

### Prerequisites

- **Node.js 20+** — https://nodejs.org
- **Docker Desktop** — https://www.docker.com/products/docker-desktop
- **Flutter 3.x** (only if working on Android) — https://flutter.dev

---

### 1. Clone the repo

```bash
git clone https://github.com/KrishnakantYadav00/moolparakh.git
cd moolparakh/code_part
```

---

### 2. Backend Setup

```bash
cd backend

# Start PostgreSQL via Docker
docker compose up -d

# Install dependencies
npm install

# Copy env template (default credentials are pre-filled for dev)
copy .env.example .env

# Push schema to database
npx prisma db push

# Seed with demo Indian MSME data
npx tsx prisma/seed.ts

# Start dev server (runs on http://localhost:5000)
npm run dev:server
```

> ✅ Check health: http://localhost:5000/health

---

### 3. Login (Auth is now required for all API calls)

```bash
# Default credentials (set in .env):
# Email:    admin@moolparakh.in
# Password: MoolParakh@2026

curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@moolparakh.in","password":"MoolParakh@2026"}'
# Returns: { "token": "eyJ..." }
```

> The Android app handles login automatically. All API calls require `Authorization: Bearer <token>`.

---

### 4. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start dev server (runs on http://localhost:5173)
npm run dev
```

---

### 5. Android App Setup

```bash
cd android

# Install Flutter dependencies
flutter pub get

# Run on emulator or device
flutter run
```

> In the app: go to **Settings** to toggle **Demo Mode** (works fully without backend).  
> To connect to live backend: set your PC's local Wi-Fi IP as the API URL in Settings, then login with the credentials above.

---

## 🐳 Production (Full Docker Build)

```bash
# From the code_part/ root:
docker build -t moolparakh-d-image .
docker compose up -d
```

The app will be available at **http://localhost** (port 80).

> ⚠️ Remember to run `npx prisma db push` and seed the database before first use.

---

## 🔑 Environment Variables

| Variable | Description | Default |
|---|---|---|
| `DATABASE_URL` | Postgres connection string | `postgresql://postgres:krishna@localhost:5432/fproject2026` |
| `JWT_SECRET` | Secret for signing JWTs | `moolparakh-dev-secret-change-in-prod` |
| `BUYER_EMAIL` | Login email | `admin@moolparakh.in` |
| `BUYER_PASSWORD` | Login password | `MoolParakh@2026` |
| `GEMINI_API_KEY` | Gemini AI — enables LLM spec parser & GDELT classifier | _(optional)_ |
| `PORT` | API server port | `5000` |
| `NODE_ENV` | Environment | `development` |
| `R2_ACCOUNT_ID` | Cloudflare R2 (optional) | — |
| `R2_ACCESS_KEY_ID` | Cloudflare R2 (optional) | — |
| `R2_SECRET_ACCESS_KEY` | Cloudflare R2 (optional) | — |
| `R2_BUCKET_NAME` | Cloudflare R2 bucket name | `moolparakh-docs` |

---

## 🛠 API Endpoints

### Auth (public)
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/auth/login` | Login → returns JWT |
| `GET` | `/api/auth/me` | Verify token / get current user |

### Vendors _(requires Bearer token)_
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/vendors` | List vendors |
| `POST` | `/api/vendors` | Create vendor |
| `GET` | `/api/vendors/:id` | Vendor detail + trust score |
| `PATCH` | `/api/vendors/:id` | Update vendor |
| `POST` | `/api/vendors/:id/verify` | Trigger Surepass KYB verification |
| `GET` | `/api/vendors/:id/relationships` | Supplier relationships |

### RFQs _(requires Bearer token)_
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/rfqs` | List RFQs |
| `POST` | `/api/rfqs` | Create RFQ |
| `POST` | `/api/rfqs/parse-spec` | AI spec parser (Gemini NLP) |
| `GET` | `/api/rfqs/:id` | RFQ + bids |
| `POST` | `/api/rfqs/:id/bids` | Submit bid |
| `PATCH` | `/api/rfqs/:id/award` | Award RFQ to vendor |

### Intelligence _(requires Bearer token)_
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/intelligence/events` | Disruption events |
| `GET` | `/api/intelligence/heatmap` | State-level heatmap data |
| `GET` | `/api/intelligence/risk-leaderboard` | Vendor risk rankings |
| `POST` | `/api/intelligence/sync-gdelt` | Trigger GDELT news sync |

### Other _(requires Bearer token)_
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/notifications` | Notifications |
| `GET` | `/api/relationships` | All supplier relationships |
| `POST` | `/api/documents/presign` | Get R2 upload URL |

---

## 👥 Team

| Role | Branch |
|---|---|
| Android | `android/supplier-app` |
| Backend / DB | `main` |
| Web / Cloud | `main` |
