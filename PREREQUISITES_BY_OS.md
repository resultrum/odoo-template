# 🖥️ Prerequisites by Operating System

Complete guide for setting up odoo-mta on different operating systems.

**TL;DR:** ✅ **No Linux VM needed!** Docker handles everything.

---

## ✅ Quick Summary

| OS | VM Needed? | Native Docker? | Total Setup |
|----|-----------|----------------|------------|
| **macOS (Intel)** | ❌ No | Docker Desktop | 30 min |
| **macOS (Apple Silicon)** | ❌ No | Docker Desktop (native) | 30 min |
| **Windows 11 Pro/Enterprise** | ❌ No | Docker Desktop + WSL2 | 45 min |
| **Windows 11 Home** | ⚠️ Maybe | Docker Desktop + WSL2 | 1 hour |
| **Windows 10** | ⚠️ Maybe | Docker Desktop + WSL2 | 1 hour |
| **Ubuntu 20.04+** | ❌ No | Docker Engine | 20 min |
| **Other Linux** | ❌ No | Docker | 20 min |

**Key Point:** Docker replaces the need for a Linux VM!

---

## 🍎 macOS Setup

### For Intel Macs

**What you need:**
1. macOS 11 (Big Sur) or later
2. Docker Desktop for Mac (Intel)
3. Git
4. Terminal (built-in)

**Installation:**

```bash
# 1. Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Git
brew install git

# 3. Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop
# Or via Homebrew:
brew install --cask docker

# 4. Verify installation
docker --version
docker-compose --version
git --version
```

**First-time Docker setup:**

1. Open Docker Desktop application
2. Go to Preferences → Resources
3. Allocate at least 4GB RAM to Docker
4. Apply & Restart
5. Wait for Docker engine to start (~1-2 minutes)

**Verify Docker is running:**
```bash
docker ps
# Should show: CONTAINER ID  IMAGE  COMMAND  CREATED  STATUS  PORTS  NAMES
# (empty list is OK)
```

### For Apple Silicon Macs (M1/M2/M3)

**Same as Intel, but:**
- Docker Desktop automatically detects Apple Silicon
- Uses native ARM64 support (better performance)
- Some Odoo versions may need `platform: linux/amd64` in docker-compose

**Check your Mac:**
```bash
# See your chip
uname -m

# Output:
# arm64 = Apple Silicon
# x86_64 = Intel
```

**Docker Desktop location:**
- Download: https://www.docker.com/products/docker-desktop
- Choose: "Apple Silicon" version

---

## 🪟 Windows Setup

### For Windows 11 Pro/Enterprise

**What you need:**
1. Windows 11 Pro or Enterprise Edition
2. Docker Desktop for Windows
3. WSL2 (Windows Subsystem for Linux 2)
4. Git for Windows

**Installation:**

```powershell
# 1. Open PowerShell as Administrator

# 2. Install WSL2
wsl --install
# This installs WSL2 and Ubuntu 22.04 LTS by default
# Restart your computer when prompted

# 3. Verify WSL2 installation
wsl --list --verbose
# Should show Ubuntu with version 2

# 4. Install Git
# Download from: https://git-scm.com/download/win
# Or use winget:
winget install Git.Git

# 5. Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop
# During installation, ensure "Install required Windows components for WSL 2" is checked

# 6. Verify installation
docker --version
docker-compose --version
git --version
```

**First-time setup:**

1. Start Docker Desktop
2. Settings → Resources → WSL Integration
3. Enable "Ubuntu" or your WSL distribution
4. Apply & Restart

**Verify Docker works:**
```powershell
docker ps
# Should work without errors
```

### For Windows 11 Home

⚠️ **Important:** Windows 11 Home has limited Hyper-V support.

**Option A: Enable Hyper-V (if CPU supports it)**

```powershell
# Run as Administrator
dism.exe /Online /Enable-Feature /FeatureName:HypervisorPlatform /All /NoRestart
dism.exe /Online /Enable-Feature /FeatureName:VirtualMachinePlatform /All /NoRestart
# Restart computer
```

Then follow Windows 11 Pro instructions above.

**Option B: Use Docker Desktop with WSL2 Backend**

Windows 11 Home can use Docker Desktop if:
- WSL2 is installed
- CPU supports virtualization
- Hyper-V is enabled

**Option C: Alternative - Use VirtualBox or VMware**

If neither option works:
1. Install VirtualBox or VMware
2. Create an Ubuntu 22.04 VM
3. Follow Linux instructions in that VM

**Recommended:** Try Option A first (usually works), then Option B.

### For Windows 10

⚠️ **More difficult.** Windows 10 has limitations.

**Option A: Windows 10 Pro/Enterprise with latest updates**

```powershell
# As Administrator
dism.exe /Online /Enable-Feature /FeatureName:VirtualMachinePlatform /All /NoRestart
# Restart computer
wsl --install -d Ubuntu-22.04
```

Then follow Windows 11 Pro instructions.

**Option B: Use Virtual Machine**

Recommended for Windows 10:
1. Download VirtualBox (free): https://www.virtualbox.org/
2. Download Ubuntu 22.04 ISO
3. Create VM with 4GB RAM, 20GB disk
4. Follow Linux instructions in the VM

---

## 🐧 Linux Setup

### Ubuntu 20.04 / 22.04 / 24.04

**Easiest setup!** Docker is built-in.

**Installation:**

```bash
# 1. Update package list
sudo apt update

# 2. Install Docker
sudo apt install docker.io docker-compose git -y

# 3. Add your user to docker group (avoid sudo)
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect

# 4. Verify installation
docker --version
docker-compose --version
git --version

# 5. Test Docker (should work without sudo)
docker ps
```

**If docker ps gives permission error:**

```bash
# Logout and back in first
# If still not working:
sudo systemctl start docker
sudo systemctl enable docker  # Start on boot
```

### Other Linux Distributions

**Fedora/RHEL:**
```bash
sudo dnf install docker docker-compose git -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

**Arch Linux:**
```bash
sudo pacman -S docker docker-compose git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

**Debian:**
```bash
sudo apt update
sudo apt install docker.io docker-compose git -y
sudo systemctl start docker
sudo usermod -aG docker $USER
```

---

## 📋 Common Prerequisites Table

| Requirement | macOS | Windows | Linux |
|------------|-------|---------|-------|
| **Docker** | Docker Desktop | Docker Desktop + WSL2 | Docker Engine |
| **Git** | Homebrew | Git for Windows | apt/dnf/pacman |
| **Virtual Machine** | ❌ Not needed | ❌ Not needed* | ❌ Not needed |
| **Hypervisor** | Native | Hyper-V (automatic) | KVM (optional) |
| **RAM** | 4GB+ | 8GB+ | 4GB+ |
| **Disk** | 20GB free | 20GB free | 20GB free |

*\*Windows only: WSL2 provides the Linux layer inside Windows*

---

## 🚀 Quick Start by OS

### macOS
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install git
brew install --cask docker

# Start Docker and project
open /Applications/Docker.app
# Wait 1 minute for Docker to start
cd odoo-mta
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Windows 11 Pro/Enterprise
```powershell
# Install WSL2
wsl --install

# Install Git and Docker
# Download Docker Desktop from: https://www.docker.com/products/docker-desktop
# Choose "Windows" version, run installer

# Open PowerShell/Terminal and:
cd odoo-mta
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Ubuntu/Linux
```bash
sudo apt update
sudo apt install docker.io docker-compose git -y
sudo usermod -aG docker $USER

# Log out and back in, then:
cd odoo-mta
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

---

## ⚙️ Configuration by OS

### macOS: Docker Resources

**Minimum:**
- Memory: 4GB
- Disk: 20GB
- CPUs: 2

**Recommended:**
- Memory: 6GB
- Disk: 50GB
- CPUs: 4

**How to set:**
1. Docker Desktop → Preferences
2. Resources tab
3. Adjust Memory, CPUs, Disk
4. Apply & Restart

### Windows: WSL2 Memory

**By default:** WSL2 uses up to 50% of your system RAM

**If running slow, limit it:**

Create `%UserProfile%\.wslconfig`:
```ini
[wsl2]
memory=4GB
processors=4
```

Then restart WSL:
```powershell
wsl --shutdown
# Next docker command will restart it
```

### Linux: Storage Driver

Check which storage driver you're using:
```bash
docker info | grep "Storage Driver"

# If using overlay2 (good): OK
# If using aufs (old): Update to overlay2
```

---

## 🔧 Troubleshooting by OS

### macOS Issues

**Docker daemon won't start:**
```bash
# Restart Docker
killall Docker
open /Applications/Docker.app
```

**Permission denied errors:**
```bash
# Check Docker socket
ls -la /var/run/docker.sock

# Reset Docker
Docker.app > Troubleshoot > Reset
```

### Windows Issues

**WSL2 not working:**
```powershell
# Check WSL status
wsl --list --verbose

# If not version 2, upgrade:
wsl --set-version Ubuntu 2
```

**Hyper-V errors on Windows Home:**
```powershell
# Enable Hyper-V features
dism.exe /Online /Enable-Feature /FeatureName:HypervisorPlatform /All
dism.exe /Online /Enable-Feature /FeatureName:VirtualMachinePlatform /All
# Restart required
```

### Linux Issues

**Docker socket permission denied:**
```bash
# Add current user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

**Docker daemon not running:**
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker  # Auto-start on boot
```

---

## 📊 System Requirements Summary

### Minimum Requirements

| Component | Minimum | Recommended |
|-----------|---------|------------|
| **RAM** | 4GB | 8GB+ |
| **Free Disk** | 20GB | 50GB |
| **CPU** | 2 cores | 4+ cores |
| **OS** | macOS 11+ / Windows 10+ / Ubuntu 20.04+ | Recent version |

### Network Requirements

- Internet connection (for initial setup)
- Docker Hub access (for pulling images)
- GitHub access (for git operations)

---

## ✅ Verification Checklist

After installation, verify everything works:

```bash
# Docker version
docker --version
# Should show: Docker version X.Y.Z

# Docker compose
docker-compose --version
# Should show: Docker Compose version X.Y.Z

# Docker engine
docker ps
# Should show: CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
# (empty list OK)

# Git
git --version
# Should show: git version X.Y.Z

# SSH key (for GitHub)
ssh -T git@github.com
# Should show: Hi [username]! You've successfully authenticated...
```

If all commands work without errors → ✅ Ready to use odoo-mta!

---

## 🎯 NO LINUX VM NEEDED!

### Why?

**Before (old way):**
- Install Linux VM on VirtualBox/VMware
- Install Docker inside Linux VM
- Run Odoo container

**Now (modern way):**
- Docker Desktop handles containerization natively
- WSL2 on Windows provides Linux layer
- No separate VM needed!

**Benefits:**
- ✅ Simpler setup (fewer steps)
- ✅ Better performance (native, not virtualized)
- ✅ Less resource usage (no extra OS)
- ✅ Faster development (file sync faster)

---

## 🚀 Next Steps

1. Choose your OS ⬇️
2. Follow installation steps
3. Verify with checklist
4. Run `DEVELOPER_SETUP_CHECKLIST.md`
5. Start developing! 🎉

---

## 📞 OS-Specific Support

**macOS issues?**
- Check Docker preferences (Resources tab)
- Restart Docker from Applications
- See: DEVELOPER_GUIDE.md#troubleshooting

**Windows issues?**
- Check WSL2 is enabled and running
- Verify Hyper-V is enabled
- See: DEVELOPER_GUIDE.md#troubleshooting

**Linux issues?**
- Check Docker daemon is running
- Verify user is in docker group
- See: DEVELOPER_GUIDE.md#troubleshooting

---

**Bottom line:** ✅ **You do NOT need a Linux VM. Docker handles everything!**

Choose your OS above and follow the instructions. Your development environment will be ready in 30 minutes!

🎉 Happy coding!
