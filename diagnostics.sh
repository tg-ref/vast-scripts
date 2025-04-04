#!/bin/bash
# 🕵️ ComfyUI Extension Download Diagnostics

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Repository to test
REPO_URL="https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
REPO_NAME="ComfyUI-Impact-Pack"
DOWNLOAD_URLS=(
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack/archive/refs/heads/main.zip"
    "https://codeload.github.com/ltdrdata/ComfyUI-Impact-Pack/zip/refs/heads/main"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack/zipball/main"
)

# Network Diagnostics
network_check() {
    echo -e "${YELLOW}🌐 Network Diagnostics${NC}"
    
    # Check basic connectivity
    echo "Testing internet connectivity..."
    if ! ping -c 4 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${RED}❌ No internet connectivity${NC}"
        return 1
    fi
    
    # Check GitHub connectivity
    echo "Testing GitHub connectivity..."
    if ! ping -c 4 github.com > /dev/null 2>&1; then
        echo -e "${RED}❌ Cannot reach GitHub${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Network connectivity appears normal${NC}"
    return 0
}

# SSL/TLS Diagnostics
ssl_check() {
    echo -e "${YELLOW}🔒 SSL/TLS Diagnostics${NC}"
    
    # Check SSL connectivity
    if ! openssl s_client -connect github.com:443 -brief > /dev/null 2>&1; then
        echo -e "${RED}❌ SSL connection to GitHub failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ SSL connectivity appears normal${NC}"
    return 0
}

# Download Diagnostics
download_diagnostics() {
    echo -e "${YELLOW}📦 Download Diagnostics${NC}"
    
    for url in "${DOWNLOAD_URLS[@]}"; do
        echo "Testing download URL: $url"
        
        # Verbose curl with full details
        echo -e "${YELLOW}Verbose curl output:${NC}"
        curl_output=$(curl -v -L -f "$url" -o "/tmp/${REPO_NAME}-test.zip" 2>&1)
        curl_exit_code=$?
        
        echo "$curl_output"
        
        # Analyze curl output
        if [ $curl_exit_code -ne 0 ]; then
            echo -e "${RED}❌ Download failed with exit code $curl_exit_code${NC}"
            continue
        fi
        
        # Check downloaded file
        file_size=$(stat -c%s "/tmp/${REPO_NAME}-test.zip")
        file_type=$(file -b "/tmp/${REPO_NAME}-test.zip")
        
        echo -e "Download file size: ${GREEN}$file_size bytes${NC}"
        echo -e "File type: ${GREEN}$file_type${NC}"
        
        # Try extraction
        if unzip -t "/tmp/${REPO_NAME}-test.zip" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ ZIP file appears valid and extractable${NC}"
            return 0
        else
            echo -e "${RED}❌ ZIP file appears invalid or corrupt${NC}"
        fi
    done
    
    return 1
}

# Git Clone Diagnostics
git_clone_diagnostics() {
    echo -e "${YELLOW}🔧 Git Clone Diagnostics${NC}"
    
    # Try various clone strategies
    clone_strategies=(
        "git clone --depth 1 $REPO_URL /tmp/${REPO_NAME}-clone"
        "GIT_TERMINAL_PROMPT=0 git clone --depth 1 $REPO_URL /tmp/${REPO_NAME}-clone"
        "git clone $REPO_URL /tmp/${REPO_NAME}-clone"
    )
    
    for strategy in "${clone_strategies[@]}"; do
        echo "Trying clone strategy: $strategy"
        
        if $strategy > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Clone successful with strategy: $strategy${NC}"
            return 0
        else
            echo -e "${RED}❌ Clone failed with strategy: $strategy${NC}"
        fi
    done
    
    return 1
}

# Main diagnostic function
main_diagnostics() {
    echo -e "${YELLOW}🚀 ComfyUI Extension Download Diagnostics${NC}"
    
    network_check
    ssl_check
    
    echo -e "\n${YELLOW}Attempting Download Methods:${NC}"
    download_diagnostics
    
    echo -e "\n${YELLOW}Attempting Git Clone Methods:${NC}"
    git_clone_diagnostics
}

# Clean up function
cleanup() {
    rm -rf /tmp/${REPO_NAME}-*
}

# Run diagnostics
trap cleanup EXIT
main_diagnostics
