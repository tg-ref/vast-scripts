#!/bin/bash
# 🕵️ Comprehensive Extension Download Diagnostics

set -euo pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error logging function
error_log() {
    echo "[ERROR] $1" >&2
}

# Repositories to test
REPOS=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    "https://github.com/WASasquatch/ComfyUI-WAN-Suite.git"
)

# Comprehensive system and network diagnostics
full_system_diagnostics() {
    log "🖥️ Comprehensive System Diagnostics"
    
    # Basic system information
    log "Hostname: $(hostname)"
    log "Current User: $(whoami)"
    
    # OS Information
    if [ -f /etc/os-release ]; then
        log "OS Details:"
        cat /etc/os-release
    else
        log "Unable to retrieve OS information"
    fi
    
    # Network interfaces
    log "Network Interfaces:"
    ip addr || ifconfig
    
    # DNS Configuration
    log "DNS Configuration:"
    cat /etc/resolv.conf
    
    # Detailed network diagnostics
    log "Network Routing:"
    ip route || route -n
}

# Advanced network connectivity check
advanced_network_check() {
    log "🌐 Advanced Network Diagnostics"
    
    # Check various network-related utilities
    log "Checking network utilities..."
    
    # List of utilities to check
    local utilities=("ping" "curl" "wget" "netstat" "ss" "ip" "traceroute")
    
    for util in "${utilities[@]}"; do
        if command -v "$util" >/dev/null 2>&1; then
            log "✅ $util is installed"
        else
            log "❌ $util is not installed"
        fi
    done
    
    # Extensive connectivity tests
    log "Testing connectivity to critical services..."
    
    local test_hosts=(
        "8.8.8.8"       # Google DNS
        "1.1.1.1"       # Cloudflare DNS
        "github.com"
        "raw.githubusercontent.com"
    )
    
    for host in "${test_hosts[@]}"; do
        log "Testing connectivity to $host:"
        if ping -c 4 "$host" >/dev/null 2>&1; then
            log "✅ Successfully pinged $host"
        else
            error_log "❌ Failed to ping $host"
        fi
    done
}

# Enhanced download diagnostics
advanced_download_diagnostics() {
    log "📦 Advanced Download Diagnostics"
    
    # Temporary directory for downloads
    local temp_dir="/tmp/extension_downloads"
    mkdir -p "$temp_dir"
    
    for repo in "${REPOS[@]}"; do
        local repo_name=$(basename "$repo" .git)
        log "Testing Repository: $repo_name"
        
        # Generate download URLs
        local download_urls=(
            "https://github.com/$(echo "$repo" | cut -d'/' -f4-5 | sed 's/\.git$//')/archive/refs/heads/main.zip"
            "https://codeload.github.com/$(echo "$repo" | cut -d'/' -f4-5 | sed 's/\.git$//')/zip/refs/heads/main"
        )
        
        for url in "${download_urls[@]}"; do
            log "Attempting to download from: $url"
            
            # Detailed curl command with extensive logging
            local output_file="$temp_dir/${repo_name}-download.zip"
            local curl_log="$temp_dir/${repo_name}-curl.log"
            
            log "Saving download to: $output_file"
            log "Curl log will be saved to: $curl_log"
            
            if ! curl -v -L -f \
                -o "$output_file" \
                --retry 3 \
                --retry-delay 5 \
                --max-time 60 \
                --trace-ascii "$curl_log" \
                "$url" 2>&1; then
                
                error_log "Download failed for $url"
                error_log "Curl log contents:"
                cat "$curl_log"
                continue
            fi
            
            # Check downloaded file
            if [ ! -f "$output_file" ]; then
                error_log "No file was downloaded"
                continue
            fi
            
            local file_size=$(stat -c%s "$output_file")
            local file_type=$(file -b "$output_file")
            
            log "Download successful:"
            log "File size: $file_size bytes"
            log "File type: $file_type"
            
            # Attempt to unzip
            if unzip -t "$output_file" >/dev/null 2>&1; then
                log "✅ ZIP file appears valid and extractable"
            else
                error_log "❌ ZIP file appears invalid or corrupt"
            fi
        done
    done
}

# Git clone diagnostics
git_clone_diagnostics() {
    log "🔧 Git Clone Diagnostics"
    
    # Temporary directory for clones
    local temp_dir="/tmp/extension_clones"
    mkdir -p "$temp_dir"
    
    for repo in "${REPOS[@]}"; do
        local repo_name=$(basename "$repo" .git)
        log "Testing Repository: $repo_name"
        
        # Clone strategies
        local clone_strategies=(
            "git clone --depth 1 $repo $temp_dir/${repo_name}-clone"
            "GIT_TERMINAL_PROMPT=0 git clone --depth 1 $repo $temp_dir/${repo_name}-clone"
        )
        
        for strategy in "${clone_strategies[@]}"; do
            log "Attempting clone strategy: $strategy"
            
            # Redirect output to log file
            local clone_log="$temp_dir/${repo_name}-clone.log"
            
            if $strategy > "$clone_log" 2>&1; then
                log "✅ Clone successful with strategy: $strategy"
                log "Clone log:"
                cat "$clone_log"
            else
                error_log "❌ Clone failed with strategy: $strategy"
                error_log "Clone log contents:"
                cat "$clone_log"
            fi
        done
    done
}

# Main diagnostic function
main_diagnostics() {
    log "🚀 Comprehensive Extension Download Diagnostics"
    
    # Run diagnostics
    full_system_diagnostics
    advanced_network_check
    advanced_download_diagnostics
    git_clone_diagnostics
}

# Cleanup function
cleanup() {
    log "🧹 Cleaning up temporary files"
    rm -rf /tmp/extension_downloads
    rm -rf /tmp/extension_clones
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main diagnostics
main_diagnostics
