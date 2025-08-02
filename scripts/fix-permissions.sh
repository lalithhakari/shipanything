#!/bin/bash
# Fix Laravel storage permissions for all microservices
# This script is now integrated into deploy.sh but can be run standalone

echo "🔧 Fixing Laravel storage permissions..."

for service in auth-app booking-app detector-app location-app payments-app; do
  echo "Fixing permissions for $service..."
  if kubectl get deployment "$service" -n shipanything &>/dev/null; then
    # Ensure directories exist
    kubectl exec -n shipanything deployment/$service -- mkdir -p /var/www/html/storage/framework/views || echo "Warning: Failed to create views directory for $service"
    kubectl exec -n shipanything deployment/$service -- mkdir -p /var/www/html/storage/framework/cache || echo "Warning: Failed to create cache directory for $service"
    kubectl exec -n shipanything deployment/$service -- mkdir -p /var/www/html/storage/framework/sessions || echo "Warning: Failed to create sessions directory for $service"
    kubectl exec -n shipanything deployment/$service -- mkdir -p /var/www/html/storage/logs || echo "Warning: Failed to create logs directory for $service"
    kubectl exec -n shipanything deployment/$service -- mkdir -p /var/www/html/bootstrap/cache || echo "Warning: Failed to create bootstrap cache directory for $service"
    
    # Fix ownership
    kubectl exec -n shipanything deployment/$service -- chown -R www:www /var/www/html/storage || echo "Warning: Failed to change ownership for $service"
    kubectl exec -n shipanything deployment/$service -- chown -R www:www /var/www/html/bootstrap/cache || echo "Warning: Failed to change ownership for bootstrap cache for $service"
    
    # Fix permissions (more permissive to ensure write access)
    kubectl exec -n shipanything deployment/$service -- chmod -R 777 /var/www/html/storage || echo "Warning: Failed to fix permissions for $service"
    kubectl exec -n shipanything deployment/$service -- chmod -R 777 /var/www/html/bootstrap/cache || echo "Warning: Failed to fix permissions for bootstrap cache for $service"
    
    # Clear compiled views to force regeneration with correct permissions
    kubectl exec -n shipanything deployment/$service -- rm -f /var/www/html/storage/framework/views/*.php || echo "Warning: Failed to clear compiled views for $service"
    
    # Clear Laravel caches to force regeneration
    kubectl exec -n shipanything deployment/$service -- php /var/www/html/artisan config:clear || echo "Warning: Failed to clear config cache for $service"
    kubectl exec -n shipanything deployment/$service -- php /var/www/html/artisan view:clear || echo "Warning: Failed to clear view cache for $service"
    kubectl exec -n shipanything deployment/$service -- php /var/www/html/artisan route:clear || echo "Warning: Failed to clear route cache for $service"
  else
    echo "Warning: $service deployment not found"
  fi
done

echo "✅ Permission fixing complete!"
