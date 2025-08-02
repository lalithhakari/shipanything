#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="shipanything"

echo -e "${BLUE}=== Execute Command in Application Pod ===${NC}"

# Function to show usage
show_usage() {
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 <service-name> [command]"
    echo ""
    echo -e "${YELLOW}Available services:${NC}"
    echo "  • auth-app"
    echo "  • booking-app"
    echo "  • detector-app"    
    echo "  • location-app"
    echo "  • payments-app"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 auth-app                    # Interactive shell"
    echo "  $0 auth-app /bin/bash          # Specific shell"
    echo "  $0 booking-app php artisan --version"
    echo "  $0 detector-app ls -la /var/www"
    echo "  $0 location-app ps aux"
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

# Function to get pod name for service
get_pod_name() {
    local service_name="$1"
    
    # Get the first running pod for the service
    local pod_name
    pod_name=$(kubectl get pods -n "${NAMESPACE}" -l app="${service_name}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        echo -e "${RED}Error: No running pods found for service '${service_name}'${NC}"
        echo ""
        list_pods
        exit 1
    fi
    
    # Check if pod is ready
    local pod_status
    pod_status=$(kubectl get pod "${pod_name}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}' 2>/dev/null)
    
    if [ "$pod_status" != "Running" ]; then
        echo -e "${RED}Error: Pod '${pod_name}' is not running (status: ${pod_status})${NC}"
        echo ""
        list_pods
        exit 1
    fi
    
    echo "$pod_name"
}

# Function to execute command in pod
exec_in_pod() {
    local service_name="$1"
    shift
    local command=("$@")
    
    # Get pod name
    local pod_name
    pod_name=$(get_pod_name "$service_name")
    
    echo -e "${YELLOW}Executing in pod '${pod_name}'...${NC}"
    
    # If no command specified, start interactive shell
    if [ ${#command[@]} -eq 0 ]; then
        echo -e "${BLUE}Starting interactive shell...${NC}"
        echo -e "${YELLOW}Tip: Type 'exit' to return to your local shell${NC}"
        echo ""
        
        # Try different shells in order of preference
        if kubectl exec -it "${pod_name}" -n "${NAMESPACE}" -- which bash &> /dev/null; then
            kubectl exec -it "${pod_name}" -n "${NAMESPACE}" -- bash
        elif kubectl exec -it "${pod_name}" -n "${NAMESPACE}" -- which sh &> /dev/null; then
            kubectl exec -it "${pod_name}" -n "${NAMESPACE}" -- sh
        else
            echo -e "${RED}No shell found in the container${NC}"
            exit 1
        fi
    else
        echo -e "${BLUE}Command: ${command[*]}${NC}"
        echo ""
        
        # Execute the specified command
        kubectl exec -it "${pod_name}" -n "${NAMESPACE}" -- "${command[@]}" || {
            echo -e "${RED}Command execution failed${NC}"
            exit 1
        }
    fi
}

# Main function
main() {
    # Parse arguments
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: Service name is required${NC}"
        show_usage
        list_pods
        exit 1
    fi
    
    local service_name="$1"
    shift
    
    # Handle help option
    if [ "$service_name" = "-h" ] || [ "$service_name" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    # Validate service name
    case "$service_name" in
        auth-app|booking-app|detector-app|location-app|payments-app)
            exec_in_pod "$service_name" "$@"
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
