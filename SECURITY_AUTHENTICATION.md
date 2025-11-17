# 🔐 Security & Authentication Guide

This document explains how to securely authenticate with GitHub Container Registry (GHCR) for Docker image deployments.

---

## ⚠️ The Problem: Personal Access Tokens Are Dangerous

### ❌ NEVER DO THIS:

```bash
# DON'T use your personal GitHub token!
docker login ghcr.io
Username: your-personal-github-account
Password: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx  # ← Your personal token with full access!
```

**Why?**
- Your personal token can access ALL your repositories
- If leaked, attacker has access to everything you own
- No audit trail for who used the token
- Violates principle of least privilege

### ✅ DO THIS INSTEAD:

Use **limited-scope deployment tokens** with minimal permissions.

---

## 🎯 Authentication Strategies

### Strategy 1: Organization-Level Deployment Token (RECOMMENDED)

**Best for:** Team environments, Azure deployments

**Setup:**

1. Go to GitHub Organization Settings
   ```
   https://github.com/organizations/resultrum/settings/tokens
   ```

2. Create Fine-Grained Personal Access Token
   - **Token name:** `odoo-mta-staging-deployer`
   - **Description:** "Staging deployment token for GHCR image pulls"
   - **Expiration:** 90 days
   - **Repository access:** Only `resultrum/odoo-mta`
   - **Permissions:**
     - ✅ `read:packages` (pull container images only)
     - ❌ `write:packages` (NOT NEEDED - we don't push)
     - ❌ `contents` (NOT NEEDED)
   - ✅ **Create token**

3. Copy and store securely:
   ```
   ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

**Usage:**

```bash
# On deployment machine
docker login ghcr.io
Username: deployment-username-or-bot-account
Password: <paste the token above>
```

---

### Strategy 2: GitHub App (Enterprise-Grade)

**Best for:** Large teams, high-security requirements

**Setup:**

1. Go to GitHub Organization Settings → Developer settings → GitHub Apps
2. Create New GitHub App
   - **App name:** `odoo-mta-staging-deployer`
   - **Homepage URL:** `https://github.com/resultrum/odoo-mta`
   - **Webhook:** Uncheck "Active"
   - **Permissions:**
     - Repository: `contents` - Read-only
     - Repository: `packages` - Read-only
   - **Where can this app be installed:** Only on this account

3. Install on repo
4. Generate private key
5. Use in CI/CD (complex setup, ask for help)

---

### Strategy 3: GitHub Actions Secrets (For CI/CD Only)

**Best for:** Automated deployments via GitHub Actions

**Setup:**

1. Create deployment token (see Strategy 1)

2. Add to GitHub repo secrets:
   ```
   GitHub → Settings → Secrets and variables → Actions
   + New repository secret

   Name: GHCR_DEPLOY_TOKEN
   Value: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

3. Use in workflow:
   ```yaml
   - name: Login to GHCR
     run: |
       docker login ghcr.io -u ${{ github.actor }} -p ${{ secrets.GHCR_DEPLOY_TOKEN }}
   ```

**Advantages:**
- Token never stored on machines
- Token only used during CI/CD runs
- Automatically logged and auditable

---

## 🔄 Token Rotation & Maintenance

### Rotate Every 90 Days

**When:**
- First Friday of each quarter
- Immediately if token is leaked
- After team member leaves

**How:**

1. Create new token (see above)
2. Update in all locations:
   - GitHub Secrets (if using CI/CD)
   - Azure VM ~/.docker/config.json
   - Any other deployment machines
3. Test deployment works
4. Delete old token
   ```
   GitHub → Settings → Developer settings → Personal access tokens
   → Delete old token
   ```

### Document Token Usage

Keep a log (secure location):

```
Token Name: odoo-mta-staging-deployer
Created: 2025-11-17
Expires: 2026-02-17
Usage: Docker image pulls from GHCR for Azure STAGING deployment
Stored in: GitHub Secrets (GHCR_DEPLOY_TOKEN)
Status: ACTIVE
```

---

## 🛡️ Securing Credentials on Machines

### Option 1: Docker config.json (Recommended)

```bash
# On Azure VM or deployment machine

# Create directory
mkdir -p ~/.docker

# Create config with base64-encoded credentials
cat > ~/.docker/config.json << EOF
{
  "auths": {
    "ghcr.io": {
      "auth": "$(echo -n 'deployment-user:ghp_token...' | base64)"
    }
  }
}
EOF

# Secure the file
chmod 600 ~/.docker/config.json

# Verify
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148
```

### Option 2: .netrc File (Alternative)

```bash
cat > ~/.netrc << EOF
machine ghcr.io
login deployment-user
password ghp_token...
EOF

chmod 600 ~/.netrc
```

### Option 3: Environment Variables (CI/CD Only)

```bash
export DOCKER_USERNAME=deployment-user
export DOCKER_PASSWORD=ghp_token...

docker login ghcr.io -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
```

---

## ⚠️ Security Checklist

### For Developers

- [ ] Never use personal GitHub token for deployments
- [ ] Create separate deployment tokens for each use case
- [ ] Only grant `read:packages` permission
- [ ] Set token expiration to 90 days
- [ ] Never commit tokens to Git
- [ ] Never share tokens in Slack/email
- [ ] Use environment variables or .docker/config.json

### For DevOps / Admins

- [ ] Rotate tokens every 90 days
- [ ] Audit token usage in GitHub logs
- [ ] Remove old tokens after rotation
- [ ] Restrict token permissions to minimum needed
- [ ] Monitor unauthorized pull attempts
- [ ] Document token lifecycle
- [ ] Test emergency token revocation

### For Azure Deployments

- [ ] Store credentials in ~/.docker/config.json (600 permissions)
- [ ] Use .env files for secrets (never committed to Git)
- [ ] Rotate database passwords separately from GHCR tokens
- [ ] Monitor Docker image pulls in logs
- [ ] Restrict SSH access to VM (key-based only)
- [ ] Firewall: Only expose ports 80/443

---

## 🚨 What If Token Is Leaked?

### Immediate Actions (< 5 minutes)

1. **Revoke token immediately:**
   ```
   GitHub → Settings → Developer settings → Personal access tokens
   → Delete compromised token
   ```

2. **Notify team:**
   - Slack: `#devops` or security channel
   - Email: security@resultrum.com

3. **Check for unauthorized access:**
   ```bash
   # GitHub: Check action logs for suspicious activity
   # Azure: Check Docker pull logs
   docker-compose -f docker-compose.staging.yml logs | grep "Error"
   ```

### Follow-Up (< 1 hour)

4. **Create new token** with same permissions
5. **Update all locations:**
   - GitHub Secrets
   - Azure VMs
   - Any other machines
6. **Test deployment works**
7. **Delete old token**

### Documentation (< 1 day)

8. **Post-mortem:**
   - How was token exposed?
   - What changes prevent it in future?
   - Update this guide if needed

---

## 🔍 Monitoring & Auditing

### GitHub Actions Audit Log

```
https://github.com/resultrum/odoo-mta/settings/audit-log
```

Look for:
- Successful GHCR logins
- Failed authentication attempts
- Token creations/deletions

### Docker Image Pull Logs

```bash
# On Azure VM
docker system df  # Show image sizes
docker history ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148
```

### Set Up Alerts

Consider setting up notifications for:
- Failed authentication attempts
- Unusual image pulls
- Token expiration warnings (optional)

---

## 📚 Related Documentation

- **STAGING_AZURE_DEPLOYMENT.md** - How to deploy using tokens
- **DEPLOYMENT.md** - General deployment guide
- **GUIDE.md** - Project architecture

---

## 💡 Best Practices Summary

| Practice | Why | How |
|----------|-----|-----|
| **Limited scope tokens** | Reduce blast radius if leaked | Use fine-grained PAT, `read:packages` only |
| **90-day rotation** | Minimize exposure window | Calendar reminder, automated rotation |
| **Separate per use case** | Audit trail, granular revocation | `odoo-mta-staging`, `odoo-mta-prod`, etc. |
| **Secure storage** | Prevent accidental exposure | ~/.docker/config.json, GitHub Secrets |
| **Never commit credentials** | Git history is permanent | .gitignore, pre-commit hooks |
| **Audit logging** | Detect compromise early | GitHub action logs, Docker logs |

---

## ❓ FAQ

**Q: Can I use a robot/bot account instead?**
A: Yes! Create a bot account in your org with minimal permissions. Better security.

**Q: Should I rotate tokens more frequently than 90 days?**
A: Only if:
- High-security environment (e.g., healthcare, finance)
- Token is used by many people
- Organization policy requires it

**Q: Can I use the same token for dev, staging, and prod?**
A: No! Use separate tokens per environment for:
- Isolation (if one is compromised, others are safe)
- Audit trail (know which env was accessed)
- Different expiration dates per environment

**Q: What if I accidentally commit a token?**
A:
1. Immediately revoke it
2. Replace it in all locations
3. Check GitHub audit logs for misuse
4. Contact GitHub support if needed

**Q: How do I test if my credentials work?**
A:
```bash
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148
# If successful, credentials are working!
```

---

**Last Updated:** 2025-11-17
**Version:** 1.0
**Audience:** All developers and DevOps engineers
