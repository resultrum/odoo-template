# Local Testing Guide for Custom Modules

Guide pour tester les modules custom en local avant de pusher.

---

## 🧪 Tests Unitaires (Odoo Framework)

### Lancer les tests pour un module custom

```bash
# Test mta_base
docker exec odoo-mta-web odoo -i mta_base -d mta-dev --test-enable --stop-after-init -p 8070

# Output attendu:
# ✅ 0 failed, 0 error(s) of X tests when loading database 'mta-dev'
```

**Comment ça marche:**
- `-i mta_base` : Installe le module et ses dépendances (automatique)
- `--test-enable` : Active la découverte et l'exécution des tests
- `--stop-after-init` : Arrête après initialisation/tests
- `-p 8070` : Utilise le port 8070 (8069 occupé par conteneur)

### Tester tous les modules custom

```bash
# Installer et tester tous les custom modules
docker exec odoo-mta-web odoo -i $(ls addons/custom) -d mta-dev --test-enable --stop-after-init -p 8070
```

---

## 📋 Code Style (Flake8, Black, isort)

### Configuration

Les règles sont définies dans:
- `.flake8` : Flake8 (max 79 caractères)
- `.pylintrc` : Pylint (max 79 caractères)
- `.pre-commit-config.yaml` : Pre-commit hooks (pour GitHub et local)

### Setup pre-commit (première fois)

Pre-commit est installé globalement dans `/Users/jonathannemry/Projects/.venv`

```bash
# Setup pre-commit hooks dans le projet
/Users/jonathannemry/Projects/.venv/bin/pre-commit install

# Vérifier que c'est installé
cat .git/hooks/pre-commit
```

### Vérifier localement

**Option 1: Pre-commit (recommandé - automatique avant commit)**
```bash
# Vérifie automatiquement avant commit
# Les hooks s'exécutent automatiquement lors de: git commit

# Ou vérifier manuellement
/Users/jonathannemry/Projects/.venv/bin/pre-commit run --all-files
```

**Option 2: Docker**
```bash
# Flake8 dans Docker
docker exec odoo-mta-web flake8 /mnt/extra-addons/custom/ --max-line-length=79

# Black check dans Docker
docker exec odoo-mta-web black /mnt/extra-addons/custom/ --check --line-length=79
```

**Option 3: Venv local (si vous voulez isolé)**
```bash
# Créer venv local
python3 -m venv .venv-local
source .venv-local/bin/activate

# Installer tools
pip install flake8 black isort pylint

# Vérifier code
flake8 addons/custom/ --config=.flake8
black addons/custom/ --check --line-length=79
isort addons/custom/ --check --profile=black
```

---

## ✅ Checklist Avant Commit

- [ ] Tests unitaires Odoo passent
  ```bash
  docker exec odoo-mta-web odoo -i mta_base -d mta-dev --test-enable --stop-after-init -p 8070
  ```

- [ ] Code respecte le style (79 car max)
  - Vérifier via flake8/black en local ou Docker

- [ ] Pas d'erreurs pylint majeures
  ```bash
  docker exec odoo-mta-web pylint addons/custom/mta_base/
  ```

- [ ] Module charge sans erreur
  ```bash
  docker exec odoo-mta-web odoo -i mta_base -d mta-dev --stop-after-init -p 8070
  ```

---

## 🚀 Processus Complet

### 1. Développer localement

```bash
# Éditer le code
nano addons/custom/mta_base/__init__.py
```

### 2. Tester en local

```bash
# Lancer tests
docker exec odoo-mta-web odoo -i mta_base -d mta-dev --test-enable --stop-after-init -p 8070

# Vérifier style
docker exec odoo-mta-web flake8 /mnt/extra-addons/custom/mta_base/ --max-line-length=79
```

### 3. Si OK, committer

```bash
git add addons/custom/mta_base/
git commit -m "feat: add feature to mta_base"
```

### 4. GitHub Actions valide aussi

- Linters (flake8, black, isort)
- Tests unitaires Odoo
- Intégration avec autres modules

---

## 🐛 Troubleshooting

### Tests échouent

```bash
# Vérifier que le conteneur tourne
docker-compose ps

# Vérifier la base de données
docker exec odoo-mta-db psql -U odoo -d mta-dev -c "SELECT 1"

# Relancer les tests avec plus de verbosité
docker exec odoo-mta-web odoo -i mta_base -d mta-dev --test-enable --stop-after-init -p 8070 --log-level=debug
```

### Module ne charge pas

```bash
# Vérifier les dépendances
docker exec odoo-mta-web odoo -i mta_base -d mta-dev --stop-after-init -p 8070

# Voir les erreurs détaillées
docker-compose logs odoo-mta-web | tail -50
```

### Erreurs flake8/black

```bash
# Auto-corriger avec black
docker exec odoo-mta-web black /mnt/extra-addons/custom/mta_base/ --line-length=79

# Auto-corriger imports avec isort
docker exec odoo-mta-web isort /mnt/extra-addons/custom/mta_base/ --profile=black
```

---

## 📖 Pour plus d'infos

- **Tests Odoo:** https://www.odoo.com/documentation/18.0/developer/tutorials/server_framework_101/01_setup.html
- **Flake8:** https://flake8.pycqa.org/
- **Black:** https://black.readthedocs.io/
- **Pre-commit:** https://pre-commit.com/
