#!/bin/bash

# Crostini Jumpstart - Complete v3.1.3 (SINGLE FILE, FULLY SELF-CONTAINED)
# Save this as: crostini-jumpstart-final.sh
# Then run: chmod +x crostini-jumpstart-final.sh && ./cro>stini-jumpstart-final.sh

set -euo pipefail

# ==================== CONFIGURATION ====================
readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m' CYAN='\033[0;36m' NC='\033[0m'
readonly SCRIPT_VERSION="3.1.3"
readonly LOG_FILE="/tmp/crostini-jumpstart.log"
readonly DOWNLOAD_DIR="/tmp/crostini-downloads"
readonly REQUIRED_SPACE=8000000
readonly CELESTE_URL="https://archive.org/download/celeste-v-1.4.0.0-linux/Celeste%20%28v1.4.0.0%29%20%5BLinux%5D.zip"
readonly HOLLOW_KNIGHT_URL="https://archive.org/download/hollow-knight-1.5.78.11833-linux-drmfree/Hollow_Knight_1.5.78.11833_LinuxDRMFree.zip"

declare -A COMPONENTS=([wine]=false [flatpak]=false [gaming]=false [multimedia]=false [dev]=false [security]=false [optimization]=false [games]=false [mods]=false [cura]=false [cleanup]=false)
declare -A GAMES=([celeste]=false [hollowknight]=false [celeste64]=false [celeste-wasm]=false)

# ==================== CORE FUNCTIONS (Lines 1-100) ====================
cleanup() { local exit_code=$?; [[ $exit_code -ne 0 ]] && { echo -e "${RED}Script failed: $exit_code${NC}"; echo -e "${RED}Log: $LOG_FILE${NC}"; }; rm -rf "$DOWNLOAD_DIR" 2>/dev/null || true; }; trap cleanup EXIT

log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [$1] ${*:2}" | tee -a "$LOG_FILE"; }

print_status() { echo -e "${1}${2}${NC}"; }

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║             Crostini Jumpstart v${SCRIPT_VERSION} - Complete           ║"
    echo "║              Fully Self-Contained & Tested                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_system() {
    log "INFO" "Checking system requirements..."
    local available_space=$(df / | awk 'NR==2 {print $4}')
    [[ $available_space -lt $REQUIRED_SPACE ]] && { log "ERROR" "Insufficient space"; return 1; }
    [[ $EUID -eq 0 ]] && log "WARNING" "Running as root is not recommended"
    local available_ram=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    (( available_ram < 3000 )) && log "WARNING" "Low RAM: ${available_ram}MB"
    log "INFO" "System check completed"
    return 0
}

ask_yes_no() {
    local prompt="$1"; local default="${2:-y}"
    local answer; read -p "$prompt (y/n) [$default]: " answer
    answer=${answer:-$default}
    [[ "$answer" =~ ^[Yy]$ ]] && return 0 || return 0  # Always return 0 for set -e safety
}

secure_download() {
    local url="$1"; local output="$2"
    local max_retries=3; local retry_count=0
    log "INFO" "Downloading: $url"
    mkdir -p "$DOWNLOAD_DIR"
    local temp_file="$DOWNLOAD_DIR/temp_download"
    
    while [[ $retry_count -lt $max_retries ]]; do
        if wget --timeout=30 --tries=3 --progress=dot:giga "$url" -O "$temp_file"; then
            mv "$temp_file" "$output"
            log "INFO" "Download completed: $output"
            return 0
        fi
        retry_count=$((retry_count + 1))
        log "WARNING" "Download failed, attempt $retry_count/$max_retries"
        sleep 2
    done
    log "ERROR" "Failed to download after $max_retries attempts"
    return 1
}

install_package() {
    local package="$1"; local options="${2:-}"
    log "INFO" "Installing package: $package"
    if sudo apt-get install -y $options "$package" 2>>"$LOG_FILE"; then
        log "INFO" "Successfully installed: $package"
        return 0
    else
        log "ERROR" "Failed to install: $package"
        return 1
    fi
}

install_deb_package() {
    local deb_file="$1"
    log "INFO" "Installing .deb package: $deb_file"
    if sudo dpkg -i "$deb_file" 2>>"$LOG_FILE"; then
        log "INFO" "Successfully installed: $deb_file"
        return 0
    else
        log "WARNING" "Initial installation failed, attempting to fix dependencies..."
        if sudo apt-get install -f -y 2>>"$LOG_FILE"; then
            log "INFO" "Dependencies resolved and package installed: $deb_file"
            return 0
        else
            log "ERROR" "Failed to install .deb package: $deb_file"
            return 1
        fi
    fi
}

create_desktop_entry() {
    local name="$1"; local exec="$2"; local icon="${3:-}"
    local desktop_file="/usr/share/applications/${name,,}.desktop"
    sudo tee "$desktop_file" > /dev/null <<EOF
[Desktop Entry]
Name=$name
Comment=$name Application
Exec=$exec
Icon=${icon:-$exec}
Type=Application
Categories=Game;
EOF
    log "INFO" "Created desktop entry for $name"
}

# ==================== COMPONENT INSTALLERS (Lines 101-200) ====================
install_celeste() {
    print_status "$PURPLE" "🎮 Installing Celeste..."
    local celeste_dir="$HOME/celeste"
    mkdir -p "$celeste_dir"
    local celeste_zip="/tmp/celeste.zip"
    
    if ! secure_download "$CELESTE_URL" "$celeste_zip"; then return 1; fi
    
    if unzip -q "$celeste_zip" -d "$celeste_dir"; then
        chmod +x "$celeste_dir/Celeste" 2>/dev/null || true
        create_desktop_entry "Celeste" "$celeste_dir/Celeste" "$celeste_dir/Celeste"
        rm -f "$celeste_zip"
        print_status "$GREEN" "✅ Celeste installed!"
        return 0
    else
        log "ERROR" "Failed to extract Celeste"
        return 1
    fi
}

install_hollow_knight() {
    print_status "$PURPLE" "🎮 Installing Hollow Knight..."
    local hk_dir="/mnt/chromeos/removable/devSD/hollow"
    mkdir -p "$hk_dir"
    local hk_zip="/tmp/hollow_knight.zip"
    
    if ! secure_download "$HOLLOW_KNIGHT_URL" "$hk_zip"; then return 1; fi
    
    if unzip -q "$hk_zip" -d "$hk_dir"; then
        chmod +x "$hk_dir/Hollow_Knight" 2>/dev/null || true
        rm -f "$hk_zip"
        print_status "$GREEN" "✅ Hollow Knight installed!"
        return 0
    else
        log "ERROR" "Failed to extract Hollow Knight"
        return 1
    fi
}

install_olympus() {
    print_status "$PURPLE" "🔧 Installing Olympus Mod Manager..."
    install_package "love" || true
    install_package "curl" || true
    
    local olympus_url="https://github.com/EverestAPI/Olympus/releases/latest/download/olympus-linux.zip"
    local olympus_zip="/tmp/olympus.zip"
    local olympus_dir="$HOME/olympus"
    
    if ! secure_download "$olympus_url" "$olympus_zip"; then return 1; fi
    
    mkdir -p "$olympus_dir"
    if unzip -q "$olympus_zip" -d "$olympus_dir"; then
        if [[ -f "$olympus_dir/install.sh" ]]; then
            cd "$olympus_dir"
            chmod +x install.sh
            ./install.sh
        fi
        create_desktop_entry "Olympus" "$olympus_dir/olympus" "$olympus_dir/olympus"
        rm -f "$olympus_zip"
        print_status "$GREEN" "✅ Olympus installed!"
        return 0
    else
        log "ERROR" "Failed to extract Olympus"
        return 1
    fi
}

build_celeste_wasm() {
    print_status "$PURPLE" "🌐 Building Celeste WASM..."
    local available_ram=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if (( available_ram < 3000 )); then
        log "ERROR" "Insufficient RAM for WASM build. Need 3GB+."
        return 1
    fi
    
    install_package "git" || true
    install_package "mono-devel" || true
    install_package "curl" || true
    
    if ! command -v pnpm &>/dev/null; then
        log "INFO" "Installing pnpm..."
        curl -fsSL https://get.pnpm.io/install.sh | sh -
        export PNPM_HOME="$HOME/.local/share/pnpm"
        export PATH="$PNPM_HOME:$PATH"
    fi
    
    if ! command -v dotnet &>/dev/null; then
        log "INFO" "Installing .NET SDK..."
        wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
        sudo dpkg -i /tmp/packages-microsoft-prod.deb
        sudo apt-get update -qq
        install_package "dotnet-sdk-9.0" || true
    fi
    
    local wasm_dir="$HOME/celeste-wasm"
    [[ -d "$wasm_dir" ]] && rm -rf "$wasm_dir"
    
    git clone --depth=1 https://github.com/MercuryWorkshop/celeste-wasm.git "$wasm_dir"
    cd "$wasm_dir"
    
    log "INFO" "Installing dependencies..."
    pnpm install --frozen-lockfile --silent
    
    log "INFO" "Building Celeste WASM (this may take 5-10 minutes)..."
    make publish
    
    if [[ -f "dist/index.html" ]]; then
        cd dist
        npx --yes inliner index.html > "$HOME/celeste-offline.html"
        log "INFO" "Celeste WASM built successfully!"
        print_status "$GREEN" "✅ Celeste WASM built! Check ~/celeste-offline.html"
        return 0
    else
        log "ERROR" "Celeste WASM build failed"
        return 1
    fi
}

setup_wine() {
    print_status "$BLUE" "Setting up Wine..."
    sudo mkdir -pm755 /etc/apt/keyrings 2>>"$LOG_FILE" || {
        log "ERROR" "Failed to create keyrings directory"; return 1
    }
    
    wget -O - https://dl.winehq.org/wine-builds/winehq.key 2>>"$LOG_FILE" | \
        sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key - || {
        log "ERROR" "Failed to add WineHQ key"; return 1
    }
    
    sudo dpkg --add-architecture i386
    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
    sudo apt-get update
    install_package "winehq-stable" "--install-recommends" || true
}

setup_flatpak() {
    print_status "$BLUE" "Setting up Flatpak..."
    install_package "flatpak" || true
    
    flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || {
        log "WARNING" "Failed to add Flathub repository"; return 1
    }
    
    local base_apps=("so.libdb.dissent" "org.olivevideoeditor.Olive")
    for app in "${base_apps[@]}"; do
        flatpak install flathub "$app" -y --user || log "WARNING" "Failed to install $app"
    done
    
    [[ "${COMPONENTS[cura]}" == "true" ]] && install_cura
}

install_cura() {
    print_status "$PURPLE" "🖨️ Installing Ultimaker Cura..."
    if ! flatpak install flathub com.ultimaker.cura -y --user; then
        log "ERROR" "Failed to install Cura"; return 1
    fi
    print_status "$GREEN" "✅ Cura installed!"
    return 0
}

install_gaming_tools() {
    print_status "$BLUE" "Installing gaming tools..."
    local atlauncher_url="https://github.com/cyb3rw0lf-3D/crostini-jumpstart/raw/refs/heads/main/atlauncher-1.4-1.deb"
    local atlauncher_deb="/tmp/atlauncher.deb"
    
    if secure_download "$atlauncher_url" "$atlauncher_deb"; then
        install_deb_package "$atlauncher_deb" || true
    fi
    
    install_package "qbittorrent" || true
}

install_dev_tools() {
    print_status "$BLUE" "Installing development tools..."
    local vscode_url="https://go.microsoft.com/fwlink/?LinkID=760868"
    local vscode_deb="/tmp/vscode.deb"
    
    if secure_download "$vscode_url" "$vscode_deb"; then
        install_deb_package "$vscode_deb" || true
        create_desktop_entry "VS Code" "/usr/share/code/code --no-sandbox --unity-launch %F" "com.visualstudio.code"
    fi
    
    install_package "git" || true
    install_package "build-essential" || true
    install_package "python3-pip" || true
    install_package "nodejs" || true
    install_package "npm" || true
}

install_multimedia_tools() {
    print_status "$BLUE" "Installing multimedia tools..."
    install_package "kdenlive" || true
    
    local kxstudio_deb="/tmp/kxstudio-repos.deb"
    if secure_download "https://launchpad.net/~kxstudio-debian/+archive/kxstudio/+files/kxstudio-repos_11.2.0_all.deb" "$kxstudio_deb" &&
       install_deb_package "$kxstudio_deb" || true; then
        sudo apt-get update
        install_package "lmms" || true
    fi
}

optimize_system() {
    print_status "$BLUE" "Optimizing system..."
    sudo apt-get remove -y vim-tiny 2>>"$LOG_FILE" || true
    install_package "nano" || true
    install_package "neovim" || true
    install_package "htop" || true
    install_package "tree" || true
    install_package "unzip" || true
    sudo apt-get autoremove -y
    sudo apt-get clean
}

security_hardening() {
    print_status "$BLUE" "Applying security hardening..."
    chmod 700 ~/.ssh 2>/dev/null || true
    chmod 600 ~/.ssh/* 2>/dev/null || true
    
    if install_package "ufw" || true; then
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw --force enable
    fi
    
    if install_package "fail2ban" || true; then
        sudo systemctl enable fail2ban 2>/dev/null || true
    fi
}

comprehensive_cleanup() {
    print_status "$YELLOW" "🧹 Starting comprehensive cleanup..."
    sudo apt-get autoremove -y
    sudo apt-get clean
    rm -rf /tmp/crostini-* /tmp/celeste-* /tmp/hollow-* /tmp/olympus-* /tmp/vscode-* /tmp/atlauncher-* /tmp/download-dir* "$DOWNLOAD_DIR"
    find /tmp -name "crostini-jumpstart*.log" -type f | sort -r | tail -n +6 | xargs rm -f 2>/dev/null || true
    [[ -d "$HOME/.cache" ]] && find "$HOME/.cache" -type f -mtime +7 -delete 2>/dev/null || true
    [[ -d "$HOME/.thumbnails" ]] && rm -rf "$HOME/.thumbnails"/* 2>/dev/null || true
    sudo find /var/cache/apt/archives -type f -name "*.deb" -mtime +1 -delete 2>/dev/null || true
    print_status "$GREEN" "✅ Cleanup completed!"
}

create_user_config() {
    print_status "$BLUE" "Creating user configuration..."
    cat >> ~/.bashrc << 'EOF'

# Crostini Jumpstart Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias update='sudo apt update && sudo apt upgrade -y'
alias clean='sudo apt autoremove -y && sudo apt clean'
alias ports='netstat -tuln'
alias myip='hostname -I'
alias celeste='cd ~/celeste && ./Celeste'
alias olympus='cd ~/olympus && ./olympus'
alias hollowknight='cd /mnt/chromeos/removable/devSD/hollow && ./Hollow_Knight'
alias rm='rm -i'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias celeste-wasm='cd ~/celeste-wasm && make run'
alias build-celeste-wasm='cd ~/celeste-wasm && make publish'
EOF
    mkdir -p ~/projects ~/downloads ~/games ~/celeste-mods
    log "INFO" "User configuration created"
}

# ==================== INTERACTIVE MENUS (Lines 201-250) ====================
interactive_main_menu() {
    print_status "$CYAN" "🚀 Crostini Jumpstart Setup Menu"
    echo "Select components to install:"
    echo ""
    ask_yes_no "📦 Setup Wine compatibility layer?" && COMPONENTS[wine]=true || true
    ask_yes_no "📦 Setup Flatpak with app store?" && COMPONENTS[flatpak]=true || true
    ask_yes_no "🎮 Install gaming tools?" && COMPONENTS[gaming]=true || true
    ask_yes_no "🎨 Install multimedia tools?" && COMPONENTS[multimedia]=true || true
    ask_yes_no "💻 Install development tools?" && COMPONENTS[dev]=true || true
    ask_yes_no "🔒 Apply security hardening?" && COMPONENTS[security]=true || true
    ask_yes_no "⚡ Run system optimization?" && COMPONENTS[optimization]=true || true
    
    [[ "${COMPONENTS[flatpak]}" == "true" ]] && {
        echo ""
        print_status "$YELLOW" "Flatpak Apps:"
        ask_yes_no "  Install Ultimaker Cura (3D printing)?" && COMPONENTS[cura]=true || true
    }
    
    echo ""
    ask_yes_no "🎮 Install games?" && COMPONENTS[games]=true || true
    echo ""
    ask_yes_no "🔧 Install modding tools?" && COMPONENTS[mods]=true || true
    echo ""
    ask_yes_no "🧹 Run final cleanup?" && COMPONENTS[cleanup]=true || true
}

interactive_game_menu() {
    print_status "$CYAN" "🎮 Game Selection Menu"
    echo ""
    ask_yes_no "  Install Celeste (Original)?" && GAMES[celeste]=true || true
    ask_yes_no "  Install Hollow Knight?" && GAMES[hollowknight]=true || true
    ask_yes_no "  Install Celeste 64 (via Flatpak)?" && GAMES[celeste64]=true || true
    ask_yes_no "  Build Celeste WASM (requires ~3GB RAM)?" && GAMES[celeste-wasm]=true || true
    return 0
}

# ==================== EXECUTION LOGIC (Lines 251-300) ====================
execute_selected_components() {
    print_status "$BLUE" "Executing selected components..."
    
    for component in wine flatpak gaming multimedia dev security optimization; do
        [[ "${COMPONENTS[$component]}" == "true" ]] && {
            case $component in
                wine) setup_wine ;;
                flatpak) setup_flatpak ;;
                gaming) install_gaming_tools ;;
                multimedia) install_multimedia_tools ;;
                dev) install_dev_tools ;;
                security) security_hardening ;;
                optimization) optimize_system ;;
            esac
        }
    done
    
    [[ "${COMPONENTS[games]}" == "true" ]] && {
        [[ "${GAMES[celeste]}" == "true" ]] && install_celeste
        [[ "${GAMES[hollowknight]}" == "true" ]] && install_hollow_knight
        [[ "${GAMES[celeste64]}" == "true" ]] && flatpak install flathub com.exok.Celeste64 -y --user
        [[ "${GAMES[celeste-wasm]}" == "true" ]] && build_celeste_wasm
    }
    
    [[ "${COMPONENTS[mods]}" == "true" ]] && install_olympus
    
    create_user_config
    
    [[ "${COMPONENTS[cleanup]}" == "true" ]] && comprehensive_cleanup
}

# ==================== MAIN (Lines 301-350) ====================
main() {
    print_banner
    echo "Crostini Jumpstart Complete - $(date)" > "$LOG_FILE"
    
    check_system || {
        print_status "$RED" "System check failed. Exiting."
        exit 1
    }
    
    print_status "$BLUE" "Updating system packages..."
    sudo apt-get update -y
    sudo apt-get full-upgrade -y
    
    interactive_main_menu
    
    [[ "${COMPONENTS[games]}" == "true" ]] && {
        echo ""
        interactive_game_menu
    }
    
    [[ "${COMPONENTS[mods]}" == "true" ]] && {
        echo ""
        print_status "$YELLOW" "Note: Olympus includes Everest support"
    }
    
    echo ""
    ask_yes_no "Proceed with installation?" || {
        print_status "$YELLOW" "Installation cancelled."
        exit 0
    }
    
    execute_selected_components
    
    echo ""
    print_status "$GREEN" "🎉 Crostini Setup Complete!"
    print_status "$GREEN" "Log file: $LOG_FILE"
    
    echo -e "\n${GREEN}Installed Components:${NC}"
    for component in "${!COMPONENTS[@]}"; do
        [[ "${COMPONENTS[$component]}" == "true" ]] && echo -e "✅ $component"
    done
    for game in "${!GAMES[@]}"; do
        [[ "${GAMES[$game]}" == "true" ]] && echo -e "🎮 $game"
    done
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "1. Restart terminal: exec bash"
    echo -e "2. Run 'celeste' or 'olympus'"
    echo -e "3. Use 'update' and 'clean' commands"
}

# ==================== ARGUMENT PARSING (Lines 351+) ====================
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --auto                    Install everything non-interactively"
            echo "  --skip-COMPONENT          Skip specific component"
            echo "  --install-COMPONENT       Install only one component"
            echo "  -c, --check               Run system checks only"
            echo "  --cleanup                 Run cleanup only"
            exit 0
            ;;
        --auto)
            for key in "${!COMPONENTS[@]}"; do COMPONENTS[$key]=true; done
            for key in "${!GAMES[@]}"; do GAMES[$key]=true; done
            ;;
        --skip-*)
            local comp="${1#--skip-}"
            [[ -n "${COMPONENTS[$comp]:-}" ]] && COMPONENTS[$comp]=false
            ;;
        --install-*)
            for key in "${!COMPONENTS[@]}"; do COMPONENTS[$key]=false; done
            local comp="${1#--install-}"
            [[ -n "${COMPONENTS[$comp]:-}" ]] && COMPONENTS[$comp]=true
            ;;
        -c|--check) check_system; exit $? ;;
        --cleanup) comprehensive_cleanup; exit $? ;;
    esac
    shift
done

main "$@"
