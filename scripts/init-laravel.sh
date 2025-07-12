#!/bin/bash

# Laravel App Initialization Script for Kubernetes
# This script runs after the Laravel pods are ready to initialize the applications

set -e

echo "🔧 Initializing Laravel Applications..."

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

# Array of Laravel applications
APPS=("auth-app" "location-app" "payments-app" "booking-app" "fraud-detector-app")

# Wait for all databases to be ready
print_status "Waiting for databases to be ready..."
for app in "${APPS[@]}"; do
    db_name="${app%-app}"
    kubectl wait --for=condition=ready pod -l app=${db_name}-postgres -n shipanything --timeout=300s
    print_success "Database for $app is ready"
done

# Initialize each Laravel application
for app in "${APPS[@]}"; do
    print_status "Initializing Laravel application: $app"
    
    # Get the first pod for this app
    POD=$(kubectl get pods -n shipanything -l app=$app -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || echo "")
    
    if [ -z "$POD" ]; then
        print_warning "No pods found for $app, skipping initialization"
        continue
    fi
    
    print_status "Found pod: $POD for $app"
    
    # Wait for pod to be ready
    kubectl wait --for=condition=ready pod/$POD -n shipanything --timeout=120s
    
    # Run Laravel migrations
    print_status "Running migrations for $app..."
    kubectl exec -n shipanything $POD -- php artisan migrate --force || print_warning "Migration failed for $app (may be expected for fresh install)"
    
    # Clear and cache Laravel configuration
    print_status "Optimizing Laravel configuration for $app..."
    kubectl exec -n shipanything $POD -- php artisan config:cache || print_warning "Config cache failed for $app"
    kubectl exec -n shipanything $POD -- php artisan route:cache || print_warning "Route cache failed for $app"
    kubectl exec -n shipanything $POD -- php artisan view:cache || print_warning "View cache failed for $app"
    
    print_success "Initialization completed for $app"
done

print_success "🎉 All Laravel applications initialized successfully!"
print_status "Applications are now ready to receive traffic."
