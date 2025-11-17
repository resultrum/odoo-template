# 🚀 STAGING Deployment on Azure - Developer Guide

This guide explains how to deploy the Odoo MTA STAGING image to Azure using secure authentication.

---

## 🔐 Authentication Setup (CRITICAL - Read First!)

### ⚠️ IMPORTANT: Never Use Personal Access Tokens in Production!

**DO NOT:**
```bash
❌ docker login ghcr.io
   Username: your-personal-github-account
   Password: your-personal-PAT-token
```

**WHY?** Your personal token has access to ALL your repositories and could compromise security if leaked.

---

## ✅ Proper Authentication Method: GitHub Actions Secrets + Deployment Keys

### Step 1: Create a Deployment-Specific Service Account (Recommended)

**Option A: GitHub Organization Token (Best for Teams)**

1. Go to GitHub Org Settings → Developer Settings → Personal Access Tokens → Fine-grained tokens
2. Create new token:
   - **Token name**: `odoo-mta-staging-deployer`
   - **Expiration**: 90 days
   - **Repository access**: `Only select repositories` → Select `resultrum/odoo-mta`
   - **Permissions**:
     - `read:packages` (pull images only)
   - ✅ Create and copy the token

**Option B: GitHub App (Enterprise-Grade - Recommended for large teams)**

1. Go to GitHub Org Settings → Developer Settings → GitHub Apps
2. Create new App:
   - **Name**: `odoo-mta-staging-deployer`
   - **Permissions**:
     - `contents`: read-only
     - `packages`: read-only
   - Create and install on repo

---

### Step 2: Store Credentials Securely

**For your Azure VM, use ONE of these methods:**

#### Method 1: GitHub Secrets (Recommended - Automated)

Store token in GitHub repo as a secret, then GitHub Actions handles authentication.

```
GitHub Repo → Settings → Secrets and variables → Actions
+ New repository secret

Name: GHCR_TOKEN
Value: <your-deployment-token>
```

Then in your deployment script on Azure, retrieve it via:
```bash
# On Azure VM - this would come from GitHub Actions env vars
# (only available when deploying via CI/CD)
docker login ghcr.io -u "${{ github.actor }}" -p "${{ secrets.GHCR_TOKEN }}"
```

#### Method 2: .docker/config.json (For Azure Manual Deployments)

Create a secure credentials file on your Azure VM:

```bash
# On Azure VM, create Docker credentials
mkdir -p ~/.docker

cat > ~/.docker/config.json << EOF
{
  "auths": {
    "ghcr.io": {
      "auth": "$(echo -n 'USERNAME:DEPLOYMENT_TOKEN' | base64)"
    }
  }
}
EOF

# Secure the file
chmod 600 ~/.docker/config.json
```

⚠️ **SECURITY NOTES:**
- Never commit `config.json` to Git
- Rotate tokens every 90 days
- Use `read:packages` permission ONLY (no write access)

#### Method 3: .netrc File (Alternative)

```bash
# On Azure VM
cat > ~/.netrc << EOF
machine ghcr.io
login your-deployment-username
password your-deployment-token
EOF

chmod 600 ~/.netrc
```

---

## 📋 Prerequisites on Azure VM

```bash
# 1. SSH into your Azure VM
ssh -i your-key.pem azureuser@your-vm-ip

# 2. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 3. Add user to docker group
sudo usermod -aG docker azureuser
newgrp docker

# 4. Verify Docker installation
docker --version
docker run hello-world

# 5. Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

---

## 🚀 Deployment Steps on Azure

### Step 1: Authenticate with GHCR

**If using GitHub Secrets + CI/CD:**
```bash
# GitHub Actions will handle this automatically
```

**If manual deployment on Azure VM:**
```bash
# Option A: Using stored credentials
docker login ghcr.io
# Will use ~/.docker/config.json or ~/.netrc

# Option B: Inline (less secure)
docker login ghcr.io -u deployment-user -p <deployment-token>

# Verify
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148
```

---

### Step 2: Create Deployment Directory

```bash
# Create staging deployment directory
mkdir -p /opt/odoo-mta-staging
cd /opt/odoo-mta-staging

# Create .env file (NEVER commit this!)
cat > .env << 'EOF'
# Database configuration
DB_PASSWORD=<strong-staging-password-change-me>

# Odoo admin configuration
ODOO_ADMIN_PASSWORD=<strong-admin-password-change-me>

# Backup path
BACKUP_PATH=/backups/odoo-mta/staging
EOF

# Secure .env file
chmod 600 .env

# Add to .gitignore (if in a repo)
echo ".env" >> .gitignore
```

⚠️ **SECURITY:** Generate strong passwords:
```bash
# Generate strong random password
openssl rand -base64 32
```

---

### Step 3: Create docker-compose.staging.yml

**Copy from local test** or create new:

```bash
# Get the file from your test environment
scp -i your-key.pem \
  /Users/jonathannemry/Projects/odoo-mta-staging-test/docker-compose.staging.yml \
  azureuser@your-vm-ip:/opt/odoo-mta-staging/
```

Or create inline:

```yaml
# /opt/odoo-mta-staging/docker-compose.staging.yml

version: '3.8'

services:
  web:
    image: ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148
    container_name: odoo-mta-staging-web
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "80:8069"  # Map port 80 to Odoo (adjust as needed)
    environment:
      - HOST=postgres
      - USER=odoo
      - PASSWORD=${DB_PASSWORD}
      - ENABLE_GIT_AGGREGATE=false
    volumes:
      - odoo-staging-data:/var/lib/odoo
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8069/web/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  postgres:
    image: postgres:15-alpine
    container_name: odoo-mta-staging-db
    environment:
      POSTGRES_DB: mta-staging
      POSTGRES_USER: odoo
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres-staging-data:/var/lib/postgresql/data
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo -d mta-staging"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

volumes:
  postgres-staging-data:
  odoo-staging-data:
```

---

### Step 4: Deploy to Azure

```bash
cd /opt/odoo-mta-staging

# Load environment variables
export $(cat .env | xargs)

# Pull the latest STAGING image
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148

# Start containers
docker-compose -f docker-compose.staging.yml up -d

# Wait for startup (~30 seconds)
sleep 30

# Check status
docker-compose -f docker-compose.staging.yml ps
```

---

### Step 5: Initialize Database

```bash
# Initialize Odoo database with base modules
docker-compose -f docker-compose.staging.yml exec web \
  odoo -d mta-staging \
    --db_host=postgres \
    --db_user=odoo \
    --db_password=$(grep DB_PASSWORD .env | cut -d= -f2) \
    -i base \
    --stop-after-init

# Restart web service
docker-compose -f docker-compose.staging.yml restart web

# Wait for startup
sleep 15
```

---

### Step 6: Verify Deployment

```bash
# Check containers are healthy
docker-compose -f docker-compose.staging.yml ps

# Check logs
docker-compose -f docker-compose.staging.yml logs web | tail -20

# Test health endpoint
curl http://localhost:8069/web/health

# Access Odoo web interface
# Open browser: http://<your-azure-vm-ip>/web
```

---

## 🔄 Updating STAGING Image

When you push to `master-iteration*` branch, GitHub Actions builds new image.

To deploy updated image on Azure:

```bash
cd /opt/odoo-mta-staging

# Pull new image
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148

# Restart services (database data persists)
docker-compose -f docker-compose.staging.yml down
docker-compose -f docker-compose.staging.yml up -d

# Verify
docker-compose -f docker-compose.staging.yml logs web | tail -20
```

✅ **Database persists across updates!** No data loss.

---

## 📊 Monitoring & Maintenance

### View logs

```bash
# Real-time logs
docker-compose -f docker-compose.staging.yml logs -f web

# Last 50 lines
docker-compose -f docker-compose.staging.yml logs web --tail 50
```

### Database operations

```bash
# Connect to PostgreSQL
docker-compose -f docker-compose.staging.yml exec postgres \
  psql -U odoo -d mta-staging

# Backup database
docker-compose -f docker-compose.staging.yml exec -T postgres \
  pg_dump -U odoo -d mta-staging -F custom \
  > backup_$(date +%Y%m%d_%H%M%S).dump

# Restore database
cat backup_20251117_120000.dump | \
  docker-compose -f docker-compose.staging.yml exec -T postgres \
  pg_restore -U odoo -d mta-staging -F custom
```

### Stop/Start

```bash
# Stop containers (data persists)
docker-compose -f docker-compose.staging.yml down

# Start containers
docker-compose -f docker-compose.staging.yml up -d

# Restart containers
docker-compose -f docker-compose.staging.yml restart
```

---

## 🔐 Security Checklist

- [ ] **Credentials**
  - [ ] Generated strong passwords (32 chars minimum)
  - [ ] .env file NOT committed to Git
  - [ ] Using deployment token (NOT personal token)
  - [ ] Token has `read:packages` permission ONLY
  - [ ] Token set to 90-day expiration

- [ ] **Azure VM**
  - [ ] SSH key secured (400 permissions)
  - [ ] Docker credentials in ~/.docker/config.json (600 permissions)
  - [ ] Firewall rules: only ports 80/443 exposed
  - [ ] SSH: only key-based auth (no password)

- [ ] **Updates**
  - [ ] Rotate deployment token every 90 days
  - [ ] Review GitHub Actions logs regularly
  - [ ] Monitor Odoo logs for errors
  - [ ] Backup database before updates

---

## 🆘 Troubleshooting

### "Error response from daemon: failed to authorize"

```bash
# Solution: Re-authenticate
docker logout ghcr.io
# Use proper credentials (deployment token, not personal)
docker login ghcr.io
```

### "Connection refused - database"

```bash
# Check PostgreSQL is running
docker-compose -f docker-compose.staging.yml ps postgres

# Check logs
docker-compose -f docker-compose.staging.yml logs postgres

# Restart
docker-compose -f docker-compose.staging.yml restart postgres
```

### "Port 8069 already in use"

```bash
# Find what's using port 8069
sudo lsof -i :8069

# Kill process or use different port in docker-compose.staging.yml
# Change: ports: ["8080:8069"]
```

### Database initialization fails

```bash
# Check if database already exists
docker-compose -f docker-compose.staging.yml exec postgres \
  psql -U odoo -l

# If exists, you can skip initialization
# If not, re-run initialization step
```

---

## 📞 Support & Escalation

For issues:

1. Check logs: `docker-compose logs`
2. Verify credentials: `docker login -u deployer ghcr.io`
3. Check GitHub Actions: https://github.com/resultrum/odoo-mta/actions
4. Review this guide: STAGING_AZURE_DEPLOYMENT.md
5. Contact DevOps team if needed

---

## 🔗 Related Documentation

- See `DEPLOYMENT.md` for general deployment info
- See `GUIDE.md` for project architecture
- See GitHub Actions: `.github/workflows/docker-build-push.yml`

---

**Last Updated:** 2025-11-17
**Version:** 1.0
**For:** Odoo MTA Project
**Audience:** Developers & DevOps Engineers
