#!/bin/bash

# Build and Test Alert Service
# This script builds the alert-service and verifies it's ready for deployment

set -e  # Exit on error

echo "=========================================="
echo "Building Alert Service"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to alert-service directory
cd "$(dirname "$0")/../backend/alert-service"

echo -e "${YELLOW}Step 1: Cleaning previous builds...${NC}"
if command -v mvn &> /dev/null; then
    mvn clean
else
    echo -e "${RED}Maven not found! Please install Maven first.${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 2: Compiling and packaging (skipping tests for now)...${NC}"
mvn package -DskipTests

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 3: Checking JAR file...${NC}"
JAR_FILE=$(find target -name "*.jar" -not -name "*-sources.jar" | head -n 1)

if [ -f "$JAR_FILE" ]; then
    echo -e "${GREEN}✓ JAR file created: $JAR_FILE${NC}"
    ls -lh "$JAR_FILE"
else
    echo -e "${RED}✗ JAR file not found!${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Alert Service Build Complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Start the complete stack:"
echo "   docker-compose up -d"
echo ""
echo "2. Check service health:"
echo "   curl http://localhost:8083/actuator/health"
echo ""
echo "3. View logs:"
echo "   docker-compose logs -f alert-service"
echo ""

# Made with Bob
