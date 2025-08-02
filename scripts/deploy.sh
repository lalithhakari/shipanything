#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="shipanything"
CLUSTER_NAME="shipanything"
NAMESPACE="shipanything"
REGISTRY="registry.example.com"
MICROSERVICES=("auth-app" "booking-app" "detector-app" "location-app" "payments-app")

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}=== ShipAnything Deployment Script ===${NC}"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    local missing_tools=()
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v kind &> /dev/null; then
        missing_tools+=("kind")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}Please install the missing tools or run: ${SCRIPT_DIR}/helper-scripts/install-prereqs.sh${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites are installed${NC}"
}

# Function to prompt for deployment mode
prompt_deployment_mode() {
    echo ""
    echo -e "${YELLOW}Please select deployment mode:${NC}"
    echo "1) Local (Kind cluster)"
    echo "2) Production"
    echo ""
    
    while true; do
        read -p "Enter your choice (1 or 2): " choice
        case $choice in
            1)
                DEPLOYMENT_MODE="local"
                break
                ;;
            2)
                DEPLOYMENT_MODE="production"
                break
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1 or 2.${NC}"
                ;;
        esac
    done
    
    echo -e "${GREEN}Selected deployment mode: ${DEPLOYMENT_MODE}${NC}"
}

# Function to create Kind cluster
create_kind_cluster() {
    echo -e "${YELLOW}Creating Kind cluster...${NC}"
    
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        echo -e "${YELLOW}Kind cluster '${CLUSTER_NAME}' already exists${NC}"
    else
        kind create cluster --config="${PROJECT_ROOT}/kind-config.yaml" || exit 1
        echo -e "${GREEN}✓ Kind cluster created${NC}"
    fi
    
    # Wait for cluster to be ready
    echo -e "${YELLOW}Waiting for cluster to be ready...${NC}"
    kubectl wait --for=condition=Ready nodes --all --timeout=300s || exit 1
    echo -e "${GREEN}✓ Cluster is ready${NC}"
}

# Function to create namespace
create_namespace() {
    echo -e "${YELLOW}Creating namespace '${NAMESPACE}'...${NC}"
    
    if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
        echo -e "${YELLOW}Namespace '${NAMESPACE}' already exists${NC}"
    else
        kubectl create namespace "${NAMESPACE}" || exit 1
        echo -e "${GREEN}✓ Namespace created${NC}"
    fi
}

# Function to install Kong operator
install_kong_operator() {
    echo -e "${YELLOW}Installing Kong operator...${NC}"
    
    # Check if Kong Mesh is already running
    if kubectl get pods -n kong-mesh-system | grep -q kong-mesh-control-plane; then
        echo -e "${YELLOW}Kong Mesh is already running. Skipping Kong Gateway installation.${NC}"
        echo -e "${BLUE}Kong Mesh can provide API Gateway functionality.${NC}"
        return 0
    fi
    
    # Add Kong Helm repository
    helm repo add kong https://charts.konghq.com || exit 1
    helm repo update || exit 1
    
    # Check if Kong operator is already installed
    if kubectl get deployment kong-controller-manager -n kong-system &> /dev/null; then
        echo -e "${YELLOW}Kong operator already installed${NC}"
        return
    fi
    
    # Check if Kong CRDs exist and clean them up if they're not Helm-managed
    if kubectl get crd ingressclassparameterses.configuration.konghq.com &> /dev/null; then
        echo -e "${YELLOW}Cleaning up existing Kong CRDs that are not Helm-managed...${NC}"
        
        # List of Kong CRDs that might conflict
        local kong_crds=(
            "ingressclassparameterses.configuration.konghq.com"
            "kongconsumers.configuration.konghq.com"
            "kongplugins.configuration.konghq.com"
            "kongclusterplugins.configuration.konghq.com"
            "kongingresses.configuration.konghq.com"
            "tcpingresses.configuration.konghq.com"
            "udpingresses.configuration.konghq.com"
        )
        
        for crd in "${kong_crds[@]}"; do
            if kubectl get crd "$crd" &> /dev/null; then
                echo -e "${YELLOW}Deleting CRD: $crd${NC}"
                kubectl delete crd "$crd" --timeout=60s || true
            fi
        done
        
        # Wait a moment for cleanup
        sleep 5
    fi
    
    # Create namespace and install Kong operator
    kubectl create namespace kong-system || true
    helm install kong-operator kong/kong --namespace kong-system --create-namespace \
        --set ingressController.installCRDs=true || exit 1
    echo -e "${GREEN}✓ Kong operator installed${NC}"
}

# Function to install RabbitMQ operator
install_rabbitmq_operator() {
    echo -e "${YELLOW}Installing RabbitMQ operator...${NC}"
    
    if ! kubectl get deployment rabbitmq-cluster-operator -n rabbitmq-system &> /dev/null; then
        kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml" || exit 1
        
        # Wait for operator to be ready
        kubectl wait --for=condition=Available deployment/rabbitmq-cluster-operator -n rabbitmq-system --timeout=300s || exit 1
        echo -e "${GREEN}✓ RabbitMQ operator installed${NC}"
    else
        echo -e "${YELLOW}RabbitMQ operator already installed${NC}"
    fi
}

# Function to cleanup old conflicting resources
cleanup_old_resources() {
    echo -e "${YELLOW}Cleaning up old conflicting resources...${NC}"
    
    # Delete old StatefulSets and resources that might conflict
    local old_resources=(
        "statefulset/kafka-kraft"
        "service/kafka-kraft"
        "service/kafka-kraft-headless"
        "deployment/kong-gateway"
        "service/kong-gateway"
        "rabbitmqcluster/rabbitmq-auth"
        "rabbitmqcluster/rabbitmq-booking"
        "rabbitmqcluster/rabbitmq-detector"
        "rabbitmqcluster/rabbitmq-location"
        "rabbitmqcluster/rabbitmq-payments"
        "statefulset/rabbitmq-auth-server"
        "statefulset/rabbitmq-booking-server"
        "statefulset/rabbitmq-detector-server"
        "statefulset/rabbitmq-location-server"
        "statefulset/rabbitmq-payments-server"
        "service/rabbitmq-auth"
        "service/rabbitmq-booking"
        "service/rabbitmq-detector"
        "service/rabbitmq-location"
        "service/rabbitmq-payments"
        "service/rabbitmq-auth-nodes"
        "service/rabbitmq-booking-nodes"
        "service/rabbitmq-detector-nodes"
        "service/rabbitmq-location-nodes"
        "service/rabbitmq-payments-nodes"
        "statefulset/redis-auth"
        "statefulset/redis-booking"
        "statefulset/redis-detector"
        "statefulset/redis-location"
        "statefulset/redis-payments"
        "service/redis-auth-headless"
        "service/redis-booking-headless"
        "service/redis-detector-headless"
        "service/redis-location-headless"
        "service/redis-payments-headless"
    )
    
    for resource in "${old_resources[@]}"; do
        kubectl delete "$resource" -n "${NAMESPACE}" --timeout=60s 2>/dev/null || true
    done
    
    # Wait for cleanup to complete
    echo -e "${YELLOW}Waiting for resource cleanup...${NC}"
    sleep 10
    
    echo -e "${GREEN}✓ Old resources cleaned up${NC}"
}

# Function to safely apply StatefulSet manifests
apply_statefulset_manifests() {
    local manifest_file="$1"
    local resource_type="$2"
    
    echo -e "${YELLOW}Applying ${resource_type} manifests safely...${NC}"
    
    # Try to apply the manifest
    if ! kubectl apply -f "${manifest_file}" 2>/dev/null; then
        echo -e "${YELLOW}StatefulSet update failed, recreating ${resource_type} StatefulSets...${NC}"
        
        # Extract StatefulSet names from the manifest file
        local statefulsets=$(grep -A 5 "kind: StatefulSet" "${manifest_file}" | grep "name:" | awk '{print $2}' | tr -d '"' | sort -u || true)
        
        if [ -n "$statefulsets" ]; then
            for sts in $statefulsets; do
                if kubectl get statefulset "$sts" -n "${NAMESPACE}" &>/dev/null; then
                    echo -e "${YELLOW}Deleting StatefulSet: $sts${NC}"
                    kubectl delete statefulset "$sts" -n "${NAMESPACE}" --timeout=120s || true
                fi
            done
            
            # Wait a moment for cleanup
            sleep 5
        fi
        
        # Now apply the manifest again
        kubectl apply -f "${manifest_file}" || exit 1
    fi
    
    echo -e "${GREEN}✓ ${resource_type} manifests applied${NC}"
}

# Function to apply Kubernetes manifests
apply_k8s_manifests() {
    echo -e "${YELLOW}Applying Kubernetes manifests...${NC}"
    
    # Apply infrastructure components with StatefulSet safety
    apply_statefulset_manifests "${PROJECT_ROOT}/k8s/postgres.yaml" "PostgreSQL"
    apply_statefulset_manifests "${PROJECT_ROOT}/k8s/redis.yaml" "Redis"
    apply_statefulset_manifests "${PROJECT_ROOT}/k8s/rabbitmq.yaml" "RabbitMQ"
    apply_statefulset_manifests "${PROJECT_ROOT}/k8s/kafka.yaml" "Kafka"
    
    echo -e "${GREEN}✓ Infrastructure manifests applied${NC}"
    
    # Wait for infrastructure to be ready
    echo -e "${YELLOW}Waiting for infrastructure to be ready...${NC}"
    kubectl wait --for=condition=Ready pod -l app=redis -n "${NAMESPACE}" --timeout=300s || exit 1
    kubectl wait --for=condition=Ready pod -l app=kafka -n "${NAMESPACE}" --timeout=300s || exit 1
    
    echo -e "${GREEN}✓ Infrastructure is ready${NC}"
}

# Function to apply Kong manifests
apply_kong_manifests() {
    echo -e "${YELLOW}Applying Kong manifests...${NC}"
    
    # Check if Kong Mesh is running instead of Kong Gateway
    if kubectl get pods -n kong-mesh-system | grep -q kong-mesh-control-plane; then
        echo -e "${YELLOW}Kong Mesh is running. Skipping Kong Gateway manifest application.${NC}"
        echo -e "${BLUE}Using Kong Mesh for service mesh functionality.${NC}"
        return 0
    fi
    
    kubectl apply -f "${PROJECT_ROOT}/kong/kong-api-gateway.yaml" || exit 1
    kubectl apply -f "${PROJECT_ROOT}/kong/kong-mesh.yaml" || exit 1
    
    echo -e "${GREEN}✓ Kong manifests applied${NC}"
    
    # Wait for Kong to be ready
    echo -e "${YELLOW}Waiting for Kong to be ready...${NC}"
    kubectl wait --for=condition=Available deployment/kong -n kong --timeout=300s || exit 1
    echo -e "${GREEN}✓ Kong is ready${NC}"
}

# Function to build and load Docker images for local deployment
build_and_load_images() {
    echo -e "${YELLOW}Building and loading Docker images...${NC}"
    
    for service in "${MICROSERVICES[@]}"; do
        echo -e "${BLUE}Building ${service}...${NC}"
        
        # Build the image
        docker build -t "${service}:latest" "${PROJECT_ROOT}/microservices/${service}/" || exit 1
        
        # Load image into Kind cluster
        kind load docker-image "${service}:latest" --name="${CLUSTER_NAME}" || exit 1
        
        echo -e "${GREEN}✓ ${service} built and loaded${NC}"
    done
}

# Function to build and push Docker images for production
build_and_push_images() {
    echo -e "${YELLOW}Building and pushing Docker images to ${REGISTRY}...${NC}"
    
    for service in "${MICROSERVICES[@]}"; do
        echo -e "${BLUE}Building and pushing ${service}...${NC}"
        
        # Build the image with registry tag
        docker build -t "${REGISTRY}/${service}:latest" "${PROJECT_ROOT}/microservices/${service}/" || exit 1
        
        # Push to registry
        docker push "${REGISTRY}/${service}:latest" || exit 1
        
        echo -e "${GREEN}✓ ${service} built and pushed${NC}"
    done
}

# Function to deploy microservices for local
deploy_microservices_local() {
    echo -e "${YELLOW}Deploying microservices...${NC}"
    
    for service in "${MICROSERVICES[@]}"; do
        echo -e "${BLUE}Deploying ${service}...${NC}"
        
        # Create deployment manifest
        cat > "/tmp/${service}-deployment.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${service}
  namespace: ${NAMESPACE}
  labels:
    app: ${service}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${service}
  template:
    metadata:
      labels:
        app: ${service}
    spec:
      securityContext:
        runAsUser: 0
        runAsGroup: 0
        fsGroup: 0
      containers:
      - name: ${service}
        image: ${service}:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 80
        env:
        - name: APP_ENV
          value: "local"
        - name: DB_HOST
          value: "postgres-${service%-app}-headless.${NAMESPACE}.svc.cluster.local"
        - name: REDIS_HOST
          value: "redis.${NAMESPACE}.svc.cluster.local"
        - name: RABBITMQ_HOST
          value: "rabbitmq.${NAMESPACE}.svc.cluster.local"
        - name: KAFKA_HOST
          value: "kafka.${NAMESPACE}.svc.cluster.local"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: ${service}
  namespace: ${NAMESPACE}
  labels:
    app: ${service}
spec:
  selector:
    app: ${service}
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
        
        kubectl apply -f "/tmp/${service}-deployment.yaml" || exit 1
        rm "/tmp/${service}-deployment.yaml"
        
        echo -e "${GREEN}✓ ${service} deployed${NC}"
    done
    
    # Wait for all deployments to be ready
    echo -e "${YELLOW}Waiting for microservices to be ready...${NC}"
    for service in "${MICROSERVICES[@]}"; do
        kubectl wait --for=condition=Available deployment/${service} -n "${NAMESPACE}" --timeout=300s || exit 1
    done
    
    echo -e "${GREEN}✓ All microservices are ready${NC}"
}

# Function to fix Laravel storage permissions
fix_laravel_permissions() {
    echo -e "${YELLOW}Fixing Laravel storage permissions...${NC}"
    
    for service in "${MICROSERVICES[@]}"; do
        echo -e "${BLUE}Fixing permissions for ${service}...${NC}"
        
        # Wait for pod to be ready and fix permissions
        kubectl wait --for=condition=Ready pod -l app=${service} -n "${NAMESPACE}" --timeout=60s || {
            echo -e "${YELLOW}Warning: ${service} pod not ready, skipping permission fix${NC}"
            continue
        }
        
        kubectl exec -n "${NAMESPACE}" deployment/${service} -- chmod -R 777 storage || {
            echo -e "${YELLOW}Warning: Failed to fix permissions for ${service}${NC}"
        }
        
        echo -e "${GREEN}✓ Permissions fixed for ${service}${NC}"
    done
    
    echo -e "${GREEN}✓ Laravel storage permissions fixed${NC}"
}

# Function to start Kong port forwarding
start_kong_access() {
    echo -e "${YELLOW}Setting up Kong access...${NC}"
    
    # Check if Kong service exists
    if ! kubectl get service -n kong kong-kong-proxy &>/dev/null; then
        echo -e "${YELLOW}Kong service not found. Checking for alternative Kong services...${NC}"
        
        # Check for Kong in different namespaces or names
        local kong_service=""
        if kubectl get service -n kong-system kong-kong-proxy &>/dev/null; then
            kong_service="kong-system/kong-kong-proxy"
        elif kubectl get service -n kong kong-proxy &>/dev/null; then
            kong_service="kong/kong-proxy"
        elif kubectl get service -n "${NAMESPACE}" kong &>/dev/null; then
            kong_service="${NAMESPACE}/kong"
        else
            echo -e "${RED}Warning: No Kong service found. Services will not be accessible via browser.${NC}"
            echo -e "${YELLOW}You can manually start port forwarding later with:${NC}"
            echo "kubectl port-forward -n <kong-namespace> service/<kong-service> 8080:80"
            return 1
        fi
        
        echo -e "${BLUE}Found Kong service: ${kong_service}${NC}"
    else
        kong_service="kong/kong-kong-proxy"
    fi
    
    # Kill any existing port forwarding
    pkill -f "kubectl port-forward.*8080:80" 2>/dev/null || true
    sleep 2
    
    # Start port forwarding in background
    echo -e "${BLUE}Starting port forwarding: ${kong_service} -> localhost:8080${NC}"
    kubectl port-forward -n "${kong_service%/*}" "service/${kong_service#*/}" 8080:80 >/dev/null 2>&1 &
    local kubectl_pid=$!
    
    # Wait a moment and check if port forwarding is working
    sleep 3
    if kill -0 $kubectl_pid 2>/dev/null; then
        echo -e "${GREEN}✓ Port forwarding started (PID: ${kubectl_pid})${NC}"
        echo ""
        echo -e "${GREEN}🌐 Your microservices are now accessible at:${NC}"
        echo -e "${BLUE}   • Auth Service:     http://auth.shipanything.test:8080${NC}"
        echo -e "${BLUE}   • Booking Service:  http://booking.shipanything.test:8080${NC}"
        echo -e "${BLUE}   • Detector Service: http://detector.shipanything.test:8080${NC}"
        echo -e "${BLUE}   • Location Service: http://location.shipanything.test:8080${NC}"
        echo -e "${BLUE}   • Payments Service: http://payments.shipanything.test:8080${NC}"
        echo ""
        echo -e "${YELLOW}💡 To stop port forwarding later, run: pkill -f 'kubectl port-forward'${NC}"
        
        # Save PID for cleanup scripts
        echo $kubectl_pid > "/tmp/kong-port-forward.pid"
        return 0
    else
        echo -e "${RED}Failed to start port forwarding${NC}"
        return 1
    fi
}

# Function to deploy production manifests
deploy_production() {
    echo -e "${YELLOW}Applying production manifests...${NC}"
    
    if [ ! -d "${PROJECT_ROOT}/k8s/production" ]; then
        echo -e "${RED}Error: Production manifests directory not found at ${PROJECT_ROOT}/k8s/production${NC}"
        exit 1
    fi
    
    kubectl apply -f "${PROJECT_ROOT}/k8s/production/" || exit 1
    echo -e "${GREEN}✓ Production manifests applied${NC}"
}

# Function to show deployment information
show_deployment_info() {
    echo ""
    echo -e "${GREEN}=== Deployment Complete ===${NC}"
    echo ""
    
    if [ "$DEPLOYMENT_MODE" = "local" ]; then
        echo -e "${YELLOW}Local deployment information:${NC}"
        echo "• Cluster: ${CLUSTER_NAME}"
        echo "• Namespace: ${NAMESPACE}"
        echo "• Laravel permissions: Fixed"
        echo "• Kong port forwarding: Active on localhost:8080"
        echo ""
        echo -e "${GREEN}🎉 Your ShipAnything microservices are ready!${NC}"
        echo ""
        echo -e "${YELLOW}Access your services at:${NC}"
        echo -e "${BLUE}• Auth Service:     http://auth.shipanything.test:8080${NC}"
        echo -e "${BLUE}• Booking Service:  http://booking.shipanything.test:8080${NC}"
        echo -e "${BLUE}• Detector Service: http://detector.shipanything.test:8080${NC}"
        echo -e "${BLUE}• Location Service: http://location.shipanything.test:8080${NC}"
        echo -e "${BLUE}• Payments Service: http://payments.shipanything.test:8080${NC}"
        echo ""
        echo -e "${YELLOW}Management commands:${NC}"
        echo -e "${BLUE}• Stop port forwarding: pkill -f 'kubectl port-forward'${NC}"
        echo -e "${BLUE}• Restart port forwarding: kubectl port-forward -n kong service/kong-kong-proxy 8080:80 &${NC}"
        echo ""
        echo -e "${YELLOW}Note: /etc/hosts should already contain the domain entries.${NC}"
        echo -e "${YELLOW}If not, add these entries to your /etc/hosts file:${NC}"
        echo "127.0.0.1 auth.shipanything.test"
        echo "127.0.0.1 booking.shipanything.test"
        echo "127.0.0.1 detector.shipanything.test"
        echo "127.0.0.1 location.shipanything.test"
        echo "127.0.0.1 payments.shipanything.test"
    else
        echo -e "${YELLOW}Production deployment complete${NC}"
        echo "• Images pushed to: ${REGISTRY}"
        echo "• Manifests applied from: k8s/production/"
    fi
    
    echo ""
    echo -e "${YELLOW}Useful commands:${NC}"
    echo "• View logs: ${SCRIPT_DIR}/helper-scripts/view-logs.sh <service-name>"
    echo "• Execute in pod: ${SCRIPT_DIR}/helper-scripts/exec-app.sh <service-name>"
    echo "• Check ingress: ${SCRIPT_DIR}/helper-scripts/check-ingress.sh"
    echo "• Cleanup: ${SCRIPT_DIR}/cleanup.sh"
}

# Main deployment logic
main() {
    check_prerequisites
    prompt_deployment_mode
    
    if [ "$DEPLOYMENT_MODE" = "local" ]; then
        echo -e "${BLUE}=== Local Deployment ===${NC}"
        create_kind_cluster
        create_namespace
        cleanup_old_resources
        install_rabbitmq_operator
        apply_k8s_manifests
        # Skip Kong installation if Kong Mesh is already running
        if ! kubectl get pods -n kong-mesh-system | grep -q kong-mesh-control-plane; then
            install_kong_operator
            apply_kong_manifests
        else
            echo -e "${YELLOW}Kong Mesh detected - skipping Kong Gateway installation${NC}"
        fi
        build_and_load_images
        deploy_microservices_local
        fix_laravel_permissions
        start_kong_access
    else
        echo -e "${BLUE}=== Production Deployment ===${NC}"
        build_and_push_images
        deploy_production
    fi
    
    show_deployment_info
}

# Run main function
main "$@"
