# 🚀 CI/CD & Deployment Strategy - REVISED PROPOSAL

**Document:** Revised strategic proposal for GitHub Actions CI/CD pipeline
**Status:** ⏳ Awaiting final validation
**Date:** October 30, 2025
**Revision:** 2 (addressing constraints & Odoo.sh compatibility)

---

## 🎯 UPDATED REQUIREMENTS

### New Requirements Added
1. ✅ Test coverage requirement (80% minimum, blocks PR if lower)
2. ✅ Separate storage: UAT images vs PROD images (5-version history each)
3. ✅ Odoo.sh compatibility (same architecture works for both VM and SH)
4. ✅ Local debug support (logs, status commands)
5. ✅ VM performance considerations (no "usine à gaz")
6. ✅ Infrastructure-as-Code (Bicep files for Azure deployment)
7. ✅ PROD → UAT anonymization (same as Odoo.sh documentation)
8. ✅ Dev workflow: Push to GitHub, instance on Odoo.sh (no VM image needed)

### Critical Constraint
> "Same architecture must work for:
> - VM-based deployment (with Docker)
> - Odoo.sh deployment (no Docker)
> - Local development (Docker Compose)
> Only difference: Deployment target changes, code/config is identical"

---

## 📊 REVISED ARCHITECTURE

### Key Principle: Deployment-Agnostic Code

```
Code Repository (GitHub)
    ↓
    Same code, config, addons
    ↓
┌───────────────────────────────────────────┐
│  CI/Testing (GitHub Actions)              │
│  - Python linting                         │
│  - Test coverage ≥80% (BLOCKS if <80%)   │
│  - Module validation                      │
│  - Unit tests                             │
└───────────────────────────────────────────┘
    ↓
    ├─ Deploy to VM (Docker) ─→ Docker image → Docker Hub
    │                             (UAT images)
    │
    ├─ Deploy to Odoo.sh ──────→ Direct git clone + config
    │                             (No Docker image)
    │
    └─ Local Dev (Docker) ─────→ docker-compose (local only)
```

### Storage Strategy: Separate Registries

```
Docker Hub (VM deployments only)
├── odoo-mta:uat-latest        # UAT working version
├── odoo-mta:uat-v1.2.3        # UAT version history
├── odoo-mta:uat-v1.2.2
├── odoo-mta:uat-v1.2.1
└── odoo-mta:uat-v1.2.0        # Keep last 5 UAT versions

odoo-mta:prod-v1.2.3           # PROD only created on PROD deploy
odoo-mta:prod-v1.2.2           # Keep last 5 PROD versions
odoo-mta:prod-v1.2.1
odoo-mta:prod-v1.2.0

⚠️ Image only pushed on successful PROD deploy
⚠️ UAT images pushed on every merge to main
```

---

## 🔄 REVISED WORKFLOW

### Workflow 1: CI with Test Coverage (ci.yml)
**Runs on:** Every push, every PR

```
1. Checkout code
2. Setup Python + Odoo testing environment
3. Install dependencies
4. Run linting (flake8, black)
   ├─ Fail PR if lint errors
5. Run unit tests
6. Generate coverage report
7. Check coverage:
   ├─ If coverage < 80% → FAIL PR (block merge)
   ├─ If coverage < previous → FAIL PR (block regression)
   └─ If coverage >= 80% → PASS
8. Report coverage stats
9. Post coverage badge to PR

Outputs:
  - Coverage report (HTML)
  - Coverage percentage
  - Lint results
```

**Key:** ❌ PR cannot merge if coverage < 80% OR coverage decreases

---

### Workflow 2: Build Docker Image (build-push.yml)
**Runs on:** Merge to main branch ONLY

```
1. Checkout code
2. Determine version from VERSION file
3. Build Docker image
   ├─ Tag: odoo-mta:uat-latest
   ├─ Tag: odoo-mta:uat-vX.Y.Z
   ├─ Build args: git commit, version, build date
   └─ Dockerfile: platform=linux/amd64,linux/arm64 (multi-arch)
4. Login to Docker Hub
5. Push all tags
6. Keep only last 5 UAT images (cleanup old)
7. Create GitHub Release
8. Notify Slack

⚠️ PROD images NOT created here
⚠️ Only UAT images for VM testing
```

---

### Workflow 3: Deploy to UAT (deploy-uat.yml)
**Runs on:** Docker image pushed OR manual trigger

```
TARGET: UAT VM only (not Odoo.sh)

1. SSH into UAT VM
2. Backup UAT database
3. Backup UAT application data
4. Pull image: odoo-mta:uat-latest
5. Stop current container
6. Run database migrations
   └─ Version check + pre-flight validation
7. Start new container
8. Health check (curl http://localhost:8069)
9. Validation checks:
   ├─ Modules loading (log check)
   ├─ Database integrity
   └─ Key endpoints responding
10. If ALL pass → UAT ready
11. If ANY fail:
    ├─ Stop new container
    ├─ Restore database
    ├─ Start old container
    ├─ Alert team
    └─ Wait for manual fix

Duration: ~5 minutes
Rollback: Automatic
```

---

### Workflow 4: Deploy to Odoo.sh (deploy-odoo-sh.yml)
**Runs on:** Manual trigger or scheduled

**⚠️ IMPORTANT: Different from VM deployment**

```
This is NOT a Docker deployment!
Uses: Odoo.sh native deployment

1. Trigger: Manual button in GitHub Actions
2. Select target Odoo.sh instance
3. Odoo.sh handles:
   ├─ Git pull from main branch
   ├─ Module updates (Odoo native)
   ├─ Database migrations (Odoo native)
   ├─ Restart services
   └─ Health check
4. If error: Odoo.sh handles rollback (native feature)

Uses: Odoo.sh deployment API
No Docker involved
```

**Key difference:** Uses Odoo.sh native tools, not Docker

---

### Workflow 5: Production Deploy (deploy-prod.yml)
**Runs on:** Manual trigger only

**Multi-step approval process:**

```
Step 1: Trigger
  User clicks "Deploy to Production"

Step 2: Select Source
  Options:
  ├─ A specific UAT image (odoo-mta:uat-vX.Y.Z)
  ├─ Promote from UAT if tested
  └─ Or test directly on PROD (risky)

Step 3: Approval Questions (in workflow UI)
  ✓ "Which UAT image to promote?"
  ✓ "Have you tested this on UAT?"
  ✓ "Backup location ready?"
  ✓ "Rollback plan documented?"
  ✓ "Type APPROVE to proceed"

Step 4: Create PROD Image
  1. Pull UAT image: odoo-mta:uat-vX.Y.Z
  2. Retag as: odoo-mta:prod-vX.Y.Z
  3. Push to Docker Hub (PROD section)
  4. Push only on success

Step 5: Deploy to PROD VM
  1. SSH into PROD VM
  2. Create FULL backup:
     ├─ Database full dump (pg_dump)
     ├─ Application data tar.gz
     ├─ Current image export
     └─ Manifest file (version, timestamp, Git SHA)
  3. Pull image: odoo-mta:prod-vX.Y.Z
  4. Stop old container
  5. Run migrations with logging
  6. Start new container
  7. Extended health check (30 seconds)
  8. If fails:
     ├─ Save error logs
     ├─ Manual rollback required
     ├─ Alert team with logs
     ├─ Document incident
     └─ Post-mortem analysis

Duration: ~10 minutes
Rollback: Manual (documented procedure)
```

---

## 🔐 NEW: PROD → UAT ANONYMIZATION

### Purpose
Enable UAT to be exact PROD copy, but with anonymized sensitive data.

### Implementation

**Trigger:** Manual workflow "Refresh UAT with PROD data"

```
Prerequisites:
  1. PROD backup created (same as deploy)
  2. PROD database accessible
  3. UAT database backup created

Steps:
  1. SSH into PROD VM
  2. Export PROD database:
     $ pg_dump -U odoo prod_db > prod_backup.sql
  3. Transfer to UAT VM (sftp or S3)
  4. SSH into UAT VM
  5. Stop UAT application
  6. Restore PROD data to UAT:
     $ dropdb odoo_test
     $ createdb odoo_test
     $ psql odoo_test < prod_backup.sql
  7. Run anonymization script
     (see below)
  8. Start UAT application
  9. Verify data integrity
```

### Anonymization Script
**File:** `scripts/anonymize_database.sql`

```sql
-- Based on Odoo.sh anonymization standard
-- Anonymizes personally identifiable information

BEGIN TRANSACTION;

-- Partner & Contact Information
UPDATE res_partner SET
  name = 'Partner ' || id,
  email = 'partner' || id || '@example.local',
  phone = '0000000000',
  mobile = '0000000000',
  street = 'Street ' || id,
  city = 'City',
  zip = '00000',
  country_id = NULL
WHERE company_id = (SELECT id FROM res_company LIMIT 1);

-- User Accounts
UPDATE res_users SET
  login = 'user' || id || '@local',
  email = 'user' || id || '@example.local',
  signature = '',
  phone = '0000000000'
WHERE id > 1;  -- Keep admin intact

-- Customer Addresses
DELETE FROM res_partner_address WHERE type IN ('invoice', 'delivery');

-- Email Messages (optional - keep for testing)
-- DELETE FROM mail_mail;
-- DELETE FROM mail_message WHERE message_type = 'email';

-- Sensitive Fields
UPDATE sale_order SET
  note = 'Test Order'
WHERE note IS NOT NULL;

UPDATE purchase_order SET
  notes = 'Test PO'
WHERE notes IS NOT NULL;

-- Session Data
DELETE FROM ir_session;

-- Clear OAuth tokens
DELETE FROM ir_config_parameter
WHERE key LIKE '%access_token%'
OR key LIKE '%refresh_token%';

COMMIT;
```

**Run after restore:**
```bash
$ psql odoo_test -f scripts/anonymize_database.sql

# Verify
$ psql odoo_test -c "SELECT COUNT(*) FROM res_partner WHERE email LIKE '%@example.local';"
```

---

## 🛠️ NEW: LOCAL DEBUG & OPERATIONS

### Local Development Workflow

**For developers working locally:**

```bash
# Clone & setup
git clone git@github.com:resultrum/odoo-mta.git
cd odoo-mta
cp .env.example .env

# Run locally (Docker Compose)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# See logs
docker-compose logs -f web

# Debug specific module
docker exec -it odoo-mta-web odoo shell -d mta-dev
# Now you're in Python REPL in Odoo context

# Check module status
docker exec odoo-mta-web odoo shell -d mta-dev << 'EOF'
module = env['ir.module.module'].search([('name', '=', 'helpdesk_mgmt')])
print(f"State: {module.state}")
EOF

# Run tests locally
./scripts/run-tests.sh
# Shows coverage report

# Run linting
./scripts/run-linting.sh

# Health check
curl http://localhost:8069
echo "Status: $?"
```

### Operational Commands (on VM)

**Deploy team operators need these commands:**

```bash
# On UAT/PROD VM

# Check status
docker-compose ps
docker-compose logs web -n 50

# Restart Odoo
docker-compose restart web

# Restart database
docker-compose restart db

# Full restart
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check database
docker exec odoo-mta-db psql -U odoo -d odoo -c "SELECT version();"

# View current version
docker exec odoo-mta-web cat /APP_VERSION

# Rollback to previous image
./scripts/rollback.sh --image previous --force

# Manual backup
./scripts/backup.sh --path /backups/manual-$(date +%Y%m%d-%H%M%S)

# Validate database integrity
docker exec odoo-mta-db pg_isready -U odoo

# Export logs
docker-compose logs --timestamps > /backups/logs-$(date +%Y%m%d-%H%M%S).log
```

---

## 💻 NEW: INFRASTRUCTURE AS CODE (Bicep)

### Architecture Deployment in <30 minutes

**Files:**

```
infrastructure/
├── main.bicep              # Main template
├── vm.bicep                # VM configuration
├── networking.bicep        # Network setup
├── storage.bicep           # Storage accounts
└── parameters.json         # Parameter file
```

**Deploy identical PROD environment:**

```bash
# Set parameters
az deployment group create \
  --resource-group odoo-mta-prod \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.json

# This deploys:
# ✓ VM with Docker installed
# ✓ Network configuration
# ✓ Storage for backups
# ✓ Monitoring/logging setup
# ✓ All in ~20 minutes
```

**Key benefit:** Disaster recovery in <30 minutes

---

## 🎯 NEW: ODOO.SH COMPATIBILITY

### Same Code, Different Target

**Key insight:** Code is deployment-agnostic

```
odoo-mta/ (GitHub)
├── Code (same for all)
├── Addons (same for all)
├── Config (deployment-specific)
│   ├── odoo.conf (VM)
│   ├── odoo.sh.conf (Odoo.sh)
│   └── environment (local)
└── Docker (VM only)
    ├── Dockerfile
    └── docker-compose.yml

Deployment:
  VM (Docker)    → pull image, docker-compose up
  Odoo.sh        → git clone, deploy button
  Local (Docker) → docker-compose up
```

### Odoo.sh Deployment

**No custom code needed:**

```
1. Add odoo-mta repo to Odoo.sh UI
2. Select branch: main
3. Odoo.sh handles:
   - Git pull
   - Module installation
   - Database migrations
   - Health checks
4. Can rollback instantly (Odoo.sh native)
```

**Our code adapts to Odoo.sh automatically:**
- Same `repos.yml` (works in Odoo.sh)
- Same module structure
- Same configuration
- No code changes needed

---

## 📋 REVISED FILE STRUCTURE

```
odoo-mta/
├── .github/workflows/
│   ├── ci.yml                      # Test + coverage (blocks if <80%)
│   ├── build-uat.yml               # Build UAT images only
│   ├── deploy-uat.yml              # Deploy to UAT VM
│   ├── deploy-odoo-sh.yml          # Deploy to Odoo.sh
│   ├── deploy-prod.yml             # Deploy to PROD VM
│   ├── refresh-uat-from-prod.yml   # Copy PROD→UAT + anonymize
│   └── operations.yml              # Manual operations (logs, status, etc.)
│
├── infrastructure/
│   ├── main.bicep                  # Main Azure template
│   ├── vm.bicep                    # VM specification
│   ├── networking.bicep            # Network setup
│   └── parameters.json             # Environment parameters
│
├── tests/
│   ├── test_modules.py             # Module loading
│   ├── test_manifest.py            # Manifest validation
│   ├── conftest.py                 # Coverage setup
│   └── test_coverage_gate.py        # 80% validation
│
├── scripts/
│   ├── run-tests.sh                # Local test runner
│   ├── run-linting.sh              # Local linting
│   ├── anonymize_database.sql      # PROD→UAT anonymization
│   ├── backup.sh                   # Manual backup
│   ├── rollback.sh                 # Manual rollback
│   ├── health-check.sh             # Health check
│   └── deploy.sh                   # Deployment helper
│
├── docker/
│   ├── Dockerfile                  # Multi-arch build
│   ├── docker-compose.yml          # Production config
│   ├── docker-compose.dev.yml      # Development config
│   └── entrypoint.sh               # Container startup
│
├── config/
│   ├── odoo.conf                   # VM/Docker config
│   ├── odoo.sh.conf                # Odoo.sh config (if needed)
│   └── config-template.py          # Python config template
│
├── docs/
│   ├── CI_CD_GUIDE.md              # How to use CI/CD
│   ├── DEPLOYMENT_GUIDE.md         # Deployment procedures
│   ├── OPERATIONS_GUIDE.md         # Daily operations
│   ├── ROLLBACK_GUIDE.md           # Rollback procedures
│   ├── TEST_COVERAGE.md            # Coverage requirements
│   ├── ODOO_SH_DEPLOYMENT.md       # Odoo.sh specific
│   └── INFRASTRUCTURE.md           # Bicep/IaC guide
│
├── VERSION                         # Semantic versioning
├── pytest.ini                      # Coverage: min 80%
└── [existing files]
```

---

## ⏱️ REVISED TIMELINE

### Phase 1: CI with Coverage (Day 1-2)
- [ ] Setup pytest with coverage
- [ ] Implement 80% gate
- [ ] Create CI workflow
- [ ] Test locally

### Phase 2: Build UAT Images (Day 2-3)
- [ ] Create build-uat workflow
- [ ] Setup Docker Hub (separate UAT/PROD sections)
- [ ] Test image build locally

### Phase 3: Deploy to UAT VM (Day 3-4)
- [ ] Create deploy-uat workflow
- [ ] SSH setup
- [ ] Backup strategy
- [ ] Health checks
- [ ] Auto-rollback

### Phase 4: PROD→UAT Anonymization (Day 4)
- [ ] Create anonymization script
- [ ] Create refresh-uat workflow
- [ ] Test anonymization locally

### Phase 5: Deploy to PROD VM (Day 5)
- [ ] Create deploy-prod workflow
- [ ] Approval mechanism
- [ ] Manual rollback procedures
- [ ] Documentation

### Phase 6: Odoo.sh Compatibility (Day 5-6)
- [ ] Verify code works with Odoo.sh
- [ ] Create deploy-odoo-sh workflow
- [ ] Document Odoo.sh process
- [ ] Test on staging Odoo.sh instance

### Phase 7: Infrastructure as Code (Day 6)
- [ ] Write Bicep templates
- [ ] Test deployment
- [ ] Document disaster recovery

### Phase 8: Documentation & Testing (Day 7)
- [ ] End-to-end tests
- [ ] Team documentation
- [ ] Runbooks
- [ ] Training

---

## ✅ PERFORMANCE CONSIDERATIONS

### Docker on VM: Not a "Usine à Gaz"

**Resource-conscious setup:**

```
Container specifications:
  Memory: 2GB (configurable)
  CPUs: 2 cores (configurable)
  Disk: Mounted volumes, not huge images

Performance:
  Startup time: ~30 seconds
  Hotreload: Native Odoo (no container overhead)
  File sync: Native volumes (zero overhead)

Not bloated because:
  ✓ Small base image (Odoo official)
  ✓ Only needed dependencies
  ✓ No extra tools
  ✓ Efficient volume mounting
```

**Comparison:**
- VM running Odoo directly: ~15 second startup
- VM running Odoo in Docker: ~30 second startup
- Overhead: ~15 seconds (acceptable trade-off for consistency)

---

## 🎯 DECISION POINTS (REVISED)

### Q1: Test Coverage Threshold
- [ ] 80% minimum (current proposal)
- [ ] 70% minimum
- [ ] No requirement (not recommended)

**My recommendation:** 80% (industry standard)

### Q2: Coverage Regression Check
- [ ] Block PR if coverage decreases (current proposal)
- [ ] Warning only (allow merge)
- [ ] No check

**My recommendation:** Block PR (prevent regressions)

### Q3: UAT Auto-deploy vs Manual
- [ ] Auto on every merge (current proposal)
- [ ] Manual trigger only
- [ ] Scheduled (e.g., daily)

**My recommendation:** Auto (fast feedback loop)

### Q4: Docker Hub Storage
- [ ] Separate UAT/PROD sections (current proposal)
- [ ] Single section, all versions
- [ ] Use GitHub Container Registry instead

**My recommendation:** Separate (cleaner, prevents accidents)

### Q5: Image History
- [ ] Keep last 5 versions (current proposal)
- [ ] Keep last 3 versions
- [ ] Keep last 10 versions

**My recommendation:** Last 5 (balance storage vs rollback)

### Q6: PROD Image Creation
- [ ] Only when deploying to PROD (current proposal)
- [ ] Create for every merge, deploy selectively
- [ ] Manual image creation workflow

**My recommendation:** Only on PROD deploy (prevents clutter)

### Q7: Anonymization Frequency
- [ ] Manual on-demand (current proposal)
- [ ] Automatic weekly
- [ ] Only before critical testing

**My recommendation:** Manual on-demand (full control)

### Q8: Infrastructure as Code
- [ ] Bicep (Azure-specific, current proposal)
- [ ] Terraform (cloud-agnostic)
- [ ] CloudFormation (AWS-specific)
- [ ] Manual VM setup only

**My recommendation:** Bicep (if using Azure) or Terraform (more portable)

### Q9: Odoo.sh Testing
- [ ] Test before each PROD deploy
- [ ] Test on staging only
- [ ] Test once, document, done

**My recommendation:** Test once thoroughly, then maintain parity

### Q10: Local Development
- [ ] Docker Compose (current proposal)
- [ ] Direct Odoo install on dev machine
- [ ] Vagrant VM

**My recommendation:** Docker Compose (matches production)

---

## 📝 SUMMARY OF CHANGES

| Aspect | Original | REVISED |
|--------|----------|---------|
| **Test Coverage** | Optional | 80% minimum, blocks PR if lower |
| **Storage Strategy** | Single | Separate UAT/PROD (5 versions each) |
| **Image Creation** | Every merge | Only on PROD deploy |
| **UAT deployment** | Manual | Automatic on merge |
| **Odoo.sh** | Not mentioned | Full compatibility |
| **PROD→UAT** | Not mentioned | Anonymization workflow included |
| **Infrastructure** | Not mentioned | Bicep templates for disaster recovery |
| **Local Debug** | Basic | Full operations guide |
| **Performance** | Not addressed | Verified not a "usine à gaz" |

---

## 🚀 READY FOR VALIDATION?

**Please confirm:**

- [ ] Test coverage requirement (80%): ✅ OK?
- [ ] Separate UAT/PROD storage: ✅ OK?
- [ ] Auto-deploy to UAT: ✅ OK?
- [ ] Manual PROD deploy: ✅ OK?
- [ ] PROD→UAT anonymization: ✅ OK?
- [ ] Odoo.sh compatibility: ✅ OK?
- [ ] Bicep for infrastructure: ✅ OK?
- [ ] All 10 decision points: ✅ Answered above?

**If yes to all, ready to implement!** 🎉

---
