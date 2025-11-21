# Guide: Odoo Enterprise Setup

Ce document explique comment utiliser Odoo Enterprise dans le template et les projets dérivés.

---

## 🏗️ Architecture Enterprise

### Image Enterprise hebdomadaire

Une **image Docker Enterprise** est buildée automatiquement chaque semaine (lundi à 00:00 UTC):

```
GitHub Actions Workflow: .github/workflows/build-enterprise-image.yml
├─ Clone: resultrum/enterprise
├─ Build: Docker image
├─ Push to GHCR: ghcr.io/resultrum/odoo:18.0-enterprise-*
└─ Tags:
   ├─ 18.0-enterprise-latest (latest build)
   ├─ 18.0-enterprise-week-47 (week number)
   ├─ 18.0-enterprise-2025-W47 (year-week)
   └─ 18.0-enterprise-2025-01-15 (date)
```

### Avantages

✅ **Cohérence**: Même image en local et en CI/CD
✅ **Automatisation**: Pas de build manuel
✅ **Versioning**: Tags par semaine et date
✅ **Sécurité**: Image publiée privément sur GHCR

---

## 🚀 Utilisation Locale

### Prérequis

1. **GitHub Token** avec accès à GHCR
   ```bash
   # Générer token:
   # Settings → Developer settings → Personal access tokens → Tokens (classic)
   # Scopes: read:packages
   ```

2. **Docker Login** (première fois uniquement)
   ```bash
   docker login ghcr.io -u <github-username> -p <github-token>
   ```

### Lancer avec Community (default)

```bash
# Par défaut, utilise FROM odoo:18.0 (Community)
cp .env.example .env
docker-compose up -d

# http://localhost:8069
# User: admin@odoo.com / Password: admin
```

### Lancer avec Enterprise

```bash
# Utilise Dockerfile.enterprise → ghcr.io/resultrum/odoo:18.0-enterprise-latest
docker-compose -f docker-compose.yml -f docker-compose.enterprise.yml up -d

# http://localhost:8069
# User: admin@odoo.com / Password: admin
```

### Vérifier l'édition en cours

```bash
# Dans les logs Docker
docker-compose logs web | grep -i "odoo.*enterprise\|community"

# Ou via l'UI
# http://localhost:8069 → Settings → About → Edition
```

---

## 🔄 Workflow GitHub Actions

### Quand s'exécute le build?

- **Schedule**: Chaque lundi à 00:00 UTC
- **Manual**: Via `workflow_dispatch` sur GitHub

### Qu'est-ce qui est buildé?

1. Clone `resultrum/enterprise` (sources Odoo Enterprise)
2. Build image Docker
3. Calcule les tags (week, date, version)
4. Push à `ghcr.io/resultrum/odoo` avec tous les tags

### Arrêter le workflow

Si tu veux arrêter le build automatique:

```bash
# Editer .github/workflows/build-enterprise-image.yml
# Commenter ou supprimer la section 'schedule:'
```

---

## 🐳 Docker Compose Configuration

### Structure des fichiers

```
.
├── docker-compose.yml           # Config de base
├── docker-compose.dev.yml       # Overrides dev (optionnel)
├── docker-compose.enterprise.yml # Override pour Enterprise
├── Dockerfile                   # Community (default)
├── Dockerfile.enterprise        # Enterprise (optionnel)
├── Dockerfile.prod             # Production
└── .env
```

### Utiliser Enterprise temporairement

```bash
# Lancer avec Enterprise
docker-compose -f docker-compose.yml -f docker-compose.enterprise.yml up -d

# Arrêter
docker-compose -f docker-compose.yml -f docker-compose.enterprise.yml down

# Retour à Community
docker-compose up -d
```

---

## 🔐 Authentification GHCR

### Première fois

```bash
# Générer un token GitHub (read:packages)
TOKEN=ghp_xxxxxxxxxxxx

# Se connecter à GHCR
docker login ghcr.io -u <username> -p $TOKEN

# Vérifier
cat ~/.docker/config.json | grep ghcr
```

### En CI/CD (GitHub Actions)

Le workflow utilise `secrets.GITHUB_TOKEN` automatiquement. Pas de configuration manuelle.

### Problèmes courants

```bash
# Error: pull access denied, repository does not exist
# → Token n'a pas les bonnes permissions (read:packages)

# Error: authentication required
# → Pas connecté: docker login ghcr.io -u ... -p ...

# Error: network timeout
# → Réseau/proxy bloqué GHCR
```

---

## 📊 Tags et Versions

### Chaque semaine, plusieurs tags pointent vers la même image:

```
ghcr.io/resultrum/odoo:18.0-enterprise-latest      # Toujours le plus récent
ghcr.io/resultrum/odoo:18.0-enterprise-week-47     # Semaine 47
ghcr.io/resultrum/odoo:18.0-enterprise-2025-W47    # Année-semaine
ghcr.io/resultrum/odoo:18.0-enterprise-2025-01-15  # Date
```

### Utiliser une version spécifique

```dockerfile
# Dockerfile.enterprise - Verrouiller une semaine
FROM ghcr.io/resultrum/odoo:18.0-enterprise-week-47
```

---

## 🔍 Troubleshooting

### L'image Enterprise ne télécharge pas

```bash
# 1. Vérifier le token
docker login ghcr.io -u <username> -p <token>

# 2. Vérifier la connexion
docker pull ghcr.io/resultrum/odoo:18.0-enterprise-latest

# 3. Vérifier les logs du build
# GitHub → Actions → build-enterprise-image → détails
```

### Utiliser Community comme fallback

```bash
# Si Enterprise ne marche pas, utiliser Community
docker-compose up -d  # Utilise Dockerfile (Community)
```

### Vérifier l'édition

```bash
# Logs
docker-compose logs web | head -30

# UI
# http://localhost:8069 → Settings → About → "Edition"
```

---

## 📝 Mise à jour de la documentation

Quand le workflow build Enterprise:

1. **Image pushée** avec tous les tags
2. **Dockerfile.enterprise** pointe toujours au `-latest`
3. **Version peut être pinée** en éditant le Dockerfile

---

## 🎯 Résumé

```bash
# Community (default)
docker-compose up -d

# Enterprise (build hebdo automatique)
docker-compose -f docker-compose.yml -f docker-compose.enterprise.yml up -d

# Vérifier édition
docker-compose logs web | grep -i "odoo.*enterprise\|community"
```

**L'image Enterprise est buildée automatiquement chaque lundi. Tu dois juste utiliser le docker-compose override pour la tirer.**

---

**Questions?** Voir `.github/workflows/build-enterprise-image.yml` ou créer une issue.
