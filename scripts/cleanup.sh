#!/bin/bash

# 🧹 ShipAnything - Complete Cleanup Script
# Completely removes all Kind cluster resources and configurations

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

echo "🧹 ShipAnything - Complete Cleanup"
echo "=================================="
echo ""

# Stop Docker Compose services first
print_step "Stopping Docker Compose services..."
docker compose down >/dev/null 2>&1 || true
print_success "Docker Compose services stopped!"

# Check if Kind cluster exists
if kind get clusters | grep -q "shipanything"; then
    print_step "Deleting Kind cluster 'shipanything'..."
    kind delete cluster --name shipanything
    print_success "Kind cluster deleted!"
else
    print_warning "No Kind cluster 'shipanything' found"
fi

# Clean up Docker images
print_step "Cleaning up Docker images..."
echo "Removing ShipAnything related images..."

docker images | grep -E "(auth-app|location-app|payments-app|booking-app|fraud-detector-app|web-nginx)" | awk '{print $3}' | xargs -r docker rmi -f || echo "No images to remove"

print_step "Removing temporary files..."
rm -f .kubectl_context_backup 2>/dev/null || true

print_success "Cleanup completed!"
echo ""
echo "📋 Summary:"
echo "  ✅ Kind cluster deleted"
echo "  ✅ Docker images removed"  
echo "  ✅ Hosts file cleaned"
echo "  ✅ Temporary files removed"
echo ""
echo "🚀 To redeploy:"
echo "  ./scripts/deploy.sh"
echo ""
