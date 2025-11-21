#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
  echo -e "${RED}❌ Usage: $0 <project-name> <module-name> <organization> [enterprise|community]${NC}"
  echo ""
  echo "Example: $0 odoo-pbt pbt_base resultrum enterprise"
  echo "         $0 odoo-crm crm_base resultrum community"
  echo ""
  echo "Default: enterprise"
  exit 1
fi

PROJECT_NAME=$1
MODULE_NAME=$2
ORG_NAME=$3
EDITION=${4:-enterprise}

# Valider l'édition
if [[ ! "$EDITION" =~ ^(enterprise|community)$ ]]; then
  echo -e "${RED}❌ Edition must be 'enterprise' or 'community'${NC}"
  exit 1
fi

# Check if we're in template directory
if [ ! -d "scripts" ] || [ ! -f "scripts/setup-new-project.sh" ]; then
  echo -e "${RED}❌ This script must be run from the root of the template repository${NC}"
  echo "Current directory: $(pwd)"
  exit 1
fi

if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo -e "${RED}❌ Project name must contain only lowercase letters, numbers, and hyphens${NC}"
  exit 1
fi

if [[ ! "$MODULE_NAME" =~ ^[a-z0-9_]+$ ]]; then
  echo -e "${RED}❌ Module name must contain only lowercase letters, numbers, and underscores${NC}"
  exit 1
fi

if [ ! -f "Dockerfile" ] || [ ! -d "addons/custom" ]; then
  echo -e "${RED}❌ This script must be run from the root of the template repository${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}🚀 Setting Up New Odoo Project from Template${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "📌 Project Name:    ${GREEN}$PROJECT_NAME${NC}"
echo -e "📦 Module Name:     ${GREEN}$MODULE_NAME${NC}"
echo -e "🏢 Organization:    ${GREEN}$ORG_NAME${NC}"
EDITION_DISPLAY=$(echo "$EDITION" | cut -c1 | tr '[:lower:]' '[:upper:]')$(echo "$EDITION" | cut -c2-)  # Capitalize first letter
echo -e "🔧 Edition:         ${GREEN}$EDITION_DISPLAY${NC}"
echo ""

# ============================================================================
# Step 0: Setup Environment Configuration
# ============================================================================

echo -e "${YELLOW}0️⃣ Setting up environment configuration...${NC}"
echo ""

# Create .env from .env.example with project-specific values
if [ ! -f ".env" ]; then
  cp .env.example .env
  echo -e "${GREEN}✅ Created .env from .env.example${NC}"
else
  echo -e "${YELLOW}⚠️  .env already exists, updating values...${NC}"
fi

# Update .env with project-specific values
sed -i '' "s|^PROJECT_NAME=.*|PROJECT_NAME=$PROJECT_NAME|g" .env
sed -i '' "s|^MODULE_NAME=.*|MODULE_NAME=$MODULE_NAME|g" .env
sed -i '' "s|^ORG_NAME=.*|ORG_NAME=$ORG_NAME|g" .env
echo -e "${GREEN}✅ Updated .env with project values${NC}"
echo ""

# Step 1: Rename custom module
echo -e "${YELLOW}1️⃣ Renaming custom module...${NC}"
if [ -d "addons/custom/mta_base" ]; then
  mv "addons/custom/mta_base" "addons/custom/$MODULE_NAME"
  echo -e "   ${GREEN}✅ Renamed mta_base → $MODULE_NAME${NC}"
fi

# Step 2: Update module manifest
echo -e "${YELLOW}2️⃣ Updating module manifest...${NC}"
MODULE_MANIFEST="addons/custom/$MODULE_NAME/__manifest__.py"
if [ -f "$MODULE_MANIFEST" ]; then
  TITLE_NAME=$(echo "$MODULE_NAME" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1))substr($i,2)} 1')
  sed -i '' "s|'name': 'MTA Base'|'name': '$TITLE_NAME'|g" "$MODULE_MANIFEST"
  sed -i '' "s|'description': 'Base module for MTA project'|'description': 'Base module for $PROJECT_NAME project'|g" "$MODULE_MANIFEST"
  echo -e "   ${GREEN}✅ Updated manifest${NC}"
fi

# Step 3: Rename and update test files
echo -e "${YELLOW}3️⃣ Renaming and updating test files...${NC}"
TEST_DIR="addons/custom/$MODULE_NAME/tests"
if [ -d "$TEST_DIR" ]; then
  # Rename test file
  if [ -f "$TEST_DIR/test_mta_base.py" ]; then
    mv "$TEST_DIR/test_mta_base.py" "$TEST_DIR/test_${MODULE_NAME}.py"
  fi

  # Update imports in __init__.py
  if [ -f "$TEST_DIR/__init__.py" ]; then
    sed -i '' "s/test_mta_base/test_${MODULE_NAME}/g" "$TEST_DIR/__init__.py"
  fi

  # Update references in test files
  if [ -f "$TEST_DIR/test_${MODULE_NAME}.py" ]; then
    sed -i '' "s/mta_base/${MODULE_NAME}/g" "$TEST_DIR/test_${MODULE_NAME}.py"
  fi

  echo -e "   ${GREEN}✅ Updated test files${NC}"
fi

# Step 4: Update docker-compose files
echo -e "${YELLOW}4️⃣ Updating docker-compose files...${NC}"
PROJECT_NAME_UNDERSCORE=$(echo "$PROJECT_NAME" | tr '-' '_')
for file in docker-compose.yml docker-compose.dev.yml docker-compose.prod.yml; do
  if [ -f "$file" ]; then
    sed -i '' "s|odoo-template|$PROJECT_NAME|g" "$file"
    sed -i '' "s|odoo_template|$PROJECT_NAME_UNDERSCORE|g" "$file"
    echo -e "   ${GREEN}✅ Updated $file${NC}"
  fi
done

# Step 4b: Handle Dockerfile variants based on edition
echo -e "${YELLOW}4️⃣b Configuring Dockerfile for $EDITION edition...${NC}"
if [ "$EDITION" = "enterprise" ]; then
  # Use Enterprise Dockerfile (with instructions)
  if [ -f "Dockerfile.enterprise" ]; then
    cp Dockerfile.enterprise Dockerfile
    rm -f Dockerfile.community
    echo -e "   ${GREEN}✅ Using Dockerfile.enterprise${NC}"
  fi
else
  # Use Community Dockerfile
  if [ -f "Dockerfile.community" ]; then
    cp Dockerfile.community Dockerfile
    rm -f Dockerfile.enterprise
    echo -e "   ${GREEN}✅ Using Dockerfile.community${NC}"
  fi
fi

# Step 5: Update GitHub workflows
echo -e "${YELLOW}5️⃣ Updating GitHub workflows...${NC}"
if [ -d ".github/workflows" ]; then
  for file in .github/workflows/*.yml; do
    if [ -f "$file" ]; then
      sed -i '' "s|image_name:.*|image_name: $ORG_NAME/$PROJECT_NAME|g" "$file"
      sed -i '' "s|resultrum/odoo-template|$ORG_NAME/$PROJECT_NAME|g" "$file"
      echo -e "   ${GREEN}✅ Updated $(basename $file)${NC}"
    fi
  done
fi

# Step 6: Update README
echo -e "${YELLOW}6️⃣ Updating README.md...${NC}"
if [ -f "README.md" ]; then
  sed -i '' "s|odoo-template|$PROJECT_NAME|g" README.md
  sed -i '' "s|resultrum|$ORG_NAME|g" README.md
  echo -e "   ${GREEN}✅ Updated README.md${NC}"
fi

# Step 6b: Update scripts (backup.sh, etc.)
echo -e "${YELLOW}6️⃣b Updating scripts...${NC}"
if [ -d "scripts" ]; then
  for file in scripts/*.sh; do
    if [ -f "$file" ]; then
      sed -i '' "s|odoo-mta|$PROJECT_NAME|g" "$file"
      sed -i '' "s|odoo_mta|$PROJECT_NAME_UNDERSCORE|g" "$file"
    fi
  done
  echo -e "   ${GREEN}✅ Updated scripts${NC}"
fi

# Step 6c: Update infrastructure (Bicep templates)
echo -e "${YELLOW}6️⃣c Updating infrastructure templates...${NC}"
if [ -d "infrastructure" ]; then
  for file in infrastructure/*.bicep infrastructure/*.json; do
    if [ -f "$file" ]; then
      sed -i '' "s|odoo-mta|$PROJECT_NAME|g" "$file"
      sed -i '' "s|odoo_mta|$PROJECT_NAME_UNDERSCORE|g" "$file"
    fi
  done
  echo -e "   ${GREEN}✅ Updated infrastructure${NC}"
fi

# Step 6d: Generate project README from template
echo -e "${YELLOW}6️⃣d Generating project README...${NC}"
if [ -f "README-PROJECT-TEMPLATE.md" ]; then
  EDITION_UPPER=$(echo "$EDITION" | tr '[:lower:]' '[:upper:]')
  DATE_CREATION=$(date +%d\ %B\ %Y)

  sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
      -e "s|{{MODULE_NAME}}|$MODULE_NAME|g" \
      -e "s|{{ORG_NAME}}|$ORG_NAME|g" \
      -e "s|{{EDITION_UPPER}}|$EDITION_UPPER|g" \
      -e "s|{{EDITION}}|$EDITION|g" \
      -e "s|\[DATE_CREATION\]|$DATE_CREATION|g" \
      README-PROJECT-TEMPLATE.md > README.md

  echo -e "   ${GREEN}✅ Generated README.md from template${NC}"
fi

# Step 7: Reset VERSION
echo -e "${YELLOW}7️⃣ Resetting VERSION...${NC}"
if [ -f "VERSION" ]; then
  echo "0.1.0" > VERSION
  echo -e "   ${GREEN}✅ VERSION reset to 0.1.0${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Project setup complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Edition-specific instructions
if [ "$EDITION" = "enterprise" ]; then
  echo -e "${YELLOW}⚠️  IMPORTANT - Enterprise Edition Setup${NC}"
  echo ""
  echo "Your Dockerfile has been configured for Enterprise Edition development."
  echo ""
  echo "📝 NEXT STEP: Update the Docker base image"
  echo ""
  echo "Edit your Dockerfile and uncomment/choose ONE of these options:"
  echo ""
  echo "  1️⃣  GitHub Enterprise Nightly (recommended)"
  echo "      FROM ghcr.io/odoo/odoo:18.0-enterprise"
  echo ""
  echo "      First authenticate:"
  echo "      docker login ghcr.io -u <github-username> -p <github-token>"
  echo ""
  echo "  2️⃣  Community Edition (for development/testing only)"
  echo "      FROM odoo:18.0"
  echo "      ✅ Already set as default"
  echo ""
  echo "  3️⃣  Build from Odoo Enterprise source"
  echo "      Clone Odoo repo and build from their Dockerfile"
  echo ""
  echo "💡 See Dockerfile comments for all options and details"
  echo ""
else
  echo -e "${GREEN}✅ Community Edition configured${NC}"
  echo "Your Dockerfile is ready to use: FROM odoo:18.0"
  echo ""
fi

echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. git diff"
echo "2. git add . && git commit -m 'chore: setup new project - $EDITION edition'"
echo "3. cp .env.example .env"
echo "4. docker-compose up -d"
echo "5. git push origin main"
echo ""

