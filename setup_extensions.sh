#!/bin/bash
# ComfyUI Custom Startup Script for Vast.ai

# Log function for better visibility
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a /workspace/comfyui.log
}

log "Starting ComfyUI setup..."

# Navigate to ComfyUI directory
cd /workspace/ComfyUI

# Configure ComfyUI to listen on all interfaces
log "Setting up ComfyUI to listen on all interfaces (0.0.0.0:8188)"
echo "--listen 0.0.0.0 --port 8188 --enable-cors-header" > extra_args.txt
chmod 755 extra_args.txt

# Update portal configuration to expose ComfyUI correctly
log "Updating portal configuration..."
cat > /etc/portal.yaml <<EOL
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

# Restart Caddy to apply new configuration
log "Restarting Caddy to apply new configuration..."
supervisorctl restart caddy

# Kill any existing ComfyUI processes
if pgrep -f "python main.py" > /dev/null; then
  log "Stopping existing ComfyUI processes..."
  pkill -f "python main.py"
  sleep 2
fi

# Ensure we're using the right Python environment
source /venv/main/bin/activate

# Start ComfyUI with public access enabled
log "Starting ComfyUI with public access enabled..."
nohup python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header > /workspace/comfyui.log 2>&1 &

# Add a wait to ensure ComfyUI starts properly
sleep 5

# Check if ComfyUI is running
if pgrep -f "python main.py" > /dev/null; then
  log "ComfyUI started successfully!"
  
  # Get the instance IP address
  INSTANCE_IP=$(hostname -I | awk '{print $1}')
  
  log "ComfyUI should now be accessible via:"
  log "- http://${INSTANCE_IP}:8188"
  log "- Also through the Vast.ai 'Open' button interface"
  log "- Check logs with: tail -f /workspace/comfyui.log"
else
  log "ERROR: ComfyUI failed to start! Check logs for details."
fi
