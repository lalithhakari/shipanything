#!/bin/bash
set -e

echo "🚀 Testing ShipAnything Microservices Platform"
echo "=============================================="
echo ""

# Function to test service via ingress
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
            pod_name=$(echo $line | awk '{print $1}')
            ready=$(echo $line | awk '{print $2}')
            status=$(echo $line | awk '{print $3}')
            echo "      📦 $pod_name: $ready $status"
        fi
    done
    
    return 1
}

# Function to test service via NodePort (fallback)
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

# Check prerequisites
echo "🔧 Checking prerequisites..."

# Check if ingress controller is ready
if ! kubectl get pods -n ingress-nginx --selector=app.kubernetes.io/component=controller 2>/dev/null | grep -q "Running"; then
    echo "❌ NGINX Ingress Controller is not running"
    echo "🔧 Run: kubectl get pods -n ingress-nginx"
    exit 1
fi

# Check if services exist
if ! kubectl get service -n shipanything web-nginx &>/dev/null; then
    echo "❌ Services are not deployed yet"
    echo "🔧 Run the deployment script first: ./scripts/deploy.sh"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Test services using ingress (primary method)
echo "🌐 Testing services via ingress (primary method)..."
echo ""

services_passed=0
services_total=0

# Test main dashboard
services_total=$((services_total + 1))
if test_service_ingress "web-nginx" "shipanything.test" "Main Dashboard"; then
    services_passed=$((services_passed + 1))
fi
echo ""

# Test microservices
services=(
    "auth-app|auth.shipanything.test|Auth Service"
    "location-app|location.shipanything.test|Location Service"
    "payments-app|payments.shipanything.test|Payments Service"
    "booking-app|booking.shipanything.test|Booking Service"
    "fraud-detector-app|fraud.shipanything.test|Fraud Detector"
)

for service_info in "${services[@]}"; do
    services_total=$((services_total + 1))
    IFS='|' read -r service host description <<< "$service_info"
    if test_service_ingress "$service" "$host" "$description"; then
        services_passed=$((services_passed + 1))
    fi
    echo ""
done

# Test NodePort services as fallback
echo "🔧 Testing NodePort services (fallback method)..."
echo ""

nodeport_services=(
    "web-nginx|30080|Main Dashboard"
    "auth-app|30081|Auth Service"
    "location-app|30082|Location Service"
    "payments-app|30083|Payments Service"
    "booking-app|30084|Booking Service"
    "fraud-detector-app|30085|Fraud Detector"
)

nodeport_passed=0
for service_info in "${nodeport_services[@]}"; do
    IFS='|' read -r service port description <<< "$service_info"
    if test_service_nodeport "$service" "$port" "$description"; then
        nodeport_passed=$((nodeport_passed + 1))
    fi
done

echo ""
echo "📊 Test Results Summary:"
echo "   Ingress Tests: $services_passed/$services_total services"
echo "   NodePort Tests: $nodeport_passed/6 services"

if [ $services_passed -eq $services_total ]; then
    echo "   🎉 All ingress services are working correctly!"
    echo ""
    echo "🌐 Verified Access URLs:"
    echo "   🌟 Main Dashboard: http://shipanything.test"
    echo "   🔐 Auth Service: http://auth.shipanything.test"
    echo "   📍 Location Service: http://location.shipanything.test"
    echo "   💳 Payments Service: http://payments.shipanything.test"
    echo "   📅 Booking Service: http://booking.shipanything.test"
    echo "   🔍 Fraud Detector: http://fraud.shipanything.test"
    exit 0
elif [ $nodeport_passed -gt 0 ]; then
    echo "   ⚠️  Ingress tests failed, but NodePort services are working"
    echo ""
    echo "🔧 Troubleshooting ingress issues:"
    echo "   1. Check ingress status: kubectl get ingress -n shipanything"
    echo "   2. Check hosts file: grep shipanything /etc/hosts"
    echo "   3. Verify ingress controller: kubectl get pods -n ingress-nginx"
    echo ""
    echo "📋 Working NodePort URLs:"
    echo "   http://localhost:30080 (Main Dashboard)"
    echo "   http://localhost:30081 (Auth Service)"
    echo "   http://localhost:30082 (Location Service)"
    echo "   http://localhost:30083 (Payments Service)"
    echo "   http://localhost:30084 (Booking Service)"
    echo "   http://localhost:30085 (Fraud Detector)"
    exit 1
else
    echo "   ❌ Both ingress and NodePort tests failed"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   1. Check pod status: kubectl get pods -n shipanything"
    echo "   2. Check service logs: kubectl logs -l app=<service-name> -n shipanything"
    echo "   3. Verify services: kubectl get services -n shipanything"
    echo "   4. Check readiness probes: kubectl describe pods -n shipanything"
    exit 1
fi
