# 🚀 Commencer par Système d'Exploitation

Guide complet pour **macOS**, **Windows** et **Linux**.

**Bonne nouvelle:** ✅ **Pas besoin de VM Linux!** Docker gère tout.

---

## ⚡ Choix Rapide

Quel est votre système?

- **[👇 macOS](#-macos)** - (Intel ou Apple Silicon)
- **[👇 Windows](#-windows)** - (11 Pro, Home, ou 10)
- **[👇 Linux](#-linux)** - (Ubuntu, Fedora, Debian, etc.)

---

## 🍎 macOS

### Vérification Préalable

```bash
# Quelle version macOS?
uname -m
# Résultat:
# arm64 = Apple Silicon (M1/M2/M3)
# x86_64 = Intel

# Quelle version du système?
sw_vers
```

### Installation (30 minutes)

#### Étape 1: Installer Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Vérifier
brew --version
```

#### Étape 2: Installer Git

```bash
brew install git

# Vérifier
git --version
```

#### Étape 3: Installer Docker Desktop

```bash
# Option A: Via Homebrew
brew install --cask docker

# Option B: Télécharger directement
# Aller sur: https://www.docker.com/products/docker-desktop
# Choisir: "Mac with Intel Chip" ou "Mac with Apple Silicon"
```

#### Étape 4: Démarrer Docker

```bash
# Lancer Docker Desktop
open /Applications/Docker.app

# Attendre 1-2 minutes...

# Vérifier dans le menu en haut à droite:
# L'icône Docker doit montrer "Docker Desktop is running"
```

#### Étape 5: Configurer Docker

```bash
# Ouvrir Docker Desktop
# Menu en haut à gauche → Preferences (ou Settings)
# Aller à: Resources
# Allouer au minimum:
#   - Memory: 4GB
#   - CPUs: 2
# Cliquer "Apply & Restart"
```

#### Étape 6: Vérifier l'Installation

```bash
# Ouvrir Terminal
docker --version
# Doit afficher: Docker version X.Y.Z

docker-compose --version
# Doit afficher: Docker Compose version X.Y.Z

docker ps
# Doit afficher le header (pas d'erreur)

git --version
# Doit afficher: git version X.Y.Z
```

✅ **Si tout fonctionne, vous êtes prêt!** Allez à [Démarrer le Projet](#démarrer-le-projet)

---

## 🪟 Windows

### Vérification Préalable

```powershell
# Ouvrir PowerShell comme administrateur
# (Click droit → Run as administrator)

# Quelle version Windows?
[System.Environment]::OSVersion.VersionString

# Résultat:
# "Microsoft Windows 11..." = Windows 11
# "Microsoft Windows 10..." = Windows 10

# Vérifier Hyper-V (seulement Pro/Enterprise)
systeminfo | findstr /I "Hyper-V"
# Résultat "Oui" = OK, "Non" = peut être activé
```

### Installation Windows 11 Pro/Enterprise (45 minutes)

#### Étape 1: Installer WSL2

```powershell
# Ouvrir PowerShell comme administrateur

# Installer WSL2
wsl --install

# Cela installe:
# - WSL2
# - Ubuntu 22.04
# Redémarrage requis après installation
```

#### Étape 2: Redémarrer

```powershell
# Votre ordinateur va redémarrer
# Attendez le redémarrage complet
```

#### Étape 3: Installer Git

```powershell
# Télécharger depuis: https://git-scm.com/download/win
# Ou avec winget:
winget install Git.Git

# Vérifier
git --version
```

#### Étape 4: Installer Docker Desktop

```powershell
# Télécharger: https://www.docker.com/products/docker-desktop
# Choisir: "Windows" (pas Mac ni Linux)
# Lancer l'installateur
# Important: Cocher "Install required Windows components for WSL 2"
# Redémarrage requis après installation
```

#### Étape 5: Configurer Docker

```powershell
# Ouvrir Docker Desktop
# Settings (gear icon en haut à droite)
# Aller à: Resources → WSL Integration
# Activer votre distribution Ubuntu
# Cliquer "Apply & Restart"
```

#### Étape 6: Vérifier l'Installation

```powershell
# Ouvrir PowerShell (pas en admin cette fois)

docker --version
# Doit afficher: Docker version X.Y.Z

docker-compose --version
# Doit afficher: Docker Compose version X.Y.Z

docker ps
# Doit afficher le header (pas d'erreur)

git --version
# Doit afficher: git version X.Y.Z
```

✅ **Si tout fonctionne, vous êtes prêt!** Allez à [Démarrer le Projet](#démarrer-le-projet)

### Installation Windows 11 Home (1 heure)

⚠️ **Plus complexe.** Windows 11 Home a des limitations.

**Essayer d'abord ces étapes:** (même que Pro, mais peut ne pas fonctionner)

```powershell
# Ouvrir PowerShell comme administrateur

# Essayer d'activer Hyper-V
dism.exe /Online /Enable-Feature /FeatureName:HypervisorPlatform /All /NoRestart
dism.exe /Online /Enable-Feature /FeatureName:VirtualMachinePlatform /All /NoRestart

# Redémarrer
Restart-Computer

# Puis installer WSL2
wsl --install

# Et Docker Desktop comme ci-dessus
```

**Si cela ne fonctionne pas:** Voir [Troubleshooting Windows Home](#windows-home-troubleshooting)

### Installation Windows 10 (1-2 heures)

⚠️ **Très complexe.** Deux options:

**Option A: Essayer WSL2** (peut ne pas fonctionner)

Suivez les étapes Windows 11 Pro ci-dessus. Si cela ne marche pas, utilisez Option B.

**Option B: VirtualBox (sûr et rapide)**

```
1. Télécharger VirtualBox: https://www.virtualbox.org/
2. Télécharger Ubuntu 22.04 ISO
3. Créer une VM Ubuntu:
   - RAM: 4GB minimum
   - Disk: 20GB
4. Installer Ubuntu dans la VM
5. Suivre les étapes Linux ci-dessous dans la VM
```

---

## 🐧 Linux

### Installation Ubuntu/Debian (20 minutes)

#### Étape 1: Mettre à Jour

```bash
sudo apt update
sudo apt upgrade -y
```

#### Étape 2: Installer Docker & Git

```bash
sudo apt install docker.io docker-compose git -y

# Vérifier
docker --version
docker-compose --version
git --version
```

#### Étape 3: Démarrer Docker

```bash
sudo systemctl start docker
sudo systemctl enable docker  # Démarrage automatique au boot
```

#### Étape 4: Autoriser l'Utilisateur Courant

```bash
sudo usermod -aG docker $USER

# Déconnexion/reconnexion requise
# Ou:
exec newgrp docker  # Pour appliquer immédiatement
```

#### Étape 5: Vérifier l'Installation

```bash
# Testez SANS sudo
docker ps
# Doit afficher le header (pas d'erreur)

docker-compose --version
git --version
```

✅ **Si tout fonctionne, vous êtes prêt!** Allez à [Démarrer le Projet](#démarrer-le-projet)

### Installation Autres Distributions Linux

**Fedora/RHEL:**
```bash
sudo dnf install docker docker-compose git -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
# Déconnexion/reconnexion requise
```

**Arch Linux:**
```bash
sudo pacman -S docker docker-compose git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
# Déconnexion/reconnexion requise
```

---

## 🚀 Démarrer le Projet

Une fois Docker, Git et votre OS configurés:

### Étape 1: Cloner le Projet

```bash
# macOS/Linux
git clone git@github.com:resultrum/odoo-mta.git
cd odoo-mta

# Windows (PowerShell)
git clone git@github.com:resultrum/odoo-mta.git
cd odoo-mta
```

### Étape 2: Configuration

```bash
# Copier le fichier d'environnement
cp .env.example .env

# Générer les symlinks OCA
./scripts/create-oca-symlinks.sh
```

### Étape 3: Démarrer Docker

```bash
# Lancer les conteneurs (mode développement)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Attendre 20 secondes...
sleep 20

# Vérifier que les conteneurs sont en cours d'exécution
docker-compose ps
# Les deux "odoo-mta-web" et "odoo-mta-db" doivent montrer "Up"
```

### Étape 4: Accéder à Odoo

```
Ouvrir dans le navigateur: http://localhost:8069

Database: mta-dev
Username: admin
Password: admin123

Click "Log In"
```

✅ **Succès!** Vous pouvez voir les modules Helpdesk!

### Étape 5: Vérifier les Modules

```
1. Cliquer sur "Apps" en haut
2. Chercher "helpdesk"
3. Vous devriez voir ~22 modules
```

✅ **Tout fonctionne!**

---

## 🐛 Troubleshooting

### macOS

**Docker ne démarre pas:**
```bash
# Tuer et relancer
killall Docker
open /Applications/Docker.app
# Attendre 2-3 minutes
```

**Erreur "Cannot connect to Docker daemon":**
```bash
# Vérifier que Docker Desktop est ouvert
# Vérifier le menu en haut à droite
# L'icône Docker doit afficher "Docker Desktop is running"
```

### Windows 11 Home

**WSL2 ne fonctionne pas:**

```powershell
# Vérifier que Hyper-V est activé
systeminfo | findstr /I "Hyper-V"

# Si "Non", activer:
dism.exe /Online /Enable-Feature /FeatureName:HypervisorPlatform /All /NoRestart
dism.exe /Online /Enable-Feature /FeatureName:VirtualMachinePlatform /All /NoRestart
Restart-Computer

# Puis:
wsl --install
```

**Si toujours une erreur:** Utiliser VirtualBox + Ubuntu (Option B ci-dessus)

### Linux

**Erreur "permission denied":**

```bash
# L'utilisateur n'est pas dans le groupe docker
sudo usermod -aG docker $USER

# Déconnexion complète requise (pas juste exec newgrp)
# Ou:
exec newgrp docker
```

**Docker daemon ne répond pas:**

```bash
# Démarrer le daemon
sudo systemctl start docker

# Vérifier le statut
sudo systemctl status docker

# Logs si besoin
sudo journalctl -u docker
```

---

## ✅ Checklist Finale

Avant de commencer à coder:

- [ ] Docker installé et démarré
- [ ] Git installé et configuré
- [ ] Clonage du projet réussi
- [ ] Docker conteneurs lancés (`docker-compose ps` montre 2 "Up")
- [ ] Accès à Odoo (http://localhost:8069)
- [ ] Modules Helpdesk visibles dans Apps
- [ ] Vous avez lu [QUICK_START.md](./QUICK_START.md)

---

## 📚 Prochaines Étapes

1. **Lire QUICK_START.md** (5 min)
2. **Suivre DEVELOPER_SETUP_CHECKLIST.md** (20 min)
3. **Lire DEVELOPER_GUIDE.md** (30 min)
4. **Commencer à coder!** 🎉

---

## 📞 Aide

**Problème non résolu?**

1. Voir [PREREQUISITES_BY_OS.md](./PREREQUISITES_BY_OS.md) pour détails
2. Voir [DEVELOPER_GUIDE.md#troubleshooting](./DEVELOPER_GUIDE.md#troubleshooting)
3. Consulter [DOCUMENTATION_INDEX.md](./DOCUMENTATION_INDEX.md) pour navigation
4. Demander à votre tech lead

---

**Bon développement!** 🚀

Vous n'avez besoin d'aucune VM Linux. Docker gère tout!
