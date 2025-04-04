#!/bin/bash
# Start ComfyUI with optimal settings

cd /workspace/ComfyUI
echo "Starting ComfyUI..."
echo "Access the interface at http://$(hostname -I | awk '{print $1}'):8188"
echo "Press Ctrl+C to stop ComfyUI"
python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header
