#!/bin/bash

# Enable pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Install .NET 9.0.4 SDK
wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-9.0 

# Install Mono (critical for this project)
sudo apt update
sudo apt install -y mono-devel

# Increase Crostini memory (critical!)
# Go to ChromeOS Settings > Developers > Linux > Memory > Set to 4GB or higher
set -euo pipefail

# Crostini-specific configuration
PROJECT_DIR="$HOME/celeste-wasm"
OUTPUT_PATH="/mnt/chromeos/MyFiles/Downloads/celeste-offline.html" # Easy access from ChromeOS
CHROMEOS_RAM_LIMIT=2048 # Crostini often limited to 2-4GB; Celeste needs ~600MB just to load

# Colors
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${GREEN}🚀${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1" >&2; exit 1; }

# Check Crostini environment
if [[ ! -d "/mnt/chromeos" ]]; then
    warn "Not running in Crostini? ChromeOS file sharing won't be available."
    OUTPUT_PATH="$HOME/celeste-offline.html"
fi

# Prerequisites check
log "Checking prerequisites..."
command -v git >/dev/null 2>&1 || error "git not found. Run: sudo apt update && sudo apt install git"
command -v pnpm >/dev/null 2>&1 || error "pnpm not found. Install it: curl -fsSL https://get.pnpm.io/install.sh | sh -"
command -v dotnet >/dev/null 2>&1 || error ".NET SDK not found. Install from: https://dotnet.microsoft.com/download"
command -v mono >/dev/null 2>&1 || error "mono-devel not found. Run: sudo apt update && sudo apt install mono-devel"

# Check available memory (critical for Crostini)
AVAILABLE_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
if (( AVAILABLE_RAM < 1500 )); then
    error "Crostini has only ${AVAILABLE_RAM}MB RAM. celeste-wasm needs ~600MB. Increase RAM in ChromeOS Settings > Developers > Linux > Memory."
fi

# Clone/update repo
if [ ! -d "$PROJECT_DIR" ]; then
    log "Cloning repository..."
    git clone https://github.com/MercuryWorkshop/celeste-wasm.git "$PROJECT_DIR"
else
    log "Updating existing repository..."
    cd "$PROJECT_DIR"
    git fetch origin
    if git diff-index --quiet HEAD --; then
        git pull --rebase
    else
        warn "Local changes detected, skipping pull"
    fi
fi

cd "$PROJECT_DIR"

# Install pnpm dependencies
log "Installing pnpm dependencies..."
pnpm install --frozen-lockfile

# Setup .NET workloads (requires sudo)
log "Setting up .NET workloads (requires sudo)..."
cd loader
sudo dotnet workload restore
cd ..

# Build for production
log "Building celeste-wasm (this takes 5-10 minutes)..."
make publish

# Check if build succeeded
if [ ! -f "dist/index.html" ]; then
    error "Build failed: dist/index.html not found. Check output above for errors."
fi

# Inline into single HTML file (use local inliner via npx)
log "Creating offline-ready single file..."
cd dist
npx --yes inliner index.html > "$OUTPUT_PATH"

log "✅ Build complete!"
log "Your offline file is at: $OUTPUT_PATH"
log "💡 On ChromeOS: Open Files app > Downloads > celeste-offline.html (double-click opens in Chrome)"

# Memory warning for runtime
echo ""
warn "IMPORTANT: Close other Linux apps before running celeste-wasm."
warn "It needs ~600MB RAM. If Crostini crashes, increase RAM in Settings."
