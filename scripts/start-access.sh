#!/bin/bash
# Start Kong port forwarding for microservices access

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting ShipAnything microservices access...${NC}"
echo -e "${YELLOW}📡 Setting up Kong port forwarding on localhost:8080${NC}"

# Kill any existing port forwarding
pkill -f "kubectl port-forward.*8080:80" 2>/dev/null || true
sleep 2

# Check if Kong service exists and find the right one
kong_service=""
if kubectl get service -n kong kong-kong-proxy &>/dev/null; then
    kong_service="kong/kong-kong-proxy"
elif kubectl get service -n kong-system kong-kong-proxy &>/dev/null; then
    kong_service="kong-system/kong-kong-proxy"
elif kubectl get service -n kong kong-proxy &>/dev/null; then
    kong_service="kong/kong-proxy"
elif kubectl get service -n shipanything kong &>/dev/null; then
    kong_service="shipanything/kong"
else
    echo -e "${RED}❌ No Kong service found!${NC}"
    echo -e "${YELLOW}Available services:${NC}"
    kubectl get services --all-namespaces | grep -i kong
    exit 1
fi

echo -e "${BLUE}Found Kong service: ${kong_service}${NC}"

# Start port forwarding in background
kubectl port-forward -n "${kong_service%/*}" "service/${kong_service#*/}" 8080:80 >/dev/null 2>&1 &
KUBECTL_PID=$!

# Wait a moment and check if port forwarding is working
sleep 3
if kill -0 $KUBECTL_PID 2>/dev/null; then
    echo -e "${GREEN}✅ Port forwarding started (PID: $KUBECTL_PID)${NC}"
    echo ""
    echo -e "${GREEN}🌐 Your microservices are now accessible at:${NC}"
    echo -e "${BLUE}   • Auth Service:     http://auth.shipanything.test:8080${NC}"
    echo -e "${BLUE}   • Booking Service:  http://booking.shipanything.test:8080${NC}"
    echo -e "${BLUE}   • Detector Service: http://detector.shipanything.test:8080${NC}"
    echo -e "${BLUE}   • Location Service: http://location.shipanything.test:8080${NC}"
    echo -e "${BLUE}   • Payments Service: http://payments.shipanything.test:8080${NC}"
    echo ""
    echo -e "${YELLOW}📝 To stop port forwarding, run: kill $KUBECTL_PID${NC}"
    echo -e "${YELLOW}💡 Or use: pkill -f 'kubectl port-forward'${NC}"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop port forwarding and exit.${NC}"
    
    # Save PID for reference
    echo $KUBECTL_PID > "/tmp/kong-port-forward.pid"
else
    echo -e "${RED}❌ Failed to start port forwarding${NC}"
    exit 1
fi

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Stopping port forwarding...${NC}"
    kill $KUBECTL_PID 2>/dev/null
    rm -f "/tmp/kong-port-forward.pid"
    echo -e "${GREEN}✅ Port forwarding stopped${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Wait for the port forwarding process
wait $KUBECTL_PID
