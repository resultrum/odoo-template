# 🐳 Docker Images on GHCR - Complete Guide

This guide explains how to access, manage, and work with Docker images stored in GitHub Container Registry (GHCR).

---

## 🎯 Quick Links

### Access Images Online
- **All Images**: https://github.com/resultrum/odoo-mta/pkgs/container/odoo-mta
- **Organization Packages**: https://github.com/organizations/resultrum/packages

### Direct Docker Commands
```bash
# STAGING Image
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0

# PRODUCTION Image
docker pull ghcr.io/resultrum/odoo-mta:latest
```

---

## 📊 Available Images

### Current Images in GHCR

| Tag | Branch | Purpose | Use Case |
|-----|--------|---------|----------|
| `master-iteration1.0` | `master-iteration1.0` | STAGING | Testing before production |
| `latest` | `main` | PRODUCTION | Production deployments |
| `v*` (semantic versions) | Git tags | VERSIONED | Release candidates |

### Image Details

**STAGING Image:**
- **Name**: `ghcr.io/resultrum/odoo-mta:master-iteration1.0`
- **Branch**: `master-iteration1.0`
- **Use**: Deploy to Azure STAGING environment
- **Platforms**: `linux/amd64`, `linux/arm64` (multi-architecture)
- **Updated**: Automatically on every push to `master-iteration1.0`

**PRODUCTION Image:**
- **Name**: `ghcr.io/resultrum/odoo-mta:latest`
- **Branch**: `main`
- **Use**: Deploy to production environments
- **Platforms**: `linux/amd64`, `linux/arm64` (multi-architecture)
- **Updated**: Automatically on every push to `main`

**Versioned Images (Optional):**
- **Name**: `ghcr.io/resultrum/odoo-mta:v1.0.0`
- **Trigger**: Create git tag: `git tag v1.0.0 && git push --tags`
- **Result**: Creates both `v1.0.0` tag AND updates `latest`

---

## 🔍 How to Find Images on GitHub.com

### Method 1: Via Repository Packages Tab (Easiest)

1. Go to your repository: https://github.com/resultrum/odoo-mta
2. Look for **"Packages"** in the right sidebar (or main navigation)
3. Click on **"Packages"**
4. You'll see the `odoo-mta` container with all tags

**Direct URL:**
```
https://github.com/resultrum/odoo-mta/pkgs/container/odoo-mta
```

### Method 2: Via Organization Packages

If you want to see all packages across the organization:

1. Go to: https://github.com/organizations/resultrum
2. Click **"Packages"** in the left sidebar
3. Filter or search for `odoo-mta`

**Direct URL:**
```
https://github.com/organizations/resultrum/packages
```

### Method 3: Via GitHub Actions Workflow

1. Go to your repo: https://github.com/resultrum/odoo-mta
2. Click **"Actions"** tab
3. Click **"Build & Push Docker to GHCR"** workflow
4. Click on the latest successful run
5. In the logs, you'll see:
   - Image digest
   - Image tags
   - Platforms built

**Direct URL (latest run):**
```
https://github.com/resultrum/odoo-mta/actions/workflows/docker-build-push.yml
```

---

## 📋 What You'll See in the Packages Page

When you open https://github.com/resultrum/odoo-mta/pkgs/container/odoo-mta:

### Image List
```
odoo-mta (Container)
├── master-iteration1.0
│   └── Created: Nov 17, 2025
│   └── Size: ~500 MB
│   └── Platforms: linux/amd64, linux/arm64
│
├── latest
│   └── Created: Nov 17, 2025
│   └── Size: ~500 MB
│   └── Platforms: linux/amd64, linux/arm64
│
└── (older versions...)
```

### Click on any tag to see:

- **Full Image Name**: `ghcr.io/resultrum/odoo-mta:master-iteration1.0`
- **Image Digest**: SHA256 hash
- **Size**: Total image size
- **Platforms**: Supported architectures (amd64, arm64)
- **Created**: Timestamp
- **Updated**: Last modification
- **Visibility**: Public or Private
- **Copy Docker pull command**: One-click copy

---

## 🐳 Docker Commands

### Pull Images

```bash
# STAGING Image
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0

# PRODUCTION Image (latest)
docker pull ghcr.io/resultrum/odoo-mta:latest

# Specific version (if using semantic versioning)
docker pull ghcr.io/resultrum/odoo-mta:v1.0.0
```

### Verify Image Availability

```bash
# Check if image can be pulled (requires auth if private repo)
docker pull ghcr.io/resultrum/odoo-mta:latest --dry-run

# List local images
docker images | grep ghcr.io/resultrum

# Inspect image details
docker inspect ghcr.io/resultrum/odoo-mta:latest
```

### Run Image

```bash
# Run STAGING image
docker run -it \
  -p 8069:8069 \
  -e HOST=postgres \
  -e USER=odoo \
  -e PASSWORD=your-db-password \
  ghcr.io/resultrum/odoo-mta:master-iteration1.0

# Run PRODUCTION image
docker run -it \
  -p 8069:8069 \
  -e HOST=postgres \
  -e USER=odoo \
  -e PASSWORD=your-db-password \
  ghcr.io/resultrum/odoo-mta:latest
```

---

## 🔐 Authentication (If Repo is Private)

If the repository is private, you'll need to authenticate before pulling images:

### Option 1: GitHub CLI (Easiest)

```bash
# Authenticate with GitHub CLI
gh auth login

# Docker will automatically use your GitHub credentials
docker pull ghcr.io/resultrum/odoo-mta:latest
```

### Option 2: Personal Access Token

```bash
# Create a fine-grained PAT (see CREATE_DEPLOYMENT_TOKEN.md)

# Login to GHCR
docker login ghcr.io -u your-username -p your-token

# Now pull images
docker pull ghcr.io/resultrum/odoo-mta:latest
```

### Option 3: Docker Config

See `SECURITY_AUTHENTICATION.md` for secure credential storage options.

---

## 🔄 When Images are Built

### Automatic Builds Trigger On:

1. **Push to `master-iteration*` branches**
   - Builds: `ghcr.io/resultrum/odoo-mta:master-iteration1.0`
   - Status: Check GitHub Actions

2. **Push to `main` branch**
   - Builds: `ghcr.io/resultrum/odoo-mta:latest`
   - Status: Check GitHub Actions

3. **Git tag creation (optional, for versioning)**
   - Command: `git tag v1.0.0 && git push --tags`
   - Builds: Both `ghcr.io/resultrum/odoo-mta:v1.0.0` AND `latest`

### Check Build Status

Go to: https://github.com/resultrum/odoo-mta/actions/workflows/docker-build-push.yml

You'll see:
- ✅ Successful builds
- ❌ Failed builds
- ⏳ In-progress builds
- Build duration
- Commit information

---

## 💡 Common Tasks

### Task 1: Deploy STAGING Image to Azure

```bash
# 1. Authenticate (if private repo)
docker login ghcr.io

# 2. Pull latest STAGING image
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0

# 3. Use with docker-compose
docker-compose -f docker-compose.staging.yml up -d
```

See `STAGING_AZURE_DEPLOYMENT.md` for complete guide.

### Task 2: Deploy PRODUCTION Image to Azure

```bash
# 1. Authenticate
docker login ghcr.io

# 2. Pull production image
docker pull ghcr.io/resultrum/odoo-mta:latest

# 3. Use with docker-compose
docker-compose -f docker-compose.prod.yml up -d
```

See `DEPLOYMENT.md` for complete guide.

### Task 3: Create a Versioned Release

```bash
# 1. Ensure main branch is ready
git checkout main
git pull origin main

# 2. Create git tag
git tag v1.0.0

# 3. Push tag (triggers build)
git push origin v1.0.0

# 4. GitHub Actions will:
#    - Build image
#    - Push to: ghcr.io/resultrum/odoo-mta:v1.0.0
#    - Also update: ghcr.io/resultrum/odoo-mta:latest
```

### Task 4: Check Image History

Go to: https://github.com/resultrum/odoo-mta/pkgs/container/odoo-mta

Scroll down to see:
- All previous tags
- Build dates
- Image sizes
- Update timestamps

---

## 🆘 Troubleshooting

### "Image not found" Error

```bash
# Problem: Image doesn't exist or wrong tag
# Solution: Check available tags

# List all available tags
docker pull ghcr.io/resultrum/odoo-mta:latest  # Try latest first

# Check GitHub Packages page
# https://github.com/resultrum/odoo-mta/pkgs/container/odoo-mta
```

### "Unauthorized" Error (Private Repo)

```bash
# Problem: Not authenticated with GHCR
# Solution: Login first

docker login ghcr.io
# Username: your-github-username
# Password: your-personal-access-token (see CREATE_DEPLOYMENT_TOKEN.md)

# Then retry pull
docker pull ghcr.io/resultrum/odoo-mta:latest
```

### "No matching manifest for linux/arm64"

```bash
# Problem: Image not built for ARM64 architecture
# Solution: Check workflow config

# GitHub Actions should build for both:
# - linux/amd64 (Intel, AMD)
# - linux/arm64 (Apple Silicon, ARM servers)

# Check: .github/workflows/docker-build-push.yml
# Should have: platforms: linux/amd64,linux/arm64
```

### Build Seems Stuck or Failed

1. Go to GitHub Actions: https://github.com/resultrum/odoo-mta/actions
2. Click "Build & Push Docker to GHCR" workflow
3. Click the failed/stuck run
4. Expand "Build and push Docker image" step
5. Scroll to see error details
6. Common issues:
   - Docker build failure (check Dockerfile)
   - Network issues
   - GitHub Actions quota exceeded

---

## 📚 Related Documentation

- **DEPLOYMENT.md** - How to deploy images (general)
- **STAGING_AZURE_DEPLOYMENT.md** - Azure STAGING deployments
- **SECURITY_AUTHENTICATION.md** - Authentication & token management
- **CREATE_DEPLOYMENT_TOKEN.md** - Token creation guide
- **GUIDE.md** - Project architecture

---

## 🔗 Useful Links

| Resource | URL |
|----------|-----|
| All Images | https://github.com/resultrum/odoo-mta/pkgs/container/odoo-mta |
| GitHub Actions | https://github.com/resultrum/odoo-mta/actions |
| Docker Build Workflow | https://github.com/resultrum/odoo-mta/actions/workflows/docker-build-push.yml |
| Organization Packages | https://github.com/organizations/resultrum/packages |
| Repository Settings | https://github.com/resultrum/odoo-mta/settings |
| Workflow File | https://github.com/resultrum/odoo-mta/blob/main/.github/workflows/docker-build-push.yml |

---

## ✅ Quick Reference

### What's in Each Environment?

**STAGING (`master-iteration1.0`):**
- Tag: `ghcr.io/resultrum/odoo-mta:master-iteration1.0`
- Use: Testing new features before production
- Database: Separate from production
- Updates: On every push to `master-iteration1.0`

**PRODUCTION (`main`):**
- Tag: `ghcr.io/resultrum/odoo-mta:latest`
- Use: Live user-facing environment
- Database: Critical data
- Updates: On every push to `main` (be careful!)

**VERSIONED RELEASES (Optional):**
- Tag: `ghcr.io/resultrum/odoo-mta:v1.0.0`
- Use: Specific release versions
- Create: `git tag v1.0.0 && git push --tags`

---

## 📞 Need Help?

1. Check this guide (DOCKER_IMAGES.md)
2. See DEPLOYMENT.md for deployment procedures
3. See STAGING_AZURE_DEPLOYMENT.md for Azure specific steps
4. Review GitHub Actions logs: https://github.com/resultrum/odoo-mta/actions
5. Check CREATE_DEPLOYMENT_TOKEN.md for authentication issues

---

**Last Updated:** 2025-11-17
**Version:** 1.0
**Audience:** All developers and DevOps engineers
**Repository:** https://github.com/resultrum/odoo-mta
