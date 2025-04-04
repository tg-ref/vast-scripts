#!/bin/bash

echo "📦 Downloading models..."

# Create necessary folders
mkdir -p models/checkpoints
mkdir -p models/controlnet
mkdir -p models/clip

# Stable Diffusion Base Model (example - change as needed)
if [ ! -f models/checkpoints/v1-5-pruned.ckpt ]; then
    echo "➡ Downloading Stable Diffusion v1.5..."
    wget -O models/checkpoints/v1-5-pruned.ckpt https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.ckpt
fi

# ControlNet Models (Depth & Canny as example)
CONTROLNET_MODELS=(
    "control_sd15_depth.pth"
    "control_sd15_canny.pth"
)

for model in \"${CONTROLNET_MODELS[@]}\"; do
    if [ ! -f models/controlnet/$model ]; then
        echo \"➡ Downloading $model...\"
        wget -O models/controlnet/$model https://huggingface.co/lllyasviel/ControlNet/resolve/main/$model
    fi
done
