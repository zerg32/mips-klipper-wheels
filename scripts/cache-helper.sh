#!/bin/bash
# cache-helper.sh
# Helper script to cache expensive setup operations based on file hashes
set -e

CACHE_DIR="/tmp/mips-klipper-cache"
CHROOT_CACHE_DIR="$CACHE_DIR/chroot"
BUILDER_CACHE_DIR="$CACHE_DIR/builder"

# Function to calculate hash of multiple files
calculate_hash() {
    local files=("$@")
    local combined_hash=""
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            combined_hash="${combined_hash}$(sha256sum "$file" | cut -d' ' -f1)"
        else
            echo "Warning: File $file not found" >&2
        fi
    done
    
    echo -n "$combined_hash" | sha256sum | cut -d' ' -f1
}

# Function to create cache archive
create_cache() {
    local cache_file="$1"
    local source_dir="$2"
    local cache_type="$3"
    
    echo "Creating $cache_type cache: $cache_file"
    mkdir -p "$(dirname "$cache_file")"
    
    # Create tar archive with compression
    tar -czf "$cache_file" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
    
    echo "$cache_type cache created successfully"
}

# Function to restore from cache
restore_cache() {
    local cache_file="$1"
    local target_dir="$2"
    local cache_type="$3"
    
    if [ -f "$cache_file" ]; then
        echo "Restoring $cache_type from cache: $cache_file"
        
        # Remove existing target directory
        rm -rf "$target_dir"
        
        # Create parent directory if it doesn't exist
        mkdir -p "$(dirname "$target_dir")"
        
        # Extract cache with error handling
        if tar -xzf "$cache_file" -C "$(dirname "$target_dir")"; then
            echo "$cache_type restored successfully from cache"
            return 0
        else
            echo "Error: Failed to extract $cache_type cache"
            rm -f "$cache_file"  # Remove corrupted cache
            return 1
        fi
    else
        echo "No $cache_type cache found: $cache_file"
        return 1
    fi
}

# Function to setup chroot with caching
setup_chroot_cached() {
    local script_files=("scripts/chroot-setup.sh")
    local hash=$(calculate_hash "${script_files[@]}")
    local cache_file="$CHROOT_CACHE_DIR/chroot-$hash.tar.gz"
    
    echo "Chroot setup cache key: $hash"
    
    if restore_cache "$cache_file" "/mnt/mipsel-root" "chroot"; then
        echo "Chroot environment restored from cache"
        
        # Ensure QEMU binary is properly set up
        cp /usr/bin/qemu-mipsel-static /mnt/mipsel-root/usr/bin/ 2>/dev/null || true
        
        # Test chroot functionality
        if chroot /mnt/mipsel-root /bin/bash -c 'echo "Chroot test successful"' 2>/dev/null; then
            echo "Cached chroot environment is functional"
            return 0
        else
            echo "Cached chroot environment failed test, rebuilding..."
            rm -f "$cache_file"
        fi
    fi
    
    echo "Setting up chroot environment from scratch..."
    ./scripts/chroot-setup.sh
    
    # Clean up before caching
    sudo rm -rf /mnt/mipsel-root/tmp/* 2>/dev/null || true
    sudo rm -rf /mnt/mipsel-root/var/cache/apt/* 2>/dev/null || true
    sudo rm -rf /mnt/mipsel-root/var/lib/apt/lists/* 2>/dev/null || true
    
    # Create cache
    create_cache "$cache_file" "/mnt/mipsel-root" "chroot"
}

# Function to setup builder environment with caching
setup_builder_cached() {
    local script_files=("scripts/builder-setup.sh" "scripts/chroot-setup.sh")
    local hash=$(calculate_hash "${script_files[@]}")
    local cache_file="$BUILDER_CACHE_DIR/builder-$hash.tar.gz"
    
    echo "Builder setup cache key: $hash"
    
    # Check if we have a cached builder environment
    if [ -f "$cache_file" ] && [ -d "/mnt/mipsel-root" ]; then
        echo "Builder environment cache found, checking if chroot is ready..."
        
        # Test if current chroot has builder tools
        if chroot /mnt/mipsel-root /bin/bash -c 'which gcc && which python3-virtualenv' 2>/dev/null; then
            echo "Builder environment is already set up and functional"
            return 0
        else
            echo "Chroot exists but builder tools missing, setting up builder environment..."
        fi
    else
        echo "No builder cache found or chroot not ready"
    fi
    
    echo "Setting up builder environment from scratch..."
    ./scripts/builder-setup.sh
    
    # Clean up before caching (builder cache includes the updated chroot)
    sudo rm -rf /mnt/mipsel-root/tmp/* 2>/dev/null || true
    sudo rm -rf /mnt/mipsel-root/var/cache/apt/* 2>/dev/null || true
    sudo rm -rf /mnt/mipsel-root/var/lib/apt/lists/* 2>/dev/null || true
    
    # Create cache (this will be a full chroot with builder tools)
    create_cache "$cache_file" "/mnt/mipsel-root" "builder"
}

# Function to restore complete builder environment
restore_builder_cached() {
    local script_files=("scripts/builder-setup.sh" "scripts/chroot-setup.sh")
    local hash=$(calculate_hash "${script_files[@]}")
    local cache_file="$BUILDER_CACHE_DIR/builder-$hash.tar.gz"
    
    echo "Builder restore cache key: $hash"
    
    if restore_cache "$cache_file" "/mnt/mipsel-root" "builder environment"; then
        echo "Complete builder environment restored from cache"
        
        # Ensure QEMU binary is properly set up
        cp /usr/bin/qemu-mipsel-static /mnt/mipsel-root/usr/bin/ 2>/dev/null || true
        
        # Test functionality
        if chroot /mnt/mipsel-root /bin/bash -c 'which gcc && which python3 && echo "Builder test successful"' 2>/dev/null; then
            echo "Cached builder environment is functional"
            return 0
        else
            echo "Cached builder environment failed test, will rebuild..."
            return 1
        fi
    else
        return 1
    fi
}

# Function to clean old caches (keep only 3 most recent)
cleanup_old_caches() {
    local cache_type="$1"
    local cache_dir="$CACHE_DIR/$cache_type"
    
    if [ -d "$cache_dir" ]; then
        echo "Cleaning up old $cache_type caches..."
        # Keep only the 3 most recent cache files
        ls -t "$cache_dir"/*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f
        echo "Cache cleanup completed for $cache_type"
    fi
}

# Main execution
case "${1:-}" in
    "chroot")
        setup_chroot_cached
        cleanup_old_caches "chroot"
        ;;
    "builder")
        setup_builder_cached
        cleanup_old_caches "builder"
        ;;
    "restore-builder")
        restore_builder_cached
        ;;
    "full-setup")
        # Try to restore complete builder environment first
        if ! restore_builder_cached; then
            echo "No usable builder cache, setting up from scratch..."
            setup_chroot_cached
            setup_builder_cached
        fi
        cleanup_old_caches "chroot"
        cleanup_old_caches "builder"
        ;;
    "clean-cache")
        echo "Cleaning all caches..."
        rm -rf "$CACHE_DIR"
        echo "All caches cleaned"
        ;;
    *)
        echo "Usage: $0 {chroot|builder|restore-builder|full-setup|clean-cache}"
        echo "  chroot         - Setup chroot with caching"
        echo "  builder        - Setup builder tools with caching"
        echo "  restore-builder - Try to restore complete builder environment"
        echo "  full-setup     - Complete setup with optimal caching"
        echo "  clean-cache    - Remove all cached data"
        exit 1
        ;;
esac

echo "Cache operation completed successfully"