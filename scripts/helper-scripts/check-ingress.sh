#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="shipanything"
KONG_NAMESPACE="kong"

echo -e "${BLUE}=== Check Ingress Controller Status ===${NC}"

# Function to check Kong ingress controller
check_kong_status() {
    echo -e "${YELLOW}Checking Kong Ingress Controller...${NC}"
    
    # Check if Kong namespace exists
    if ! kubectl get namespace "${KONG_NAMESPACE}" &> /dev/null; then
        echo -e "${RED}✗ Kong namespace '${KONG_NAMESPACE}' not found${NC}"
        return 1
    fi
    
    # Check Kong deployment
    if kubectl get deployment kong -n "${KONG_NAMESPACE}" &> /dev/null; then
        local ready_replicas
        ready_replicas=$(kubectl get deployment kong -n "${KONG_NAMESPACE}" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired_replicas
        desired_replicas=$(kubectl get deployment kong -n "${KONG_NAMESPACE}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
        
        if [ "$ready_replicas" = "$desired_replicas" ] && [ "$ready_replicas" != "0" ]; then
            echo -e "${GREEN}✓ Kong deployment is ready (${ready_replicas}/${desired_replicas})${NC}"
        else
            echo -e "${RED}✗ Kong deployment not ready (${ready_replicas}/${desired_replicas})${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Kong deployment not found${NC}"
        return 1
    fi
    
    # Check Kong service
    if kubectl get service kong-proxy -n "${KONG_NAMESPACE}" &> /dev/null; then
        local service_type
        service_type=$(kubectl get service kong-proxy -n "${KONG_NAMESPACE}" -o jsonpath='{.spec.type}')
        echo -e "${GREEN}✓ Kong proxy service found (type: ${service_type})${NC}"
        
        # Show service details
        kubectl get service kong-proxy -n "${KONG_NAMESPACE}" -o wide
    else
        echo -e "${RED}✗ Kong proxy service not found${NC}"
        return 1
    fi
    
    return 0
}

# Function to check ingress resources
check_ingress_resources() {
    echo ""
    echo -e "${YELLOW}Checking Ingress resources...${NC}"
    
    if kubectl get ingress -n "${NAMESPACE}" &> /dev/null; then
        local ingress_count
        ingress_count=$(kubectl get ingress -n "${NAMESPACE}" --no-headers | wc -l)
        
        if [ "$ingress_count" -gt 0 ]; then
            echo -e "${GREEN}✓ Found ${ingress_count} ingress resource(s)${NC}"
            echo ""
            kubectl get ingress -n "${NAMESPACE}" -o wide
        else
            echo -e "${YELLOW}! No ingress resources found in namespace '${NAMESPACE}'${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to check ingress resources${NC}"
        return 1
    fi
    
    return 0
}

# Function to check ingress class
check_ingress_class() {
    echo ""
    echo -e "${YELLOW}Checking IngressClass...${NC}"
    
    if kubectl get ingressclass kong &> /dev/null; then
        local is_default
        is_default=$(kubectl get ingressclass kong -o jsonpath='{.metadata.annotations.ingressclass\.kubernetes\.io/is-default-class}' 2>/dev/null || echo "false")
        
        echo -e "${GREEN}✓ Kong IngressClass found${NC}"
        if [ "$is_default" = "true" ]; then
            echo -e "${GREEN}✓ Kong is set as default IngressClass${NC}"
        else
            echo -e "${YELLOW}! Kong is not the default IngressClass${NC}"
        fi
        
        kubectl get ingressclass kong -o wide
    else
        echo -e "${RED}✗ Kong IngressClass not found${NC}"
        return 1
    fi
    
    return 0
}

# Function to test ingress connectivity
test_ingress_connectivity() {
    echo ""
    echo -e "${YELLOW}Testing ingress connectivity...${NC}"
    
    # Get Kong proxy service external IP/port
    local service_type
    service_type=$(kubectl get service kong-proxy -n "${KONG_NAMESPACE}" -o jsonpath='{.spec.type}')
    
    if [ "$service_type" = "LoadBalancer" ]; then
        local external_ip
        external_ip=$(kubectl get service kong-proxy -n "${KONG_NAMESPACE}" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        
        if [ -z "$external_ip" ]; then
            external_ip=$(kubectl get service kong-proxy -n "${KONG_NAMESPACE}" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        fi
        
        if [ -n "$external_ip" ]; then
            echo -e "${GREEN}✓ External IP/Hostname: ${external_ip}${NC}"
            
            # Test HTTP connectivity
            echo -e "${BLUE}Testing HTTP connectivity...${NC}"
            if curl -s --max-time 5 "http://${external_ip}" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ HTTP connectivity successful${NC}"
            else
                echo -e "${YELLOW}! HTTP connectivity failed (this may be expected if no default backend is configured)${NC}"
            fi
        else
            echo -e "${YELLOW}! External IP not yet assigned${NC}"
        fi
    elif [ "$service_type" = "NodePort" ]; then
        local node_port
        node_port=$(kubectl get service kong-proxy -n "${KONG_NAMESPACE}" -o jsonpath='{.spec.ports[0].nodePort}')
        echo -e "${YELLOW}NodePort service detected (port: ${node_port})${NC}"
        echo -e "${BLUE}For local access, use: localhost:${node_port}${NC}"
    else
        echo -e "${YELLOW}Service type '${service_type}' detected${NC}"
    fi
}

# Function to show ingress endpoints
show_ingress_endpoints() {
    echo ""
    echo -e "${YELLOW}Application endpoints (add to /etc/hosts for local development):${NC}"
    echo ""
    
    # For Kind clusters, assume localhost
    local current_context
    current_context=$(kubectl config current-context 2>/dev/null || echo "")
    
    if echo "$current_context" | grep -q "kind-"; then
        echo "127.0.0.1 auth.shipanything.test"
        echo "127.0.0.1 booking.shipanything.test"
        echo "127.0.0.1 detector.shipanything.test"
        echo "127.0.0.1 location.shipanything.test"
        echo "127.0.0.1 payments.shipanything.test"
        echo ""
        echo -e "${BLUE}Access your applications at:${NC}"
        echo "• http://auth.shipanything.test"
        echo "• http://booking.shipanything.test"
        echo "• http://detector.shipanything.test"
        echo "• http://location.shipanything.test"
        echo "• http://payments.shipanything.test"
    else
        # For other clusters, try to get the external IP
        local external_ip
        external_ip=$(kubectl get service kong-proxy -n "${KONG_NAMESPACE}" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        
        if [ -z "$external_ip" ]; then
            external_ip=$(kubectl get service kong-proxy -n "${KONG_NAMESPACE}" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        fi
        
        if [ -n "$external_ip" ]; then
            echo "${external_ip} auth.shipanything.test"
            echo "${external_ip} booking.shipanything.test"
            echo "${external_ip} detector.shipanything.test"
            echo "${external_ip} location.shipanything.test"
            echo "${external_ip} payments.shipanything.test"
        else
            echo -e "${YELLOW}External IP not available. Check your LoadBalancer configuration.${NC}"
        fi
    fi
}

# Function to show troubleshooting tips
show_troubleshooting_tips() {
    echo ""
    echo -e "${YELLOW}Troubleshooting tips:${NC}"
    echo ""
    echo "• Check Kong logs:"
    echo "  kubectl logs -l app=kong -n ${KONG_NAMESPACE}"
    echo ""
    echo "• Check Kong configuration:"
    echo "  kubectl exec -it deployment/kong -n ${KONG_NAMESPACE} -- kong config"
    echo ""
    echo "• Verify ingress resources:"
    echo "  kubectl describe ingress -n ${NAMESPACE}"
    echo ""
    echo "• Check service endpoints:"
    echo "  kubectl get endpoints -n ${NAMESPACE}"
    echo ""
    echo "• Restart Kong deployment:"
    echo "  kubectl rollout restart deployment/kong -n ${KONG_NAMESPACE}"
}

# Main function
main() {
    local overall_status=0
    
    # Check Kong status
    if ! check_kong_status; then
        overall_status=1
    fi
    
    # Check ingress class
    if ! check_ingress_class; then
        overall_status=1
    fi
    
    # Check ingress resources
    if ! check_ingress_resources; then
        overall_status=1
    fi
    
    # Test connectivity
    test_ingress_connectivity
    
    # Show endpoints
    show_ingress_endpoints
    
    # Show troubleshooting tips if there are issues
    if [ $overall_status -ne 0 ]; then
        show_troubleshooting_tips
    fi
    
    echo ""
    if [ $overall_status -eq 0 ]; then
        echo -e "${GREEN}✓ Ingress controller appears to be working correctly${NC}"
    else
        echo -e "${RED}✗ Issues detected with ingress controller${NC}"
    fi
    
    exit $overall_status
}

# Run main function
main "$@"
