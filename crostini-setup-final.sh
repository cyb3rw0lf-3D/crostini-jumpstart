#!/bin/bash

# Crostini Jumpstart - Complete v3.1.4 (PATCHED)
# Save this as: crostini-jumpstart-final.sh
# Then run: chmod +x crostini-jumpstart-final.sh && ./crostini-jumpstart-final.sh

set -euo pipefail

# ==================== CONFIGURATION ====================
readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m' CYAN='\033[0;36m' NC='\033[0m'
readonly SCRIPT_VERSION="3.1.4-PATCHED"
readonly LOG_FILE="/tmp/crostini-jumpstart.log"
readonly DOWNLOAD_DIR="/tmp/crostini-downloads"
readonly REQUIRED_SPACE=8000000  # 8GB in KB
# UPDATED: MediaFire link for Celeste (replace with your actual link)
readonly CELESTE_URL="https://download1654.mediafire.com/z1nu68dlz3wgkL_oRUTTgNdYMzB44NI3vKnFLvtHgMvfrmTcluR73aAvf7VSY7kok1i2qOAZpnx6NNiS4upe2_T4K5QaYRjyYae4m_4gxvgw6YAG0cAVwMGP2p8Zc9NHwvOqaAyysZwIBzbUshGiaYw_CzzzevGSlBWcVJqYAacr/eye8shb5mo3v5zd/Celeste_%28v1.4.0.0%29_%5BLinux%5D+%28extract.me%29.zip"
# FIXED: Use a safer default path instead of external SD card
readonly HOLLOW_KNIGHT_DIR="$HOME/games/hollow-knight"

declare -A COMPONENTS=([wine]=false [flatpak]=false [gaming]=false [multimedia]=false [dev]=false [security]=false [optimization]=false [games]=false [mods]=false [cura]=false [cleanup]=false)
declare -A GAMES=([celeste]=false [hollowknight]=false [celeste64]=false [celeste-wasm]=false)

# RAM-based component disabling
SKIP_MULTIMEDIA=false
SKIP_DEV=false

# ==================== CORE FUNCTIONS ====================
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}Script failed with exit code: $exit_code${NC}" | tee -a "$LOG_FILE"
        echo -e "${RED}Check log for details: $LOG_FILE${NC}" | tee -a "$LOG_FILE"
    fi
    rm -rf "$DOWNLOAD_DIR" 2>/dev/null || true
}
trap cleanup EXIT

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [$1] ${*:2}" | tee -a "$LOG_FILE"
}

print_status() {
    echo -e "${1}${2}${NC}"
}

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         Crostini Jumpstart v${SCRIPT_VERSION} - Optimized        ║"
    echo "║           Low RAM & Error-Resilient Edition               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_system() {
    log "INFO" "Checking system requirements..."
    
    # Check disk space
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt $REQUIRED_SPACE ]]; then
        log "ERROR" "Insufficient disk space. Need 8GB+, have $(($available_space/1024/1024))GB"
        return 1
    fi
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log "WARNING" "Running as root is not recommended"
    fi
    
    # Check RAM and adjust components
    local available_ram=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    log "INFO" "Available RAM: ${available_ram}MB"
    
    if (( available_ram < 3000 )); then
        log "WARNING" "Low RAM detected: ${available_ram}MB"
        log "WARNING" "Disabling memory-intensive components (multimedia, dev tools, WASM)"
        SKIP_MULTIMEDIA=true
        SKIP_DEV=true
        GAMES[celeste-wasm]=false
    elif (( available_ram < 4000 )); then
        log "WARNING" "Limited RAM: ${available_ram}MB"
        log "WARNING" "Disabling WASM build (requires 3GB+)"
        GAMES[celeste-wasm]=false
    fi
    
    log "INFO" "System check completed"
    return 0
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local answer
    read -p "$prompt (y/n) [$default]: " answer
    answer=${answer:-$default}
    [[ "$answer" =~ ^[Yy]$ ]]
}

secure_download() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry_count=0
    
    log "INFO" "Downloading: $url"
    mkdir -p "$(dirname "$output")"
    
    while [[ $retry_count -lt $max_retries ]]; do
        # Use wget with proper error handling
        if wget --timeout=60 --tries=3 --progress=dot:giga -O "${output}.tmp" "$url" 2>&1 | tee -a "$LOG_FILE"; then
            mv "${output}.tmp" "$output"
            log "INFO" "Download completed: $output"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        log "WARNING" "Download failed, attempt $retry_count/$max_retries"
        rm -f "${output}.tmp"
        sleep 5
    done
    
    log "ERROR" "Failed to download after $max_retries attempts"
    return 1
}

install_package() {
    local package="$1"
    local options="${2:-}"
    
    log "INFO" "Installing package: $package"
    
    # Try installation with retry logic
    for attempt in {1..3}; do
        if sudo apt-get install -y $options "$package" 2>&1 | tee -a "$LOG_FILE"; then
            log "INFO" "Successfully installed: $package"
            return 0
        fi
        
        if [[ $attempt -lt 3 ]]; then
            log "WARNING" "Installation failed, attempt $attempt/3. Fixing dependencies..."
            sudo apt-get install -f -y 2>&1 | tee -a "$LOG_FILE"
            sleep 3
        fi
    done
    
    log "ERROR" "Failed to install $package after 3 attempts"
    return 1
}

install_deb_package() {
    local deb_file="$1"
    log "INFO" "Installing .deb package: $deb_file"
    
    if sudo dpkg -i "$deb_file" 2>&1 | tee -a "$LOG_FILE"; then
        log "INFO" "Successfully installed: $deb_file"
        return 0
    else
        log "WARNING" "Initial dpkg failed, attempting dependency fix..."
        if sudo apt-get install -f -y 2>&1 | tee -a "$LOG_FILE"; then
            log "INFO" "Dependencies resolved and package installed: $deb_file"
            return 0
        else
            log "ERROR" "Failed to install .deb package: $deb_file"
            return 1
        fi
    fi
}

create_desktop_entry() {
    local name="$1"
    local exec="$2"
    local icon="${3:-}"
    local desktop_file="/usr/share/applications/${name,,}.desktop"
    
    # Create safe desktop entry
    sudo tee "$desktop_file" > /dev/null <<EOF
[Desktop Entry]
Name=$name
Comment=$name Application
Exec=$exec
Icon=${icon:-$exec}
Type=Application
Categories=Game;
StartupNotify=true
Terminal=false
EOF
    log "INFO" "Created desktop entry for $name"
}

# ==================== COMPONENT INSTALLERS ====================
install_celeste() {
    print_status "$PURPLE" "🎮 Installing Celeste..."
    local celeste_dir="$HOME/games/celeste"
    mkdir -p "$celeste_dir"
    local celeste_zip="/tmp/celeste.zip"
    
    if ! secure_download "$CELESTE_URL" "$celeste_zip"; then
        print_status "$YELLOW" "⚠️  Celeste download failed. Skipping."
        return 1
    fi
    
    print_status "$BLUE" "Extracting Celeste (this may take a moment)..."
    if unzip -q "$celeste_zip" -d "$celeste_dir"; then
        # Make executable and find actual binary
        find "$celeste_dir" -name "Celeste" -type f -exec chmod +x {} \; 2>/dev/null || true
        
        # Look for the actual executable in subdirectories
        local celeste_exe=$(find "$celeste_dir" -name "Celeste" -type f -executable | head -1)
        
        if [[ -n "$celeste_exe" ]]; then
            create_desktop_entry "Celeste" "$celeste_exe" "$celeste_exe"
            rm -f "$celeste_zip"
            print_status "$GREEN" "✅ Celeste installed successfully!"
            return 0
        else
            log "ERROR" "Could not find Celeste executable after extraction"
            print_status "$YELLOW" "⚠️  Celeste extracted but executable not found. Check $celeste_dir"
        fi
    else
        log "ERROR" "Failed to extract Celeste. Zip may be corrupted or invalid."
        print_status "$RED" "❌ Celeste extraction failed"
        return 1
    fi
}

install_hollow_knight() {
    print_status "$PURPLE" "🎮 Installing Hollow Knight..."
    
    # Check if external SD card path exists, otherwise use home directory
    local sd_path="/mnt/chromeos/removable/devSD"
    local hk_dir
    
    if [[ -d "$sd_path" && -w "$sd_path" ]]; then
        hk_dir="$sd_path/hollow-knight"
        print_status "$BLUE" "Using external SD card for installation..."
    else
        hk_dir="$HOLLOW_KNIGHT_DIR"
        print_status "$YELLOW" "SD card not found. Installing to home directory..."
    fi
    
    mkdir -p "$hk_dir"
    local hk_zip="/tmp/hollow_knight.zip"
    
    if ! secure_download "$HOLLOW_KNIGHT_URL" "$hk_zip"; then
        print_status "$YELLOW" "⚠️  Hollow Knight download failed. Skipping."
        return 1
    fi
    
    if unzip -q "$hk_zip" -d "$hk_dir"; then
        find "$hk_dir" -name "Hollow_Knight" -type f -exec chmod +x {} \; 2>/dev/null || true
        
        local hk_exe=$(find "$hk_dir" -name "Hollow_Knight" -type f -executable | head -1)
        if [[ -n "$hk_exe" ]]; then
            create_desktop_entry "Hollow Knight" "$hk_exe" "$hk_exe"
            rm -f "$hk_zip"
            print_status "$GREEN" "✅ Hollow Knight installed successfully!"
            return 0
        else
            print_status "$YELLOW" "⚠️  Hollow Knight extracted but executable not found. Check $hk_dir"
        fi
    else
        log "ERROR" "Failed to extract Hollow Knight"
        return 1
    fi
}

install_olympus() {
    print_status "$PURPLE" "🔧 Installing Olympus Mod Manager..."
    install_package "love" || print_status "$YELLOW" "⚠️  Could not install LOVE framework"
    
    local olympus_url="https://github.com/EverestAPI/Olympus/releases/latest/download/olympus-linux.zip"
    local olympus_zip="/tmp/olympus.zip"
    local olympus_dir="$HOME/games/olympus"
    
    if ! secure_download "$olympus_url" "$olympus_zip"; then
        print_status "$YELLOW" "⚠️  Olympus download failed. Skipping."
        return 1
    fi
    
    mkdir -p "$olympus_dir"
    if unzip -q "$olympus_zip" -d "$olympus_dir"; then
        find "$olympus_dir" -name "olympus" -type f -exec chmod +x {} \; 2>/dev/null || true
        
        local olympus_exe=$(find "$olympus_dir" -name "olympus" -type f -executable | head -1)
        if [[ -n "$olympus_exe" ]]; then
            create_desktop_entry "Olympus" "$olympus_exe" "$olympus_exe"
            rm -f "$olympus_zip"
            print_status "$GREEN" "✅ Olympus installed successfully!"
            return 0
        else
            print_status "$YELLOW" "⚠️  Olympus extracted but executable not found. Check $olympus_dir"
        fi
    else
        log "ERROR" "Failed to extract Olympus"
        return 1
    fi
}

build_celeste_wasm() {
    print_status "$PURPLE" "🌐 Building Celeste WASM..."
    
    local available_ram=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if (( available_ram < 3072 )); then
        log "ERROR" "Insufficient RAM for WASM build. Need 3GB+, have ${available_ram}MB"
        print_status "$YELLOW" "⚠️  Skipping WASM build due to low RAM"
        return 1
    fi
    
    print_status "$BLUE" "Installing build dependencies..."
    install_package "git" || true
    install_package "mono-devel" || true
    install_package "curl" || true
    
    # Install pnpm if not present
    if ! command -v pnpm &>/dev/null; then
        log "INFO" "Installing pnpm..."
        curl -fsSL https://get.pnpm.io/install.sh | sh -
        export PNPM_HOME="$HOME/.local/share/pnpm"
        export PATH="$PNPM_HOME:$PATH"
        source ~/.bashrc 2>/dev/null || true
    fi
    
    # Install .NET SDK if not present
    if ! command -v dotnet &>/dev/null; then
        log "INFO" "Installing .NET SDK..."
        wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
        sudo dpkg -i /tmp/packages-microsoft-prod.deb 2>/dev/null || true
        sudo apt-get update -qq
        install_package "dotnet-sdk-8.0" || true  # Use stable 8.0 instead of 9.0
    fi
    
    local wasm_dir="$HOME/games/celeste-wasm"
    [[ -d "$wasm_dir" ]] && rm -rf "$wasm_dir"
    
    print_status "$BLUE" "Cloning Celeste WASM repository..."
    git clone --depth=1 https://github.com/MercuryWorkshop/celeste-wasm.git "$wasm_dir"
    cd "$wasm_dir"
    
    log "INFO" "Installing npm dependencies..."
    pnpm install --frozen-lockfile --silent || npm install
    
    log "INFO" "Building Celeste WASM (this will take 5-15 minutes)..."
    if make publish 2>&1 | tee -a "$LOG_FILE"; then
        if [[ -f "dist/index.html" ]]; then
            cd dist
            npx --yes inliner index.html > "$HOME/celeste-offline.html" 2>/dev/null || true
            print_status "$GREEN" "✅ Celeste WASM built successfully!"
            print_status "$BLUE" "   Offline version: ~/celeste-offline.html"
            print_status "$BLUE" "   Run with: cd $wasm_dir && make run"
            return 0
        fi
    fi
    
    log "ERROR" "Celeste WASM build failed"
    print_status "$RED" "❌ WASM build failed. Check logs for details."
    return 1
}

setup_wine() {
    print_status "$BLUE" "Setting up Wine..."
    
    # Add architecture and repository
    sudo dpkg --add-architecture i386
    sudo mkdir -pm755 /etc/apt/keyrings 2>/dev/null || true
    
    # Add WineHQ key
    if ! sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key 2>/dev/null; then
        log "ERROR" "Failed to add WineHQ key"
        return 1
    fi
    
    # Add WineHQ repository
    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
    
    sudo apt-get update
    
    # Install Wine with error handling
    if ! install_package "winehq-stable" "--install-recommends"; then
        log "WARNING" "WineHQ installation failed. Trying stable version from Debian..."
        install_package "wine" "--install-recommends" || true
    fi
}

setup_flatpak() {
    print_status "$BLUE" "Setting up Flatpak..."
    
    if ! install_package "flatpak"; then
        log "ERROR" "Failed to install Flatpak"
        return 1
    fi
    
    # Add Flathub repository
    flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || {
        log "WARNING" "Flathub repository may already exist"
    }
    
    # Install base apps with better error handling
    local base_apps=("com.discordapp.Discord" "org.kde.kdenlive")
    for app in "${base_apps[@]}"; do
        print_status "$BLUE" "Installing $app..."
        if flatpak install -y --user flathub "$app" 2>&1 | tee -a "$LOG_FILE"; then
            log "INFO" "Successfully installed: $app"
        else
            log "WARNING" "Failed to install $app (may not be compatible with your system)"
        fi
    done
    
    # Install Cura if selected
    [[ "${COMPONENTS[cura]}" == "true" ]] && install_cura
}

install_cura() {
    print_status "$PURPLE" "🖨️ Installing Ultimaker Cura..."
    if flatpak install -y --user flathub com.ultimaker.cura 2>&1 | tee -a "$LOG_FILE"; then
        print_status "$GREEN" "✅ Cura installed successfully!"
        return 0
    else
        log "ERROR" "Failed to install Cura"
        print_status "$YELLOW" "⚠️  Cura installation failed"
        return 1
    fi
}

install_gaming_tools() {
    print_status "$BLUE" "Installing gaming tools..."
    
    # Install ATLauncher - ensure Java is available first
    print_status "$BLUE" "Installing Java for ATLauncher..."
    install_package "openjdk-17-jre" || install_package "default-jre" || true
    
    local atlauncher_url="https://github.com/cyb3rw0lf-3D/crostini-jumpstart/raw/main/atlauncher-1.4-1.deb"
    local atlauncher_deb="/tmp/atlauncher.deb"
    
    if secure_download "$atlauncher_url" "$atlauncher_deb"; then
        install_deb_package "$atlauncher_deb"
        rm -f "$atlauncher_deb"
    else
        log "WARNING" "ATLauncher download failed"
        print_status "$YELLOW" "⚠️  ATLauncher download failed. You can install it manually later."
    fi
    
    # Install qBittorrent
    install_package "qbittorrent" || print_status "$YELLOW" "⚠️  qBittorrent installation failed"
}

install_dev_tools() {
    print_status "$BLUE" "Installing development tools..."
    
    # Skip if low RAM
    if [[ "$SKIP_DEV" == "true" ]]; then
        log "WARNING" "Skipping dev tools due to low RAM"
        print_status "$YELLOW" "⚠️  Skipping dev tools (low RAM)"
        return 0
    fi
    
    # Install VS Code
    local vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
    local vscode_deb="/tmp/vscode.deb"
    
    if secure_download "$vscode_url" "$vscode_deb"; then
        install_deb_package "$vscode_deb"
        create_desktop_entry "VS Code" "/usr/share/code/code --no-sandbox" "code"
        rm -f "$vscode_deb"
    else
        log "WARNING" "VS Code download failed"
        print_status "$YELLOW" "⚠️  VS Code download failed"
    fi
    
    # Install other dev tools
    local dev_packages=("git" "build-essential" "python3-pip" "nodejs" "npm" "curl")
    for pkg in "${dev_packages[@]}"; do
        install_package "$pkg" || print_status "$YELLOW" "⚠️  Failed to install $pkg"
    done
}

install_multimedia_tools() {
    print_status "$BLUE" "Installing multimedia tools..."
    
    # Skip if low RAM
    if [[ "$SKIP_MULTIMEDIA" == "true" ]]; then
        log "WARNING" "Skipping multimedia tools due to low RAM"
        print_status "$YELLOW" "⚠️  Skipping Kdenlive (low RAM)"
        return 0
    fi
    
    # Install Kdenlive
    if ! install_package "kdenlive"; then
        log "ERROR" "Kdenlive installation failed"
        print_status "$RED" "❌ Kdenlive installation failed"
        return 1
    fi
    
    # Try to install LMMS with KXStudio repo
    local kxstudio_deb="/tmp/kxstudio-repos.deb"
    if secure_download "https://launchpad.net/~kxstudio-debian/+archive/kxstudio/+files/kxstudio-repos_11.2.0_all.deb" "$kxstudio_deb"; then
        if install_deb_package "$kxstudio_deb"; then
            sudo apt-get update
            install_package "lmms" || true
        fi
        rm -f "$kxstudio_deb"
    fi
}

optimize_system() {
    print_status "$BLUE" "Optimizing system..."
    
    # Replace vim-tiny with full vim
    sudo apt-get remove -y vim-tiny 2>/dev/null || true
    
    local utils=("nano" "vim" "neovim" "htop" "tree" "unzip" "curl" "wget" "zip")
    for util in "${utils[@]}"; do
        install_package "$util" || true
    done
    
    # Clean up
    sudo apt-get autoremove -y
    sudo apt-get clean
}

security_hardening() {
    print_status "$BLUE" "Applying security hardening..."
    
    # Secure SSH
    if [[ -d ~/.ssh ]]; then
        chmod 700 ~/.ssh 2>/dev/null || true
        chmod 600 ~/.ssh/* 2>/dev/null || true
    fi
    
    # Install and configure UFW
    if install_package "ufw"; then
        sudo ufw default deny incoming 2>/dev/null || true
        sudo ufw default allow outgoing 2>/dev/null || true
        sudo ufw --force enable 2>/dev/null || true
    fi
    
    # Install fail2ban
    if install_package "fail2ban"; then
        sudo systemctl enable fail2ban 2>/dev/null || true
        sudo systemctl start fail2ban 2>/dev/null || true
    fi
}

comprehensive_cleanup() {
    print_status "$YELLOW" "🧹 Starting comprehensive cleanup..."
    
    # Clean package cache
    sudo apt-get autoremove -y
    sudo apt-get clean
    
    # Remove temp files
    rm -rf /tmp/crostini-* /tmp/celeste-* /tmp/hollow-* /tmp/olympus-* /tmp/vscode-* /tmp/atlauncher-* "$DOWNLOAD_DIR"
    
    # Clean old logs (keep last 5)
    find /tmp -name "crostini-jumpstart*.log" -type f | sort -r | tail -n +6 | xargs rm -f 2>/dev/null || true
    
    # Clean user caches
    [[ -d "$HOME/.cache" ]] && find "$HOME/.cache" -type f -mtime +7 -delete 2>/dev/null || true
    [[ -d "$HOME/.thumbnails" ]] && rm -rf "$HOME/.thumbnails"/* 2>/dev/null || true
    
    # Clean apt archives older than 1 day
    sudo find /var/cache/apt/archives -type f -name "*.deb" -mtime +1 -delete 2>/dev/null || true
    
    print_status "$GREEN" "✅ Cleanup completed! Freed up disk space."
}

create_user_config() {
    print_status "$BLUE" "Creating user configuration..."
    
    # Create config directories
    mkdir -p ~/projects ~/downloads ~/games ~/celeste-mods
    
    # Add useful aliases to bashrc
    if ! grep -q "Crostini Jumpstart Aliases" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# Crostini Jumpstart Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias update='sudo apt update && sudo apt upgrade -y'
alias clean='sudo apt autoremove -y && sudo apt clean'
alias ports='netstat -tuln'
alias myip='hostname -I'
alias celeste='cd ~/games/celeste && ./Celeste'
alias olympus='cd ~/games/olympus && ./olympus'
alias hollowknight='cd ~/games/hollow-knight && ./Hollow_Knight'
alias rm='rm -i'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias celeste-wasm='cd ~/games/celeste-wasm && make run'
alias build-celeste-wasm='cd ~/games/celeste-wasm && make publish'
EOF
    fi
    
    log "INFO" "User configuration created"
}

# ==================== INTERACTIVE MENUS ====================
interactive_main_menu() {
    print_status "$CYAN" "🚀 Crostini Jumpstart Setup Menu"
    echo ""
    
    ask_yes_no "📦 Setup Wine compatibility layer?" && COMPONENTS[wine]=true
    ask_yes_no "📦 Setup Flatpak with app store?" && COMPONENTS[flatpak]=true
    [[ "$SKIP_MULTIMEDIA" != "true" ]] && ask_yes_no "🎨 Install multimedia tools?" && COMPONENTS[multimedia]=true
    [[ "$SKIP_DEV" != "true" ]] && ask_yes_no "💻 Install development tools?" && COMPONENTS[dev]=true
    ask_yes_no "🎮 Install gaming tools?" && COMPONENTS[gaming]=true
    ask_yes_no "🔒 Apply security hardening?" && COMPONENTS[security]=true
    ask_yes_no "⚡ Run system optimization?" && COMPONENTS[optimization]=true
    
    [[ "${COMPONENTS[flatpak]}" == "true" ]] && {
        echo ""
        print_status "$YELLOW" "Flatpak Apps:"
        ask_yes_no "  Install Ultimaker Cura (3D printing)?" && COMPONENTS[cura]=true
    }
    
    echo ""
    ask_yes_no "🎮 Install games?" && COMPONENTS[games]=true
    
    [[ "${COMPONENTS[games]}" == "true" ]] && {
        echo ""
        interactive_game_menu
    }
    
    echo ""
    ask_yes_no "🔧 Install modding tools?" && COMPONENTS[mods]=true
    
    [[ "${COMPONENTS[mods]}" == "true" ]] && {
        echo ""
        print_status "$YELLOW" "Note: Olympus includes Everest support for Celeste modding"
    }
    
    echo ""
    ask_yes_no "🧹 Run final cleanup?" && COMPONENTS[cleanup]=true
}

interactive_game_menu() {
    print_status "$CYAN" "🎮 Game Selection Menu"
    echo ""
    
    ask_yes_no "  Install Celeste (Original)?" && GAMES[celeste]=true
    ask_yes_no "  Install Hollow Knight?" && GAMES[hollowknight]=true
    ask_yes_no "  Install Celeste 64 (via Flatpak)?" && GAMES[celeste64]=true
    
    [[ "$SKIP_MULTIMEDIA" != "true" ]] && [[ "$SKIP_DEV" != "true" ]] && \
        ask_yes_no "  Build Celeste WASM (requires ~3GB RAM)?" && GAMES[celeste-wasm]=true
}

# ==================== EXECUTION LOGIC ====================
execute_selected_components() {
    print_status "$BLUE" "Executing selected components..."
    echo ""
    
    # Execute components in order of dependency
    for component in wine flatpak gaming multimedia dev security optimization; do
        if [[ "${COMPONENTS[$component]}" == "true" ]]; then
            print_status "$BLUE" "Installing $component..."
            
            case $component in
                wine) setup_wine ;;
                flatpak) setup_flatpak ;;
                gaming) install_gaming_tools ;;
                multimedia) [[ "$SKIP_MULTIMEDIA" != "true" ]] && install_multimedia_tools ;;
                dev) [[ "$SKIP_DEV" != "true" ]] && install_dev_tools ;;
                security) security_hardening ;;
                optimization) optimize_system ;;
            esac
            
            echo ""
        fi
    done
    
    # Install games
    if [[ "${COMPONENTS[games]}" == "true" ]]; then
        print_status "$BLUE" "Installing games..."
        
        [[ "${GAMES[celeste]}" == "true" ]] && install_celeste
        [[ "${GAMES[hollowknight]}" == "true" ]] && install_hollow_knight
        [[ "${GAMES[celeste64]}" == "true" ]] && {
            flatpak install -y --user flathub com.exok.Celeste64 2>/dev/null || \
                print_status "$YELLOW" "⚠️  Celeste 64 not available for your architecture"
        }
        [[ "${GAMES[celeste-wasm]}" == "true" ]] && build_celeste_wasm
        
        echo ""
    fi
    
    # Install modding tools
    if [[ "${COMPONENTS[mods]}" == "true" ]]; then
        print_status "$BLUE" "Installing modding tools..."
        install_olympus
        echo ""
    fi
    
    # Create user config
    create_user_config
    
    # Final cleanup
    if [[ "${COMPONENTS[cleanup]}" == "true" ]]; then
        print_status "$BLUE" "Running final cleanup..."
        comprehensive_cleanup
        echo ""
    fi
}

# ==================== MAIN ====================
main() {
    print_banner
    
    # Initialize log
    echo "Crostini Jumpstart - $(date)" > "$LOG_FILE"
    echo "Version: $SCRIPT_VERSION" >> "$LOG_FILE"
    echo "User: $(whoami)" >> "$LOG_FILE"
    echo "------------------------" >> "$LOG_FILE"
    
    # Check system first
    if ! check_system; then
        print_status "$RED" "❌ System check failed. Please address issues and try again."
        print_status "$BLUE" "Log: $LOG_FILE"
        exit 1
    fi
    
    # Update system
    print_status "$BLUE" "Updating system packages..."
    if ! sudo apt-get update -y 2>&1 | tee -a "$LOG_FILE"; then
        log "ERROR" "Failed to update package lists"
        print_status "$RED" "❌ Update failed. Check internet connection."
        exit 1
    fi
    
    # Full upgrade
    print_status "$BLUE" "Upgrading existing packages..."
    sudo apt-get full-upgrade -y 2>&1 | tee -a "$LOG_FILE" || log "WARNING" "Some upgrades failed"
    
    # Show interactive menu
    interactive_main_menu
    
    # Confirm before proceeding
    echo ""
    if ! ask_yes_no "Proceed with installation?"; then
        print_status "$YELLOW" "Installation cancelled by user."
        exit 0
    fi
    
    # Execute everything
    execute_selected_components
    
    # Final summary
    echo ""
    print_status "$GREEN" "🎉 Crostini Setup Complete!"
    print_status "$BLUE" "📄 Log file: $LOG_FILE"
    
    echo -e "\n${GREEN}Installed Components:${NC}"
    for component in "${!COMPONENTS[@]}"; do
        [[ "${COMPONENTS[$component]}" == "true" ]] && echo -e "  ✅ ${component}"
    done
    
    if [[ "${COMPONENTS[games]}" == "true" ]]; then
        echo -e "\n${GREEN}Installed Games:${NC}"
        for game in "${!GAMES[@]}"; do
            [[ "${GAMES[$game]}" == "true" ]] && echo -e "  🎮 ${game}"
        done
    fi
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "  • Restart terminal: exec bash"
    echo -e "  • Use 'celeste' or 'olympus' commands"
    echo -e "  • Run 'update' to update packages"
    echo -e "  • Run 'clean' to clean up"
    echo -e "  • Check log for any warnings: less $LOG_FILE"
}

# ==================== ARGUMENT PARSING ====================
AUTO_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Crostini Jumpstart v$SCRIPT_VERSION"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --auto                    Install recommended components non-interactively"
            echo "  --skip-COMPONENT          Skip specific component (e.g., --skip-wine)"
            echo "  --install-COMPONENT       Install only one component (e.g., --install-gaming)"
            echo "  -c, --check               Run system checks only"
            echo "  --cleanup                 Run cleanup only"
            echo ""
            echo "Components: wine, flatpak, gaming, multimedia, dev, security, optimization, cleanup"
            echo ""
            echo "Examples:"
            echo "  $0 --auto"
            echo "  $0 --skip-wine --skip-multimedia"
            echo "  $0 --install-gaming"
            exit 0
            ;;
        --auto)
            AUTO_MODE=true
            # Set sensible defaults for auto mode
            COMPONENTS[wine]=false  # Wine is large, let user opt-in
            COMPONENTS[flatpak]=true
            COMPONENTS[gaming]=true
            COMPONENTS[multimedia]=true
            COMPONENTS[dev]=false
            COMPONENTS[security]=true
            COMPONENTS[optimization]=true
            COMPONENTS[cleanup]=true
            
            # Auto-disable based on RAM
            if [[ "$SKIP_MULTIMEDIA" != "true" ]]; then
                COMPONENTS[multimedia]=true
            else
                COMPONENTS[multimedia]=false
            fi
            
            if [[ "$SKIP_DEV" != "true" ]]; then
                COMPONENTS[dev]=true
            else
                COMPONENTS[dev]=false
            fi
            ;;
        --skip-*)
            local comp="${1#--skip-}"
            if [[ -n "${COMPONENTS[$comp]:-}" ]]; then
                COMPONENTS[$comp]=false
                log "INFO" "Skipping $comp"
            fi
            ;;
        --install-*)
            # Disable all, then enable one
            for key in "${!COMPONENTS[@]}"; do COMPONENTS[$key]=false; done
            local comp="${1#--install-}"
            if [[ -n "${COMPONENTS[$comp]:-}" ]]; then
                COMPONENTS[$comp]=true
                log "INFO" "Installing only $comp"
            fi
            ;;
        -c|--check)
            check_system
            exit $?
            ;;
        --cleanup)
            comprehensive_cleanup
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# Run main function
main "$@"

# Print any errors at the end
if [[ -f "$LOG_FILE" ]] && grep -q "ERROR" "$LOG_FILE"; then
    echo ""
    print_status "$YELLOW" "⚠️  Some components had warnings/errors. Check the log:"
    print_status "$BLUE" "   less $LOG_FILE"
    print_status "$YELLOW" "   grep ERROR $LOG_FILE"
fi
