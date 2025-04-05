#!/bin/bash
# Universal ComfyUI Setup and Diagnostic Script
# GitHub-based deployment for Vast.ai instances
# Enhanced with WAN 2.1 Image to Video support

# Configuration
GITHUB_REPO="tg-ref/vast-scripts"
BASE_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main"
WORKSPACE="/workspace"
COMFYUI_DIR="${WORKSPACE}/ComfyUI"
DIAGNOSTIC_LOG="${WORKSPACE}/comfyui_universal_setup.log"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize log file
> "$DIAGNOSTIC_LOG"

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
    log "Check log file for details: $DIAGNOSTIC_LOG" "$RED" "ERROR"
    exit 1
}

# Function to run commands with error handling
run_command() {
    local cmd="$1"
    local error_msg="$2"
    local timeout_sec="${3:-300}"  # Default timeout of 5 minutes
    
    log "Running command: $cmd" "$BLUE" "DEBUG"
    
    # Run command with timeout and capture output and exit code
    local output
    output=$(timeout $timeout_sec bash -c "$cmd" 2>&1)
    local exit_code=$?
    
    # Log the command output
    echo "[Command Output] $output" >> "$DIAGNOSTIC_LOG"
    
    # Check for errors
    if [ $exit_code -ne 0 ]; then
        if [ $exit_code -eq 124 ]; then
            log "Command timed out after ${timeout_sec} seconds: $cmd" "$YELLOW" "WARNING"
            return 1
        else
            log "Command failed (exit code $exit_code): $cmd" "$YELLOW" "WARNING"
            log "Output: $output" "$YELLOW" "WARNING"
            return 1
        fi
    fi
    
    return 0
}

# Prepare system environment
prepare_system() {
    log "Preparing system environment..." "$YELLOW"
    
    run_command "mkdir -p \"$WORKSPACE\"" "Failed to create workspace directory" || error_exit "System preparation failed"
    cd "$WORKSPACE" || error_exit "Failed to change to workspace directory"

    log "Updating package lists..." "$GREEN"
    for _ in {1..3}; do
        if run_command "sudo apt-get update -y" "Failed to update package lists" 120; then
            break
        fi
        log "Package list update failed. Retrying..." "$YELLOW" "WARNING"
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
            if run_command "sudo apt-get install -y $pkg" "Failed to install $pkg" 120; then
                break
            fi
            log "Failed to install $pkg. Retrying..." "$YELLOW" "WARNING"
            sleep 5
        done
    done

    run_command "python3 -m pip install --upgrade pip" "Failed to upgrade pip" || log "Pip upgrade failed, continuing..." "$YELLOW" "WARNING"
}

check_system_compatibility() {
    log "Checking System Compatibility..." "$YELLOW"

    log "Python Version:" "$GREEN"
    python_version=$(python3 --version 2>&1)
    log "$python_version" "$GREEN"
    echo "Python Version: $python_version" >> "$DIAGNOSTIC_LOG"

    if command -v nvidia-smi &> /dev/null; then
        log "NVIDIA GPU Detected:" "$GREEN"
        nvidia_info=$(nvidia-smi)
        log "$nvidia_info" "$GREEN"
        echo "NVIDIA Info: $nvidia_info" >> "$DIAGNOSTIC_LOG"
        
        cuda_version=$(nvidia-smi | grep "CUDA Version" | awk '{print $NF}')
        log "CUDA Version: $cuda_version" "$GREEN"
        echo "CUDA Version: $cuda_version" >> "$DIAGNOSTIC_LOG"
        
        # Check GPU memory - important for image generation tasks
        gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n 1)
        log "GPU Memory: ${gpu_memory}MB" "$GREEN"
        echo "GPU Memory: ${gpu_memory}MB" >> "$DIAGNOSTIC_LOG"
        
        if [ "$gpu_memory" -lt 8000 ]; then
            log "Warning: Less than 8GB VRAM detected. Some models may not work properly." "$YELLOW" "WARNING"
        fi
    else
        log "No NVIDIA GPU detected. Continuing with CPU setup..." "$YELLOW" "WARNING"
    fi
}

download_setup_scripts() {
    log "Downloading setup scripts from GitHub..." "$YELLOW"

    local scripts=(
        "setup_comfyui.sh"
        "setup_extensions.sh"
        "start_comfyui.sh"
        "download_models.sh"
        "download_wan_i2v_models.sh"
        "setup_wan_i2v_workflow.sh"
    )

    for script in "${scripts[@]}"; do
        log "Downloading $script..." "$GREEN"
        for _ in {1..3}; do
            if run_command "curl -L \"${BASE_RAW_URL}/${script}\" -o \"${WORKSPACE}/${script}\"" "Failed to download $script"; then
                run_command "chmod +x \"${WORKSPACE}/${script}\"" "Failed to make $script executable"
                break
            else
                log "Download attempt failed for $script. Retrying..." "$YELLOW" "WARNING"
                sleep 5
            fi
        done
    done
    
    # Download run script with special handling for binary file
    log "Downloading run_wan_i2v.sh..." "$GREEN"
    for _ in {1..3}; do
        if run_command "curl -L \"${BASE_RAW_URL}/run_wan_i2v.sh\" -o \"${WORKSPACE}/run_wan_i2v.sh\"" "Failed to download run_wan_i2v.sh"; then
            run_command "chmod +x \"${WORKSPACE}/run_wan_i2v.sh\"" "Failed to make run_wan_i2v.sh executable"
            break
        else
            log "Download attempt failed for run_wan_i2v.sh. Retrying..." "$YELLOW" "WARNING"
            sleep 5
        fi
    done
}

install_comfyui() {
    log "Installing ComfyUI..." "$YELLOW"

    # Run setup_comfyui.sh with retry logic
    log "Running ComfyUI base installation..." "$GREEN"
    for _ in {1..3}; do
        if run_command "${WORKSPACE}/setup_comfyui.sh" "ComfyUI installation failed" 600; then
            break
        fi
        log "ComfyUI installation failed. Retrying..." "$YELLOW" "WARNING"
        sleep 10
    done
    
    # Check if ComfyUI was installed successfully
    if [ ! -d "$COMFYUI_DIR" ]; then
        error_exit "ComfyUI installation failed. Directory not found."
    fi
    
    # Run extension installer with retry logic
    log "Installing ComfyUI extensions..." "$GREEN"
    for _ in {1..3}; do
        if run_command "${WORKSPACE}/setup_extensions.sh" "Extensions installation failed" 900; then
            break
        fi
        log "Extensions installation failed. Retrying..." "$YELLOW" "WARNING"
        sleep 10
    done
    
    # Verify some extensions were installed
    if [ ! "$(ls -A ${COMFYUI_DIR}/custom_nodes 2>/dev/null)" ]; then
        log "Warning: No extensions appear to be installed. Continuing anyway..." "$YELLOW" "WARNING"
    fi
}

setup_wan_i2v() {
    log "Setting up WAN 2.1 Image to Video support..." "$YELLOW"
    
    # Run the WAN 2.1 Image to Video model download script with retry logic
    log "Downloading WAN 2.1 Image to Video models..." "$GREEN"
    for _ in {1..3}; do
        if run_command "${WORKSPACE}/download_wan_i2v_models.sh" "WAN model download failed" 3600; then
            break
        fi
        log "WAN model download failed. Retrying..." "$YELLOW" "WARNING"
        sleep 10
    done
    
    # Run the workflow setup script with retry logic
    log "Setting up WAN 2.1 Image to Video workflow..." "$GREEN"
    for _ in {1..3}; do
        if run_command "${WORKSPACE}/setup_wan_i2v_workflow.sh" "WAN workflow setup failed" 300; then
            break
        fi
        log "WAN workflow setup failed. Retrying..." "$YELLOW" "WARNING"
        sleep 10
    done
    
    # Make the run script executable
    run_command "chmod +x \"${WORKSPACE}/run_wan_i2v.sh\"" "Failed to make run script executable"
    
    # Verify key WAN components
    if [ ! -f "${COMFYUI_DIR}/models/checkpoints/wan2.1-i2v-14b-480p-Q4_K_S.gguf" ]; then
        log "Warning: WAN 2.1 model file not found. Image to Video may not work properly." "$YELLOW" "WARNING"
    fi
    
    if [ ! -f "${COMFYUI_DIR}/workflows/wan_i2v_workflow.json" ]; then
        log "Warning: WAN 2.1 workflow file not found. Creating empty directory..." "$YELLOW" "WARNING"
        run_command "mkdir -p \"${COMFYUI_DIR}/workflows\"" "Failed to create workflows directory"
    fi
    
    log "WAN 2.1 Image to Video setup complete!" "$GREEN"
}

download_base_models() {
    log "Downloading base models..." "$YELLOW"
    
    # Run the model download script with retry logic
    for _ in {1..3}; do
        if run_command "${WORKSPACE}/download_models.sh" "Base model download failed" 1800; then
            break
        fi
        log "Base model download failed. Retrying..." "$YELLOW" "WARNING"
        sleep 10
    done
}

create_persistent_service() {
    log "Creating persistent startup service..." "$YELLOW"

    cat > "${WORKSPACE}/comfyui_persistent_start.sh" << 'EOL'
#!/bin/bash
# Persistent ComfyUI Startup Script

log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" >> /workspace/comfyui_persistent.log
}

start_comfyui() {
    cd /workspace/ComfyUI
    pkill -f "python.*main.py" || true
    nohup python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header --force-fp16 >> /workspace/comfyui_output.log 2>&1 &
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
    
    # Check if ComfyUI is still running
    if ! pgrep -f "python.*main.py" > /dev/null; then
        log "ComfyUI crashed or stopped. Restarting..."
        start_comfyui
    fi
done
EOL

    run_command "chmod +x \"${WORKSPACE}/comfyui_persistent_start.sh\"" "Failed to make persistent start script executable"

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

    log "Enabling and starting ComfyUI service..." "$GREEN"
    run_command "systemctl daemon-reload" "Failed to reload systemd"
    run_command "systemctl enable comfyui.service" "Failed to enable ComfyUI service"
    run_command "systemctl start comfyui.service" "Failed to start ComfyUI service"
}

generate_diagnostic_report() {
    log "Generating Comprehensive Diagnostic Report..." "$YELLOW"

    {
        echo "=== SYSTEM DIAGNOSTIC REPORT ==="
        echo "Timestamp: $(date)"
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
        echo "=== DISK SPACE ==="
        df -h
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
        echo "=== NETWORK CONNECTIVITY ==="
        curl -s ifconfig.me || echo "Failed to get public IP"
        echo ""
        echo "=== COMFYUI DIRECTORY ==="
        ls -la "$COMFYUI_DIR"
        echo ""
        echo "=== CUSTOM NODES ==="
        ls -la "$COMFYUI_DIR/custom_nodes"
        echo ""
        echo "=== MODEL FILES ==="
        find "$COMFYUI_DIR/models" -type f -name "*.safetensors" -o -name "*.ckpt" -o -name "*.pth" -o -name "*.gguf" | sort
        echo ""
        echo "=== WAN 2.1 IMAGE TO VIDEO STATUS ==="
        if [ -f "$COMFYUI_DIR/models/checkpoints/wan2.1-i2v-14b-480p-Q4_K_S.gguf" ]; then
            echo "✅ WAN I2V Model: Installed"
            echo "   Size: $(du -h "$COMFYUI_DIR/models/checkpoints/wan2.1-i2v-14b-480p-Q4_K_S.gguf" | cut -f1)"
        else
            echo "❌ WAN I2V Model: Missing"
        fi
        
        if [ -f "$COMFYUI_DIR/workflows/wan_i2v_workflow.json" ]; then
            echo "✅ WAN I2V Workflow: Installed"
        else
            echo "❌ WAN I2V Workflow: Missing"
        fi
        
        if [ -f "$WORKSPACE/run_wan_i2v.sh" ]; then
            echo "✅ WAN I2V Run Script: Installed"
        else
            echo "❌ WAN I2V Run Script: Missing"
        fi
        
        echo ""
        echo "=== SERVICE STATUS ==="
        systemctl status comfyui.service
        echo ""
        echo "=== LOG FILES ==="
        ls -la /workspace/*.log
        echo ""
        echo "=== END OF REPORT ==="
    } >> "${DIAGNOSTIC_LOG}"
    
    log "Diagnostic report saved to: $DIAGNOSTIC_LOG" "$GREEN"
}

create_quickstart_guide() {
    log "Creating quickstart guide..." "$YELLOW"
    
    cat > "${WORKSPACE}/QUICKSTART.md" << 'EOL'
# ComfyUI Quickstart Guide

## Accessing ComfyUI
- Open your browser and navigate to: http://YOUR_VAST_AI_IP:8188

## Using WAN 2.1 Image to Video
1. Connect to your Vast.ai instance via SSH
2. Run the WAN 2.1 Image to Video specific script:
3. Open your browser and access the interface
4. The workflow should be loaded automatically
5. Upload your reference image
6. Adjust the prompt to describe the desired motion
7. Click "Queue Prompt" to generate your video

## Tips for RTX 3090
- You can increase resolution to 768x1280
- Try 60-100+ frames for longer videos
- Experiment with different samplers (dpm++ 2m karras often works well)
- Adjust CFG scale between 5-7 for best results

## Troubleshooting
- Check logs: `/workspace/comfyui_output.log`
- Diagnostic report: `/workspace/comfyui_universal_setup.log`
- Restart ComfyUI: `systemctl restart comfyui.service`

## Important Directories
- Models: `/workspace/ComfyUI/models/`
- Custom nodes: `/workspace/ComfyUI/custom_nodes/`
- Workflows: `/workspace/ComfyUI/workflows/`
- Outputs: `/workspace/ComfyUI/output/`
EOL

 log "Quickstart guide created at: ${WORKSPACE}/QUICKSTART.md" "$GREEN"
}

main() {
 log "Starting Universal ComfyUI Setup" "$GREEN"
 log "Repository: ${GITHUB_REPO}" "$GREEN"
 
 prepare_system
 check_system_compatibility
 download_setup_scripts
 install_comfyui
 download_base_models
 
 # Set up WAN 2.1 Image to Video support
 setup_wan_i2v
 
 create_persistent_service
 generate_diagnostic_report
 create_quickstart_guide

 log "ComfyUI setup complete!" "$GREEN"
 log "Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188" "$GREEN"
 log "Use WAN 2.1 Image to Video with: ${WORKSPACE}/run_wan_i2v.sh" "$GREEN"
 log "See quickstart guide: ${WORKSPACE}/QUICKSTART.md" "$GREEN"
 log "Final System Check:" "$YELLOW"
 
 if systemctl is-active --quiet comfyui.service; then
     log "ComfyUI service is running" "$GREEN"
 else
     log "Warning: ComfyUI service is not running. Starting manually..." "$YELLOW" "WARNING"
     run_command "systemctl start comfyui.service" "Failed to start ComfyUI service"
 fi
 
 log "For diagnostics, check: ${DIAGNOSTIC_LOG}" "$GREEN"
 log "Setup completed at: $(date)" "$GREEN"
}

# Trap errors for the entire script
trap 'error_exit "Script failed at line $LINENO"' ERR

# Run the main function
main
