# 🚀 CI/CD & Deployment Strategy - Proposal

**Document:** Strategic proposal for GitHub Actions CI/CD pipeline
**Status:** ⏳ Awaiting validation
**Date:** October 30, 2025

---

## 🎯 GOALS

1. ✅ Automatic testing on every push (PR)
2. ✅ Auto-deploy to TEST environment after merge to main
3. ✅ Manual deploy to PROD (button/approval)
4. ✅ Docker images versioning (5-image history)
5. ✅ Database migration safety (with rollback)
6. ✅ Easy rollback if issues occur

---

## 📋 PROPOSED APPROACH

### Phase 1: CI Pipeline (Testing)
- **Trigger:** Every push to any branch + Pull Requests
- **Tests:**
  - Python linting (flake8, black)
  - Module manifest validation
  - Odoo module loading test
  - Unit tests (if any)
- **Output:** ✅ Pass/❌ Fail status on PR
- **Artifacts:** Test reports

### Phase 2: Build & Registry
- **Build Docker images on:**
  - Every merge to `main` (auto-deploy to TEST)
  - Manual trigger (manual-deploy to PROD)
- **Push to Docker Hub:**
  - Tag: `latest` (for TEST)
  - Tag: `vX.Y.Z` (for PROD releases)
  - Keep: Last 5 images for rollback
- **Image naming:**
  - `resultrum/odoo-mta:latest` (TEST)
  - `resultrum/odoo-mta:v1.0.0` (PROD)
  - `resultrum/odoo-mta:v0.9.9` (backup)

### Phase 3: Auto-Deploy TEST
- **Trigger:** Docker image pushed with `latest` tag
- **Actions:**
  1. Pull image from Docker Hub on TEST VM
  2. Backup current database (to filesystem)
  3. Run database migrations (with version check)
  4. Start new container
  5. Health check (curl http://localhost:8069)
  6. If health check fails: Rollback to previous image + restore DB

### Phase 4: Manual Deploy PROD
- **Trigger:** Manual GitHub Actions workflow (button click)
- **Prerequisites:**
  - User selects which tag to deploy (`v1.0.0`, `v0.9.9`, etc.)
  - User provides: PROD database backup path
  - User confirms: "I understand this deploys to PRODUCTION"
- **Actions:**
  1. Backup current PROD database
  2. Backup current PROD container/data
  3. Pull selected image from Docker Hub
  4. Run database migrations (with version tracking)
  5. Start new container on PROD
  6. Health check
  7. If fails: Manual rollback (documented procedure)

---

## 🔧 TECHNICAL ARCHITECTURE

### Repository Structure

```
odoo-mta/
├── .github/workflows/
│   ├── ci.yml                 # Linting, testing, validation
│   ├── build-push.yml         # Build Docker image, push to Docker Hub
│   ├── deploy-test.yml        # Auto-deploy to TEST
│   └── deploy-prod.yml        # Manual deploy to PROD
├── tests/
│   ├── test_modules.py        # Module loading tests
│   ├── test_manifest.py       # Manifest validation
│   └── conftest.py            # Pytest configuration
├── scripts/
│   ├── create-oca-symlinks.sh
│   ├── run-tests.sh           # Local testing
│   ├── deploy.sh              # Deployment helper (idempotent)
│   └── rollback.sh            # Emergency rollback
└── [existing files]
```

### VM Setup

**Assumed existing VMs:**
- `test-vm.internal` - TEST environment
- `prod-vm.internal` - PROD environment

**Required on each VM:**
- Docker installed
- Persistent storage for DB backups
- SSH access from GitHub Actions (via Deploy Key)
- Cron job to clean old backups

---

## 📊 WORKFLOW DIAGRAM

```
Developer creates PR
        ↓
[CI] Test + Lint (GitHub)
        ↓
    ✅ All pass?
        ↓ Yes
   Merge to main
        ↓
[Build] Create Docker image
        ↓
[Push] to Docker Hub
   Tags: latest, vX.Y.Z
        ↓
[Deploy-TEST] Auto-trigger
   1. Backup TEST DB
   2. Pull image
   3. Run migrations
   4. Start container
   5. Health check
   ↓
   ✅ Success? → TEST ready
   ❌ Failed? → Rollback + Alert
        ↓
Manager clicks "Deploy to PROD"
        ↓
[Deploy-PROD] Manual workflow
   1. Confirm selection
   2. Backup PROD DB + data
   3. Pull image
   4. Run migrations
   5. Start container
   6. Health check
   ↓
   ✅ Success? → PROD updated
   ❌ Failed? → Manual rollback + Alert
```

---

## 🔄 DATABASE MIGRATION STRATEGY

### Challenge
- Odoo DB schema changes with module versions
- Need backward compatibility or safe upgrades
- Risk of data loss if migration fails

### Solution: Version-based Migration

**1. Database Version Tracking**
```
Table: ir_config_parameter
Key: odoo_mta_db_version
Value: 1.0.0

Before running migrations:
  Current DB version: 1.0.0
  Target image version: 1.1.0
  Action: Run migrations for 1.0.0 → 1.1.0
```

**2. Pre-migration Checks**
```
1. Check if version difference is compatible
2. Check available disk space for backup
3. Check database connectivity
4. Backup database (full dump)
5. Run migrations
6. Validate schema
7. If error: Restore from backup
```

**3. Migration Scripts**
```
migrations/
├── 1.0.0_to_1.1.0.sql       # Schema changes
├── 1.1.0_to_1.2.0.sql       # Add fields, etc.
└── rollback_1.1.0.sql       # Reverse changes
```

**4. Odoo Module Updates**
```
On container start:
  $ odoo -i base --db-name=odoo --update=base
  (Odoo auto-updates installed modules)
```

**5. Rollback Procedure**
```
If deployment fails:
  1. Stop current container
  2. Restore database from backup
  3. Start previous container version
  4. Validate data integrity
  5. Alert team
```

---

## 🔐 SECURITY CONSIDERATIONS

### GitHub Secrets
```
DOCKER_HUB_USERNAME      # Docker Hub login
DOCKER_HUB_TOKEN         # Docker Hub token
TEST_VM_SSH_KEY          # SSH key for test-vm
TEST_VM_HOST             # test-vm.internal
PROD_VM_SSH_KEY          # SSH key for prod-vm
PROD_VM_HOST             # prod-vm.internal
SLACK_WEBHOOK            # For notifications
```

### Backup Management
```
Location: /backups/odoo-mta/
├── test/
│   ├── 2025-10-30_14-00-db.sql.gz
│   ├── 2025-10-30_14-00-data.tar.gz
│   └── manifest.json    # Metadata (version, timestamp)
└── prod/
    ├── 2025-10-30_14-00-db.sql.gz
    ├── 2025-10-30_14-00-data.tar.gz
    └── manifest.json

Retention: Last 10 backups per environment
Auto-cleanup: Cron job deletes old backups
```

### Database Credentials
```
Never in GitHub!
Use: Environment variables on VMs
Store in: /etc/odoo/secrets.env
Access: Only Docker containers + admin users
```

---

## 📈 DOCKER HUB VERSIONING STRATEGY

### Image Tagging

```
Push Trigger: Merge to main
├── Image version: v1.2.3
├── Git commit: abc123def456
└── Tags pushed:
    ├── resultrum/odoo-mta:latest    (TEST)
    ├── resultrum/odoo-mta:v1.2.3    (PROD option)
    ├── resultrum/odoo-mta:v1.2.2    (Previous)
    ├── resultrum/odoo-mta:v1.2.1    (Older)
    └── resultrum/odoo-mta:stable    (Last stable)

Keep history: Last 5 versions
Cleanup: Delete old images after 5 versions
```

### Versioning Scheme

**Use Semantic Versioning:**
```
v1.2.3
  ↑ ↑ ↑
  | | └─ Patch (bug fixes, security patches)
  | └─── Minor (new features, backwards compatible)
  └───── Major (breaking changes)

Examples:
  v1.0.0 → First release
  v1.0.1 → Bug fix
  v1.1.0 → New feature (OCA modules added)
  v2.0.0 → Major change (Odoo version upgrade)
```

**Auto-increment in workflow:**
```
1. Read current version from VERSION file
2. Determine change type (major/minor/patch)
3. Auto-increment version
4. Tag image with new version
5. Commit VERSION file to main
```

---

## ⚙️ WORKFLOW BREAKDOWN

### Workflow 1: CI (ci.yml)
**Runs on:** Every push, every PR

**Steps:**
1. Checkout code
2. Setup Python
3. Install dependencies
4. Run linting (flake8, black)
5. Validate module manifests
6. Run unit tests
7. Report results

**Failure:** Blocks PR merge

---

### Workflow 2: Build & Push (build-push.yml)
**Runs on:** Merge to main branch

**Steps:**
1. Build Docker image
   - Tag: `latest` + `vX.Y.Z`
   - Build args: git commit, version
2. Login to Docker Hub
3. Push image with all tags
4. Create GitHub Release (if version changed)
5. Notify on Slack

**Output:** Image in Docker Hub

---

### Workflow 3: Deploy TEST (deploy-test.yml)
**Trigger:** Docker image pushed

**Steps:**
1. SSH into TEST VM
2. Backup current DB (named with timestamp)
3. Pull new image from Docker Hub
4. Stop old container
5. Run database migrations
6. Start new container
7. Health check (curl http://localhost:8069)
8. If health check fails:
   - Stop new container
   - Restore database from backup
   - Start old container
   - Alert team

**Duration:** ~5 minutes
**Risk:** Low (automated rollback)

---

### Workflow 4: Deploy PROD (deploy-prod.yml)
**Trigger:** Manual (GitHub Actions button)

**Parameters:**
- Which image version to deploy (dropdown)
- Confirmation message
- (Optional) Backup path

**Steps:**
1. Confirm deployment
2. SSH into PROD VM
3. Create backup:
   - Database dump
   - Current container image
   - Application data
4. Pull new image
5. Stop old container
6. Run database migrations (with logging)
7. Start new container
8. Health check
9. If fails:
   - Log error details
   - Manual rollback required
   - Alert team (with instructions)

**Duration:** ~10 minutes
**Risk:** Requires manual attention if failure

---

## 🔄 ROLLBACK PROCEDURE

### Automatic Rollback (TEST)
```
If health check fails:
  1. Stop new container (automatic)
  2. Restore DB from backup (automatic)
  3. Start old container (automatic)
  4. Send alert to team Slack
  5. Logs available for debugging

Result: TEST back to previous state
Next: Team investigates issue before retry
```

### Manual Rollback (PROD)
```
If health check fails on PROD:
  1. Logs show what went wrong
  2. Team decides: retry or rollback?

If retry:
  - Fix issue in code
  - Merge to main
  - New image built and pushed
  - Re-deploy PROD

If rollback:
  - SSH into PROD VM
  - Run: docker-compose down
  - Run: docker load < /backups/prod/last-working-image.tar
  - Run: docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
  - Restore database
  - Verify

Script: scripts/rollback.sh (idempotent)
```

---

## 📊 FILES TO CREATE/MODIFY

### Create New

```
.github/workflows/
├── ci.yml                      # Linting + testing
├── build-push.yml              # Build Docker image
├── deploy-test.yml             # Auto-deploy TEST
└── deploy-prod.yml             # Manual deploy PROD

tests/
├── test_modules.py             # Module loading tests
├── test_manifest.py            # Manifest validation
└── conftest.py                 # Pytest config

scripts/
├── run-tests.sh                # Local test runner
├── deploy.sh                   # Deployment helper
├── rollback.sh                 # Rollback helper
└── health-check.sh             # Health check script

docs/
├── CI_CD_GUIDE.md              # How to use CI/CD
├── ROLLBACK_GUIDE.md           # How to rollback
└── DATABASE_MIGRATION.md       # Migration procedures

VERSION                         # Version file (semantic versioning)
pytest.ini                      # Pytest configuration
```

### Modify Existing

```
docker-compose.yml             # Add prod overrides
docker-compose.prod.yml        # Production config (new)
Dockerfile                     # Add build args for versioning
README.md                       # Add CI/CD badge + links
.gitignore                      # Add test artifacts, coverage
```

---

## ⏱️ EXECUTION TIMELINE

### Phase 1: GitHub Actions Setup (Day 1-2)
- [ ] Create CI workflow
- [ ] Create Build workflow
- [ ] Setup Docker Hub credentials
- [ ] Test locally with act (GitHub Actions emulator)

### Phase 2: TEST Deployment (Day 3-4)
- [ ] Create deploy-test workflow
- [ ] SSH setup to TEST VM
- [ ] Backup strategy implementation
- [ ] Health check implementation
- [ ] Rollback automation

### Phase 3: PROD Deployment (Day 5)
- [ ] Create deploy-prod workflow
- [ ] Manual approval mechanism
- [ ] PROD VM setup
- [ ] Database migration safety checks
- [ ] Rollback procedures documented

### Phase 4: Testing & Documentation (Day 6)
- [ ] End-to-end testing
- [ ] Documentation
- [ ] Team training
- [ ] Runbook creation

---

## ✅ DECISION POINTS FOR YOU

### Question 1: Docker Hub or GitLab Registry?
**Options:**
- A) Docker Hub (simple, public)
- B) GitHub Container Registry (private, free)
- C) GitLab Registry (if you use GitLab)

**Recommendation:** Docker Hub (you mentioned it)

### Question 2: Database Backup Location?
**Options:**
- A) Local on VM (/backups/odoo-mta/)
- B) Cloud storage (AWS S3, Google Cloud)
- C) External database server

**Recommendation:** A) Local + external sync (s3 backup job)

### Question 3: Number of Keep Versions?
**Options:**
- A) Last 3 versions
- B) Last 5 versions (current proposal)
- C) Last 10 versions

**Recommendation:** B) Last 5 (balance between storage & rollback options)

### Question 4: Approval Process for PROD?
**Options:**
- A) Any team member can deploy
- B) Only tech leads can deploy
- C) Auto-merge to PROD (risky)

**Recommendation:** B) Only authorized users (GitHub protection rules)

### Question 5: Database Migration Strategy?
**Options:**
- A) Odoo handles it (auto-update modules)
- B) Manual migration scripts
- C) Blue-green deployment (more complex)

**Recommendation:** A + B hybrid (Odoo auto-update + pre-migration checks)

---

## 🚀 ALTERNATIVE APPROACHES

### Option 1: Current Proposal (Recommended)
- ✅ Full automation for TEST
- ✅ Safe manual approval for PROD
- ✅ Automated rollback capability
- ✅ Simple and maintainable
- ⏱️ Implementation: 6 days

### Option 2: Blue-Green Deployment
- ✅ Zero-downtime deployments
- ✅ Instant rollback
- ❌ More complex infrastructure
- ❌ Higher resource usage (2 Odoo instances)
- ⏱️ Implementation: 10+ days

### Option 3: Kubernetes (Helm)
- ✅ Enterprise-grade
- ✅ Auto-scaling
- ❌ Much more complex
- ❌ Overkill for single team
- ⏱️ Implementation: 14+ days

---

## 📝 SUMMARY TABLE

| Aspect | Current Proposal | Blue-Green | Kubernetes |
|--------|-----------------|-----------|------------|
| **Complexity** | ⭐ Simple | ⭐⭐⭐ Medium | ⭐⭐⭐⭐⭐ Complex |
| **Automation** | High (TEST) | High (both) | Very High |
| **Rollback** | Automated | Instant | Instant |
| **Cost** | Low | Medium | High |
| **Time to implement** | 6 days | 10 days | 14+ days |
| **Maintenance** | Easy | Medium | Hard |
| **Team skill** | Basic | Advanced | Expert |

---

## ❓ QUESTIONS FOR YOU

1. **Docker Hub versioning:** Keep 5 images? Or different number?
2. **TEST environment:** Deploy automatically on every merge? Or manually?
3. **PROD approval:** Only tech leads? Or team vote?
4. **Database backups:** On VM? Or external storage?
5. **Downtime acceptable:** How long can TEST/PROD be offline during deploy?
6. **Rollback speed:** Automatic (TEST)? Manual (PROD)? Or both automatic?
7. **Slack notifications:** Alert on every deploy? Or only on failure?
8. **VM access:** You have SSH keys to both VMs already?

---

## 🎯 NEXT STEPS (Once Approved)

1. You validate the approach ✅
2. You answer the decision points above ✅
3. I create the GitHub Actions workflows ✅
4. I create deployment scripts ✅
5. I create documentation ✅
6. We test everything locally ✅
7. We deploy to TEST ✅
8. We document PROD procedures ✅
9. Team training ✅
10. First PROD deploy ✅

---

**Status:** ⏳ Awaiting your feedback and validation

**Please comment on:**
- [ ] Overall approach (good? need changes?)
- [ ] Specific phases (too much? too little?)
- [ ] Risk mitigation (adequate?)
- [ ] Timeline (realistic?)
- [ ] Answer the 8 questions above

---
