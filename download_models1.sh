download_workflow_files() {
  log "Downloading workflow files..."
  mkdir -p "$COMFYUI_DIR/workflows"
  
  # Download the WAN 2.1 Image to Video workflow
  wget -q -O "$COMFYUI_DIR/workflows/wan_i2v_workflow.json" \
    "https://raw.githubusercontent.com/DnsSrinath/vast-scripts/main/workflows/wan_i2v_workflow.json"
    
  log "Workflow files downloaded successfully"
}
