# MoolParakh — Supplier Intelligence Platform

A B2B supplier management platform for Indian MSMEs with trust scoring, KYB verification, RFQ management, and disruption intelligence.

## Project Structure

```
code_part/
├── android/        # Flutter mobile app (supplier-side)
├── backend/        # Express + TypeScript + Prisma + PostgreSQL API
├── frontend/       # React + Vite + Tailwind web dashboard
├── Dockerfile      # Production multi-stage build
└── docker-compose.yml  # Production deployment (builds full image)
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

# Copy env template and edit if needed (default password is: krishna)
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

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start dev server (runs on http://localhost:5173)
npm run dev
```

---

### 4. Android App Setup

```bash
cd android

# Install Flutter dependencies
flutter pub get

# Run on emulator or device
flutter run
```

> In the app: go to **Settings** to toggle **Demo Mode** (works without backend).  
> To connect to live backend, set your PC's local IP as the API URL in Settings.

---

## 🐳 Production (Full Docker Build)

```bash
# From the code_part/ root:
docker build -t moolparakh-d-image .
docker compose up -d
```

The app will be available at **http://localhost** (port 80).

> ⚠️ Remember to run `npx prisma db push` and seed inside the running container or locally before first use.

---

## 🔑 Environment Variables

| Variable | Description | Default |
|---|---|---|
| `DATABASE_URL` | Postgres connection string | `postgresql://postgres:krishna@localhost:5432/fproject2026` |
| `PORT` | API server port | `5000` |
| `NODE_ENV` | Environment | `development` |
| `R2_ACCOUNT_ID` | Cloudflare R2 (optional) | — |
| `R2_ACCESS_KEY_ID` | Cloudflare R2 (optional) | — |
| `R2_SECRET_ACCESS_KEY` | Cloudflare R2 (optional) | — |
| `R2_BUCKET_NAME` | Cloudflare R2 bucket name | `moolparakh-docs` |

> Without R2 credentials, file uploads return `503` but all other API endpoints work normally.

---

## 🛠 API Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `GET` | `/api/vendors` | List vendors |
| `POST` | `/api/vendors` | Create vendor |
| `GET` | `/api/vendors/:id` | Vendor detail |
| `GET` | `/api/rfqs` | List RFQs |
| `POST` | `/api/rfqs` | Create RFQ |
| `GET` | `/api/rfqs/:id` | RFQ + bids |
| `POST` | `/api/rfqs/:id/bids` | Submit bid |
| `GET` | `/api/intelligence/events` | Disruption events |
| `GET` | `/api/relationships` | Supplier relationships |
| `GET` | `/api/notifications` | Notifications |

---

## 👥 Team

| Role | Branch |
|---|---|
| Android | `android/supplier-app` |
| Backend / DB | `main` |
| Web / Cloud | `main` |
