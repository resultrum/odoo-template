# Odoo Template

Template reusable pour créer rapidement de nouveaux projets Odoo Enterprise.

**Version**: 0.1.0
**Odoo Version**: 18.0 Enterprise
**Stack**: Docker + Docker Compose + PostgreSQL

---

## 📋 À propos de ce Template

Ce repository est un **template** pour créer de nouveaux projets Odoo. Il contient:

- ✅ Structure de projet standardisée
- ✅ Docker + Docker Compose configurés
- ✅ Module custom de base (renommable)
- ✅ Scripts d'automatisation
- ✅ Configuration PyCharm pour développement local
- ✅ Scripts de base de données (anonymisation, etc.)

---

## 🚀 Créer un Nouveau Projet depuis ce Template

### Méthode 1: GitHub (Recommandée)
```bash
# 1. Aller sur https://github.com/<org>/odoo-template
# 2. Cliquer sur "Use this template" → "Create a new repository"
# 3. Donner un nom: odoo-<project> (ex: odoo-crm)
# 4. Cloner votre nouveau repository
git clone https://github.com/<org>/odoo-<project>.git
cd odoo-<project>

# 5. Exécuter le script de setup
./scripts/setup-new-project.sh odoo-<project> <module_name> <organization> [enterprise|community]
```

### Méthode 2: Clone Local + Setup
```bash
# 1. Cloner le template
git clone https://github.com/resultrum/odoo-template.git odoo-<project>
cd odoo-<project>

# 2. Exécuter le script de setup
./scripts/setup-new-project.sh odoo-<project> <module_name> <organization> [enterprise|community]

# Exemple pour Community:
./scripts/setup-new-project.sh odoo-myproject myproject_base myorg community

# Exemple pour Enterprise:
./scripts/setup-new-project.sh odoo-myproject myproject_base myorg enterprise

# 3. Committer les changements
git add .
git commit -m "chore: setup new project odoo-<project> - <edition> edition"

# 4. Configurer et lancer
cp .env.example .env
docker-compose up -d
```

### Après Setup (Enterprise Uniquement)

Si vous avez choisi **enterprise**, une image Docker Enterprise est buildée **automatiquement chaque lundi** par GitHub Actions.

**Pour utiliser Enterprise localement:**

```bash
# 1. Se connecter à GHCR (une seule fois)
docker login ghcr.io -u <github-username> -p <github-token>

# 2. Lancer avec Enterprise
docker-compose -f docker-compose.yml -f docker-compose.enterprise.yml up -d

# 3. Vérifier
docker-compose logs web | grep -i "enterprise\|community"
```

**Détails:**
- Image buildée chaque lundi: `ghcr.io/resultrum/odoo:18.0-enterprise-latest`
- Tags aussi disponibles: `week-47`, `2025-W47`, `2025-01-15`
- Repository source: `https://github.com/resultrum/enterprise`

---

## 🏗️ Structure du Projet

```
.
├── addons/
│   ├── custom/              # Modules custom (renommé durant setup)
│   │   └── <module_name>/   # Module de base du projet
│   ├── oca/                 # Dépôts OCA fusionnés (via git-aggregator)
│   └── oca-addons/          # Symlinks vers modules OCA
│
├── scripts/
│   ├── setup-new-project.sh # Setup automatique du projet
│   ├── pycharm-setup.sh     # Configuration PyCharm
│   ├── anonymize_database.sql
│   └── ...
│
├── .github/workflows/       # CI/CD pipelines
├── docker-compose.yml       # Configuration base
├── docker-compose.dev.yml   # Overrides développement
├── docker-compose.prod.yml  # Overrides production
├── Dockerfile               # Image Odoo custom
├── odoo.conf               # Configuration Odoo
├── repos.yml               # Configuration Git-Aggregator
│
└── README.md               # Ce fichier
```

---

## 💻 Développement Local avec PyCharm

### Prérequis
- Docker Desktop
- PyCharm Professional (Community a support limité)
- Git + SSH configuré (optionnel, seulement pour clone Odoo)

### Setup Rapide
```bash
# 1. Configurer Docker Compose interpreter dans PyCharm:
#    Settings → Project → Python Interpreter
#    Add → Docker Compose → odoo-template web service

# 2. Lancer les containers:
cp .env.example .env
docker-compose up -d

# 3. Debugger ton code custom:
#    Clic sur le numéro de ligne pour mettre breakpoint
#    Déclenche l'action dans Odoo
#    PyCharm pause automatiquement
```

### Documentation
- **`docs/DEBUGGING_SIMPLE.md`** - Guide simple (sans clone Odoo) ⭐ Start here!
- **`docs/PYCHARM_SETUP.md`** - Configuration détaillée
- **`docs/PYCHARM_DEBUGGING.md`** - Debug avancé (avec clone optionnel)

---

## 🗄️ Gestion des Dépôts OCA

Le fichier `repos.yml` vide par défaut. Ajouter des dépôts OCA selon vos besoins:

```yaml
./addons/oca/account-invoicing:
  remotes:
    oca: git@github.com:OCA/account-invoicing.git
    resultrum: git@github.com:resultrum/account-invoicing.git
  merges:
    - oca 18.0
  target: resultrum master-18.0
```

Pour peupler automatiquement: `./scripts/setup-repositories.sh`

---

## 🔐 Anonymisation de Base de Données

Pour utiliser une DB de production en développement:

```bash
# 1. Faire un dump de production
pg_dump -U odoo production_db > production.sql

# 2. Restaurer en local
createdb dev_db
psql dev_db < production.sql

# 3. Anonymiser (Odoo Sh compatible)
psql -U odoo -d dev_db -f scripts/anonymize_database.sql

# 4. Sélectionner la DB dans Odoo
# localhost:8069 → Créer DB → restaurer depuis backup
```

Voir `scripts/anonymize_database.sql` pour les détails (tokens, mails, etc.)

---

## 📖 Documentation

- **docs/PYCHARM_SETUP.md** - Configuration PyCharm détaillée
- **docs/CI_CD_GUIDE.md** - Pipelines GitHub Actions
- **docs/INFRASTRUCTURE.md** - Déploiement sur Azure

---

## 🔄 Workflows Typiques

### Modifier un Module OCA
```bash
# 1. Le module est cloné dans addons/oca/<repo-name>
# 2. Éditer les fichiers
# 3. Commit dans le fork OCA
# 4. Merger via repos.yml (optionnel)
```

### Créer un Module Custom
```bash
# 1. Dans addons/custom/<module-name>/
# 2. Créer __manifest__.py
# 3. Implémenter votre logique
# 4. Installer dans Odoo via Apps
```

### Ajouter une Dépendance OCA
```bash
# 1. Éditer repos.yml
# 2. Ajouter le repo (voir exemple ci-dessus)
# 3. docker-compose down && docker-compose up -d
# 4. Rafraîchir Apps dans Odoo (Ctrl+Shift+R)
```

---

## 🚨 Troubleshooting

**Port 8069 déjà utilisé?**
```bash
docker-compose down
# Ou modifier docker-compose.yml: ports: ["8070:8069"]
```

**Module custom pas détecté?**
```bash
# Vérifier addons_path dans odoo.conf
# Redémarrer: docker-compose restart web
# Rafraîchir: Odoo → Apps → Ctrl+Shift+R
```

**Erreur de connexion DB?**
```bash
docker-compose logs web | grep -i postgres
# Vérifier .env: DB_HOST, DB_USER, DB_PASSWORD
```

---

## 📝 License

Propriétaire Resultrum

---

**Questions?** Voir la documentation dans `docs/` ou les scripts dans `scripts/`
