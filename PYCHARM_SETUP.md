# Configuration PyCharm - Odoo Template

## 📌 Vue d'ensemble

Ce guide couvre deux scénarios:

1. **Mode Développement** (par défaut): Construire et tester vos modules custom
2. **Mode Debug Production**: Restaurer une base de données production et reproduire des bugs localement

---

## 🚀 Mode Développement (Développement de Modules Custom)

### 1️⃣ Configuration Initiale

Après avoir créé votre projet depuis le template:

```bash
# 1. Aller dans le répertoire du projet
cd odoo-<project>

# 2. Lancer les services Docker
docker-compose up -d

# 3. Ouvrir le projet dans PyCharm
open -a PyCharm .
```

### 2️⃣ Configurer l'Interpréteur Python (Docker)

**Menu**: `PyCharm → Settings → Project → Python Interpreter`

**Étapes**:

1. Cliquer sur l'engrenage ⚙️ en haut à droite
2. Sélectionner **"Add..."**
3. Choisir **"Docker Compose"**
4. Remplir le formulaire:
   - **Docker Compose file**: Sélectionner le `docker-compose.yml` de votre projet
   - **Service**: `web`
   - **Python interpreter path**: (Laisser vide, PyCharm le détectera)
5. Cliquer sur **OK**

PyCharm va:
- ✅ Créer les volumes Docker propres
- ✅ Détecter l'interpréteur Python du conteneur
- ✅ Synchroniser les dépendances Odoo
- ⏳ Prendre 2-5 minutes pour la synchronisation initiale

### 3️⃣ Développer Vos Modules

```bash
# L'image Dockerfile locale construit automatiquement vos modules custom
# Vous pouvez éditer dans:
addons/custom/<votre-module>/
addons/custom/<votre-module>/__manifest__.py
addons/custom/<votre-module>/models/*.py
addons/custom/<votre-module>/views/*.xml
```

**Workflow de développement**:

1. Éditer vos modules dans PyCharm
2. Utiliser "Run → Edit Configurations → + → Python"
3. Ou utiliser le terminal: `docker exec -it odoo-<project>-web odoo -d odoo -u <votre-module> --no-http`

### 4️⃣ Accès à Odoo

- **URL**: http://localhost:8069
- **Email**: `admin@odoo.com`
- **Mot de passe**: `admin`

---

## 🔧 Mode Debug Production (Restaurer une DB Production Localement)

### Cas d'Usage

Vous avez un bug en production et vous voulez:
1. Restaurer une copie anonymisée de la base de données production
2. Reproduire le bug localement
3. Déboguer avec PyCharm

### 1️⃣ Préparation

```bash
# 1. Obtenir une dump du backup Odoo SH ou de votre serveur
# Exemple:
scp user@prod-server:/backups/odoo.sql ./backup.sql

# 2. (Optionnel) Anonymiser les données sensibles
psql -U odoo -d odoo -f scripts/anonymize_database.sql
```

### 2️⃣ Configuration Docker pour Production

**Créer `docker-compose.prod-debug.yml`:**

```yaml
version: '3.8'

services:
  web:
    # Utiliser l'image pre-built de production
    image: ghcr.io/resultrum/odoo:18.0-enterprise-latest
    # (ou votre image custom buildée)
    environment:
      - ODOO_DATABASE=prod_debug
      - PGPASSWORD=odoo
    volumes:
      # Ajouter le dump du backup
      - ./backup.sql:/tmp/backup.sql:ro
      # Conserver les addons custom pour debugging
      - ./addons/custom:/mnt/extra-addons/custom:ro
    ports:
      - "8070:8069"  # Port différent du dev pour éviter les conflits
```

### 3️⃣ Lancer l'Environnement de Debug

```bash
# 1. Démarrer avec la configuration production
docker-compose -f docker-compose.yml -f docker-compose.prod-debug.yml up -d

# 2. Restaurer la base de données
docker exec -i odoo-<project>-db psql -U odoo < ./backup.sql

# 3. Connecter PyCharm à cette instance
# Menu: PyCharm → Settings → Project → Python Interpreter
# → Ajouter un nouvel interpréteur Docker Compose
# → Sélectionner docker-compose.yml + docker-compose.prod-debug.yml
# → Service: web
# → Port: 8070
```

### 4️⃣ Debugging

```bash
# Accéder à Odoo
http://localhost:8070

# Voir les logs en temps réel
docker logs -f odoo-<project>-web

# Accéder au shell du conteneur
docker exec -it odoo-<project>-web bash

# Redémarrer le service Web
docker restart odoo-<project>-web
```

---

## 🚀 Commandes Utiles

### Gestion des Services

```bash
# Démarrer
docker-compose up -d

# Arrêter
docker-compose down

# Voir l'état
docker-compose ps

# Logs en temps réel
docker-compose logs -f web
```

### Gestion des Modules

```bash
# Installer un module
docker exec odoo-<project>-web odoo -d odoo -i my_module --without-demo=all

# Mettre à jour un module
docker exec odoo-<project>-web odoo -d odoo -u my_module --without-demo=all

# Tester un module
docker exec odoo-<project>-web odoo -d odoo --test-enable -i my_module --stop-after-init
```

### Accès à la Base de Données

```bash
# Connexion psql
docker exec -it odoo-<project>-db psql -U odoo -d odoo

# Exporter une dump
docker exec odoo-<project>-db pg_dump -U odoo odoo > backup.sql

# Importer une dump
docker exec -i odoo-<project>-db psql -U odoo < backup.sql
```

---

## 🔧 Dépannage

### Problème: PyCharm dit "Python not found"

**Solution**:
1. Vérifier que Docker est actif: `docker ps`
2. Recréer l'interpréteur:
   - `Settings → Project → Python Interpreter → ⚙️ → Remove`
   - Ajouter un nouvel interpréteur Docker Compose

### Problème: Port 8069 déjà utilisé

**Solution**:
```bash
docker-compose down
docker network prune -f
docker-compose up -d
```

### Problème: Synchronisation PyCharm très lente

- La première synchronisation peut prendre 5-10 minutes
- Vérifier la bande passante et les logs: `docker logs web`
- Patience! Les dépendances Odoo sont nombreuses

### Problème: Le module n'apparaît pas en installation

**Solution**:
```bash
# Nettoyer le cache
docker exec odoo-<project>-web rm -rf /mnt/extra-addons/custom/__pycache__

# Redémarrer
docker restart odoo-<project>-web
```

---

## 📚 Ressources Utiles

- **Documentation Odoo**: https://www.odoo.com/documentation/18.0/
- **Docker Compose**: https://docs.docker.com/compose/
- **PyCharm Docker**: https://www.jetbrains.com/help/pycharm/docker.html
- **Odoo.sh Anonymization**: https://www.odoo.sh/documentation/user/advanced/security

---

**Dernière mise à jour**: Auto-généré par Claude Code
