# 📖 Documentation Index

Complete guide to all documentation files in odoo-mta project.

---

## 🎯 Getting Started

**First time here?** Start with:

1. **[README.md](./README.md)** - Project overview (5 min read)
2. **[DEVELOPER_SETUP_CHECKLIST.md](./DEVELOPER_SETUP_CHECKLIST.md)** - Setup your machine (15-20 min)
3. **[DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)** - Learn the workflows (30 min read)

---

## 📚 Complete Documentation

### Quick References

| Document | Purpose | Audience | Time |
|----------|---------|----------|------|
| **[README.md](./README.md)** | Project overview, quick start | Everyone | 5 min |
| **[PREREQUISITES_BY_OS.md](./PREREQUISITES_BY_OS.md)** | OS-specific setup guide (macOS, Windows, Linux) | All developers | 15 min |
| **[QUICK_START.md](./QUICK_START.md)** | 5-minute quick setup | Impatient developers | 5 min |
| **[DEVELOPER_SETUP_CHECKLIST.md](./DEVELOPER_SETUP_CHECKLIST.md)** | Step-by-step setup guide | New developers | 20 min |
| **[DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)** | Complete workflow guide | Developers | 30 min |
| **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** | Validation procedures | QA, Maintainers | 45 min |
| **[DEPLOYMENT_TEMPLATE.md](./DEPLOYMENT_TEMPLATE.md)** | Deploy to your organization | Tech leads | 60 min |
| **[GITIGNORE_REFERENCE.md](./GITIGNORE_REFERENCE.md)** | .gitignore explanation & security | Developers, DevOps | 20 min |

---

## 🎓 Learning Paths

### Path 1: I'm a New Developer

1. Read: [README.md](./README.md)
2. Follow: [DEVELOPER_SETUP_CHECKLIST.md](./DEVELOPER_SETUP_CHECKLIST.md)
3. Study: [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) sections:
   - Architecture Overview
   - Scenario 1: Modify an OCA Module
   - Scenario 3: Create a Custom Module
4. Reference: [Troubleshooting](./DEVELOPER_GUIDE.md#troubleshooting) as needed

**Time to productivity:** ~1-2 hours

### Path 2: I'm a Tech Lead

1. Read: [README.md](./README.md)
2. Study: [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) - all sections
3. Read: [TESTING_GUIDE.md](./TESTING_GUIDE.md)
4. Plan: [DEPLOYMENT_TEMPLATE.md](./DEPLOYMENT_TEMPLATE.md)
5. Execute: Setup for team

**Time to understand:** ~2-3 hours

### Path 3: I'm Deploying to a New Team

1. Read: [DEPLOYMENT_TEMPLATE.md](./DEPLOYMENT_TEMPLATE.md) - complete
2. Reference: [DEVELOPER_SETUP_CHECKLIST.md](./DEVELOPER_SETUP_CHECKLIST.md)
3. Customize: All files for your organization
4. Test: [TESTING_GUIDE.md](./TESTING_GUIDE.md)
5. Distribute: Documentation to your team

**Time to deploy:** ~4-6 hours

---

## 📋 Document Structure

### [README.md](./README.md)
**Project overview and quick start**

**Contents:**
- Project objectives
- Technology stack
- Quick start instructions
- Links to full documentation

**For:** Everyone
**When:** First introduction to project

---

### [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)
**Complete developer workflow guide**

**Contents:**
- [Quick Start](#quick-start) - 2-minute setup
- [Architecture Overview](#architecture-overview)
  - Directory structure
  - Git-aggregator explanation
  - Symlinks explanation
  - Docker volumes explanation
- [Git-Aggregator Workflow](#git-aggregator-workflow)
  - Understanding repos.yml
  - Activation & deactivation
- [Developer Workflows](#developer-workflows)
  - **Scenario 1:** Modify an OCA Module
    - Create fork, branches, custom branch in repos.yml
    - Enable git-aggregator, test in Odoo
  - **Scenario 2:** Add a New OCA Repository
    - Fork, update repos.yml, restart Docker
  - **Scenario 3:** Create a Custom Metrum Module
    - Directory structure, manifest, models, views, security
- [Troubleshooting](#troubleshooting)
- [Reference](#reference)
  - Useful commands
  - Git commands
  - Configuration files
  - Environment variables

**For:** All developers
**When:** Learning workflows and solving problems

---

### [DEVELOPER_SETUP_CHECKLIST.md](./DEVELOPER_SETUP_CHECKLIST.md)
**Step-by-step setup guide for new developers**

**Contents:**
- Prerequisites installation
- Project setup
- IDE configuration
- Git workflow setup
- Development environment verification
- Common workflows (quick reference)
- Troubleshooting
- Final verification checklist

**For:** New developers setting up their machine
**When:** First time joining the project

---

### [TESTING_GUIDE.md](./TESTING_GUIDE.md)
**Comprehensive testing procedures**

**Contents:**
- **Test 1:** Verify current setup
- **Test 2:** Simulate adding custom branch to OCA
- **Test 3:** Simulate adding new repository
- **Test 4:** Verify symlink regeneration
- **Test 5:** Verify production mode
- **Common test scenarios**
  - Update OCA modules
  - Merge multiple custom branches
  - Switch between OCA versions
- **Troubleshooting tests**
- **Summary checklist**

**For:** QA, Maintainers, Tech leads verifying setup
**When:** Before deployment, when introducing changes

---

### [DEPLOYMENT_TEMPLATE.md](./DEPLOYMENT_TEMPLATE.md)
**Guide to using odoo-mta as a template for your organization**

**Contents:**
- What to customize
  - Organization/repository names
  - Project names
  - Database names
  - Module prefixes
  - Documentation
- Step-by-step deployment to team
  - Phase 1: Prepare template
  - Phase 2: Distribute to team
  - Phase 3: Developer onboarding
- Customization examples for different industries
- Multi-environment setup (dev, staging, prod)
- CI/CD integration examples
- Security considerations
- Monitoring & logging
- Backup strategy
- Documentation structure for teams
- Success metrics

**For:** Tech leads, DevOps, project managers
**When:** Deploying to new organization/team

---

## 🔍 Quick Lookup

### I want to...

**Understand the project**
→ Read [README.md](./README.md)

**Set up my development machine**
→ Follow [DEVELOPER_SETUP_CHECKLIST.md](./DEVELOPER_SETUP_CHECKLIST.md)

**Modify an OCA module**
→ Go to [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md#scenario-1-modify-an-oca-module)

**Add a new OCA repository**
→ Go to [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md#scenario-2-add-a-new-oca-repository)

**Create a custom Metrum module**
→ Go to [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md#scenario-3-create-a-custom-metrum-module)

**Fix git-aggregator issues**
→ See [DEVELOPER_GUIDE.md#git-aggregator-issues](./DEVELOPER_GUIDE.md#git-aggregator-issues)

**Fix Docker issues**
→ See [DEVELOPER_GUIDE.md#docker-issues](./DEVELOPER_GUIDE.md#docker-issues)

**Test the setup**
→ Follow [TESTING_GUIDE.md](./TESTING_GUIDE.md)

**Deploy to my organization**
→ Follow [DEPLOYMENT_TEMPLATE.md](./DEPLOYMENT_TEMPLATE.md)

**Find a specific command**
→ See [DEVELOPER_GUIDE.md#reference](./DEVELOPER_GUIDE.md#reference) - "Useful Commands"

---

## 🛠️ Configuration Files

| File | Purpose | When to Edit |
|------|---------|--------------|
| [repos.yml](./repos.yml) | Git-aggregator configuration | Adding/updating OCA repos |
| [docker-compose.yml](./docker-compose.yml) | Production Docker setup | Rare, production config |
| [docker-compose.dev.yml](./docker-compose.dev.yml) | Development overrides | When enabling git-aggregator |
| [odoo.conf](./odoo.conf) | Odoo server config | Odoo-specific settings |
| [.env.example](./.env.example) | Environment template | Use as reference, copy to .env |
| [Dockerfile](./Dockerfile) | Container image | Rare, Docker dependencies |
| [entrypoint.sh](./entrypoint.sh) | Container startup script | Rare, initialization logic |

---

## 🚀 Common Commands

### Starting Development
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
docker-compose logs -f web
```

### Enabling Git-Aggregator
```bash
# Edit docker-compose.dev.yml
# Set: ENABLE_GIT_AGGREGATE=true
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Accessing Container
```bash
docker exec -it odoo-mta-web bash
```

### Checking Modules
```bash
docker exec odoo-mta-web ls /mnt/extra-addons/oca-addons/
```

### Regenerating Symlinks
```bash
./scripts/create-oca-symlinks.sh
```

---

## 📞 Help & Support

### If you're stuck:

1. **Check [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) Troubleshooting section**
2. **Check [TESTING_GUIDE.md](./TESTING_GUIDE.md) for validation tests**
3. **Run diagnostic commands in [DEVELOPER_GUIDE.md#reference](./DEVELOPER_GUIDE.md#reference)**
4. **Check your Docker logs:** `docker-compose logs web`
5. **Ask your team lead or technical contact**

### Common Issues:

**"Can't find modules"**
→ [DEVELOPER_GUIDE.md#symlinks-not-created](./DEVELOPER_GUIDE.md#symlinks-not-created)

**"Git authentication fails"**
→ [DEVELOPER_GUIDE.md#git-authentication-fails](./DEVELOPER_GUIDE.md#git-authentication-fails)

**"Docker containers crashing"**
→ [DEVELOPER_GUIDE.md#container-keeps-stopping](./DEVELOPER_GUIDE.md#container-keeps-stopping)

**"Permission errors"**
→ [DEVELOPER_GUIDE.md#permission-errors-on-volumes](./DEVELOPER_GUIDE.md#permission-errors-on-volumes)

---

## 📊 Documentation Statistics

- **Total documents:** 6 markdown files
- **Total content:** ~6000+ lines
- **Code examples:** 50+
- **Workflows covered:** 5+
- **Troubleshooting scenarios:** 10+
- **Test procedures:** 5

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Oct 30, 2025 | Initial release with complete documentation |

---

## 📝 Notes for Maintainers

### How to Update Documentation

1. Update the relevant document
2. Update version date if major changes
3. Update this index if adding new documents
4. Commit with message: `docs: update [doc-name]`

### Document Standards

- Use clear, concise language
- Include code examples for all procedures
- Cross-reference related sections
- Include troubleshooting for complex topics
- Use consistent formatting (headers, code blocks, tables)

---

**Last updated:** October 30, 2025

**Questions?** Open an issue or contact the team.
