# 🚀 Deployment Template Guide

This document explains how to use odoo-mta as a template/skeleton for deploying to developers and teams.

---

## Overview

**odoo-mta** is designed to be:
1. A **working reference implementation** showing best practices
2. A **template** to customize for your organization
3. A **test skeleton** before production deployment

This guide helps you deploy this setup to your team.

---

## What to Customize

### 1. Organization/Repository Names

**In repos.yml:**
```yaml
# Change from: git@github.com:resultrum/*
# To: git@github.com:YOUR_ORG/*

./addons/oca/helpdesk:
  remotes:
    oca: git@github.com:OCA/helpdesk.git
    resultrum: git@github.com:YOUR_ORG/helpdesk.git  # ← Change this
  target: resultrum master-18.0-mta  # ← Can stay or change
```

### 2. Project Names

**In README.md:**
- Change "odoo-mta" to your project name
- Update "MOTECMA" to your company's acronym
- Update objectives and features

**In docker-compose.yml:**
```yaml
# container_name: odoo-mta-web  ← Change if desired
# container_name: odoo-YOUR_PROJECT-web
```

**In odoo.conf:**
```conf
# Update any project-specific settings
# Database name patterns, admin password, etc.
```

### 3. Database Names

**In docker-compose.yml:**
```yaml
environment:
  - POSTGRES_DB=postgres  # ← Can change
```

**In entrypoint.sh & docs:**
- Update references from `mta-dev` to your naming convention

### 4. Module Prefixes

**Custom modules should use your organization prefix:**
```bash
# Instead of: mta_developer_planning
# Use: YOUR_PREFIX_developer_planning
```

Update examples in documentation.

### 5. Documentation

- Update all references to "Metrum" to your company name
- Update contact information and team structure
- Add your internal deployment procedures
- Add your specific compliance/security requirements

---

## Step-by-Step Deployment to Team

### Phase 1: Prepare Your Template

```bash
# 1. Fork this repository as a template
# Go to: https://github.com/resultrum/odoo-mta
# Click "Use this template"
# Create new repo: YOUR_ORG/odoo-YOUR_PROJECT

# 2. Customize the files (see "What to Customize" above)
git clone git@github.com:YOUR_ORG/odoo-YOUR_PROJECT.git
cd odoo-YOUR_PROJECT

# Edit and customize:
# - README.md
# - repos.yml
# - docker-compose.yml
# - odoo.conf
# - .env.example
# - All documentation files

# 3. Create forks for OCA repositories you'll use
# Fork: OCA/helpdesk → YOUR_ORG/helpdesk
# Fork: OCA/server-tools → YOUR_ORG/server-tools (if needed)
# etc.

# 4. Commit and push
git add .
git commit -m "chore: customize template for YOUR_PROJECT"
git push origin main
```

### Phase 2: Distribute to Team

```bash
# 1. Create team repository (if not public)
# Set up appropriate access controls

# 2. Create developer onboarding documentation
# - Include customized DEVELOPER_SETUP_CHECKLIST.md
# - Add team-specific procedures
# - Add troubleshooting for your environment

# 3. Host documentation somewhere accessible
# - GitHub Wiki
# - Confluence
# - Notion
# - Internal wiki
```

### Phase 3: Developer Onboarding

**For each developer:**

1. **Send them:**
   - Link to repository
   - Link to DEVELOPER_SETUP_CHECKLIST.md
   - Link to DEVELOPER_GUIDE.md
   - Any team-specific documentation

2. **Have them:**
   - Follow DEVELOPER_SETUP_CHECKLIST.md
   - Run the 4 tests in "Testing Your Setup"
   - Read DEVELOPER_GUIDE.md
   - Create a feature branch to test the workflow

3. **Verify:**
   - They can access Odoo
   - They can modify files and see changes
   - They understand git workflow

---

## Customization Examples

### Example 1: Company X - Financial Services

**repos.yml customization:**
```yaml
./addons/oca/account:
  remotes:
    oca: git@github.com:OCA/account-financial-tools.git
    companyX: git@github.com:companyX/account-financial-tools.git
  merges:
    - oca 18.0
    - companyX compliance/sarbanes-oxley
  target: companyX master-18.0

./addons/oca/banking:
  remotes:
    oca: git@github.com:OCA/banking.git
    companyX: git@github.com:companyX/banking.git
  merges:
    - oca 18.0
  target: companyX master-18.0
```

### Example 2: Company Y - Manufacturing

**repos.yml customization:**
```yaml
./addons/oca/manufacture:
  remotes:
    oca: git@github.com:OCA/manufacture.git
    companyY: git@github.com:companyY/manufacture.git
  merges:
    - oca 18.0
  target: companyY master-18.0

./addons/oca/supply-chain:
  remotes:
    oca: git@github.com:OCA/supply-chain.git
    companyY: git@github.com:companyY/supply-chain.git
  merges:
    - oca 18.0
    - companyY enhancement/just-in-time
  target: companyY master-18.0
```

### Example 3: Company Z - SaaS with Multiple Customers

**docker-compose.yml customization:**
```yaml
services:
  web:
    environment:
      - ENABLE_GIT_AGGREGATE=false
      - WORKERS=4  # More for production
      - LONGPOLLING_PORT=8072
    volumes:
      - ./addons/custom:/mnt/extra-addons/custom:ro
      - ./addons/oca:/mnt/extra-addons/oca:ro
      - ./addons/oca-addons:/mnt/extra-addons/oca-addons:ro
      - odoo-web-data:/var/lib/odoo
      - ./ssl/:/etc/ssl/:ro  # Add SSL certs
```

---

## Multi-Environment Setup

### Development Environment

**docker-compose.dev.yml** (as provided)
```yaml
environment:
  - ENABLE_GIT_AGGREGATE=false
volumes:
  # All read-write for development
```

### Staging Environment

**docker-compose.staging.yml** (create new)
```yaml
version: '3.8'
services:
  web:
    environment:
      - ENABLE_GIT_AGGREGATE=false
      - WORKERS=2
    volumes:
      - ./addons/custom:/mnt/extra-addons/custom:ro
      - ./addons/oca:/mnt/extra-addons/oca:ro
      - ./addons/oca-addons:/mnt/extra-addons/oca-addons:ro
      - odoo-web-data:/var/lib/odoo
    # Add health checks, logging, monitoring
```

### Production Environment

**docker-compose.yml** (already production-ready)
```yaml
environment:
  - ENABLE_GIT_AGGREGATE=false
volumes:
  - ./addons/custom:/mnt/extra-addons/custom:ro  # Read-only
  - ./addons/oca:/mnt/extra-addons/oca:ro
  - ./addons/oca-addons:/mnt/extra-addons/oca-addons:ro
```

---

## Integration with CI/CD

### GitHub Actions Example

**.github/workflows/test.yml**
```yaml
name: Test Odoo-MTA

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Start Docker
        run: |
          docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
          sleep 30

      - name: Run tests
        run: |
          docker-compose exec -T web odoo -m odoo --test-enable --stop-after-init -d test-db

      - name: Verify modules load
        run: |
          docker-compose exec -T web ls /mnt/extra-addons/oca-addons/ | wc -l
          # Should be > 20
```

### GitLab CI Example

**.gitlab-ci.yml**
```yaml
test:
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
    - sleep 30
    - docker-compose exec -T web odoo --test-enable --stop-after-init -d test-db
```

---

## Security Considerations

### 1. SSH Keys

**For developers:**
- Each developer should have their own SSH key
- Added to their GitHub account
- Mount only in development mode

**docker-compose.dev.yml:**
```yaml
volumes:
  - ~/.ssh:/root/.ssh:ro  # Only in dev
```

### 2. Database Credentials

**Never commit:**
- `.env` file with real passwords
- `odoo.conf` with real credentials

**Use:**
- `.env.example` as template
- Environment variables for deployment
- Secrets management (Vault, etc.)

### 3. Docker Security

```bash
# Don't run as root in production
# Use: docker-compose exec -u odoo ...

# Regular image updates
docker-compose pull
```

---

## Monitoring & Logging

### Add Logging

**docker-compose.yml:**
```yaml
services:
  web:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### Add Monitoring

**New service: prometheus**
```yaml
prometheus:
  image: prom/prometheus
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
  ports:
    - "9090:9090"
```

### Health Checks

**docker-compose.yml:**
```yaml
services:
  web:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8069"]
      interval: 30s
      timeout: 10s
      retries: 3
  db:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo"]
      interval: 10s
      timeout: 5s
      retries: 5
```

---

## Backup Strategy

### Database Backups

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="./backups"
DB_NAME="mta-dev"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

docker-compose exec -T db pg_dump -U odoo $DB_NAME > \
  $BACKUP_DIR/odoo_$TIMESTAMP.sql

gzip $BACKUP_DIR/odoo_$TIMESTAMP.sql
```

### File Backups

```bash
#!/bin/bash
# backup-files.sh

tar -czf backups/odoo-files-$(date +%Y%m%d).tar.gz \
  addons/custom \
  odoo-web-data
```

---

## Documentation Structure for Teams

```
Documentation/
├── README.md                           # Overview
├── GETTING_STARTED.md                  # Quick start
├── DEVELOPER_SETUP_CHECKLIST.md        # Onboarding checklist
├── DEVELOPER_GUIDE.md                  # Full guide
├── TESTING_GUIDE.md                    # Testing procedures
│
├── Team Specific/
│   ├── SECURITY_GUIDELINES.md
│   ├── GIT_WORKFLOW.md
│   ├── CODE_REVIEW_PROCESS.md
│   ├── DEPLOYMENT_PROCEDURE.md
│   └── TROUBLESHOOTING_FAQ.md
│
└── Architecture/
    ├── SYSTEM_ARCHITECTURE.md
    ├── GIT_AGGREGATOR_DETAILS.md
    └── MODULE_STRUCTURE.md
```

---

## Success Metrics

After deployment, verify:

- [ ] All developers can start Odoo
- [ ] All developers can see all modules
- [ ] All developers can modify files and see changes
- [ ] All developers understand git workflow
- [ ] All developers can create custom modules
- [ ] All developers can add new OCA repos
- [ ] Zero setup issues from team

---

## Support & Maintenance

### Regular Updates

```bash
# Weekly: Update OCA modules
docker-compose.dev.yml: ENABLE_GIT_AGGREGATE=true
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
# Wait for git-aggregator to complete
```

### Bug Fixes

- Document issues in team Wiki/Confluence
- Create issues in GitHub
- Link to solutions in docs

### Team Communication

- Announce breaking changes
- Explain git-aggregator usage patterns
- Share best practices

---

## Checklist for Your Deployment

- [ ] Repository created from template
- [ ] All customizations completed
- [ ] OCA forks created for your organization
- [ ] repos.yml updated with your fork URLs
- [ ] README.md and docs customized
- [ ] CI/CD pipeline configured (optional)
- [ ] Security review completed
- [ ] Documentation published
- [ ] First developer onboarded successfully
- [ ] All tests passing
- [ ] Team trained on workflows

---

**Ready to deploy?** Start with Phase 1 above!
