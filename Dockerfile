# ============================================================
# Stage 1: Build React Frontend
# ============================================================
FROM node:20-alpine AS frontend-builder

WORKDIR /app/frontend

# Install dependencies
COPY frontend/package*.json ./
RUN npm ci

# Copy source and build
COPY frontend/ ./
RUN npm run build
# Output: /app/frontend/dist


# ============================================================
# Stage 2: Production Backend (serves API + frontend)
# ============================================================
FROM node:20-alpine AS production

WORKDIR /app/backend

# Install backend dependencies
COPY backend/package*.json ./
RUN npm ci

# Copy backend source
COPY backend/ ./

# Copy built frontend into the place server.ts looks for it:
# candidateDistPaths checks '../frontend/dist' relative to cwd (/app/backend)
COPY --from=frontend-builder /app/frontend/dist /app/frontend/dist

# Generate Prisma client
RUN npx prisma generate

# Expose the port the Express server listens on
EXPOSE 5000

# Start the server using tsx (handles @/* path aliases natively)
CMD ["npx", "tsx", "src/server.ts"]
