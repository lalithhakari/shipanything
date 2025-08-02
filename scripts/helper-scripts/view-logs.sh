#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="shipanything"

echo -e "${BLUE}=== View Application Logs ===${NC}"

# Function to show usage
show_usage() {
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 <service-name> [options]"
    echo ""
    echo -e "${YELLOW}Available services:${NC}"
    echo "  • auth-app"
    echo "  • booking-app"
    echo "  • detector-app"
    echo "  • location-app"
    echo "  • payments-app"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -f, --follow     Follow log output"
    echo "  -t, --tail N     Show last N lines (default: 100)"
    echo "  --previous       Show logs from previous container instance"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 auth-app"
    echo "  $0 booking-app --follow"
    echo "  $0 detector-app --tail 50"
    echo ""
}

# Function to list running pods
list_pods() {
    echo -e "${YELLOW}Available pods in namespace '${NAMESPACE}':${NC}"
    kubectl get pods -n "${NAMESPACE}" -o wide 2>/dev/null || {
        echo -e "${RED}Failed to list pods. Is the cluster running and namespace deployed?${NC}"
        exit 1
    }
    echo ""
}

# Function to view logs
view_logs() {
    local service_name="$1"
    local follow="$2"
    local tail_lines="$3"
    local previous="$4"
    
    # Check if service exists
    if ! kubectl get deployment "${service_name}" -n "${NAMESPACE}" &> /dev/null; then
        echo -e "${RED}Error: Service '${service_name}' not found in namespace '${NAMESPACE}'${NC}"
        echo ""
        list_pods
        exit 1
    fi
    
    # Build kubectl logs command
    local cmd="kubectl logs"
    
    if [ "$follow" = true ]; then
        cmd="${cmd} -f"
    fi
    
    if [ -n "$tail_lines" ]; then
        cmd="${cmd} --tail=${tail_lines}"
    fi
    
    if [ "$previous" = true ]; then
        cmd="${cmd} --previous"
    fi
    
    cmd="${cmd} -l app=${service_name} -n ${NAMESPACE}"
    
    echo -e "${YELLOW}Viewing logs for '${service_name}'...${NC}"
    echo -e "${BLUE}Command: ${cmd}${NC}"
    echo ""
    
    # Execute the command
    eval "$cmd" || {
        echo -e "${RED}Failed to retrieve logs${NC}"
        exit 1
    }
}

# Main function
main() {
    # Parse arguments
    local service_name=""
    local follow=false
    local tail_lines="100"
    local previous=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--follow)
                follow=true
                shift
                ;;
            -t|--tail)
                tail_lines="$2"
                shift 2
                ;;
            --previous)
                previous=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$service_name" ]; then
                    service_name="$1"
                else
                    echo -e "${RED}Too many arguments${NC}"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if service name is provided
    if [ -z "$service_name" ]; then
        echo -e "${RED}Error: Service name is required${NC}"
        show_usage
        list_pods
        exit 1
    fi
    
    # Validate service name
    case "$service_name" in
        auth-app|booking-app|detector-app|location-app|payments-app)
            view_logs "$service_name" "$follow" "$tail_lines" "$previous"
            ;;
        *)
            echo -e "${RED}Error: Invalid service name '${service_name}'${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
