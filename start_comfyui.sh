#!/bin/bash
# Robust ComfyUI Startup Script for Vast.ai

# Logging function
log() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] $message" | tee -a /workspace/comfyui_startup.log
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Ensure we're in the correct directory
cd /workspace/ComfyUI || error_exit "Cannot change to ComfyUI directory"

# Log script start
log "Starting ComfyUI startup script..."

# Detect GPU availability
GPU_AVAILABLE=false
if command -v nvidia-smi &> /dev/null; then
    log "NVIDIA GPU detected"
    GPU_AVAILABLE=true
else
    log "No NVIDIA GPU detected. Running in CPU mode."
fi

# Kill any existing ComfyUI processes
log "Checking and terminating existing ComfyUI processes..."
pkill -f "python.*main.py" || true
sleep 3

# Prepare startup configuration
log "Preparing ComfyUI startup configuration..."

# Create extra arguments file
echo "--listen 0.0.0.0 --port 8188 --enable-cors-header" > extra_args.txt
chmod 755 extra_args.txt

# Create portal configuration
mkdir -p /etc
cat > /etc/portal.yaml << EOL
instance_portal:
  app_host: localhost
  app_port: 11111
  tls_port: 1111
  app_name: Instance Portal
comfyui:
  app_host: localhost
  app_port: 8188
  tls_port: 8188
  app_name: ComfyUI
EOL

# Install additional dependencies if GPU is available
if [ "$GPU_AVAILABLE" = true ]; then
    log "Installing GPU-specific dependencies..."
    python3 -m pip install torch torchvision torchaudio xformers || \
        log "Warning: Failed to install GPU dependencies"
fi

# Create persistent startup script
log "Creating persistent startup wrapper..."
cat > /workspace/comfyui_persistent_start.sh << 'PERSISTENT_EOF'
#!/bin/bash
# Persistent ComfyUI Startup Wrapper

log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" >> /workspace/comfyui_persistent.log
}

start_comfyui() {
    cd /workspace/ComfyUI
    
    # Kill existing processes
    pkill -f "python.*main.py" || true
    
    # Start ComfyUI
    nohup python3 main.py --listen 0.0.0.0 --port 8188 --enable-cors-header >> /workspace/comfyui_output.log 2>&1 &
    
    # Wait and verify
    sleep 10
    
    if pgrep -f "python.*main.py" > /dev/null; then
        log "ComfyUI started successfully"
    else
        log "Failed to start ComfyUI"
    fi
}

# Restart loop
while true; do
    start_comfyui
    sleep 60
done
PERSISTENT_EOF

chmod +x /workspace/comfyui_persistent_start.sh

# Create systemd service for persistent startup
log "Creating systemd service..."
cat > /etc/systemd/system/comfyui.service << 'SYSTEMD_EOF'
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
SYSTEMD_EOF

# Reload systemd, enable and start service
systemctl daemon-reload
systemctl enable comfyui.service
systemctl start comfyui.service

# Final startup and verification
log "ComfyUI startup process complete"
log "Access ComfyUI at: http://$(hostname -I | awk '{print $1}'):8188"

# Provide final status check
systemctl status comfyui.service
