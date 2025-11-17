# 🚀 Project Template Guide - Creating New Odoo MTA Projects

This guide explains how to use this template for creating new Odoo MTA projects.

---

## Quick Start

1. Go to: https://github.com/resultrum/odoo-template
2. Click **"Use this template"**
3. Create your new repository (e.g., `odoo-crm`)
4. Clone and run: `./scripts/setup-new-project.sh odoo-crm crm_base resultrum`

---

## What to Rename

| Original | New | Example |
|----------|-----|---------|
| `odoo-template` | Your project name | `odoo-crm` |
| `mta_base` | Your module name | `crm_base` |
| `resultrum` | Your organization | `yourorg` |

The `setup-new-project.sh` script automates this for you!

---

## Files Structure

```
Your Project/
├── .github/workflows/        # CI/CD pipelines (update org/project names)
├── addons/
│   ├── custom/               # Your custom modules
│   ├── oca/                  # Forked OCA addons
│   └── oca-addons/           # Symlinked OCA addons
├── scripts/
│   ├── setup-new-project.sh  # Automated setup
│   ├── backup.sh
│   └── health-check.sh
├── docker-compose.yml        # Base config
├── docker-compose.dev.yml    # Dev override
├── docker-compose.prod.yml   # Prod override
├── Dockerfile                # Odoo image
├── GUIDE.md                  # Architecture
├── DEPLOYMENT.md             # Deployment
└── README.md                 # Project info
```

---

## Setup Script Usage

```bash
./scripts/setup-new-project.sh <project-name> <module-name> <organization>

# Example:
./scripts/setup-new-project.sh odoo-crm crm_base resultrum
```

The script will:
1. Rename custom module directory
2. Update manifest files
3. Update docker-compose files
4. Update GitHub workflows
5. Update README and documentation
6. Reset VERSION to 0.1.0

---

## What NOT to Rename

These stay the same (they're generic):
- `Dockerfile`
- `.github/workflows/ci.yml`
- `entrypoint.sh`
- `.gitignore`
- `.pre-commit-config.yaml`
- Configuration files (.flake8, .pylintrc, pytest.ini)

---

## Complete Workflow

```bash
# 1. Create from template (via GitHub UI)
# 2. Clone
git clone https://github.com/yourorg/odoo-crm.git
cd odoo-crm

# 3. Run setup script
./scripts/setup-new-project.sh odoo-crm crm_base resultrum

# 4. Review and commit
git diff
git add .
git commit -m "chore: setup new project from template"

# 5. Create environment
cp .env.example .env
# Edit .env with your values

# 6. Start developing
docker-compose up -d

# 7. Push to GitHub
git push origin main
```

---

## Related Documentation

- **GUIDE.md** - Project architecture (5 phases)
- **DEPLOYMENT.md** - How to deploy
- **SECURITY_AUTHENTICATION.md** - Authentication & tokens
- **DOCKER_IMAGES.md** - Docker image management

---

**Version:** 1.0
**Template Repository:** https://github.com/resultrum/odoo-template
