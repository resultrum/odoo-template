# ✅ Developer Setup Checklist

Use this checklist when setting up odoo-mta on a new developer machine.

---

## Prerequisites Installation

### 1. System Requirements
- [ ] macOS/Linux/Windows with WSL2
- [ ] Minimum 8 GB RAM available
- [ ] 20 GB free disk space
- [ ] Administrator/sudo access

### 2. Required Software
- [ ] Docker Desktop installed (version 4.0+)
  - [ ] Docker running and accessible via CLI
  - [ ] At least 4 GB memory allocated to Docker
- [ ] Git installed
  - [ ] SSH keys generated and added to GitHub
  - [ ] Test: `ssh -T git@github.com` works
- [ ] Text editor/IDE (VS Code or PyCharm recommended)

### 3. GitHub Access
- [ ] GitHub account created
- [ ] SSH key added to GitHub account
- [ ] Access to `resultrum` organization repositories
  - [ ] resultrum/odoo-mta
  - [ ] resultrum/helpdesk
  - [ ] resultrum/server-tools (future)

---

## Project Setup

### 1. Clone Repository
```bash
[ ] git clone git@github.com:resultrum/odoo-mta.git
[ ] cd odoo-mta
[ ] git status  # Verify it's clean
```

### 2. Configure Environment
```bash
[ ] cp .env.example .env
[ ] cat .env  # Verify settings
```

### 3. Create Symlinks
```bash
[ ] ./scripts/create-oca-symlinks.sh
[ ] ls addons/oca-addons/ | wc -l  # Should be ~24
```

### 4. Start Docker
```bash
[ ] Docker Desktop is running
[ ] docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
[ ] docker-compose ps  # Both containers running
[ ] sleep 20  # Wait for startup
```

### 5. Initialize Database (if first time)
```bash
[ ] docker exec odoo-mta-web odoo -i base -d mta-dev --stop-after-init
[ ] docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### 6. Access Odoo
```bash
[ ] Open http://localhost:8069 in browser
[ ] Select database: mta-dev
[ ] Username: admin
[ ] Password: admin123
[ ] Click "Log In"
```

### 7. Verify Modules Visible
```bash
[ ] Click "Apps" in top navigation
[ ] Click "Update Apps List" (⟳ button)
[ ] Search for "helpdesk"
[ ] See at least 10+ helpdesk modules in results
```

---

## IDE Setup (Optional but Recommended)

### PyCharm Configuration
```bash
[ ] Open project folder in PyCharm
[ ] Configure Docker as remote interpreter
    [ ] PyCharm → Preferences → Python Interpreter
    [ ] Click gear icon → Add
    [ ] Select "Docker Compose"
    [ ] Select docker-compose.dev.yml
    [ ] Service: web
    [ ] Python interpreter path: /usr/bin/python3
[ ] Set project root for module resolution
```

### VS Code Configuration (Alternative)
```bash
[ ] Install extensions:
    [ ] Python
    [ ] Docker
    [ ] Remote - Containers
    [ ] Odoo snippets (optional)
[ ] Configure Python interpreter to Docker
```

---

## Git Workflow Setup

### 1. Fork Configuration
```bash
[ ] Fork these repositories to resultrum:
    [ ] github.com/OCA/helpdesk → resultrum/helpdesk
    [ ] github.com/OCA/server-tools → resultrum/server-tools
    [ ] github.com/OCA/sale → resultrum/sale (if needed)
```

### 2. Configure Git User
```bash
[ ] git config --global user.name "Your Name"
[ ] git config --global user.email "your.email@metrum.fr"
```

### 3. SSH Key Added to Agent
```bash
# macOS
[ ] ssh-add ~/.ssh/id_ed25519

# Linux
[ ] eval "$(ssh-agent -s)"
[ ] ssh-add ~/.ssh/id_ed25519

# Windows (Git Bash)
[ ] eval $(ssh-agent -s)
[ ] ssh-add ~/.ssh/id_ed25519
```

---

## Development Environment

### 1. Verify Docker Volumes
```bash
[ ] Check file sync works:
    [ ] Create test file: touch addons/custom/test.txt
    [ ] In Docker: docker exec odoo-mta-web ls /mnt/extra-addons/custom/test.txt
    [ ] File should exist
    [ ] Delete test file: rm addons/custom/test.txt
```

### 2. Test Hot Reload
```bash
[ ] Edit a module file (e.g., models/helpdesk_ticket.py)
[ ] Check Docker logs: docker-compose logs -f web
[ ] Should see "reload" or "module updated"
[ ] Changes visible in Odoo after refresh
```

### 3. Configure Code Formatting
```bash
[ ] Install Python formatter (optional):
    [ ] pip install black flake8
[ ] Configure IDE to use these on save
```

---

## Understanding the Setup

### Git-Aggregator

- [ ] Read: [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) - "Git-Aggregator Workflow" section
- [ ] Understand what `repos.yml` does
- [ ] Know how to enable git-aggregator: `ENABLE_GIT_AGGREGATE=true` in docker-compose.dev.yml

### Symlinks

- [ ] Understand symlinks:
  - [ ] `addons/oca-addons/helpdesk_mgmt` → `../oca/helpdesk/helpdesk_mgmt`
  - [ ] Why: Odoo expects flat structure, OCA repos have nested structure
- [ ] Know how to regenerate: `./scripts/create-oca-symlinks.sh`

### Docker Volumes

- [ ] Understand volume mounts:
  ```
  ./addons/custom     ↔ /mnt/extra-addons/custom (rw)
  ./addons/oca        ↔ /mnt/extra-addons/oca (rw)
  ./addons/oca-addons ↔ /mnt/extra-addons/oca-addons (rw)
  ```
- [ ] File changes sync in real-time during development

---

## Common Development Workflows

### Scenario 1: Modify an OCA Module

```bash
[ ] Follow steps in DEVELOPER_GUIDE.md, "Scenario 1: Modify an OCA Module"
```

**Quick version:**
```bash
[ ] cd addons/oca/helpdesk
[ ] git checkout -b feature/your-feature
[ ] Edit files and test in Odoo (reload happens automatically)
[ ] git commit and git push resultrum feature/your-feature
[ ] (Optional) Update repos.yml to include your branch
[ ] (Optional) Enable git-aggregator to merge your branch
```

### Scenario 2: Create a Custom Module

```bash
[ ] Follow steps in DEVELOPER_GUIDE.md, "Scenario 3: Create a Custom Metrum Module"
```

**Quick version:**
```bash
[ ] mkdir -p addons/custom/mta_mymodule/{models,views,security}
[ ] Create __manifest__.py
[ ] Create models, views, security files
[ ] Go to Odoo: Apps → Update Apps List
[ ] Search and install your module
```

### Scenario 3: Work with Multiple Developers

```bash
[ ] Everyone follows this checklist
[ ] Use feature branches (not committing to main)
[ ] Pull latest before starting: git pull origin main
[ ] Push regularly: git push origin feature/your-feature
[ ] Create PRs for code review
```

---

## Testing Your Setup

Run these tests to verify everything works:

### Test 1: Modules Visible
```bash
[ ] Go to http://localhost:8069
[ ] Apps → Search for "helpdesk"
[ ] At least 10 modules should appear
```

### Test 2: Hot Reload Works
```bash
[ ] Edit a file in addons/custom/
[ ] Save file
[ ] Go to Odoo and reload the page
[ ] No restart required - changes load automatically
```

### Test 3: Git-Aggregator Preparation
```bash
[ ] Verify repos.yml exists
[ ] Understand current configuration
[ ] Know how to enable it (for future use)
```

### Test 4: Symlinks Work
```bash
[ ] ./scripts/create-oca-symlinks.sh
[ ] ls addons/oca-addons/ | wc -l  # Should show ~24
```

---

## Troubleshooting

If you encounter issues:

1. **"Docker not running"**
   - [ ] Start Docker Desktop
   - [ ] Verify: `docker ps`

2. **"Permission denied" on git operations**
   - [ ] Test SSH: `ssh -T git@github.com`
   - [ ] Add SSH key to agent: `ssh-add ~/.ssh/id_ed25519`

3. **"Odoo not accessible"**
   - [ ] Check containers: `docker-compose ps`
   - [ ] Check logs: `docker-compose logs web`
   - [ ] Restart: `docker-compose restart web`

4. **"Modules not appearing in Odoo"**
   - [ ] Check symlinks: `ls addons/oca-addons/`
   - [ ] Regenerate: `./scripts/create-oca-symlinks.sh`
   - [ ] Refresh Odoo: Apps → Update Apps List

5. **Still stuck?**
   - [ ] Read DEVELOPER_GUIDE.md "Troubleshooting" section
   - [ ] Check TESTING_GUIDE.md
   - [ ] Ask team lead for help

---

## Final Verification

```bash
[ ] Docker containers running: docker-compose ps
[ ] Odoo accessible: http://localhost:8069 works
[ ] Can see helpdesk modules in Odoo
[ ] Can modify files and see changes (hot reload)
[ ] Git configured: git config --global --list
[ ] SSH working: ssh -T git@github.com
```

---

## Next Steps

1. **Read Documentation**
   - [ ] [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)
   - [ ] [TESTING_GUIDE.md](./TESTING_GUIDE.md)

2. **Understand the Workflow**
   - [ ] How to modify OCA modules
   - [ ] How to create custom modules
   - [ ] How to add new repositories

3. **Start Development**
   - [ ] Create your first feature branch
   - [ ] Make a test modification
   - [ ] Commit and push

---

**Completed on:** ____________________

**Setup verified by:** ____________________

**Need help?** Contact your team lead or check the documentation.
