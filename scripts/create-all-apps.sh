#!/bin/bash

# Script to create all Laravel applications
set -e

echo "🚀 Creating all Laravel applications for ShipAnything..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Change to microservices directory
cd "$(dirname "$0")/../microservices"

# Array of Laravel applications to create
APPS=("auth-app" "location-app" "payments-app" "booking-app" "fraud-detector-app")

# Create each Laravel application
for app in "${APPS[@]}"; do
    if [ ! -d "$app" ]; then
        print_status "Creating Laravel application: $app"
        echo "⚠️  Please manually select options for $app when prompted"
        laravel new "$app"
        
        print_status "Setting up Docker configuration for $app..."
        "$(dirname "$0")/setup-laravel-docker.sh" "$app"
        
        print_success "Completed setup for $app"
        echo ""
    else
        print_warning "$app already exists, skipping creation"
    fi
done

print_success "🎉 All Laravel applications have been created!"
print_status "Next steps:"
echo "  1. Review the generated Laravel applications"
echo "  2. Run ./scripts/deploy.sh to deploy to Kubernetes"
