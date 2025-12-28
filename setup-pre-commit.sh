#!/bin/bash

# Pre-commit Setup Script for BrowserQuest
# This script helps you install and configure pre-commit hooks

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}BrowserQuest Pre-commit Setup${NC}"
echo "========================================"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${RED}Error: Python is not installed${NC}"
    echo "Please install Python 3.x first:"
    echo "  - Ubuntu/Debian: sudo apt-get install python3 python3-pip"
    echo "  - macOS: brew install python3"
    echo "  - Or visit: https://www.python.org/downloads/"
    exit 1
fi

echo -e "${GREEN}✓${NC} Python is installed"

# Check if pip is installed
if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    echo -e "${RED}Error: pip is not installed${NC}"
    echo "Please install pip first:"
    echo "  - Ubuntu/Debian: sudo apt-get install python3-pip"
    echo "  - macOS: python3 -m ensurepip"
    exit 1
fi

echo -e "${GREEN}✓${NC} pip is installed"

# Install pre-commit
echo ""
echo -e "${YELLOW}Installing pre-commit...${NC}"

if command -v pip3 &> /dev/null; then
    pip3 install pre-commit --user
elif command -v pip &> /dev/null; then
    pip install pre-commit --user
fi

echo -e "${GREEN}✓${NC} pre-commit installed"

# Install npm dependencies
echo ""
echo -e "${YELLOW}Installing npm dependencies...${NC}"
npm install

echo -e "${GREEN}✓${NC} npm dependencies installed"

# Install pre-commit hooks
echo ""
echo -e "${YELLOW}Installing pre-commit hooks...${NC}"
pre-commit install

echo -e "${GREEN}✓${NC} Pre-commit hooks installed"

# Initialize detect-secrets baseline
echo ""
echo -e "${YELLOW}Initializing detect-secrets baseline...${NC}"

if command -v detect-secrets &> /dev/null; then
    detect-secrets scan > .secrets.baseline
    echo -e "${GREEN}✓${NC} Secrets baseline created"
else
    echo -e "${YELLOW}⚠${NC}  detect-secrets not found, creating placeholder baseline"
    echo "# Detect-secrets baseline (install detect-secrets for full functionality)" > .secrets.baseline
    echo -e "${YELLOW}   To install: pip install detect-secrets${NC}"
fi

# Optional: Run pre-commit on all files
echo ""
read -p "Do you want to run pre-commit on all files now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Running pre-commit on all files...${NC}"
    pre-commit run --all-files || echo -e "${YELLOW}Some hooks failed. This is normal for the first run.${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Pre-commit setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Make changes to files"
echo "  2. git add <files>"
echo "  3. git commit -m 'type(scope): message'"
echo ""
echo "The pre-commit hooks will run automatically on commit."
echo ""
echo "Useful commands:"
echo "  npm run format       - Format all files with Prettier"
echo "  npm run lint         - Lint JavaScript files"
echo "  pre-commit run       - Run hooks on staged files"
echo "  pre-commit run -a    - Run hooks on all files"
echo ""
echo "For more info, see PRE_COMMIT_SETUP.md"
