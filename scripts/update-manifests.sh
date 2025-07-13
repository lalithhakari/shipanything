#!/bin/bash

# Update all Laravel app manifests with APP_KEY and improved readiness probes

set -e

echo "🔧 Updating Laravel app manifests..."

# Define the apps and their keys
declare -A apps=(
    ["payments-app"]="payments-service-key-shipanything-2025"
    ["booking-app"]="booking-service-key-shipanything-2025" 
    ["fraud-detector-app"]="fraud-service-key-shipanything-2025"
)

for app in "${!apps[@]}"; do
    echo "📝 Updating $app..."
    
    # Add APP_KEY to environment variables
    sed -i '' '/- name: APP_DEBUG/a\
        - name: APP_KEY\
          value: "base64:$(echo '"'"'${apps[$app]}'"'"' | base64)"' "k8s/${app}.yaml"
    
    # Update readiness probe settings
    sed -i '' 's/initialDelaySeconds: 60/initialDelaySeconds: 120/' "k8s/${app}.yaml"
    sed -i '' 's/timeoutSeconds: 5/timeoutSeconds: 10/' "k8s/${app}.yaml" 
    sed -i '' 's/failureThreshold: 6/failureThreshold: 10/' "k8s/${app}.yaml"
    
    echo "✅ Updated $app"
done

echo "🎉 All Laravel app manifests updated!"
