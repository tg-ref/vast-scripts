#!/bin/bash
# Universal ComfyUI Setup and Diagnostic Script
# GitHub-based deployment for Vast.ai instances

# Configuration
GITHUB_REPO="DnsSrinath/vast-scripts"
BASE_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main"
WORKSPACE="/workspace"
COMFYUI_DIR="${WORKSPACE}/ComfyUI"
DIAGNOSTIC_LOG="${WORKSPACE}/comfyui_universal_setup.log"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging function
log() {
    local message="$1"
    local color="${2:-$NC}"
    local log_level="${3:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    echo -e "${color}[${timestamp}] $message${NC}"
    echo "[${timestamp}] [$log_level] $message" >> "$DIAGNOSTIC_LOG"
}

# Error handling
error_exit() {
    log "CRITICAL ERROR: $1" "$RED" "ERROR"
    exit 1
}

# Prepare system environment
prepare_system() {
    log "Preparing system environment..." "$YELLOW"
    
    mkdir -p "$WORKSPACE"
    cd "$WORKSPACE"

    log "Updating package lists..." "$GREEN"
    for _ in {1..3}; do
        if sudo apt-get update; then
            break
        fi
        log "Package list update failed. Retrying..." "$YELLOW"
        sleep 5
    done

    local packages=(
        "git" "wget" "curl" "unzip"
        "python3" "python3-pip" "python3-venv"
        "software-properties-common"
    )

    for pkg in "${packages[@]}"; do
        log "Installing $pkg..." "$GREEN"
        for _ in {1..3}; do
            if sudo apt-get install -y "$pkg"; then
                break
            fi
            log "Failed to install $pkg. Retrying..." "$YELLOW"
            sleep 5
        done
    done

    python3 -m pip install --upgrade pip
}

check_system_compatibility() {
    log "Checking System Compatibility..." "$YELLOW"

    log "Python Version:" "$GREEN"
    python3 --version

    if command -v nvidia-smi &> /dev/null; then
        log "NVIDIA GPU Detected:" "$GREEN"
        nvidia-smi
        cuda_version=$(nvidia-smi | grep "CUDA Version" | awk '{print $NF}')
        log "CUDA Version: $cuda_version" "$GREEN"
    else
        log "No NVIDIA GPU detected. Continuing with CPU setup..." "$YELLOW"
    fi
}

download_setup_scripts() {
    log "Downloading setup scripts from GitHub..." "$YELLOW"

    local scripts=(
        "setup_comfyui.sh"
        "setup_extensions.sh"
        "start_comfyui.sh"
    )

    for script in "${scripts[@]}"; do
        log "Downloading $script..." "$GREEN"
        curl -L "${BASE_RAW_URL}/${script}" -o "${WORKSPACE}/${script}"
        chmod +x "${WORKSPACE}/${script}"
    done
}

install_comfyui() {
    log "Installing ComfyUI..." "$YELLOW"

    for script in setup_comfyui.sh setup_extensions.sh; do
        log "Running $script..." "$GREEN"
        for _ in {1..3}; do
            if "${WORKSPACE}/${script}"; then
                break
            fi
            log "Failed to run $script. Retrying..." "$YELLOW"
            sleep 10
        done
    done
}

create_persistent_service() {
    log "Creating persistent startup service..." "$YELLOW"

    cat > "${WORKSPACE}/comfyui_persistent_start.sh" << 'EOL'
#!/bin/bash
# Persistent ComfyUI Startup Script

log() {
    echo "[\$(date "+%Y-%m-%d %H:%M:%S")] \$1" >> /workspace/comfyui_persistent.log
}

start_comfyui() {
    cd /workspace/ComfyUI
    pkill -f "python.*main.py" || true
    nohup python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header >> /workspace/comfyui_output.log 2>&1 &
    sleep 10
    if pgrep -f "python.*main.py" > /dev/null; then
        log "ComfyUI started successfully"
    else
        log "Failed to start ComfyUI"
    fi
}

while true; do
    start_comfyui
    sleep 60
done
EOL

    chmod +x "${WORKSPACE}/comfyui_persistent_start.sh"

    cat > /etc/systemd/system/comfyui.service << 'EOL'
[Unit]
Description=Persistent ComfyUI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/workspace
ExecStart=/workspace/comfyui_persistent_start.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload
    systemctl enable comfyui.service
    systemctl start comfyui.service
}

generate_diagnostic_report() {
    log "Generating Comprehensive Diagnostic Report..." "$YELLOW"

    {
        echo "=== SYSTEM DIAGNOSTIC REPORT ==="
        echo "Timestamp: \$(date)"
        echo ""
        echo "=== SYSTEM DETAILS ==="
        hostnamectl
        echo ""
        echo "=== CPU INFO ==="
        lscpu | grep "Model name\|Socket(s)\|Core(s) per socket\|Thread(s) per core"
        echo ""
        echo "=== MEMORY INFO ==="
        free -h
        echo ""
        echo "=== GPU INFORMATION ==="
        if command -v nvidia-smi &> /dev/null; then
            nvidia-smi
        else
            echo "No NVIDIA GPU detected"
        fi
        echo ""
        echo "=== PYTHON ENVIRONMENT ==="
        python3 --version
        python3 -m pip list
        echo ""
        echo "=== COMFYUI DIRECTORY ==="
        ls -l /workspace/ComfyUI
        echo ""
        echo "=== CUSTOM NODES ==="
        ls -l /workspace/ComfyUI/custom_nodes
    } >> "${DIAGNOSTIC_LOG}"
}

main() {
    log "Starting Universal ComfyUI Setup" "$GREEN"
    prepare_system
    check_system_compatibility
    download_setup_scripts
    install_comfyui
    create_persistent_service
    generate_diagnostic_report

    log "ComfyUI setup complete!" "$GREEN"
    log "Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188" "$GREEN"
    log "Final System Check:" "$YELLOW"
    systemctl status comfyui.service
}

main
