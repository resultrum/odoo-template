# 🔐 Creating Deployment Token - Step-by-Step Guide

This guide walks you through creating a secure deployment token for pulling Docker images from GHCR.

**⏱️ Time required:** 5 minutes
**🔑 Who should do this:** Organization admin or GitHub team lead

---

## Step 1: Go to GitHub Organization Settings

### Via Web UI:

1. Open GitHub: https://github.com
2. Click your profile icon (top right)
3. Select **"Your organizations"**
4. Click on **"resultrum"** organization
5. Click **Settings** (right sidebar)

**Or direct URL:**
```
https://github.com/organizations/resultrum/settings
```

✅ You should see the organization settings page.

---

## Step 2: Navigate to Developer Settings

From organization settings page:

1. Left sidebar → Scroll down to **"Developer settings"**
2. Click **"Developer settings"**

**Or direct URL:**
```
https://github.com/organizations/resultrum/settings/personal-access-tokens
```

---

## Step 3: Create New Fine-Grained Token

### You should see: "Personal access tokens" page

1. Click **"Fine-grained tokens"** tab (if not already selected)
2. Click **"Generate new token"** button (green button, top right)

**Or direct URL:**
```
https://github.com/organizations/resultrum/settings/tokens/new
```

---

## Step 4: Configure Token Details

### Fill in the form:

```
┌─────────────────────────────────────────────────────────────┐
│ Token Name *                                                │
│ odoo-mta-staging-deployer                                   │
│                                                             │
│ Description (optional)                                      │
│ Docker image pulls from GHCR for STAGING deployment         │
│                                                             │
│ Expiration *                                                │
│ 90 days                                                     │
│                                                             │
│ Resource owner *                                            │
│ resultrum (organization)                                    │
└─────────────────────────────────────────────────────────────┘
```

✅ **Token name**: `odoo-mta-staging-deployer`
✅ **Expiration**: 90 days
✅ **Owner**: resultrum (organization, NOT your user account)

---

## Step 5: Set Repository Access

### Under "Repository access"

Select: **"Only select repositories"**

Then click the dropdown and:
1. Search for: `odoo-mta`
2. Select: `resultrum/odoo-mta`
3. Click **"Select repository"**

```
Repository access
  ⦿ All repositories
  ⦿ Only select repositories  ← SELECT THIS
    └─ Selected repositories:
       └─ [resultrum/odoo-mta] ✓
```

✅ **Only** `resultrum/odoo-mta` should be selected (not other repos)

---

## Step 6: Set Permissions

### Scroll down to "Permissions"

You'll see two sections:
- **Repository permissions**
- **Organization permissions**

### Repository permissions - IMPORTANT:

Find **"Contents"** and set to: **Read-only**

Find **"Packages"** and set to: **Read-only**

**All other permissions:** Leave as default (or "No access")

```
Repository Permissions:
  Contents:        ▼ Read-only  ✓
  Packages:        ▼ Read-only  ✓
  Issues:          ▼ No access
  Discussions:     ▼ No access
  Pull requests:   ▼ No access
  Code scanning:   ▼ No access
  Deployments:     ▼ No access
  ... (rest on "No access")
```

### Organization permissions - IMPORTANT:

Leave all as default or "No access"

⚠️ **Do NOT grant organization-level permissions**

---

## Step 7: Review & Create Token

Before clicking "Generate token", verify:

```
✅ Token name: odoo-mta-staging-deployer
✅ Expiration: 90 days
✅ Repository access: Only resultrum/odoo-mta
✅ Contents: Read-only
✅ Packages: Read-only
✅ All other permissions: No access
✅ Organization: resultrum
```

If everything looks correct:

👉 Click **"Generate token"** button (green)

---

## Step 8: Copy Token (IMPORTANT!)

⚠️ **CRITICAL:** GitHub only shows the token ONCE!

You'll see:

```
┌─────────────────────────────────────────────────────────────┐
│ Fine-grained personal access token                          │
│                                                             │
│ ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx            │
│                                                             │
│ [Copy] button ← CLICK THIS                                 │
│                                                             │
│ ⚠️ Make sure to copy your token now!                       │
│    You won't be able to see it again.                       │
└─────────────────────────────────────────────────────────────┘
```

1. Click **[Copy]** button
2. Paste into a SECURE location (see below)
3. Do NOT share or commit this token!

---

## Step 9: Store Token Securely

### Choose ONE method:

#### Option A: GitHub Secrets (For CI/CD)

If you want GitHub Actions to use this token:

1. Go to: `https://github.com/resultrum/odoo-mta/settings/secrets/actions`
2. Click **"New repository secret"**
3. **Name**: `GHCR_DEPLOY_TOKEN`
4. **Value**: Paste the token you just copied
5. Click **"Add secret"**

✅ Token is now stored in GitHub Secrets
✅ Accessible in GitHub Actions workflows
✅ Never visible in logs

#### Option B: Local Development Machine

If you want to deploy manually from your computer:

```bash
# macOS / Linux
cat > ~/.docker/config.json << 'EOF'
{
  "auths": {
    "ghcr.io": {
      "auth": "$(echo -n 'your-github-username:ghp_xxxxx...' | base64)"
    }
  }
}
EOF

# Secure the file
chmod 600 ~/.docker/config.json
```

⚠️ Replace:
- `your-github-username` with your actual GitHub username
- `ghp_xxxxx...` with the token you just copied

#### Option C: Azure VM (For Production Deployments)

On your Azure VM:

```bash
# SSH into VM
ssh -i your-key.pem azureuser@your-vm-ip

# Create Docker credentials
mkdir -p ~/.docker

cat > ~/.docker/config.json << 'EOF'
{
  "auths": {
    "ghcr.io": {
      "auth": "$(echo -n 'your-github-username:ghp_xxxxx...' | base64)"
    }
  }
}
EOF

# Secure the file
chmod 600 ~/.docker/config.json

# Test authentication
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148
```

If successful, you'll see:
```
master-iteration1.0-63148: Pulling from resultrum/odoo-mta
...
Status: Downloaded newer image for ghcr.io/resultrum/odoo-mta:...
```

---

## ✅ Verification Checklist

After creating the token:

- [ ] Token created in GitHub organization (NOT your user account)
- [ ] Named `odoo-mta-staging-deployer`
- [ ] Set to 90-day expiration
- [ ] Repository access: Only `resultrum/odoo-mta`
- [ ] Permissions: `read:packages` ONLY
- [ ] Token copied and stored securely
- [ ] NOT committed to Git
- [ ] Test pull works: `docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148`

---

## 🔄 Using the Token

### In Docker Commands:

```bash
# Option 1: Via docker login
docker login ghcr.io
Username: your-github-username
Password: ghp_xxxxx...  # Your token

# Option 2: Inline
docker login ghcr.io -u your-github-username -p ghp_xxxxx...

# Option 3: Via stored credentials
# (if you created ~/.docker/config.json)
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148
```

### In GitHub Actions:

```yaml
- name: Login to GHCR
  run: |
    docker login ghcr.io -u ${{ github.actor }} -p ${{ secrets.GHCR_DEPLOY_TOKEN }}

- name: Pull image
  run: |
    docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0-63148
```

---

## 🔐 Security Best Practices

After creating token:

✅ **DO:**
- Store in GitHub Secrets for CI/CD
- Store in ~/.docker/config.json on deployment machines
- Set file permissions to 600 on Unix/Linux
- Rotate token every 90 days
- Document token purpose

❌ **DON'T:**
- Commit token to Git
- Share in Slack/email/messages
- Use personal GitHub token instead
- Grant unnecessary permissions
- Keep token longer than 90 days

---

## 🔄 Token Rotation (Every 90 Days)

When token expires (or before):

1. Create NEW token (follow steps 1-8 again)
2. Update in all locations:
   - GitHub Secrets: `GHCR_DEPLOY_TOKEN`
   - Local machine: ~/.docker/config.json
   - Azure VMs: ~/.docker/config.json
3. Test new token works
4. Delete old token:
   ```
   https://github.com/organizations/resultrum/settings/tokens
   → Find old token
   → Click delete
   ```

---

## 🆘 Troubleshooting

### "Invalid authentication credentials"

```bash
# Problem: Token is wrong or expired
# Solution:
docker logout ghcr.io
# Create new token and login again
docker login ghcr.io
```

### "Repository not found"

```bash
# Problem: Token doesn't have access to repo
# Solution:
# 1. Check token was created with resultrum/odoo-mta access
# 2. Verify token has read:packages permission
# 3. Create new token if necessary
```

### "Token not found"

```bash
# Problem: Forgot where you stored token
# Solution:
# Check ~/.docker/config.json or GitHub Secrets
# Create new token if needed (old one was displayed only once)
```

---

## 📞 Questions?

Refer to:
- **SECURITY_AUTHENTICATION.md** - Why we use deployment tokens
- **STAGING_AZURE_DEPLOYMENT.md** - How to use token for deployments
- **DEPLOYMENT.md** - General deployment guide

---

## 🎓 What You've Done

✅ Created organization-level deployment token (not personal!)
✅ Limited to single repository (odoo-mta)
✅ Minimal permissions (read:packages only)
✅ 90-day expiration (automatic rotation)
✅ Stored securely (GitHub Secrets or config.json)

**Result:** Safe, auditable, rotatable authentication for Docker deployments 🚀

---

**Last Updated:** 2025-11-17
**Version:** 1.0
**Audience:** GitHub Organization Admins, DevOps Engineers
