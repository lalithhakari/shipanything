#!/bin/bash

# 🚀 ShipAnything - Main Deployment Script
# Deploys the entire microservices platform using Kind

set -e

echo "🚀 ShipAnything - Platform Deployment"
echo "====================================="
echo ""

# Function to print colored output
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

# Function to clean up previous deployment
cleanup_previous_deployment() {
    print_step "Cleaning up previous deployment..."
    
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
        
        # Wait for namespace to be fully deleted with timeout
        cleanup_timeout=60
        cleanup_elapsed=0
        while kubectl get namespace shipanything >/dev/null 2>&1 && [ $cleanup_elapsed -lt $cleanup_timeout ]; do
            echo "Waiting for namespace cleanup... ($cleanup_elapsed/$cleanup_timeout seconds)"
            sleep 2
            cleanup_elapsed=$((cleanup_elapsed + 2))
        done
        
        if kubectl get namespace shipanything >/dev/null 2>&1; then
            print_warning "Namespace still exists after cleanup, but continuing with deployment..."
        else
            print_success "Namespace cleanup completed!"
        fi
    fi
    
    # Clean up old Docker images
    print_step "Cleaning up old Docker images..."
    docker images | grep -E "(auth-app|location-app|payments-app|booking-app|fraud-detector-app)" | awk '{print $3}' | xargs -r docker rmi -f || true
    
    print_success "Previous deployment cleaned up!"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    print_error "Kind is not installed. Install it with: brew install kind"
    exit 1
fi

print_step "Checking existing Kind cluster..."
if kind get clusters | grep -q "shipanything"; then
    echo "Found existing 'shipanything' cluster."
    echo ""
    echo "Deployment options:"
    echo "  1) Clean deployment (delete cluster and start fresh) - Recommended"
    echo "  2) Update deployment (keep cluster, clean up resources)"
    echo "  3) Keep existing (use current state)"
    echo ""
    
    # Set a timeout for user input
    if read -t 30 -p "Choose option (1-3) [default: 2]: " deploy_option; then
        # User provided input within timeout
        case $deploy_option in
            1)
                print_step "Deleting existing cluster for clean deployment..."
                kind delete cluster --name shipanything
                ;;
            2)
                print_step "Keeping cluster, cleaning up resources..."
                cleanup_previous_deployment
                ;;
            3)
                print_warning "Using existing deployment state..."
                ;;
            ""|*)
                print_step "Using default option: update deployment..."
                cleanup_previous_deployment
                ;;
        esac
    else
        # Timeout reached, use default option
        echo ""
        print_warning "No input received within 30 seconds, using default option 2 (update deployment)..."
        cleanup_previous_deployment
    fi
fi

# Create Kind cluster if it doesn't exist
if ! kind get clusters | grep -q "shipanything"; then
    print_step "Creating Kind cluster with custom configuration..."
    kind create cluster --config k8s/kind-config.yaml
    print_success "Kind cluster 'shipanything' created successfully!"
else
    print_success "Using existing Kind cluster 'shipanything'"
fi

print_step "Setting kubectl context to Kind cluster..."
kubectl cluster-info --context kind-shipanything

print_step "Installing NGINX Ingress Controller for Kind..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

print_step "Waiting for NGINX Ingress Controller to be ready..."
# Wait for the ingress controller deployment to be available
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if kubectl get pods -n ingress-nginx --selector=app.kubernetes.io/component=controller &>/dev/null; then
        print_step "Found ingress controller pods, waiting for ready state..."
        if kubectl wait --namespace ingress-nginx \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/component=controller \
          --timeout=60s 2>/dev/null; then
            print_success "NGINX Ingress Controller is ready!"
            break
        else
            print_warning "Ingress controller pods not ready yet, retrying..."
        fi
    else
        print_step "Waiting for ingress controller pods to be created... (attempt $((attempt + 1))/$max_attempts)"
    fi
    
    sleep 3
    ((attempt++))
done

if [ $attempt -eq $max_attempts ]; then
    print_warning "NGINX Ingress Controller may still be starting up, continuing with deployment..."
else
    print_success "NGINX Ingress Controller is ready!"
fi

print_step "Building and loading Docker images for microservices..."

# Function to build and load Docker image
build_and_load_image() {
    local app_name=$1
    local app_dir="microservices/$app_name"
    
    if [[ -d "$app_dir" ]]; then
        print_step "Building Docker image for $app_name..."
        
        # Build the image
        if docker build -t $app_name:latest $app_dir/; then
            print_success "Successfully built $app_name:latest"
            
            # Load into Kind cluster
            print_step "Loading $app_name into Kind cluster..."
            if kind load docker-image $app_name:latest --name shipanything; then
                print_success "Successfully loaded $app_name into Kind cluster"
            else
                print_error "Failed to load $app_name into Kind cluster"
                return 1
            fi
        else
            print_error "Failed to build Docker image for $app_name"
            return 1
        fi
    else
        print_error "Directory $app_dir not found!"
        return 1
    fi
}

# Build all Laravel microservices
microservices=("auth-app" "location-app" "payments-app" "booking-app" "fraud-detector-app")

for app in "${microservices[@]}"; do
    build_and_load_image $app
done

print_success "All Docker images built and loaded successfully!"

print_step "Deploying Kubernetes resources..."

# Create namespace first
print_step "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Deploy all Kubernetes resources (excluding kind-config.yaml)
print_step "Deploying all infrastructure and application components..."

# Deploy in order: namespace, infrastructure, then applications
echo "1️⃣ Deploying namespace..."
kubectl apply -f k8s/namespace.yaml

echo "2️⃣ Deploying infrastructure (databases, messaging)..."
find k8s/ -name "*postgres*.yaml" -exec kubectl apply -f {} \;
find k8s/ -name "*redis*.yaml" -exec kubectl apply -f {} \;
find k8s/ -name "*rabbitmq*.yaml" -exec kubectl apply -f {} \;
find k8s/ -name "*kafka*.yaml" -exec kubectl apply -f {} \;

echo "3️⃣ Deploying applications and services..."
find k8s/ -name "*-app.yaml" -exec kubectl apply -f {} \;
find k8s/ -name "web-*.yaml" -exec kubectl apply -f {} \;

echo "4️⃣ Deploying ingress configuration..."
kubectl apply -f k8s/ingress.yaml

print_success "All Kubernetes resources deployed!"

# Wait for infrastructure components first
print_step "Waiting for databases and infrastructure to be ready..."
infrastructure_deployments=("auth-postgres" "booking-postgres" "fraud-postgres" "location-postgres" "payments-postgres" "kafka")

for deployment in "${infrastructure_deployments[@]}"; do
    if kubectl get deployment $deployment -n shipanything &>/dev/null; then
        print_step "Waiting for deployment $deployment..."
        kubectl wait --for=condition=available --timeout=180s deployment/$deployment -n shipanything || print_warning "$deployment deployment may need more time"
    elif kubectl get statefulset $deployment -n shipanything &>/dev/null; then
        print_step "Waiting for statefulset $deployment..."
        
        # Show initial status
        echo "📋 Initial $deployment status:"
        kubectl get statefulset $deployment -n shipanything -o wide 2>/dev/null || echo "StatefulSet not found yet"
        kubectl get pod -l app=$deployment -n shipanything -o wide 2>/dev/null || echo "No pods found yet"
        echo ""
        
        # Wait with enhanced progress monitoring
        wait_timeout=180
        wait_elapsed=0
        last_status=""
        
        while [ $wait_elapsed -lt $wait_timeout ]; do
            if kubectl wait --for=condition=ready --timeout=10s pod -l app=$deployment -n shipanything 2>/dev/null; then
                print_success "$deployment is ready!"
                break
            else
                wait_elapsed=$((wait_elapsed + 10))
                echo "⏳ $deployment still starting... ($wait_elapsed/${wait_timeout}s)"
                
                # Show detailed pod status
                kubectl get pod -l app=$deployment -n shipanything --no-headers 2>/dev/null | while read line; do
                    if [ -n "$line" ]; then
                        pod_name=$(echo $line | awk '{print $1}')
                        ready=$(echo $line | awk '{print $2}')
                        status=$(echo $line | awk '{print $3}')
                        restarts=$(echo $line | awk '{print $4}')
                        age=$(echo $line | awk '{print $5}')
                        echo "   📦 $pod_name: $ready | $status | Restarts: $restarts | Age: $age"
                        
                        # Show events for problematic pods
                        if [[ "$status" != "Running" && "$status" != "ContainerCreating" ]]; then
                            echo "   🔍 Recent events for $pod_name:"
                            kubectl get events --field-selector involvedObject.name=$pod_name -n shipanything --sort-by='.lastTimestamp' | tail -3 | sed 's/^/      /'
                        fi
                    fi
                done
                echo ""
            fi
        done
        
        if [ $wait_elapsed -ge $wait_timeout ]; then
            print_warning "$deployment statefulset may need more time"
            echo "🔍 Final status check:"
            kubectl describe statefulset $deployment -n shipanything | tail -10
        fi
    else
        print_warning "No deployment or statefulset found for $deployment, skipping..."
    fi
done

# Additional wait to ensure services are fully ready
print_step "Waiting for infrastructure services to be fully ready..."
sleep 30

# Wait for application deployments
print_step "Waiting for application deployments to be ready..."
app_deployments=("auth-app" "location-app" "payments-app" "booking-app" "fraud-detector-app" "web-nginx")

for deployment in "${app_deployments[@]}"; do
    if kubectl get deployment $deployment -n shipanything &>/dev/null; then
        print_step "Waiting for deployment $deployment..."
        
        # Show initial status
        echo "📋 Initial $deployment status:"
        kubectl get deployment $deployment -n shipanything -o wide 2>/dev/null || echo "Deployment not found yet"
        kubectl get pod -l app=$deployment -n shipanything -o wide 2>/dev/null || echo "No pods found yet"
        echo ""
        
        # Wait with enhanced progress monitoring
        wait_timeout=300
        wait_elapsed=0
        
        while [ $wait_elapsed -lt $wait_timeout ]; do
            if kubectl wait --for=condition=available --timeout=15s deployment/$deployment -n shipanything 2>/dev/null; then
                print_success "$deployment is ready!"
                
                # Show final ready status
                kubectl get pod -l app=$deployment -n shipanything --no-headers 2>/dev/null | while read line; do
                    if [ -n "$line" ]; then
                        pod_name=$(echo $line | awk '{print $1}')
                        ready=$(echo $line | awk '{print $2}')
                        status=$(echo $line | awk '{print $3}')
                        echo "   ✅ $pod_name: $ready $status"
                    fi
                done
                echo ""
                break
            else
                wait_elapsed=$((wait_elapsed + 15))
                echo "⏳ $deployment still starting... ($wait_elapsed/${wait_timeout}s)"
                
                # Show detailed pod status and readiness probe info
                kubectl get pod -l app=$deployment -n shipanything --no-headers 2>/dev/null | while read line; do
                    if [ -n "$line" ]; then
                        pod_name=$(echo $line | awk '{print $1}')
                        ready=$(echo $line | awk '{print $2}')
                        status=$(echo $line | awk '{print $3}')
                        restarts=$(echo $line | awk '{print $4}')
                        age=$(echo $line | awk '{print $5}')
                        echo "   📦 $pod_name: $ready | $status | Restarts: $restarts | Age: $age"
                        
                        # Show readiness probe details for non-ready pods
                        if [[ "$ready" != "1/1" && "$status" == "Running" ]]; then
                            echo "   🔍 Readiness probe info: Waiting for HTTP probe on :80/"
                            echo "   ⏱️  Configured: initialDelay=60s, timeout=5s, period=10s"
                        fi
                        
                        # Show recent events for problematic pods
                        if [[ "$status" != "Running" && "$status" != "ContainerCreating" ]]; then
                            echo "   🔍 Recent events:"
                            kubectl get events --field-selector involvedObject.name=$pod_name -n shipanything --sort-by='.lastTimestamp' | tail -2 | sed 's/^/      /'
                        fi
                    fi
                done
                echo ""
            fi
        done
        
        if [ $wait_elapsed -ge $wait_timeout ]; then
            print_warning "$deployment may not be ready yet, continuing..."
            echo "🔍 Final status check:"
            kubectl describe deployment $deployment -n shipanything | grep -A 5 -B 5 "Conditions:\|Replicas:"
        fi
    else
        print_warning "No deployment found for $deployment, skipping..."
    fi
done

print_step "Creating NodePort services for easy access..."
# Create NodePort services for direct access
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-nginx-nodeport
  namespace: shipanything
spec:
  type: NodePort
  selector:
    app: web-nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
---
apiVersion: v1
kind: Service
metadata:
  name: auth-app-nodeport
  namespace: shipanything
spec:
  type: NodePort
  selector:
    app: auth-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30081
---
apiVersion: v1
kind: Service
metadata:
  name: location-app-nodeport
  namespace: shipanything
spec:
  type: NodePort
  selector:
    app: location-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30082
---
apiVersion: v1
kind: Service
metadata:
  name: payments-app-nodeport
  namespace: shipanything
spec:
  type: NodePort
  selector:
    app: payments-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30083
---
apiVersion: v1
kind: Service
metadata:
  name: booking-app-nodeport
  namespace: shipanything
spec:
  type: NodePort
  selector:
    app: booking-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30084
---
apiVersion: v1
kind: Service
metadata:
  name: fraud-detector-app-nodeport
  namespace: shipanything
spec:
  type: NodePort
  selector:
    app: fraud-detector-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30085
EOF

print_success "NodePort services created!"

print_step "Updating /etc/hosts file for custom domains..."
# Check if entries already exist
if ! grep -q "shipanything.test" /etc/hosts; then
    echo "Adding hosts file entries..."
    
    # Add Kind-specific hosts entries (127.0.0.1 for Kind networking)
    sudo sh -c 'cat >> /etc/hosts << EOF

# ShipAnything - Kind Local Development
127.0.0.1 shipanything.test
127.0.0.1 auth.shipanything.test
127.0.0.1 location.shipanything.test
127.0.0.1 payments.shipanything.test
127.0.0.1 booking.shipanything.test
127.0.0.1 fraud.shipanything.test
EOF'
    print_success "Hosts file updated with Kind networking configuration!"
else
    print_success "Hosts file entries already exist!"
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Access your services:"
echo ""
echo "🌐 Localhost Access:"
echo "🌟 Main Dashboard: http://localhost:8080"
echo "🔐 Auth Service: http://localhost:8081"
echo "📍 Location Service: http://localhost:8082"
echo "💳 Payments Service: http://localhost:8083"
echo "📅 Booking Service: http://localhost:8084"
echo "🔍 Fraud Detector: http://localhost:8085"
echo ""
echo "🏷️  Custom Domain Access:"
echo "🌟 Main Dashboard: http://shipanything.test"
echo "🔐 Auth Service: http://auth.shipanything.test"
echo "📍 Location Service: http://location.shipanything.test"  
echo "💳 Payments Service: http://payments.shipanything.test"
echo "📅 Booking Service: http://booking.shipanything.test"
echo "🔍 Fraud Detector: http://fraud.shipanything.test"
echo ""
echo "💡 Both localhost and custom domains work simultaneously!"
echo "💡 Kind provides reliable networking without any workarounds!"
echo ""
echo "🔧 Alternative Access Methods:"
echo "   📡 NodePort (direct): http://localhost:30080-30085"
echo "   🌐 Ingress domains: http://*.shipanything.test"
echo "   🔗 Port forwarding: kubectl port-forward svc/<service> <port>:80 -n shipanything"
echo ""
echo "🔧 Useful commands:"
echo "  kubectl get pods -n shipanything"
echo "  kubectl get services -n shipanything"
echo "  ./scripts/status-report.sh"
echo "  ./scripts/quick-access.sh"
echo ""
echo "🧹 To cleanup:"
echo "  kind delete cluster --name shipanything"
echo ""

# Run post-deployment service connectivity tests
print_step "Running post-deployment service connectivity tests..."
if [ -f "$(dirname "$0")/test-services.sh" ]; then
    "$(dirname "$0")/test-services.sh"
    test_exit_code=$?
    if [ $test_exit_code -eq 0 ]; then
        print_success "All service connectivity tests passed!"
    else
        print_warning "Some service connectivity tests failed. The services may still be starting up."
        echo ""
        print_step "Final pod status check..."
        kubectl get pods -n shipanything
        echo ""
        print_step "If services are still starting, wait a few minutes and try accessing the URLs directly."
    fi
else
    print_warning "test-services.sh not found, skipping connectivity tests"
    echo ""
    print_step "Manual verification:"
    echo "1. Check pod status: kubectl get pods -n shipanything"
    echo "2. Test main dashboard: curl -H 'Host: shipanything.test' http://localhost/"
fi
echo ""
