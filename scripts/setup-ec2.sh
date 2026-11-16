#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/setup-ec2.sh
# One-time EC2 / Amazon Linux 2023 setup script.
# Run as ec2-user after git-cloning the project onto the instance.
#
# Usage:
#   chmod +x scripts/setup-ec2.sh
#   sudo ./scripts/setup-ec2.sh yourdomain.com admin@you.com
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DOMAIN="${1:-yourdomain.com}"
EMAIL="${2:-admin@yourdomain.com}"
APP_DIR="/home/ec2-user/moolparakh"

echo "=== MoolParakh EC2 Setup ==="
echo "Domain : $DOMAIN"
echo "Email  : $EMAIL"
echo ""

# ── 1. Install Docker + Docker Compose ───────────────────────────────────────
echo "[1/6] Installing Docker..."
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

# Docker Compose v2 (plugin)
COMPOSE_VERSION="v2.27.1"
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
echo "Docker $(docker --version) installed."
echo "Docker Compose $(docker compose version) installed."

# ── 2. Install Nginx ──────────────────────────────────────────────────────────
echo "[2/6] Installing Nginx..."
dnf install -y nginx
systemctl enable --now nginx

# ── 3. Install Certbot (Let's Encrypt) ───────────────────────────────────────
echo "[3/6] Installing Certbot..."
dnf install -y python3-certbot-nginx

# ── 4. Obtain TLS certificate ─────────────────────────────────────────────────
echo "[4/6] Obtaining Let's Encrypt certificate for $DOMAIN..."
# Temporarily stop nginx so certbot can bind port 80
systemctl stop nginx

certbot certonly \
  --standalone \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  -d "$DOMAIN" \
  -d "www.$DOMAIN"

# Start nginx back
systemctl start nginx

# ── 5. Deploy Nginx config ────────────────────────────────────────────────────
echo "[5/6] Deploying Nginx config..."
CONF_SRC="$APP_DIR/nginx/moolparakh.conf"
CONF_DST="/etc/nginx/conf.d/moolparakh.conf"

# Replace placeholder domain with the real one
sed "s/yourdomain.com/$DOMAIN/g" "$CONF_SRC" > "$CONF_DST"

nginx -t && systemctl reload nginx
echo "Nginx configured for $DOMAIN."

# ── 6. Install backup cron ────────────────────────────────────────────────────
echo "[6/6] Installing daily backup cron..."
chmod +x "$APP_DIR/scripts/backup-db.sh"
(crontab -l 2>/dev/null; echo "0 2 * * * $APP_DIR/scripts/backup-db.sh >> /home/ec2-user/backups/backup.log 2>&1") | crontab -
echo "Backup cron set for 02:00 UTC daily."

echo ""
echo "✅ Setup complete!"
echo "   Next steps:"
echo "   1. Edit .env in $APP_DIR (set JWT_SECRET, BUYER_PASSWORD, etc.)"
echo "   2. docker compose up -d"
echo "   3. docker exec moolparakh_app npx tsx prisma/seed.ts"
echo "   4. Visit https://$DOMAIN"
