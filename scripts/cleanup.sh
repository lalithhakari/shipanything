#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
CLUSTER_NAME="shipanything"
NAMESPACE="shipanything"

echo -e "${BLUE}=== ShipAnything Cleanup Script ===${NC}"
echo ""

# Function to confirm cleanup
confirm_cleanup() {
    echo -e "${YELLOW}This will:${NC}"
    echo "• Delete the Kind cluster '${CLUSTER_NAME}'"
    echo "• Delete the namespace '${NAMESPACE}' (if cluster is external)"
    echo "• Prune all unused Docker resources"
    echo ""
    
    while true; do
        read -p "Are you sure you want to continue? (y/N): " choice
        case $choice in
            [Yy]*)
                break
                ;;
            [Nn]*|"")
                echo -e "${YELLOW}Cleanup cancelled${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Please enter 'y' for yes or 'n' for no${NC}"
                ;;
        esac
    done
}

# Function to delete Kind cluster
delete_kind_cluster() {
    echo -e "${YELLOW}Checking for Kind cluster '${CLUSTER_NAME}'...${NC}"
    
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        echo -e "${YELLOW}Deleting Kind cluster '${CLUSTER_NAME}'...${NC}"
        kind delete cluster --name="${CLUSTER_NAME}" || {
            echo -e "${RED}Failed to delete Kind cluster${NC}"
            exit 1
        }
        echo -e "${GREEN}✓ Kind cluster deleted${NC}"
    else
        echo -e "${YELLOW}Kind cluster '${CLUSTER_NAME}' not found${NC}"
    fi
}

# Function to delete namespace (for external clusters)
delete_namespace() {
    # Check if we're connected to a different cluster
    current_context=$(kubectl config current-context 2>/dev/null || echo "")
    
    if [ -n "$current_context" ] && ! echo "$current_context" | grep -q "kind-${CLUSTER_NAME}"; then
        echo -e "${YELLOW}Detected external cluster. Checking for namespace '${NAMESPACE}'...${NC}"
        
        if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
            echo -e "${YELLOW}Deleting namespace '${NAMESPACE}'...${NC}"
            kubectl delete namespace "${NAMESPACE}" --timeout=300s || {
                echo -e "${RED}Failed to delete namespace${NC}"
                exit 1
            }
            echo -e "${GREEN}✓ Namespace deleted${NC}"
        else
            echo -e "${YELLOW}Namespace '${NAMESPACE}' not found${NC}"
        fi
    fi
}

# Function to prune Docker resources
prune_docker_resources() {
    echo -e "${YELLOW}Pruning unused Docker resources...${NC}"
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}Docker is not running or not accessible${NC}"
        exit 1
    fi
    
    # Prune unused containers
    echo -e "${BLUE}Removing stopped containers...${NC}"
    docker container prune -f || echo -e "${YELLOW}No containers to remove${NC}"
    
    # Prune unused images
    echo -e "${BLUE}Removing unused images...${NC}"
    docker image prune -f || echo -e "${YELLOW}No images to remove${NC}"
    
    # Prune unused networks
    echo -e "${BLUE}Removing unused networks...${NC}"
    docker network prune -f || echo -e "${YELLOW}No networks to remove${NC}"
    
    # Prune unused volumes
    echo -e "${BLUE}Removing unused volumes...${NC}"
    docker volume prune -f || echo -e "${YELLOW}No volumes to remove${NC}"
    
    # Prune build cache
    echo -e "${BLUE}Removing build cache...${NC}"
    docker builder prune -f || echo -e "${YELLOW}No build cache to remove${NC}"
    
    echo -e "${GREEN}✓ Docker resources pruned${NC}"
}

# Function to remove project-specific Docker images
remove_project_images() {
    echo -e "${YELLOW}Removing project-specific Docker images...${NC}"
    
    # List of microservices
    local services=("auth-app" "booking-app" "detector-app" "location-app" "payments-app")
    
    for service in "${services[@]}"; do
        # Remove local images
        if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^${service}:latest$"; then
            echo -e "${BLUE}Removing ${service}:latest...${NC}"
            docker rmi "${service}:latest" -f || echo -e "${YELLOW}Failed to remove ${service}:latest${NC}"
        fi
        
        # Remove registry images (if they exist locally)
        if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "registry.example.com/${service}:latest"; then
            echo -e "${BLUE}Removing registry.example.com/${service}:latest...${NC}"
            docker rmi "registry.example.com/${service}:latest" -f || echo -e "${YELLOW}Failed to remove registry image${NC}"
        fi
    done
    
    echo -e "${GREEN}✓ Project images removed${NC}"
}

# Function to show cleanup summary
show_cleanup_summary() {
    echo ""
    echo -e "${GREEN}=== Cleanup Complete ===${NC}"
    echo ""
    echo -e "${YELLOW}What was cleaned up:${NC}"
    echo "• Kind cluster '${CLUSTER_NAME}' (if it existed)"
    echo "• Namespace '${NAMESPACE}' (if on external cluster)"
    echo "• Unused Docker containers, images, networks, and volumes"
    echo "• Project-specific Docker images"
    echo ""
    echo -e "${YELLOW}Your system is now clean!${NC}"
    echo ""
    echo -e "${BLUE}To redeploy the project, run:${NC}"
    echo "  ./scripts/deploy.sh"
}

# Main cleanup logic
main() {
    confirm_cleanup
    
    echo -e "${BLUE}Starting cleanup...${NC}"
    echo ""
    
    delete_kind_cluster
    delete_namespace
    remove_project_images
    prune_docker_resources
    
    show_cleanup_summary
}

# Run main function
main "$@"
