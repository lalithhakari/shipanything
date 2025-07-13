#!/bin/bash

# 🔧 ShipAnything - Shared Utility Functions
# Common functions used across all scripts

# Color definitions
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# Shared print functions
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

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_fail() {
    echo -e "${RED}[✗]${NC} $1"
}

# Service definitions
export LARAVEL_APPS=("auth-app" "location-app" "payments-app" "booking-app" "fraud-detector-app")
export SERVICES=("web-nginx" "auth-app" "location-app" "payments-app" "booking-app" "fraud-detector-app")

# Service URLs
export SERVICE_URLS=(
    "web-nginx|30080|Main Dashboard|shipanything.test"
    "auth-app|30081|Auth Service|auth.shipanything.test"
    "location-app|30082|Location Service|location.shipanything.test"
    "payments-app|30083|Payments Service|payments.shipanything.test"
    "booking-app|30084|Booking Service|booking.shipanything.test"
    "fraud-detector-app|30085|Fraud Detector|fraud.shipanything.test"
)

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker Desktop first."
        return 1
    fi
    return 0
}

# Check if Kind is installed
check_kind() {
    if ! command -v kind &> /dev/null; then
        print_error "Kind is not installed. Install it with: brew install kind"
        return 1
    fi
    return 0
}

# Check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Install it with: brew install kubectl"
        return 1
    fi
    return 0
}

# Check if Kind cluster exists
check_kind_cluster() {
    kind get clusters | grep -q "shipanything"
}

# Wait for pods to be ready
wait_for_pods() {
    local namespace=${1:-shipanything}
    local timeout=${2:-300}
    
    print_step "Waiting for pods to be ready in namespace $namespace..."
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        local not_ready=$(kubectl get pods -n $namespace --no-headers 2>/dev/null | grep -v "1/1.*Running\|Completed" | wc -l | tr -d ' ')
        
        if [ "$not_ready" -eq 0 ]; then
            print_success "All pods are ready!"
            return 0
        fi
        
        echo "Waiting for $not_ready pods to be ready... ($elapsed/$timeout seconds)"
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    print_warning "Timeout waiting for pods to be ready"
    kubectl get pods -n $namespace
    return 1
}

# Test service connectivity
test_service_connection() {
    local service_name=$1
    local port=$2
    local timeout=${3:-10}
    
    if timeout $timeout curl -s --connect-timeout 5 --max-time 10 http://localhost:$port/ >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Update hosts file
update_hosts_file() {
    print_step "Updating /etc/hosts file for custom domains..."
    
    # Check if entries already exist
    if ! grep -q "shipanything.test" /etc/hosts; then
        echo "Adding hosts file entries..."
        
        # Add hosts entries
        sudo sh -c 'cat >> /etc/hosts << EOF

# ShipAnything - Local Development
127.0.0.1 shipanything.test
127.0.0.1 auth.shipanything.test
127.0.0.1 location.shipanything.test
127.0.0.1 payments.shipanything.test
127.0.0.1 booking.shipanything.test
127.0.0.1 fraud.shipanything.test
EOF'
        print_success "Hosts file updated!"
    else
        print_success "Hosts file entries already exist!"
    fi
}

# Show service access information
show_service_access_info() {
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Access your services:"
    echo ""
    echo "🌐 Localhost Access:"
    for service_info in "${SERVICE_URLS[@]}"; do
        IFS='|' read -r service port description host <<< "$service_info"
        echo "  🔗 $description: http://localhost:$port"
    done
    echo ""
    echo "🏷️  Custom Domain Access:"
    for service_info in "${SERVICE_URLS[@]}"; do
        IFS='|' read -r service port description host <<< "$service_info"
        echo "  🌟 $description: http://$host"
    done
    echo ""
}

# Service testing functions
test_service_ingress() {
    local service_name=$1
    local host_header=$2
    local description=$3
    
    echo "🔍 Testing $description..."
    echo "   Service: $service_name"
    echo "   Host: $host_header"
    
    # Test with curl using host header (Kind ingress approach)
    local response
    if response=$(curl -s -H "Host: $host_header" --connect-timeout 10 --max-time 15 http://localhost/ 2>/dev/null); then
        if echo "$response" | head -1 | grep -q -E "<!DOCTYPE|<html|Welcome"; then
            echo "   ✅ $description is responding correctly"
            return 0
        else
            echo "   ❌ $description returned unexpected content"
            echo "   📝 Response preview: $(echo "$response" | head -1 | cut -c1-100)..."
        fi
    else
        echo "   ❌ $description connection failed"
    fi
    
    # Show pod status for debugging
    echo "   🔍 Pod status:"
    kubectl get pods -l app=$service_name -n shipanything --no-headers 2>/dev/null | while read line; do
        if [ -n "$line" ]; then
            name=$(echo $line | awk '{print $1}')
            ready=$(echo $line | awk '{print $2}')
            status=$(echo $line | awk '{print $3}')
            echo "     $name: $ready $status"
        fi
    done
    
    return 1
}

test_service_nodeport() {
    local service_name=$1
    local nodeport=$2
    local description=$3
    
    echo "🔄 Testing $description via NodePort (fallback)..."
    echo "   NodePort: $nodeport"
    
    if curl -s --connect-timeout 5 --max-time 10 http://localhost:$nodeport/ | head -1 | grep -q -E "<!DOCTYPE|<html|Welcome"; then
        echo "   ✅ $description NodePort is working"
        return 0
    else
        echo "   ❌ $description NodePort failed"
        return 1
    fi
}
