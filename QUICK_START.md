# ⚡ Quick Start (5 minutes)

For the impatient developer who wants to start coding immediately.

---

## Prerequisites Check

```bash
# Verify you have:
docker --version          # Should be 4.0+
docker-compose --version  # Should be 2.0+
git --version             # Should be 2.0+
ssh -T git@github.com     # Should work without errors
```

If any fail, see [DEVELOPER_SETUP_CHECKLIST.md](./DEVELOPER_SETUP_CHECKLIST.md)

---

## Installation (2 minutes)

```bash
# 1. Clone
git clone git@github.com:resultrum/odoo-mta.git
cd odoo-mta

# 2. Setup
cp .env.example .env
./scripts/create-oca-symlinks.sh

# 3. Start Docker
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# 4. Wait 20 seconds
sleep 20

# 5. Access
open http://localhost:8069
```

**Credentials:**
- Database: `mta-dev`
- Username: `admin`
- Password: `admin123`

---

## First Development Task (3 minutes)

### Create a Custom Module

```bash
# 1. Create the module
mkdir -p addons/custom/mta_mymodule/{models,views}

# 2. Create __manifest__.py
cat > addons/custom/mta_mymodule/__manifest__.py << 'EOF'
{
    'name': 'My Module',
    'version': '18.0.1.0.0',
    'depends': ['base'],
    'data': [],
    'installable': True,
}
EOF

# 3. Create __init__.py
cat > addons/custom/mta_mymodule/__init__.py << 'EOF'
from . import models
EOF

# 4. Create models/__init__.py
touch addons/custom/mta_mymodule/models/__init__.py

# 5. Go to Odoo
# Apps → Update Apps List
# Search "My Module" and install
```

**That's it!** You now have a working module.

---

## Make Changes & See Them Live

```bash
# 1. Edit a file
nano addons/custom/mta_mymodule/models/__init__.py

# 2. Save
# Ctrl+S (editor)

# 3. Check Odoo logs
docker-compose logs web | tail -20

# 4. Refresh browser
# F5 or Cmd+R

# ✅ Changes loaded automatically!
```

---

## Common Tasks

### Modify an OCA Module

```bash
cd addons/oca/helpdesk
git checkout -b feature/my-change
# ... edit files ...
git add .
git commit -m "Fix: description"
git push resultrum feature/my-change
```

Then read [DEVELOPER_GUIDE.md#scenario-1](./DEVELOPER_GUIDE.md#scenario-1-modify-an-oca-module) for next steps.

### Access Container Shell

```bash
docker exec -it odoo-mta-web bash
```

### View Logs

```bash
docker-compose logs -f web    # Follow logs
docker-compose logs web       # Last 100 lines
```

### Restart Everything

```bash
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Check Modules Loaded

```bash
docker exec odoo-mta-web ls /mnt/extra-addons/oca-addons/ | wc -l
# Should show: 23 (22 modules + 1 .gitkeep)
```

---

## Need Help?

| Issue | Solution |
|-------|----------|
| **Can't clone** | Check SSH: `ssh -T git@github.com` |
| **Docker not running** | Start Docker Desktop |
| **Odoo not accessible** | Check containers: `docker-compose ps` |
| **Modules not visible** | Run: `./scripts/create-oca-symlinks.sh` |
| **Changes not loading** | Check logs: `docker-compose logs web` |

For more issues, see [DEVELOPER_GUIDE.md#troubleshooting](./DEVELOPER_GUIDE.md#troubleshooting)

---

## Next: Read Full Docs

- 📖 [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) - Complete workflows
- 📖 [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md) - Find anything

---

**You're ready!** Start coding! 🚀
