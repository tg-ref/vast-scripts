# Function to download and prepare the WAN 2.1 Image to Video workflow
setup_wan_i2v_workflow() {
    log "📋 Setting up WAN 2.1 Image to Video workflow..."
    
    # Create workflows directory if it doesn't exist
    mkdir -p "$COMFYUI_DIR/workflows"
    
    # Download the workflow JSON file from GitHub
    log "⬇️ Downloading WAN 2.1 Image to Video workflow JSON..."
    wget --progress=bar:force:noscroll -c \
         https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/workflows/wan_i2v_workflow.json \
         -O "$COMFYUI_DIR/workflows/wan_i2v_workflow.json" || {
        log "⚠️ Warning: Failed to download workflow JSON"
        return 1
    }
    
    # Create a symbolic link to make it accessible in the ComfyUI interface
    if [ -f "$COMFYUI_DIR/workflows/wan_i2v_workflow.json" ]; then
        # Ensure web directory exists
        mkdir -p "$COMFYUI_DIR/web/extensions/workflow_library"
        
        # Create symlink to the workflow in the web extensions directory
        ln -sf "$COMFYUI_DIR/workflows/wan_i2v_workflow.json" \
               "$COMFYUI_DIR/web/extensions/workflow_library/wan_i2v_workflow.json"
        
        log "✅ WAN 2.1 Image to Video workflow set up successfully"
        
        # Create an auto-loading script for the workflow
        cat > "$WORKSPACE/load_wan_i2v_workflow.sh" << 'EOL'
#!/bin/bash
# Script to automatically load the WAN 2.1 Image to Video workflow

# Wait for ComfyUI to start (10 seconds)
sleep 10

# Use curl to trigger workflow loading via the API
curl -X POST "http://127.0.0.1:8188/upload/load" \
     -H "Content-Type: application/json" \
     -d '{"workflow_json_path": "/workspace/ComfyUI/workflows/wan_i2v_workflow.json"}'

echo "WAN 2.1 Image to Video workflow loaded!"
EOL

        chmod +x "$WORKSPACE/load_wan_i2v_workflow.sh"
        log "📝 Created workflow auto-loading script at $WORKSPACE/load_wan_i2v_workflow.sh"
        
        # Update the run script to also load the workflow
        cat > "$WORKSPACE/run_wan_i2v.sh" << 'EOL'
#!/bin/bash
# Optimized startup script for WAN 2.1 Image to Video with auto-loading workflow

# Start ComfyUI in background
cd /workspace/ComfyUI
python main.py --listen --port 8188 --enable-insecure-extension-install --force-fp16 &

# Wait for ComfyUI to initialize
sleep 15

# Load the workflow
curl -s -X POST "http://127.0.0.1:8188/upload/load" \
     -H "Content-Type: application/json" \
     -d '{"workflow_json_path": "/workspace/ComfyUI/workflows/wan_i2v_workflow.json"}'

echo "WAN 2.1 Image to Video is running with workflow auto-loaded!"
echo "Access the interface at: http://$(hostname -I | awk '{print $1}'):8188"

# Keep the script running
wait
EOL

        chmod +x "$WORKSPACE/run_wan_i2v.sh"
        log "✅ Updated run script to auto-load the workflow"
    else
        log "⚠️ Workflow file not found after download"
        return 1
    fi
    
    return 0
}
