# 🚀 Deployment Guide - Odoo MTA

Ce guide explique comment déployer les images Docker depuis GHCR (GitHub Container Registry) en STAGING et PRODUCTION.

## 📋 Table des matières

1. [Architecture](#architecture)
2. [Prérequis](#prérequis)
3. [Déploiement STAGING](#déploiement-staging)
4. [Déploiement PRODUCTION](#déploiement-production)
5. [Gestion des données](#gestion-des-données)
6. [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture

### Images Docker

Les images sont construites automatiquement via GitHub Actions et stockées sur **GHCR (GitHub Container Registry)**.

**Flux de tagging :**

```
Branch: master-iteration*           Branch: main
         ↓                                  ↓
    Push commit              Git tag v1.0.0 ou push
         ↓                                  ↓
  GHCR:master-iteration1.0       GHCR:v1.0.0 + latest
         ↓                                  ↓
   STAGING Environment          PRODUCTION Environment
```

### Données persistantes

**L'image Docker est STATELESS.** Les données sont séparées :

| Composant | Emplacement | Persistance |
|-----------|-------------|-------------|
| **Odoo Application** | Image Docker | Versionnée (ghcr.io/...) |
| **Database (PostgreSQL)** | Volume nommé | Persiste entre redémarrages/updates |
| **User Files** | Volume nommé | Persiste entre redémarrages/updates |
| **Secrets/Config** | Fichier `.env` | Géré par l'équipe ops |

---

## 📦 Prérequis

### Sur la machine de déploiement

```bash
# 1. Docker & Docker Compose
docker --version      # >= 24.0
docker-compose --version  # >= 2.20

# 2. Accès à GitHub (pour tirer les images privées)
# Créer un Personal Access Token (PAT) sur GitHub:
# - GitHub Settings → Developer Settings → Personal Access Tokens
# - Permissions: read:packages (lire images de container)

# 3. Vous identifier auprès de GHCR
docker login ghcr.io
# Username: <votre-username-github>
# Password: <votre-personal-access-token>

# 4. Vérifier l'accès aux images
docker pull ghcr.io/resultrum/odoo-mta:latest
```

### Variables d'environnement

Créer un fichier `.env` à la racine du projet de déploiement :

```bash
# Database (DOIT être défini, pas de valeur par défaut)
DB_PASSWORD=<password-super-securise>

# Odoo Admin (DOIT être défini)
ODOO_ADMIN_PASSWORD=<admin-password-different>

# Backup path (optionnel, défaut: /backups/odoo-mta/prod)
BACKUP_PATH=/backups/odoo-mta/prod
```

⚠️ **JAMAIS commiter `.env` dans Git !**

---

## 🧪 Déploiement STAGING

### Prérequis STAGING

```bash
# Répertoire de déploiement
mkdir -p /opt/odoo-mta-staging
cd /opt/odoo-mta-staging

# Cloner/récupérer les fichiers docker-compose
cp docker-compose.yml .
cp docker-compose.prod.yml .  # Réutilisé pour staging avec vars différentes
cp .env.staging .env
```

### Fichier `.env.staging`

```bash
# STAGING Configuration
DB_PASSWORD=staging-password-1234
ODOO_ADMIN_PASSWORD=staging-admin-pass
BACKUP_PATH=/backups/odoo-mta/staging

# Optionnel: Configuration adaptée au staging
# WORKERS=4
# LOG_LEVEL=debug
```

### Étapes de déploiement STAGING

```bash
# 1. Se positionner
cd /opt/odoo-mta-staging

# 2. Charger les variables d'environnement
export $(cat .env | xargs)

# 3. Récupérer l'image STAGING (depuis GHCR)
# Remplacer "master-iteration1.0" par votre branche staging
docker pull ghcr.io/resultrum/odoo-mta:master-iteration1.0

# 4. Démarrer les containers
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 5. Vérifier l'état
docker-compose ps

# 6. Attendre le démarrage (~60 secondes)
sleep 60

# 7. Vérifier la santé
docker-compose exec web curl -f http://localhost:8069/web || echo "Not ready yet"

# 8. Voir les logs
docker-compose logs -f web
```

### Vérification STAGING

```bash
# Accéder à Odoo
# http://<staging-vm-ip>:8069

# Vérifier les logs
docker-compose logs web | grep -i "error\|warning"

# Vérifier la DB
docker-compose exec postgres psql -U odoo -d mta-staging -c "SELECT * FROM ir_module_module WHERE name = 'mta_base';"
```

---

## 🚀 Déploiement PRODUCTION

### ⚠️ AVERTISSEMENT PRODUCTION

```
🚨 PRODUCTION DEPLOYMENT CHECKLIST:

✅ Avez-vous testé en STAGING ?
✅ Avez-vous des backups de la DB ?
✅ Avez-vous testé le `.env` ?
✅ Avez-vous reviewé les changements depuis la dernière release ?
✅ Avez-vous un plan de rollback ?

Ne continuez que si tous les points sont cochés ✅
```

### Prérequis PRODUCTION

```bash
# Répertoire de déploiement
mkdir -p /opt/odoo-mta-prod
cd /opt/odoo-mta-prod

# Fichiers de config
cp docker-compose.yml .
cp docker-compose.prod.yml .
cp .env.prod .env
```

### Fichier `.env.prod`

```bash
# PRODUCTION Configuration (SÉCURISÉ!)
DB_PASSWORD=<password-super-super-securise>
ODOO_ADMIN_PASSWORD=<admin-password-different>
BACKUP_PATH=/backups/odoo-mta/prod

# Configuration adaptée à la production
# (actuellement dans docker-compose.prod.yml, peut être overridé ici)
```

### Étapes de déploiement PRODUCTION

```bash
# 1. Se positionner
cd /opt/odoo-mta-prod

# 2. Charger les variables d'environnement
export $(cat .env | xargs)

# 3. Créer un backup PRÉ-DEPLOYMENT
echo "📦 Creating pre-deployment backup..."
BACKUP_DIR="/backups/odoo-mta/prod"
mkdir -p $BACKUP_DIR
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Backup DB
docker-compose exec -T postgres pg_dump -U odoo -d mta-prod -F custom \
  > "$BACKUP_DIR/database_${TIMESTAMP}.dump"
gzip "$BACKUP_DIR/database_${TIMESTAMP}.dump"
echo "  ✅ Database backup: $BACKUP_DIR/database_${TIMESTAMP}.dump.gz"

# Backup Filestore
docker-compose exec -T web tar czf - -C /var/lib/odoo/.local/share/Odoo filestore/ \
  > "$BACKUP_DIR/filestore_${TIMESTAMP}.tar.gz" 2>/dev/null || echo "  ⚠️  Filestore backup skipped"
echo "  ✅ Filestore backup: $BACKUP_DIR/filestore_${TIMESTAMP}.tar.gz"

# 4. Récupérer l'image PRODUCTION
# Remplacer "v1.0.0" par le tag de votre release
echo "🐳 Pulling production image..."
docker pull ghcr.io/resultrum/odoo-mta:v1.0.0

# 5. Arrêter les containers (pas de downtime si config correcte)
echo "🛑 Stopping current containers..."
docker-compose down

# 6. Démarrer avec la nouvelle image
echo "🚀 Starting new containers..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 7. Attendre le démarrage (~90 secondes)
echo "⏳ Waiting for services to be ready..."
sleep 90

# 8. Vérifier la santé
echo "🏥 Performing health checks..."
docker-compose exec web curl -f http://localhost:8069/web > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✅ Health check PASSED"
else
  echo "❌ Health check FAILED - Check logs below"
  docker-compose logs web | tail -50
  exit 1
fi

# 9. Résumé du déploiement
echo ""
echo "✅ DEPLOYMENT SUCCESSFUL"
echo "  - Image: ghcr.io/resultrum/odoo-mta:v1.0.0"
echo "  - Timestamp: $TIMESTAMP"
echo "  - Backup: $BACKUP_DIR"
echo "  - Access: http://localhost:8069"
echo ""
```

### Vérification PRODUCTION

```bash
# Accéder à Odoo
# http://<prod-vm-ip>:8069

# Vérifier les logs
docker-compose logs web | grep -i "error\|critical"

# Vérifier la DB
docker-compose exec postgres psql -U odoo -d mta-prod -c "SELECT COUNT(*) FROM ir_module_module;"

# Voir l'état des containers
docker-compose ps
```

---

## 💾 Gestion des données

### Volumes persistants

**STAGING :**
```bash
# Voir les volumes
docker volume ls | grep staging

# Inspecter un volume
docker volume inspect odoo-mta_postgres-prod-data
```

**PRODUCTION :**
```bash
# Voir les volumes
docker volume ls | grep prod

# Sauvegarder un volume
docker run --rm -v odoo-mta_postgres-prod-data:/data -v /backup:/backup \
  alpine tar czf /backup/postgres-prod-$(date +%Y%m%d).tar.gz /data
```

### Backups

**Backup quotidien recommandé :**

```bash
#!/bin/bash
# /opt/odoo-mta-prod/backup.sh

export $(cat .env | xargs)
BACKUP_DIR="/backups/odoo-mta/prod"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

mkdir -p $BACKUP_DIR

# Database backup
docker-compose exec -T postgres pg_dump -U odoo -d mta-prod -F custom \
  | gzip > "$BACKUP_DIR/database_${TIMESTAMP}.dump.gz"

# Retention: keep last 7 days
find $BACKUP_DIR -name "database_*.dump.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/database_${TIMESTAMP}.dump.gz"
```

**Ajouter au crontab :**
```bash
# Backup tous les jours à 2h du matin
0 2 * * * cd /opt/odoo-mta-prod && bash backup.sh >> /var/log/odoo-mta-backup.log 2>&1
```

### Restauration d'un backup

```bash
# Restaurer une base de données
export $(cat .env | xargs)
BACKUP_FILE="/backups/odoo-mta/prod/database_2024-11-17.dump.gz"

# 1. Arrêter les containers
docker-compose down

# 2. Créer une nouvelle base
docker-compose up -d postgres
sleep 30

# 3. Restaurer
zcat $BACKUP_FILE | docker-compose exec -T postgres pg_restore -U odoo -d mta-prod -F custom

# 4. Redémarrer tout
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

echo "✅ Database restored from $BACKUP_FILE"
```

---

## 🔄 Mise à jour sans downtime

### Procédure

```bash
cd /opt/odoo-mta-prod
export $(cat .env | xargs)

# 1. Récupérer la nouvelle image
docker pull ghcr.io/resultrum/odoo-mta:v1.0.1

# 2. Redémarrer avec la nouvelle image
#    Docker Compose arrête les anciens containers et démarre les nouveaux
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 3. Vérifier
docker-compose ps
docker-compose logs web | tail -20
```

**Downtime approximatif :** 30-60 secondes (dépend de la DB et du volume de données)

---

## 🐛 Troubleshooting

### L'image ne se pull pas

```bash
# Erreur: "unauthorized: authentication required"

# Solution:
docker login ghcr.io
# Username: <votre-username>
# Password: <votre-personal-access-token>

# Réessayer
docker pull ghcr.io/resultrum/odoo-mta:v1.0.0
```

### Les containers ne démarrent pas

```bash
# Vérifier les logs
docker-compose logs web

# Problèmes courants:
# - ".env" mal configuré (DB_PASSWORD manquant)
# - PostgreSQL ne démarre pas
# - Port 8069 déjà utilisé

# Solutions:
docker-compose down
rm -v volumes  # ⚠️ Attention: supprime les données!
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### La base de données ne démarre pas

```bash
# Vérifier PostgreSQL
docker-compose exec postgres pg_isready

# Voir les logs PostgreSQL
docker-compose logs postgres

# Problèmes courants:
# - Volume corrompu
# - Permission sur /var/lib/postgresql/data

# Solution: réinitialiser (⚠️ perte de données)
docker volume rm odoo-mta_postgres-prod-data
docker-compose up -d
```

### Odoo est lent

```bash
# Vérifier les ressources
docker stats

# Vérifier les logs Odoo
docker-compose logs web | grep -i "warning\|error"

# Vérifier la DB
docker-compose exec postgres psql -U odoo -d mta-prod -c "SELECT COUNT(*) FROM ir_ui_view;"

# Si beaucoup de données:
# - Augmenter WORKERS dans docker-compose.prod.yml
# - Augmenter memory/CPU allocation
```

### Rollback d'une déploiement failed

```bash
# 1. Récupérer le tag de la version précédente
# (exemple: v1.0.0 au lieu de v1.0.1 qui a failed)

# 2. Restaurer l'image précédente
docker pull ghcr.io/resultrum/odoo-mta:v1.0.0
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 3. Si nécessaire, restaurer la DB à partir d'un backup
# (voir section Restauration d'un backup ci-dessus)

echo "✅ Rollback to v1.0.0 completed"
```

---

## 📞 Support

Pour toute question ou problème :

1. Vérifier les logs : `docker-compose logs -f`
2. Vérifier la configuration `.env`
3. Consulter le GUIDE.md du projet pour l'architecture globale
4. Vérifier le session-log.md pour l'historique des déploiements

---

**Dernière mise à jour :** 2025-11-17
**Version :** 1.0
**Responsable :** Équipe DevOps
