#!/bin/bash

# 🚀 ShipAnything - Main Deployment Script
# Deploys the entire microservices platform using Kind or starts Docker Compose for local development

set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if Docker is running
    if ! check_docker; then
        exit 1
    fi
    
    # Check if kind is installed (only for Kubernetes options)
    if [ "$mode_choice" != "1" ] && ! check_kind; then
        exit 1
    fi
    
    # Check if kubectl is installed (only for Kubernetes options)
    if [ "$mode_choice" != "1" ] && ! check_kubectl; then
        exit 1
    fi
    
    print_success "Prerequisites check completed!"
}

# Function to start Docker Compose
start_docker_compose() {
    print_step "Starting ShipAnything in Docker Compose DEV mode (hot reload)"
    
    # Stop any existing containers
    docker compose down >/dev/null 2>&1 || true
    
    # Start services
    docker compose up --build -d
    
    print_success "Docker Compose services started!"
    print_step "Waiting for services to be ready..."
    sleep 10
    
    # Update hosts file for custom domains
    update_hosts_file
    
    # Show service access information
    show_service_access_info
    
    echo "💡 Hot reload is enabled - changes to your code will be reflected immediately!"
    echo ""
    echo "🔧 Useful commands:"
    echo "  docker compose logs -f [service-name]  # View logs"
    echo "  docker compose down                    # Stop all services"
    echo "  docker compose ps                      # Check service status"
    echo ""
}

# Function to clean up previous Kubernetes deployment
cleanup_kubernetes() {
    print_step "Cleaning up previous Kubernetes deployment..."
    
    # Stop Docker Compose services first to free up ports
    print_step "Stopping Docker Compose services..."
    docker compose down >/dev/null 2>&1 || true
    print_success "Docker Compose services stopped!"
    
    # Delete the entire cluster
    if kind get clusters | grep -q "shipanything"; then
        print_step "Deleting existing Kind cluster..."
        kind delete cluster --name shipanything
        print_success "Kind cluster deleted!"
    fi
    
    # Clean up old Docker images
    print_step "Cleaning up old Docker images..."
    docker images | grep -E "(auth-app|location-app|payments-app|booking-app|fraud-detector-app)" | awk '{print $3}' | xargs -r docker rmi -f >/dev/null 2>&1 || true
    
    print_success "Cleanup completed!"
}

# Function to clean up Kubernetes resources (keep cluster)
cleanup_kubernetes_resources() {
    print_step "Cleaning up Kubernetes resources (keeping cluster)..."
    
    # Delete all resources in the shipanything namespace
    if kubectl get namespace shipanything >/dev/null 2>&1; then
        print_step "Removing existing Kubernetes resources..."
        
        # First try graceful deletion
        kubectl delete namespace shipanything --timeout=30s || {
            print_warning "Graceful deletion timed out, forcing cleanup..."
            
            # Try patching the namespace to remove finalizers
            kubectl patch namespace shipanything -p '{"metadata":{"finalizers":[]}}' --type=merge || true
            
            # Force delete with kubectl
            kubectl delete namespace shipanything --force --grace-period=0 || true
        }
        
        # Wait for namespace to be fully deleted
        cleanup_timeout=60
        cleanup_elapsed=0
        while kubectl get namespace shipanything >/dev/null 2>&1 && [ $cleanup_elapsed -lt $cleanup_timeout ]; do
            echo "Waiting for namespace cleanup... ($cleanup_elapsed/$cleanup_timeout seconds)"
            sleep 2
            cleanup_elapsed=$((cleanup_elapsed + 2))
        done
        
        print_success "Namespace cleanup completed!"
    fi
}

# Function to create Kind cluster
create_kind_cluster() {
    print_step "Creating Kind cluster with custom configuration..."
    
    if ! check_kind_cluster; then
        kind create cluster --config k8s/kind-config.yaml --name shipanything
        print_success "Kind cluster 'shipanything' created successfully!"
    else
        print_success "Using existing Kind cluster 'shipanything'"
    fi
    
    # Set kubectl context
    kubectl cluster-info --context kind-shipanything >/dev/null 2>&1
    print_success "kubectl context set to Kind cluster"
}

# Function to deploy Kubernetes applications
deploy_kubernetes_apps() {
    print_step "Deploying Kubernetes applications..."
    
    # Install NGINX Ingress Controller first
    print_step "Installing NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    # Wait for ingress controller to be ready
    print_step "Waiting for NGINX Ingress Controller to be ready..."
    
    # Wait for the pods to exist first
    local timeout=300
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if kubectl get pods -n ingress-nginx --selector=app.kubernetes.io/component=controller --no-headers 2>/dev/null | grep -q "ingress-nginx-controller"; then
            break
        fi
        echo "Waiting for ingress controller pod to be created... ($elapsed/$timeout seconds)"
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    # Now wait for readiness
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    
    print_success "NGINX Ingress Controller is ready!"
    
    # Build and load Docker images into Kind cluster
    print_step "Building and loading Laravel microservice images..."
    
    # Build all Laravel apps
    apps=(auth-app location-app payments-app booking-app fraud-detector-app)
    for app in "${apps[@]}"; do
        print_step "Building ${app}..."
        docker build -t "${app}:latest" -f "microservices/${app}/Dockerfile.prod" .
        
        print_step "Loading ${app} into Kind cluster..."
        kind load docker-image "${app}:latest" --name shipanything
    done
    
    print_success "All images built and loaded into Kind cluster!"
    
    # Create namespace
    kubectl apply -f k8s/namespace.yaml
    
    # Deploy databases and Redis
    print_step "Deploying databases and Redis..."
    kubectl apply -f k8s/auth-postgres.yaml
    kubectl apply -f k8s/auth-redis.yaml
    kubectl apply -f k8s/location-postgres.yaml
    kubectl apply -f k8s/location-redis.yaml
    kubectl apply -f k8s/payments-postgres.yaml
    kubectl apply -f k8s/payments-redis.yaml
    kubectl apply -f k8s/booking-postgres.yaml
    kubectl apply -f k8s/booking-redis.yaml
    kubectl apply -f k8s/fraud-postgres.yaml
    kubectl apply -f k8s/fraud-redis.yaml
    
    # Deploy message brokers
    print_step "Deploying message brokers (Kafka and RabbitMQ)..."
    kubectl apply -f k8s/kafka.yaml
    kubectl apply -f k8s/auth-rabbitmq.yaml
    kubectl apply -f k8s/location-rabbitmq.yaml
    kubectl apply -f k8s/payments-rabbitmq.yaml
    kubectl apply -f k8s/booking-rabbitmq.yaml
    kubectl apply -f k8s/fraud-rabbitmq.yaml
    
    # Deploy web content configmap
    kubectl apply -f k8s/web-configmap.yaml
    
    # Wait for databases to be ready
    print_step "Waiting for databases to be ready..."
    sleep 30
    
    # Deploy applications
    print_step "Deploying applications..."
    kubectl apply -f k8s/auth-app.yaml
    kubectl apply -f k8s/location-app.yaml
    kubectl apply -f k8s/payments-app.yaml
    kubectl apply -f k8s/booking-app.yaml
    kubectl apply -f k8s/fraud-detector-app.yaml
    kubectl apply -f k8s/web-nginx.yaml
    
    # Deploy ingress
    kubectl apply -f k8s/ingress.yaml
    
    # Wait for applications to be ready
    wait_for_pods shipanything 300
    
    # Run database migrations for all Laravel apps
    print_step "Running database migrations for all Laravel applications..."
    apps=(auth-app location-app payments-app booking-app fraud-detector-app)
    for app in "${apps[@]}"; do
        print_step "Running migrations for ${app}..."
        # Get the first pod for this app
        POD=$(kubectl get pods -n shipanything -l app=$app -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || echo "")
        
        if [ -n "$POD" ]; then
            # Run Laravel migrations
            kubectl exec -n shipanything $POD -- php artisan migrate --force
            print_success "Migrations completed for $app"
            
            # Optimize Laravel configuration for production (Kubernetes modes only)
            print_step "Optimizing Laravel configuration for ${app}..."
            kubectl exec -n shipanything $POD -- php artisan config:cache || print_warning "Config cache failed for $app"
            kubectl exec -n shipanything $POD -- php artisan route:cache || print_warning "Route cache failed for $app"
            kubectl exec -n shipanything $POD -- php artisan view:cache || print_warning "View cache failed for $app"
            print_success "Laravel optimization completed for $app"
        else
            print_warning "No pod found for $app, skipping migrations"
        fi
    done
    
    print_success "All database migrations completed!"
    
    # Update /etc/hosts file
    update_hosts_file
    
    print_success "Kubernetes deployment completed!"
    
    # Show service access information
    show_service_access_info
    
    echo "🔧 Useful commands:"
    echo "  kubectl get pods -n shipanything"
    echo "  kubectl get services -n shipanything"
    echo "  kubectl logs -f deployment/auth-app -n shipanything"
    echo ""
    echo "🧹 To cleanup:"
    echo "  kind delete cluster --name shipanything"
    echo ""
}

# Function to update hosts file
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

# Main script starts here
echo "🚀 ShipAnything - Platform Deployment"
echo "====================================="
echo ""
echo "Select deployment mode:"
echo "  1) Local Development (Docker Compose, hot reload) [default]"
echo "  2) Clean deployment (delete cluster and start fresh) - Recommended"
echo "  3) Update deployment (keep cluster, clean up resources)"
echo "  4) Keep existing (use current state)"
echo ""
read -p "Enter choice [1-4, default=1]: " mode_choice

# Default to 1 if empty
if [ -z "$mode_choice" ]; then
    mode_choice=1
fi

case $mode_choice in
    1)
        echo ""
        echo "🚀 Starting ShipAnything in Docker Compose DEV mode (hot reload)"
        echo ""
        check_prerequisites
        start_docker_compose
        ;;
    2)
        echo ""
        echo "🧹 Clean deployment (delete cluster and start fresh)"
        echo ""
        check_prerequisites
        cleanup_kubernetes
        create_kind_cluster
        deploy_kubernetes_apps
        ;;
    3)
        echo ""
        echo "🔄 Update deployment (keep cluster, clean up resources)"
        echo ""
        check_prerequisites
        if ! kind get clusters | grep -q "shipanything"; then
            print_error "No existing Kind cluster found. Use option 2 (Clean deployment) instead."
            exit 1
        fi
        cleanup_kubernetes_resources
        deploy_kubernetes_apps
        ;;
    4)
        echo ""
        echo "⚡ Keep existing (use current state)"
        echo ""
        check_prerequisites
        if ! kind get clusters | grep -q "shipanything"; then
            print_error "No existing Kind cluster found. Use option 2 (Clean deployment) instead."
            exit 1
        fi
        print_step "Checking existing deployment status..."
        kubectl get pods -n shipanything 2>/dev/null || {
            print_warning "No existing deployment found. Deploying applications..."
            deploy_kubernetes_apps
        }
        update_hosts_file
        echo ""
        echo "🎉 Using existing deployment!"
        echo ""
        echo "📋 Check service status:"
        echo "  kubectl get pods -n shipanything"
        echo "  kubectl get services -n shipanything"
        echo ""
        ;;
    *)
        echo ""
        print_error "Invalid choice. Exiting."
        exit 1
        ;;
esac
