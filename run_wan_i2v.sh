#!/bin/bash
# Optimized startup script for WAN 2.1 Image to Video

# Start ComfyUI in background
cd /workspace/ComfyUI
python main.py --listen --port 8188 --enable-insecure-extension-install --force-fp16 &
COMFY_PID=$!

# Wait for ComfyUI to initialize
echo "Starting ComfyUI with optimized settings for WAN 2.1 Image to Video..."
echo "Waiting for server to initialize..."
sleep 15

# Load the workflow
echo "Loading WAN 2.1 Image to Video workflow..."
curl -s -X POST "http://127.0.0.1:8188/upload/load" \
     -H "Content-Type: application/json" \
     -d '{"workflow_json_path": "/workspace/ComfyUI/workflows/wan_i2v_workflow.json"}'

echo "WAN 2.1 Image to Video is running with workflow auto-loaded!"
echo "Access the interface at: http://$(hostname -I | awk '{print $1}'):8188"

# Keep the script running and capture logs
wait $COMFY_PID
