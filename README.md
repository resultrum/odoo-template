# odoo-mta

**MOTECMA - Metrum Odoo Technical Management**
**Trigram : MTA**

Projet Odoo Community 18.0 pour la gestion technique et le management de projets chez Metrum.

## Objectifs

- Planning développeurs avec adéquation charge/capacité
- Fiche projet complète (hébergement, contrat, run, clients)
- Helpdesk pour le support
- Intégration IA (phase 2)

## Structure

```
addons/
├── custom/                 # Modules custom Metrum (mta_*)
├── oca/                    # Dépôts OCA (fusionnés par git-aggregator)
│   ├── helpdesk/           # 22 modules Helpdesk OCA
│   └── server-tools/       # (Future)
└── oca-addons/             # Symlinks vers tous les modules OCA
```

## Stack Technique

- Odoo Community 18.0
- PostgreSQL 15
- Docker + Docker Compose
- Git-Aggregator (fusion multi-repos)
- Ansible (déploiement Azure)

## Nomenclature

- **Projet** : odoo-mta
- **Modules custom** : mta_*
- **Trigram** : MTA

## 🚀 Quick Start

### Prérequis

- Docker Desktop installé et lancé
- Git avec SSH configuré pour GitHub
- PyCharm (recommandé)

### Lancement en local
```bash
# 1. Clone le projet
git clone https://github.com/resultrum/odoo-mta.git
cd odoo-mta

# 2. Copier le fichier d'environnement
cp .env.example .env

# 3. Créer les symlinks OCA
./scripts/create-oca-symlinks.sh

# 4. Lancer les conteneurs Docker (mode dev)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# 5. Accéder à Odoo
# http://localhost:8069
# Database: mta-dev
# Username: admin
# Password: admin123
```

## 📚 Documentation

- **[DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)** - Guide complet pour les développeurs
  - Architecture et workflows
  - Scénarios : modifier un module OCA, ajouter un repo, créer un module custom
  - Commandes utiles et dépannage

- **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - Guide de test
  - 5 tests de validation de la setup
  - Scénarios de test pour git-aggregator
  - Checklist de vérification

## Roadmap

### Phase 1 : Base (Semaine 1)
- [ ] Setup infrastructure
- [ ] Installation Odoo + modules de base
- [ ] Configuration helpdesk

### Phase 2 : Planning (Semaine 1)
- [ ] Vue charge/capacité
- [ ] Planning développeurs

### Phase 3 : Fiche projet (Semaine 1)
- [ ] Extension modèle projet
- [ ] Vues personnalisées

### Phase 4 : IA (Bonus)
- [ ] Intégration API IA
- [ ] Automatisations

---

**Projets liés :**
- **odoo-mtt** (MOTECTO) : Metrum Odoo Technical Topic
