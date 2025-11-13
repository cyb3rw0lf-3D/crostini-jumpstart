#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────────────────────
PROJECT_DIR="$HOME/celeste-wasm"
OUTPUT_PATH="/mnt/chromeos/MyFiles/Downloads/celeste-offline.html"
MIN_RAM_MB=3000

# Colors
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
log() { echo -e "${GREEN}[BUILD]${NC} $1"; }
setup() { echo -e "${BLUE}[SETUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

# ──────────────────────────────────────────────────────────────
# PREREQUISITE CHECK & INSTALL
# ──────────────────────────────────────────────────────────────
setup "Checking system prerequisites..."

# Check for sudo access
if ! sudo -v &>/dev/null; then
    error "This script requires sudo access. Please run: sudo echo 'test' first"
fi

# Install system packages (idempotent)
setup "Installing system packages (git, mono-devel)..."
sudo apt update -qq
sudo apt install -y -qq git mono-devel

# Install pnpm if missing
if ! command -v pnpm &>/dev/null; then
    setup "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    # Reload shell to get pnpm in PATH
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
fi

# Install .NET SDK if missing
if ! command -v dotnet &>/dev/null; then
    setup "Installing .NET 9.0 SDK..."
    wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
    sudo dpkg -i /tmp/packages-microsoft-prod.deb
    sudo apt update -qq
    sudo apt install -y -qq dotnet-sdk-9.0
fi

# Verify installations
setup "Verifying installations..."
command -v git >/dev/null || error "git installation failed"
command -v pnpm >/dev/null || error "pnpm installation failed"
command -v dotnet >/dev/null || error "dotnet installation failed"
command -v mono >/dev/null || error "mono installation failed"

# ──────────────────────────────────────────────────────────────
# SYSTEM VALIDATION
# ──────────────────────────────────────────────────────────────
log "Validating system resources..."

# RAM check
AVAILABLE_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
if (( AVAILABLE_RAM < MIN_RAM_MB )); then
    error "Insufficient RAM: ${AVAILABLE_RAM}MB available. Need ${MIN_RAM_MB}MB+. Increase in ChromeOS Settings > Developers > Linux"
fi

# Disk space check (build needs ~5GB)
AVAILABLE_GB=$(df -BG "$HOME" | awk 'NR==2{sub(/G/,"",$4); print $4}')
if (( AVAILABLE_GB < 10 )); then
    error "Low disk space: ${AVAILABLE_GB}GB available. Need 10GB+ free."
fi

# ──────────────────────────────────────────────────────────────
# PROJECT BUILD
# ──────────────────────────────────────────────────────────────
log "Starting celeste-wasm build..."

# Fresh clone (removes old attempts)
if [ -d "$PROJECT_DIR" ]; then
    warn "Removing existing project directory..."
    rm -rf "$PROJECT_DIR"
fi

log "Cloning repository..."
git clone --depth=1 https://github.com/MercuryWorkshop/celeste-wasm.git "$PROJECT_DIR"
cd "$PROJECT_DIR"

log "Installing pnpm dependencies..."
pnpm install --frozen-lockfile --silent

log "Setting up .NET workloads (requires sudo)..."
cd loader
sudo dotnet workload restore --silent
cd ..

log "Building project (this takes 5-10 minutes)..."
make publish

# Verify build output
if [ ! -f "dist/index.html" ]; then
    error "Build failed: dist/index.html not found"
fi

# ──────────────────────────────────────────────────────────────
# INLINE ASSETS
# ──────────────────────────────────────────────────────────────
log "Inlining assets into single HTML file..."
cd dist
npx --yes inliner index.html > "$OUTPUT_PATH"

# Verify final output
if [ -f "$OUTPUT_PATH" ]; then
    SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
    log "✅ Build successful!"
    log "📁 Output: $OUTPUT_PATH (${SIZE})"
    log "💡 Open from ChromeOS Files app > Downloads (double-click to open in Chrome)"
else
    error "Inlining failed: output file not created"
fi

# Cleanup
cd ..
log "Cleaning up build directory..."
rm -rf "$PROJECT_DIR"

echo ""
log "🎉 All done! You can now run celeste-wasm offline in Chrome. Check your Downloads folder and try it out yourself! -past Xavier/SUPXRECHO"
