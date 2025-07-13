#!/bin/bash

# Laravel App Initialization Script for Kubernetes - DEPRECATED
# This functionality has been moved to laravel-manager.sh

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_warning "This script is deprecated!"
print_info "Use the new unified Laravel manager instead:"
echo ""
echo "  ./scripts/laravel-manager.sh k8s-init"
echo ""
print_info "Redirecting to new script..."
echo ""

# Redirect to the new unified script
exec "$SCRIPT_DIR/laravel-manager.sh" k8s-init
