# CI/CD Pipeline Guide for odoo-mta

Complete documentation for the GitHub Actions CI/CD pipeline.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Workflows](#workflows)
4. [Setup & Configuration](#setup--configuration)
5. [Usage](#usage)
6. [Troubleshooting](#troubleshooting)

---

## Overview

The odoo-mta CI/CD pipeline automates:

- **Testing**: Runs linting, tests, and coverage checks on every push/PR
- **Building**: Creates Docker images tagged for UAT
- **Deploying**: Auto-deploys to UAT, manual deploys to PROD and Odoo.sh
- **Monitoring**: Health checks with automatic rollback capability

### Key Features

✅ **80% Test Coverage Gate** - PRs blocked if coverage < 80% or regresses
✅ **Separate Storage** - odoo-mta:uat-* for UAT, odoo-mta:prod-* for PROD
✅ **Multi-target** - Deploy to VM (Docker), Odoo.sh (native), or Local dev
✅ **Automated Rollback** - UAT auto-rolls back on health check failure
✅ **Database Safety** - Backups created before every deployment
✅ **Anonymization** - PROD→UAT data copy with GDPR compliance

---

## Architecture

### Pipeline Flow

```
Developer pushes code
    ↓
[CI] Test & Lint → Coverage check (80% gate)
    ↓ (pass)
Merge to main
    ↓
[Build] Docker image → Push to odoo-mta:uat-*
    ↓
[Deploy-UAT] Auto-deploy to UAT VM
    ↓ (health check success)
UAT ready for testing
    ↓
[Deploy-PROD] Manual trigger (approval)
    ↓
Push prod-* image to Docker Hub
Deploy to PROD VM with backups
    ↓ (health check)
PROD ready
```

### Image Storage Strategy

```
Docker Hub
├── odoo-mta:uat-latest         (latest working UAT version)
├── odoo-mta:uat-v0.1.0         (specific UAT versions)
├── odoo-mta:uat-abc123def      (commit-based UAT tags)
│
└── odoo-mta:prod-v0.1.0        (PROD versions - created on PROD deploy)
    odoo-mta:prod-v0.0.9
    odoo-mta:prod-v0.0.8
    (keep last 5 versions)
```

---

## Workflows

### 1. CI Workflow (`ci.yml`)

**Triggers**: Every push, every pull request

**Steps**:
1. Checkout code
2. Setup Python environment
3. Run black formatting check
4. Run isort import check
5. Run flake8 linting
6. Validate module manifests
7. Run pytest with coverage
8. Check for hardcoded secrets
9. Verify .gitignore configuration
10. Build Docker image (test build)
11. Scan for Odoo modules

**Success Criteria**:
- ✅ All linting passes
- ✅ Tests pass
- ✅ Coverage ≥ 80%
- ✅ No coverage regression
- ✅ No hardcoded secrets found

**Failure Actions**:
- ❌ PR cannot be merged if CI fails
- ❌ Blocks on low coverage or regression
- ❌ Requires developer fixes

### 2. Build UAT Workflow (`build-uat.yml`)

**Triggers**: Merge to main

**Steps**:
1. Checkout code
2. Generate image metadata (version, commit, build date)
3. Login to Docker Hub
4. Build Docker image
5. Push with tags:
   - `resultrum/odoo-mta:uat-latest`
   - `resultrum/odoo-mta:uat-v0.1.0` (version)
   - `resultrum/odoo-mta:uat-abc123` (commit)
6. Create GitHub Release (optional)

**Outputs**:
- Docker image on Docker Hub
- Ready for UAT deployment

### 3. Deploy UAT Workflow (`deploy-uat.yml`)

**Triggers**:
- Automatically after build-uat completes
- Manual trigger with image tag selection

**Steps**:
1. Verify image exists on Docker Hub
2. SSH to UAT VM
3. Backup current database (timestamped)
4. Pull new image
5. Stop old containers
6. Run migrations
7. Start new containers
8. Health check (http://uat-host:8069)
9. On failure: Auto-rollback

**Rollback**:
- Stops new containers
- Restores database from backup
- Starts previous version
- Alerts team

### 4. Deploy PROD Workflow (`deploy-prod.yml`)

**Triggers**: Manual only

**Prerequisites**:
```
Inputs required:
- Select image version (v0.1.0, v0.0.9, etc.)
- Confirmation: "I understand this deploys to PRODUCTION"
- (Optional) Backup path
```

**Steps**:
1. Validate confirmation phrase
2. Verify image exists
3. SSH to PROD VM
4. Create comprehensive backups:
   - Database dump (compressed)
   - Application filestore
   - Docker image backup
   - Backup manifest (JSON)
5. Pull new image
6. Stop old containers
7. Run migrations
8. Start new containers
9. Health check
10. If fails: Manual rollback required

### 5. Deploy Odoo.sh Workflow (`deploy-odoo-sh.yml`)

**Triggers**: Manual only

**Prerequisites**:
```
Secrets required:
- ODOO_SH_SSH_KEY: SSH key for git.odoo.sh
- ODOO_SH_REPO: Repository path (e.g., customer/database)
- ODOO_SH_HOST: Odoo.sh instance hostname

Inputs:
- Branch to deploy (default: main)
- Confirmation phrase
```

**Process**:
1. Validate confirmation
2. Setup SSH for Odoo.sh
3. Push code to git.odoo.sh
4. Odoo.sh automatically:
   - Pulls code
   - Installs dependencies
   - Runs migrations
   - Restarts service

### 6. Refresh UAT from PROD Workflow (`refresh-uat-from-prod.yml`)

**Triggers**: Manual only

**Prerequisites**:
```
Inputs:
- Confirmation: "Refresh UAT database from PROD"
- Anonymize data: yes/no (default: yes)
```

**Process**:
1. Create UAT database backup
2. SSH to PROD VM, dump database
3. Copy dump to UAT VM
4. Restore into UAT database
5. (Optional) Run anonymization script
6. Verify data integrity
7. Restart UAT containers

---

## Setup & Configuration

### 1. GitHub Secrets Required

Add these secrets to your GitHub repository settings:

**Docker Hub**:
```
DOCKER_HUB_USERNAME = resultrum
DOCKER_HUB_TOKEN = <token from Docker Hub>
```

**UAT Environment**:
```
UAT_VM_HOST = 192.168.1.100 (or hostname)
UAT_VM_USER = ubuntu
UAT_VM_SSH_KEY = <SSH private key>
```

**PROD Environment**:
```
PROD_VM_HOST = 192.168.1.200
PROD_VM_USER = ubuntu
PROD_VM_SSH_KEY = <SSH private key>
```

**Odoo.sh (optional)**:
```
ODOO_SH_HOST = customer.odoo.sh
ODOO_SH_REPO = customer/production
ODOO_SH_SSH_KEY = <SSH private key for git.odoo.sh>
```

**Notifications (optional)**:
```
SLACK_WEBHOOK_URL = <Slack webhook URL>
```

### 2. VM Preparation

On each VM (UAT and PROD):

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install docker-compose
sudo curl -L \
  "https://github.com/docker/compose/releases/download/v2.10.0/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create directories
sudo mkdir -p /opt/odoo-mta
sudo mkdir -p /backups/odoo-mta/test
sudo mkdir -p /backups/odoo-mta/prod
sudo chown -R $USER:$USER /opt/odoo-mta /backups

# Clone repository
cd /opt/odoo-mta
git clone https://github.com/resultrum/odoo-mta.git .

# Create .env file
cp .env.example .env
# Edit .env with secrets
```

### 3. Test Workflow Locally

Use `act` to test workflows locally:

```bash
# Install act
brew install act  # macOS
sudo apt install act  # Linux
choco install act  # Windows

# Run CI workflow
act push --job lint-and-test

# Run with secrets
act -s DOCKER_HUB_USERNAME=resultrum \
    -s DOCKER_HUB_TOKEN=your_token \
    push --job build-and-push-uat
```

---

## Usage

### PR Workflow

1. **Create feature branch**:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes, test locally**:
   ```bash
   pytest tests/
   docker-compose up -d
   # Test in http://localhost:8069
   ```

3. **Push to GitHub**:
   ```bash
   git push -u origin feature/my-feature
   ```

4. **CI runs automatically**:
   - Code linting
   - Tests execution
   - Coverage check (must be ≥ 80%)

5. **Fix any issues, push again**:
   ```bash
   # Fix code
   pytest tests/  # Verify locally
   git push
   ```

6. **Once CI passes, create PR and merge to main**

### Deploy to UAT

**Option 1: Automatic** (after merge to main)
- Merge PR to main
- Build workflow pushes image
- Deploy workflow auto-deploys to UAT

**Option 2: Manual**
- Go to GitHub Actions
- Select "Deploy UAT" workflow
- Click "Run workflow"
- Select image tag
- Wait for deployment

### Deploy to PROD

1. Go to GitHub Actions → Deploy PROD
2. Click "Run workflow"
3. Select image version from dropdown
4. Type confirmation phrase: `I understand this deploys to PRODUCTION`
5. (Optional) Specify backup path
6. Click "Run workflow"
7. Monitor deployment in logs

### Deploy to Odoo.sh

1. Go to GitHub Actions → Deploy Odoo.sh
2. Click "Run workflow"
3. Select branch (default: main)
4. Type confirmation: `Deploy to Odoo.sh`
5. Monitor at: https://accounts.odoo.com

### Refresh UAT from PROD

1. Go to GitHub Actions → Refresh UAT from PROD
2. Click "Run workflow"
3. Type confirmation: `Refresh UAT database from PROD`
4. Choose: Anonymize data (yes/no)
5. Monitor in workflow logs

---

## Troubleshooting

### CI Fails: Coverage Below 80%

**Problem**: Test coverage below 80%

**Solution**:
1. Write more tests to cover missing code paths
2. Use `pytest --cov-report=html` to see coverage map
3. Check `htmlcov/index.html` for uncovered lines

### CI Fails: Coverage Regression

**Problem**: Coverage decreased from previous version

**Solution**:
1. Add tests for newly uncovered code
2. Or remove code that's no longer needed
3. Check workflow logs for exact regression details

### UAT Deployment Fails: Health Check Timeout

**Problem**: Containers start but health check fails

**Solution**:
1. Check UAT VM logs: `docker-compose logs -f odoo-mta-web`
2. Check database status: `docker-compose exec postgres pg_isready`
3. Automatic rollback should have already occurred
4. Check previous backup is restored

### PROD Deployment: Manual Rollback Needed

If PROD health check fails:

1. SSH to PROD VM:
   ```bash
   ssh ubuntu@prod-vm-host
   ```

2. Check status:
   ```bash
   cd /opt/odoo-mta-prod
   docker-compose ps
   docker-compose logs
   ```

3. Restore from backup:
   ```bash
   # Find latest backup manifest
   ls -t /backups/odoo-mta/prod/manifest_*.json | head -1

   # Restore database
   BACKUP_DIR=/backups/odoo-mta/prod
   LATEST=$(ls -t "$BACKUP_DIR"/database_*.dump.gz | head -1)
   zcat "$LATEST" | docker exec -i odoo-mta-db psql -U odoo -d mta-prod

   # Restart
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
   docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

4. Verify:
   ```bash
   docker-compose ps
   curl http://localhost:8069
   ```

### GitHub Secrets Not Working

**Problem**: Workflow fails with "undefined variable"

**Solution**:
1. Go to Settings → Secrets
2. Verify all required secrets are present
3. Check secret names match workflow references
4. Redeploy workflow after adding secrets

### Docker Image Not Found

**Problem**: Deploy fails with "image not found"

**Solution**:
1. Check Docker Hub: resultrum/odoo-mta
2. Verify Docker Hub credentials are correct
3. Check build workflow completed successfully
4. For manual deploys, ensure image tag exists

### Odoo.sh SSH Connection Fails

**Problem**: Can't push to git.odoo.sh

**Solution**:
1. Verify ODOO_SH_SSH_KEY is correct
2. Test SSH locally:
   ```bash
   ssh -i ~/.ssh/odoo_sh git@git.odoo.sh
   ```
3. Check if key is added to git.odoo.sh
4. Verify ODOO_SH_REPO path is correct

---

## Monitoring & Alerts

### Check Workflow Status

- GitHub Actions tab in repository
- Each workflow shows: ✅ Success or ❌ Failed
- Click workflow for detailed logs

### Monitor Deployments

**UAT**:
- Access: http://uat-vm:8069
- Logs: `docker-compose logs -f`

**PROD**:
- Access: http://prod-vm:8069
- Logs: `/opt/odoo-mta-prod/docker-compose logs -f`

**Odoo.sh**:
- Dashboard: https://accounts.odoo.com
- Check "Logs" tab for deployment status

### Backup Verification

```bash
# List recent backups
ls -lh /backups/odoo-mta/{test,prod}/

# Check backup manifest
cat /backups/odoo-mta/prod/manifest_*.json

# Verify backup integrity
gzip -t /backups/odoo-mta/prod/database_*.dump.gz
```

---

## Performance Notes

### Typical Deployment Times

- **CI Pipeline**: 2-5 minutes
- **Build Image**: 5-10 minutes
- **Deploy UAT**: 5 minutes
- **Deploy PROD**: 10 minutes (includes backups)
- **Refresh UAT**: 10-15 minutes (includes anonymization)
- **Odoo.sh Deploy**: 5-10 minutes

### Resource Requirements

- VM: Minimum 2 CPU, 4GB RAM (recommended: Standard_D2s_v3)
- Storage: 50GB+ for images and backups
- Network: Standard internet connection sufficient

---

## Next Steps

1. [Setup Secrets in GitHub](./CI_CD_GUIDE.md#setup--configuration)
2. [Configure your VMs](./CI_CD_GUIDE.md#2-vm-preparation)
3. [Test workflow locally with act](./CI_CD_GUIDE.md#3-test-workflow-locally)
4. [Deploy to UAT](./CI_CD_GUIDE.md#deploy-to-uat)
5. [Test UAT environment](./TESTING_GUIDE.md)
6. [Deploy to PROD](./CI_CD_GUIDE.md#deploy-to-prod)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-30
**Maintained by**: DevOps Team
