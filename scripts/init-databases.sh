#!/usr/bin/env bash

# Database initialization and seeding script for ShipAnything
set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

echo "🗄️ Initializing Databases for ShipAnything..."

# Database services array (compatible with all shells)
DB_SERVICES=(
    "auth:auth-postgres:auth_user:auth_password:auth_db"
    "location:location-postgres:location_user:location_password:location_db"
    "payments:payments-postgres:payments_user:payments_password:payments_db"
    "booking:booking-postgres:booking_user:booking_password:booking_db"
    "fraud:fraud-postgres:fraud_user:fraud_password:fraud_db"
)

# Wait for all databases to be ready
print_info "Waiting for all databases to be ready..."
for db_info in "${DB_SERVICES[@]}"; do
    IFS=':' read -r service pod_prefix user password db <<< "$db_info"
    kubectl wait --for=condition=ready pod -l app=${service}-postgres -n shipanything --timeout=300s
    print_success "${service} database is ready"
done

# Create additional database objects if needed
for db_info in "${DB_SERVICES[@]}"; do
    IFS=':' read -r service pod_prefix user password db <<< "$db_info"
    
    print_info "Configuring ${service} database..."
    
    # Get the pod name
    POD=$(kubectl get pods -n shipanything -l app=${service}-postgres -o jsonpath="{.items[0].metadata.name}")
    
    if [ -n "$POD" ]; then
        # Create additional extensions if needed
        print_info "Setting up database extensions for ${service}..."
        kubectl exec -n shipanything $POD -- psql -U "$user" -d "$db" -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" || print_warning "Extension setup failed for $service"
        kubectl exec -n shipanything $POD -- psql -U "$user" -d "$db" -c "CREATE EXTENSION IF NOT EXISTS \"pg_trgm\";" || print_warning "Extension setup failed for $service"
        
        print_success "Database configuration completed for ${service}"
    else
        print_error "Could not find pod for ${service}-postgres"
    fi
done

print_success "🎉 All databases initialized successfully!"
