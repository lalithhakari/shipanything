#!/bin/bash

# Script to set up Docker configurations for Laravel apps - DEPRECATED
# This functionality has been moved to laravel-manager.sh

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
    source "$SCRIPT_DIR/utils.sh"
else
    print_warning() { echo "⚠️  $1"; }
    print_info() { echo "ℹ️  $1"; }
fi

APP_NAME=$1
if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name>"
    echo ""
    print_warning "This script is deprecated!"
    print_info "Use the new unified Laravel manager instead:"
    echo ""
    echo "  ./scripts/laravel-manager.sh setup <app-name>"
    echo "  ./scripts/laravel-manager.sh setup-all"
    echo ""
    exit 1
fi

print_warning "This script is deprecated!"
print_info "Use the new unified Laravel manager instead:"
echo ""
echo "  ./scripts/laravel-manager.sh setup $APP_NAME"
echo ""
print_info "Redirecting to new script..."
echo ""

# Redirect to the new unified script
exec "$SCRIPT_DIR/laravel-manager.sh" setup "$APP_NAME"
