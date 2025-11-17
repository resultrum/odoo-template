#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -ne 3 ]; then
  echo -e "${RED}❌ Usage: $0 <project-name> <module-name> <organization>${NC}"
  echo ""
  echo "Example: $0 odoo-crm crm_base resultrum"
  exit 1
fi

PROJECT_NAME=$1
MODULE_NAME=$2
ORG_NAME=$3

if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo -e "${RED}❌ Project name must contain only lowercase letters, numbers, and hyphens${NC}"
  exit 1
fi

if [[ ! "$MODULE_NAME" =~ ^[a-z0-9_]+$ ]]; then
  echo -e "${RED}❌ Module name must contain only lowercase letters, numbers, and underscores${NC}"
  exit 1
fi

if [ ! -f "Dockerfile" ] || [ ! -d "addons/custom/mta_base" ]; then
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
echo ""

# 1. Rename custom module
echo -e "${YELLOW}1️⃣ Renaming custom module...${NC}"
if [ -d "addons/custom/mta_base" ]; then
  mv "addons/custom/mta_base" "addons/custom/$MODULE_NAME"
  echo -e "   ${GREEN}✅ Renamed mta_base → $MODULE_NAME${NC}"
fi

# 2. Update module manifest
echo -e "${YELLOW}2️⃣ Updating module manifest...${NC}"
MODULE_MANIFEST="addons/custom/$MODULE_NAME/__manifest__.py"
if [ -f "$MODULE_MANIFEST" ]; then
  TITLE_NAME=$(echo "$MODULE_NAME" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1))substr($i,2)} 1')
  sed -i '' "s/'name': 'MTA Base'/'name': '$TITLE_NAME'/g" "$MODULE_MANIFEST"
  sed -i '' "s/'description': 'Base module for MTA project'/'description': 'Base module for $PROJECT_NAME project'/g" "$MODULE_MANIFEST"
  echo -e "   ${GREEN}✅ Updated manifest${NC}"
fi

# 3. Rename test file
echo -e "${YELLOW}3️⃣ Renaming test files...${NC}"
if [ -f "addons/custom/$MODULE_NAME/tests/test_mta_base.py" ]; then
  mv "addons/custom/$MODULE_NAME/tests/test_mta_base.py" "addons/custom/$MODULE_NAME/tests/test_${MODULE_NAME}.py"
  echo -e "   ${GREEN}✅ Renamed test file${NC}"
fi

# 4. Update docker-compose files
echo -e "${YELLOW}4️⃣ Updating docker-compose files...${NC}"
for file in docker-compose.yml docker-compose.dev.yml docker-compose.prod.yml; do
  if [ -f "$file" ]; then
    sed -i '' "s/odoo-mta/$PROJECT_NAME/g" "$file"
    sed -i '' "s/odoo_mta/$(echo $PROJECT_NAME | tr '-' '_')/g" "$file"
    echo -e "   ${GREEN}✅ Updated $file${NC}"
  fi
done

# 5. Update GitHub workflows
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

# 6. Update README
echo -e "${YELLOW}6️⃣ Updating README.md...${NC}"
if [ -f "README.md" ]; then
  sed -i '' "s/odoo-template/$PROJECT_NAME/g" README.md
  sed -i '' "s/resultrum/$ORG_NAME/g" README.md
  echo -e "   ${GREEN}✅ Updated README.md${NC}"
fi

# 7. Reset VERSION
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
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. git diff"
echo "2. git add . && git commit -m 'chore: setup new project'"
echo "3. cp .env.example .env"
echo "4. docker-compose up -d"
echo "5. git push origin main"
echo ""

