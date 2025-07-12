#!/bin/bash

# 🧹 ShipAnything - Kind Cleanup Script
# Completely removes all Kind cluster resources and configurations

set -e

echo "🧹 ShipAnything - Complete Cleanup"
echo "=================================="
echo ""

# Function to print colored output
print_step() {
    echo "🔧 $1"
}

print_success() {
    echo "✅ $1"
}

print_warning() {
    echo "⚠️  $1"
}

print_error() {
    echo "❌ $1"
}

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

print_step "Cleaning up hosts file entries..."
if grep -q "shipanything.test" /etc/hosts; then
    print_warning "Removing hosts file entries (requires sudo)..."
    sudo sed -i '' '/shipanything.test/d' /etc/hosts
    print_success "Hosts file cleaned!"
else
    print_success "No hosts file entries found"
fi

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
