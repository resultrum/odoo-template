#!/bin/bash

# ============================================================================
# PyCharm Setup Script for odoo-pbt
# ============================================================================
#
# This script prepares the project for PyCharm development with Docker
#
# Usage:
#   ./scripts/pycharm-setup.sh
#
# What it does:
#   1. Creates .env file if it doesn't exist
#   2. Creates Docker Compose configuration for PyCharm
#   3. Verifies Docker connection
#   4. Pulls required Docker images
#   5. Prints setup instructions
#
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Dockerfile" ] || [ ! -f "docker-compose.yml" ]; then
  echo -e "${RED}❌ Error: This script must be run from the project root${NC}"
  echo "   Current directory: $(pwd)"
  exit 1
fi

echo ""
echo -e "${BLUE}═════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🐍 PyCharm Setup for odoo-pbt${NC}"
echo -e "${BLUE}═════════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# 1. Create .env file
# ============================================================================

echo -e "${YELLOW}1️⃣ Setting up environment variables...${NC}"

if [ ! -f ".env" ]; then
  cp .env.example .env
  echo -e "   ${GREEN}✅ Created .env file${NC}"
  echo "      Edit .env to customize your configuration"
else
  echo -e "   ${GREEN}✅ .env already exists${NC}"
fi

# ============================================================================
# 2. Verify Docker
# ============================================================================

echo -e "${YELLOW}2️⃣ Verifying Docker installation...${NC}"

if ! command -v docker &> /dev/null; then
  echo -e "   ${RED}❌ Docker not found${NC}"
  echo "      Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
  exit 1
fi

if ! docker ps &> /dev/null; then
  echo -e "   ${RED}❌ Docker daemon is not running${NC}"
  echo "      Please start Docker Desktop"
  exit 1
fi

echo -e "   ${GREEN}✅ Docker is installed and running${NC}"

# ============================================================================
# 3. Create PyCharm configuration directories
# ============================================================================

echo -e "${YELLOW}3️⃣ Creating PyCharm configuration...${NC}"

mkdir -p .idea/runConfigurations
echo -e "   ${GREEN}✅ Created .idea/runConfigurations${NC}"

# ============================================================================
# 4. Pull Docker images
# ============================================================================

echo -e "${YELLOW}4️⃣ Pulling Docker images...${NC}"

docker-compose pull --quiet
echo -e "   ${GREEN}✅ Docker images pulled${NC}"

# ============================================================================
# 5. Build custom image
# ============================================================================

echo -e "${YELLOW}5️⃣ Building custom Odoo image...${NC}"

docker-compose build --quiet
echo -e "   ${GREEN}✅ Odoo image built${NC}"

# ============================================================================
# 6. Print setup instructions
# ============================================================================

echo ""
echo -e "${GREEN}═════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ PyCharm setup complete!${NC}"
echo -e "${GREEN}═════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📖 Next steps:${NC}"
echo ""
echo -e "1. ${BLUE}Open project in PyCharm:${NC}"
echo "   File → Open → Select this project directory"
echo ""
echo -e "2. ${BLUE}Configure Docker in PyCharm:${NC}"
echo "   PyCharm → Preferences (or Settings on Linux) → Docker"
echo "   Add your Docker installation"
echo ""
echo -e "3. ${BLUE}Set Python Interpreter:${NC}"
echo "   Preferences → Project → Python Interpreter"
echo "   Click gear ⚙️ → Add → Docker Compose"
echo "   - Configuration file: docker-compose.yml"
echo "   - Service: web"
echo "   - Path: /usr/local/bin/python3"
echo ""
echo -e "4. ${BLUE}Start containers:${NC}"
echo "   Option A: Run → Edit Configurations → + → Docker Compose"
echo "   Option B: docker-compose up -d"
echo ""
echo -e "5. ${BLUE}Access Odoo:${NC}"
echo "   Browser: http://localhost:8069"
echo "   Username: admin"
echo "   Password: (check .env file)"
echo ""
echo -e "${YELLOW}📚 For detailed instructions:${NC}"
echo "   See README.md in project root"
echo ""

exit 0
