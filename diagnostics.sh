#!/bin/bash
# 🕵️ ComfyUI Extension Download Diagnostics

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Repositories to test
REPOS=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    "https://github.com/WASasquatch/ComfyUI-WAN-Suite.git"
)

# Network Diagnostics
network_check() {
    echo -e "${YELLOW}🌐 Network Diagnostics${NC}"
    
    # Detailed network checks
    echo "Network Interfaces:"
    ip addr || ifconfig
    
    echo "Routing Table:"
    ip route || route -n
    
    echo "DNS Configuration:"
    cat /etc/resolv.conf
    
    # Check basic connectivity
    echo "Testing internet connectivity..."
    if ! timeout 10 ping -c 4 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${RED}❌ No internet connectivity${NC}"
        return 1
    fi
    
    # Check GitHub connectivity
    echo "Testing GitHub connectivity..."
    if ! timeout 10 ping -c 4 github.com > /dev/null 2>&1; then
        echo -e "${RED}❌ Cannot reach GitHub${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Network connectivity appears normal${NC}"
    return 0
}

# SSL/TLS Diagnostics
ssl_check() {
    echo -e "${YELLOW}🔒 SSL/TLS Diagnostics${NC}"
    
    # Detailed SSL check
    echo "SSL/TLS Certificate Details:"
    echo | openssl s_client -connect github.com:443 2>/dev/null | openssl x509 -noout -dates
    
    # Check SSL connectivity
    if ! timeout 10 openssl s_client -connect github.com:443 -brief > /dev/null 2>&1; then
        echo -e "${RED}❌ SSL connection to GitHub failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ SSL connectivity appears normal${NC}"
    return 0
}

# Enhanced Download Diagnostics
download_diagnostics() {
    echo -e "${YELLOW}📦 Download Diagnostics${NC}"
    
    mkdir -p /tmp/download_diagnostics
    
    for repo in "${REPOS[@]}"; do
        repo_name=$(basename "$repo" .git)
        echo -e "\n${YELLOW}Testing Repository: $repo${NC}"
        
        # Generate download URLs
        DOWNLOAD_URLS=(
            "https://github.com/$(echo "$repo" | cut -d'/' -f4-5 | sed 's/\.git$//')/archive/refs/heads/main.zip"
            "https://codeload.github.com/$(echo "$repo" | cut -d'/' -f4-5 | sed 's/\.git$//')/zip/refs/heads/main"
            "https://github.com/$(echo "$repo" | cut -d'/' -f4-5 | sed 's/\.git$//')/zipball/main"
        )
        
        for url in "${DOWNLOAD_URLS[@]}"; do
            echo "Testing download URL: $url"
            
            output_file="/tmp/download_diagnostics/${repo_name}-test.zip"
            log_file="/tmp/download_diagnostics/${repo_name}-curl.log"
            
            # Enhanced curl with timeout and detailed logging
            echo -e "${YELLOW}Attempting download with enhanced curl:${NC}"
            if timeout 60 curl -v -L -f \
                --max-time 30 \
                --retry 3 \
                --retry-delay 5 \
                -o "$output_file" \
                --trace-ascii "$log_file" \
                "$url" 2>&1; then
                
                # Check downloaded file
                if [ -f "$output_file" ]; then
                    file_size=$(stat -c%s "$output_file")
                    file_type=$(file -b "$output_file")
                    
                    echo -e "Download file size: ${GREEN}$file_size bytes${NC}"
                    echo -e "File type: ${GREEN}$file_type${NC}"
                    
                    # Try extraction
                    if unzip -t "$output_file" > /dev/null 2>&1; then
                        echo -e "${GREEN}✅ ZIP file appears valid and extractable${NC}"
                    else
                        echo -e "${RED}❌ ZIP file appears invalid or corrupt${NC}"
                        echo "Curl log contents:"
                        cat "$log_file"
                    fi
                else
                    echo -e "${RED}❌ No file was downloaded${NC}"
                fi
            else
                curl_exit_code=$?
                echo -e "${RED}❌ Download failed with exit code $curl_exit_code${NC}"
                echo "Curl log contents:"
                cat "$log_file"
            fi
        done
    done
}

# Git Clone Diagnostics
git_clone_diagnostics() {
    echo -e "${YELLOW}🔧 Git Clone Diagnostics${NC}"
    
    mkdir -p /tmp/clone_diagnostics
    
    for repo in "${REPOS[@]}"; do
        repo_name=$(basename "$repo" .git)
        echo -e "\n${YELLOW}Testing Repository: $repo${NC}"
        
        # Try various clone strategies
        clone_strategies=(
            "git clone --depth 1 $repo /tmp/clone_diagnostics/${repo_name}-clone"
            "GIT_TERMINAL_PROMPT=0 git clone --depth 1 $repo /tmp/clone_diagnostics/${repo_name}-clone"
            "git clone $repo /tmp/clone_diagnostics/${repo_name}-clone"
        )
        
        for strategy in "${clone_strategies[@]}"; do
            log_file="/tmp/clone_diagnostics/${repo_name}-clone.log"
            
            echo "Trying clone strategy: $strategy"
            
            if $strategy > "$log_file" 2>&1; then
                echo -e "${GREEN}✅ Clone successful with strategy: $strategy${NC}"
                break
            else
                echo -e "${RED}❌ Clone failed with strategy: $strategy${NC}"
                echo "Clone log contents:"
                cat "$log_file"
            fi
        done
    done
}

# Main diagnostic function
main_diagnostics() {
    echo -e "${YELLOW}🚀 ComfyUI Extension Download Diagnostics${NC}"
    
    # Run diagnostics
    network_check
    ssl_check
    
    echo -e "\n${YELLOW}Attempting Download Methods:${NC}"
    download_diagnostics
    
    echo -e "\n${YELLOW}Attempting Git Clone Methods:${NC}"
    git_clone_diagnostics
}

# Clean up function
cleanup() {
    rm -rf /tmp/download_diagnostics
    rm -rf /tmp/clone_diagnostics
}

# Run diagnostics
trap cleanup EXIT
main_diagnostics
