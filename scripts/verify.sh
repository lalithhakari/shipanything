#!/bin/bash

# Pre-deployment verification script for ShipAnything
set -e

echo "🔍 ShipAnything Pre-Deployment Verification"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

ERRORS=0

# Check prerequisites
print_status "Checking prerequisites..."

if command -v docker &> /dev/null; then
    print_success "Docker is installed"
else
    print_error "Docker is not installed"
    ERRORS=$((ERRORS + 1))
fi

if command -v kind &> /dev/null; then
    print_success "Kind is installed"
else
    print_error "Kind is not installed"
    ERRORS=$((ERRORS + 1))
fi

if command -v kubectl &> /dev/null; then
    print_success "kubectl is installed"
else
    print_error "kubectl is not installed"
    ERRORS=$((ERRORS + 1))
fi

if command -v laravel &> /dev/null; then
    print_success "Laravel installer is available"
else
    print_warning "Laravel installer not found (optional for deployment)"
fi

# Check Laravel applications
print_status "Checking Laravel applications..."

APPS=("auth-app" "location-app" "payments-app" "booking-app" "fraud-detector-app")

for app in "${APPS[@]}"; do
    if [ -d "/Users/lalith/Documents/Projects/shipanything/microservices/$app" ]; then
        print_success "Laravel app $app exists"
        
        # Check if Docker configuration exists
        if [ -d "/Users/lalith/Documents/Projects/shipanything/microservices/$app/docker" ]; then
            print_success "Docker configuration for $app exists"
        else
            print_warning "Docker configuration for $app missing"
        fi
        
        # Check if Dockerfile exists
        if [ -f "/Users/lalith/Documents/Projects/shipanything/microservices/$app/Dockerfile" ]; then
            print_success "Dockerfile for $app exists"
        else
            print_error "Dockerfile for $app missing"
            ERRORS=$((ERRORS + 1))
        fi
    else
        print_error "Laravel app $app not found"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check Kubernetes manifests
print_status "Checking Kubernetes manifests..."

K8S_FILES=(
    "namespace.yaml"
    "auth-postgres.yaml" "auth-redis.yaml" "auth-rabbitmq.yaml" "auth-app.yaml"
    "location-postgres.yaml" "location-redis.yaml" "location-rabbitmq.yaml" "location-app.yaml"
    "payments-postgres.yaml" "payments-redis.yaml" "payments-rabbitmq.yaml" "payments-app.yaml"
    "booking-postgres.yaml" "booking-redis.yaml" "booking-rabbitmq.yaml" "booking-app.yaml"
    "fraud-postgres.yaml" "fraud-redis.yaml" "fraud-rabbitmq.yaml" "fraud-detector-app.yaml"
    "kafka.yaml"
    "web-configmap.yaml" "web-nginx.yaml"
    "ingress.yaml"
)

for file in "${K8S_FILES[@]}"; do
    if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/$file" ]; then
        print_success "K8s manifest $file exists"
    else
        print_error "K8s manifest $file missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check scripts
print_status "Checking deployment scripts..."

SCRIPTS=("deploy.sh" "cleanup.sh" "setup-laravel-docker.sh" "create-all-apps.sh")

for script in "${SCRIPTS[@]}"; do
    if [ -f "/Users/lalith/Documents/Projects/shipanything/scripts/$script" ]; then
        if [ -x "/Users/lalith/Documents/Projects/shipanything/scripts/$script" ]; then
            print_success "Script $script exists and is executable"
        else
            print_warning "Script $script exists but is not executable"
        fi
    else
        print_error "Script $script missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check web content
print_status "Checking web content..."

if [ -f "/Users/lalith/Documents/Projects/shipanything/web/index.html" ]; then
    print_success "Main landing page exists"
else
    print_error "Main landing page missing"
    ERRORS=$((ERRORS + 1))
fi

# Check Docker status
print_status "Checking Docker status..."

if docker ps &> /dev/null; then
    print_success "Docker is running"
else
    print_error "Docker is not running"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
echo "============================================"
if [ $ERRORS -eq 0 ]; then
    print_success "🎉 All basic checks passed!"
    
    # Run comprehensive requirements check
    print_status "Running comprehensive requirements validation..."
    if [ -f "$(dirname "$0")/final-check.sh" ]; then
        "$(dirname "$0")/final-check.sh"
        if [ $? -eq 0 ]; then
            print_success "🎉 All comprehensive checks passed! Ready for deployment."
            echo ""
            print_status "To deploy ShipAnything, run:"
            echo "  cd /Users/lalith/Documents/Projects/shipanything"
            echo "  ./scripts/deploy.sh"
        else
            print_warning "Some comprehensive checks failed. Review the detailed output above."
        fi
    else
        print_warning "final-check.sh not found, skipping comprehensive validation"
        echo ""
        print_status "To deploy ShipAnything, run:"
        echo "  cd /Users/lalith/Documents/Projects/shipanything"
        echo "  ./scripts/deploy.sh"
    fi
else
    print_error "❌ $ERRORS errors found. Please fix them before deployment."
fi

echo ""
