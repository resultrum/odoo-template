# 🧪 Testing Guide - Git-Aggregator & Repository Management

This guide walks through testing the git-aggregator workflow with realistic scenarios.

---

## Test 1: Verify Current Setup

### Objective
Confirm that the current helpdesk setup works correctly.

### Steps

```bash
# 1. Check current structure
ls -la addons/
ls -la addons/oca/
ls -la addons/oca-addons/ | head -15

# Expected output:
# oca-addons/
# ├── helpdesk_mgmt -> ../oca/helpdesk/helpdesk_mgmt
# ├── helpdesk_crm -> ../oca/helpdesk/helpdesk_crm
# └── ... (22 symlinks)
```

```bash
# 2. Check if Docker is running
docker-compose ps

# Expected: Both odoo-mta-web and odoo-mta-db should be "Up"
```

```bash
# 3. Verify Odoo can see modules
docker exec odoo-mta-web ls /mnt/extra-addons/oca-addons/ | wc -l

# Expected: 23 (22 symlinks + 1 .gitkeep)
```

```bash
# 4. Check Odoo logs for symlink creation
docker-compose logs web | grep -A 5 "Setting up OCA addons symlinks"

# Expected output should show:
# 🔗 Setting up OCA addons symlinks...
# ✓ helpdesk_mgmt
# ✓ helpdesk_crm
# ... (20 more)
# ✅ OCA addons symlinks created successfully
```

### Validation
- ✅ Symlinks exist locally
- ✅ Docker container shows symlinks
- ✅ Odoo logs show symlinks created
- ✅ Odoo can access modules

---

## Test 2: Simulate Adding a Custom Branch to Helpdesk

### Objective
Test the workflow for adding a custom branch to an existing OCA repository.

### Prerequisites

You need:
1. A fork of the helpdesk repo: `resultrum/helpdesk`
2. SSH access to GitHub configured

### Steps

#### Step 2.1: Create a Test Branch

```bash
# Navigate to the helpdesk repo
cd addons/oca/helpdesk

# Create a test branch (simulating a custom modification)
git checkout -b test/custom-modification

# Make a minimal change (just for testing)
echo "# Test modification" >> README.md

# Commit
git add README.md
git commit -m "test: add comment to README for testing purposes"

# Push to your fork
git push resultrum test/custom-modification

# Verify it's there
git branch -a | grep test/custom-modification
# Should show: remotes/resultrum/test/custom-modification
```

#### Step 2.2: Update repos.yml to Include the Custom Branch

```bash
# Go back to project root
cd ../../../

# Edit repos.yml
# Change the merges section from:
#   merges:
#     - oca 18.0
# To:
#   merges:
#     - oca 18.0
#     - resultrum test/custom-modification
```

**Before:**
```yaml
./addons/oca/helpdesk:
  merges:
    - oca 18.0
```

**After:**
```yaml
./addons/oca/helpdesk:
  merges:
    - oca 18.0
    - resultrum test/custom-modification
```

#### Step 2.3: Enable Git-Aggregator

```bash
# Edit docker-compose.dev.yml and change:
# From: ENABLE_GIT_AGGREGATE=false
# To:   ENABLE_GIT_AGGREGATE=true

# Verify the change
cat docker-compose.dev.yml | grep ENABLE_GIT_AGGREGATE
```

#### Step 2.4: Restart Docker with Git-Aggregator

```bash
# Stop containers
docker-compose down

# Start with git-aggregator enabled
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Wait for startup (usually 20-30 seconds)
sleep 30

# Check logs
docker-compose logs web | head -100
```

**Expected output:**
```
odoo-mta-web  | 🔧 DEV MODE: Running git-aggregator...
odoo-mta-web  | ✅ git-aggregator completed
odoo-mta-web  | 🔗 Setting up OCA addons symlinks...
odoo-mta-web  | ✅ OCA addons symlinks created successfully
```

#### Step 2.5: Verify Merge Was Successful

```bash
# Check if the modification is in the merged repo
cat addons/oca/helpdesk/README.md | grep "Test modification"

# Expected: You should see the comment from your test branch
```

```bash
# Check Git history to confirm merge
cd addons/oca/helpdesk
git log --oneline -n 5
git log --oneline --graph -n 10

# You should see:
# - The test branch commit
# - The OCA 18.0 commits
# - A merge commit combining them
```

#### Step 2.6: Test in Odoo

```bash
# 1. Go to Odoo: http://localhost:8069
# 2. Navigate to: Apps → Update Apps List
# 3. Search for "helpdesk_mgmt"
# 4. Should see modules and be able to reload them
```

#### Step 2.7: Clean Up Test Branch

```bash
# Remove the test branch from repos.yml
# Change back to:
#   merges:
#     - oca 18.0

# Disable git-aggregator again
# In docker-compose.dev.yml:
#   ENABLE_GIT_AGGREGATE=false

# Restart
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Delete the test branch from the fork
cd addons/oca/helpdesk
git push resultrum --delete test/custom-modification
git branch -d test/custom-modification
```

### Validation
- ✅ Custom branch merged successfully
- ✅ Git history shows merge commit
- ✅ Changes from custom branch present in local copy
- ✅ Symlinks still work
- ✅ Odoo sees modules

---

## Test 3: Simulate Adding a New Repository

### Objective
Test adding a new OCA repository (e.g., server-tools).

### Prerequisites

1. A fork of server-tools: `resultrum/server-tools` (or any small OCA repo)
2. SSH access to GitHub

### Steps

#### Step 3.1: Create Fork and Update repos.yml

```bash
# For testing, you can use an existing test repo or create a fork
# For this guide, we'll assume you have resultrum/server-tools

# Add to repos.yml:
# Uncomment the server-tools section at the bottom of repos.yml

cd /Users/jonathannemry/Projects/odoo-mta

# Edit repos.yml
# Change:
# # ./addons/oca/server-tools:
# To:
# ./addons/oca/server-tools:

# Also uncomment the remotes, merges, and target lines
```

**File should now look like:**
```yaml
./addons/oca/helpdesk:
  remotes:
    oca: git@github.com:OCA/helpdesk.git
    resultrum: git@github.com:resultrum/helpdesk.git
  merges:
    - oca 18.0
  target: resultrum master-18.0-mta

./addons/oca/server-tools:
  remotes:
    oca: git@github.com:OCA/server-tools.git
    resultrum: git@github.com:resultrum/server-tools.git
  merges:
    - oca 18.0
  target: resultrum master-18.0-mta
```

#### Step 3.2: Enable Git-Aggregator

```bash
# Edit docker-compose.dev.yml
# Change: ENABLE_GIT_AGGREGATE=false
# To:     ENABLE_GIT_AGGREGATE=true
```

#### Step 3.3: Restart Docker

```bash
docker-compose down

docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Wait for startup
sleep 30

# Check logs
docker-compose logs web | head -100
```

**Expected output:**
```
odoo-mta-web  | 🔧 DEV MODE: Running git-aggregator...
# ... output showing git-aggregator processing helpdesk ...
# ... output showing git-aggregator processing server-tools ...
odoo-mta-web  | ✅ git-aggregator completed
odoo-mta-web  | 🔗 Setting up OCA addons symlinks...
# ... showing helpdesk symlinks ...
# ... showing server-tools symlinks ...
odoo-mta-web  | ✅ OCA addons symlinks created successfully
```

#### Step 3.4: Verify New Repository Structure

```bash
# Check if server-tools directory was created
ls -la addons/oca/server-tools/

# Should contain multiple modules like:
# - server_env
# - base_sparse_field
# - etc.
```

```bash
# Check if symlinks were created
ls -la addons/oca-addons/ | grep server

# Should show links like:
# server_env -> ../oca/server-tools/server_env
# base_sparse_field -> ../oca/server-tools/base_sparse_field
```

```bash
# Verify in Docker
docker exec odoo-mta-web ls /mnt/extra-addons/oca-addons/ | grep server

# Should show the same symlinks
```

#### Step 3.5: Test in Odoo

```bash
# 1. Go to Odoo: http://localhost:8069
# 2. Apps → Update Apps List (click the ⟳ button)
# 3. Search for "server"
# 4. Should see new modules from server-tools
# 5. Try installing one
```

#### Step 3.6: Clean Up

```bash
# Remove server-tools from repos.yml (comment it back out)
# Disable git-aggregator
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Validation
- ✅ New repository downloaded and merged
- ✅ New symlinks created
- ✅ Odoo sees new modules
- ✅ Modules can be installed
- ✅ No conflicts with existing repos

---

## Test 4: Verify Symlink Regeneration

### Objective
Ensure symlinks can be regenerated if accidentally deleted.

### Steps

```bash
# 1. Delete all symlinks
rm addons/oca-addons/*

# 2. Run the symlink script
./scripts/create-oca-symlinks.sh

# Expected output:
# 🔗 Creating OCA addons symlinks...
# ✓ helpdesk_mgmt
# ... (all modules)
# ✅ Successfully created 22 symlinks

# 3. Verify they're back
ls -la addons/oca-addons/ | wc -l

# Should be 24 (23 symlinks + 1 .gitkeep)
```

### Validation
- ✅ Script successfully regenerates symlinks
- ✅ All 22 modules have symlinks
- ✅ Symlinks point to correct locations

---

## Test 5: Verify Production Mode

### Objective
Ensure everything works in production mode (git-aggregator disabled).

### Steps

```bash
# 1. Make sure git-aggregator is disabled
cat docker-compose.dev.yml | grep ENABLE_GIT_AGGREGATE
# Should show: ENABLE_GIT_AGGREGATE=false

# 2. Restart in production mode (using main docker-compose)
docker-compose down
docker-compose up -d

# 3. Wait for startup
sleep 20

# 4. Check if modules are still visible
docker-compose logs web | grep "addons paths"

# Should show:
# addons paths: [...'/mnt/extra-addons/oca-addons']

# 5. Test in Odoo
# Go to http://localhost:8069 and verify modules are there
```

### Validation
- ✅ Production mode works without git-aggregator
- ✅ Modules remain accessible via symlinks
- ✅ No git operations on startup

---

## Common Test Scenarios

### Scenario A: Update OCA Modules

```bash
# 1. Enable git-aggregator
# 2. Restart Docker
# 3. It will pull latest from OCA/18.0
# 4. Check git log to see new commits
cd addons/oca/helpdesk
git log --oneline -n 10
```

### Scenario B: Merge Multiple Custom Branches

```yaml
# In repos.yml:
./addons/oca/helpdesk:
  merges:
    - oca 18.0
    - resultrum feature/custom-fields
    - resultrum fix/ticket-bug
    - resultrum enhancement/ui-improvements
```

All three custom branches will be merged on top of OCA's 18.0.

### Scenario C: Switch Between OCA Versions

```yaml
# Change from 18.0 to 17.0:
./addons/oca/helpdesk:
  merges:
    - oca 17.0  # Changed from 18.0
```

Then run git-aggregator to pull that version.

---

## Troubleshooting Tests

### If Git-Aggregator Fails

```bash
# Check logs for specific error
docker-compose logs web | grep -i "git\|error\|failed"

# Try manually:
docker exec odoo-mta-web bash -c "cd /mnt && gitaggregate -c repos.yml"

# Check SSH access to GitHub
docker exec odoo-mta-web ssh -T git@github.com
```

### If Symlinks Aren't Created

```bash
# Manually regenerate
./scripts/create-oca-symlinks.sh

# Or in Docker:
docker exec odoo-mta-web /mnt/entrypoint-custom.sh
```

### If Modules Don't Appear in Odoo

```bash
# 1. Restart Odoo in dev mode
docker exec odoo-mta-web odoo --dev=reload

# 2. Clear Odoo cache
rm -rf addons/odoo-web-data/*

# 3. Restart container
docker-compose restart web
```

---

## Summary Checklist

- [ ] Test 1: Current setup works
- [ ] Test 2: Custom branch merges correctly
- [ ] Test 3: New repo downloads and merges
- [ ] Test 4: Symlinks can be regenerated
- [ ] Test 5: Production mode works
- [ ] All modules visible in Odoo
- [ ] Modules can be reloaded/installed
- [ ] Git history shows proper merges
- [ ] No permission or git errors

---

**Next Steps:** Once all tests pass, you're ready to share this setup with developers!
