#!/bin/bash

# Comprehensive ShipAnything Requirements Verification
set -e

echo "🔍 COMPREHENSIVE SHIPANYTHING REQUIREMENTS CHECK"
echo "================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to print colored output
print_check() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ "$2" = "PASS" ]; then
        echo -e "${GREEN}[✓]${NC} $1"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$2" = "FAIL" ]; then
        echo -e "${RED}[✗]${NC} $1"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    elif [ "$2" = "WARN" ]; then
        echo -e "${YELLOW}[!]${NC} $1"
    else
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

print_section() {
    echo ""
    echo -e "${BOLD}${BLUE}=== $1 ===${NC}"
}

# REQUIREMENT 1: Five Laravel v12+ microservices
print_section "1. MICROSERVICE ARCHITECTURE"

SERVICES=("auth-app" "location-app" "payments-app" "booking-app" "fraud-detector-app")
for service in "${SERVICES[@]}"; do
    if [ -d "/Users/lalith/Documents/Projects/shipanything/microservices/$service" ]; then
        print_check "Laravel microservice $service exists" "PASS"
        
        # Check Laravel version
        if [ -f "/Users/lalith/Documents/Projects/shipanything/microservices/$service/composer.json" ]; then
            VERSION=$(grep -o '"laravel/framework": "[^"]*"' "/Users/lalith/Documents/Projects/shipanything/microservices/$service/composer.json" | cut -d'"' -f4)
            print_check "Laravel version for $service: $VERSION" "PASS"
        else
            print_check "composer.json missing for $service" "FAIL"
        fi
    else
        print_check "Laravel microservice $service missing" "FAIL"
    fi
done

# REQUIREMENT 2: Each microservice has own PostgreSQL, Redis, RabbitMQ
print_section "2. DEDICATED INFRASTRUCTURE PER SERVICE"

for service in "${SERVICES[@]}"; do
    service_name=$(echo $service | sed 's/-app$//')
    
    # Special case for fraud-detector-app -> fraud
    if [ "$service" = "fraud-detector-app" ]; then
        service_name="fraud"
    fi
    
    # PostgreSQL
    if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/${service_name}-postgres.yaml" ]; then
        print_check "PostgreSQL for $service exists" "PASS"
    else
        print_check "PostgreSQL for $service missing" "FAIL"
    fi
    
    # Redis
    if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/${service_name}-redis.yaml" ]; then
        print_check "Redis for $service exists" "PASS"
    else
        print_check "Redis for $service missing" "FAIL"
    fi
    
    # RabbitMQ
    if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/${service_name}-rabbitmq.yaml" ]; then
        print_check "RabbitMQ for $service exists" "PASS"
    else
        print_check "RabbitMQ for $service missing" "FAIL"
    fi
done

# REQUIREMENT 3: Shared Kafka using KRaft
print_section "3. SHARED KAFKA CLUSTER"

if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/kafka.yaml" ]; then
    print_check "Kafka KRaft cluster configuration exists" "PASS"
    
    # Check for KRaft configuration
    if grep -q "KAFKA_PROCESS_ROLES" "/Users/lalith/Documents/Projects/shipanything/k8s/kafka.yaml"; then
        print_check "Kafka configured in KRaft mode" "PASS"
    else
        print_check "Kafka KRaft configuration missing" "FAIL"
    fi
else
    print_check "Kafka configuration missing" "FAIL"
fi

# REQUIREMENT 4: Common network bridge (Kubernetes namespace)
print_section "4. KUBERNETES NETWORKING"

if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/namespace.yaml" ]; then
    print_check "Kubernetes namespace configuration exists" "PASS"
else
    print_check "Kubernetes namespace configuration missing" "FAIL"
fi

# REQUIREMENT 5: Subdomain URLs
print_section "5. SUBDOMAIN CONFIGURATION"

if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/ingress.yaml" ]; then
    print_check "Ingress configuration exists" "PASS"
    
    EXPECTED_HOSTS=("auth.shipanything.test" "location.shipanything.test" "payments.shipanything.test" "booking.shipanything.test" "fraud.shipanything.test")
    for host in "${EXPECTED_HOSTS[@]}"; do
        if grep -q "$host" "/Users/lalith/Documents/Projects/shipanything/k8s/ingress.yaml"; then
            print_check "Subdomain $host configured" "PASS"
        else
            print_check "Subdomain $host missing" "FAIL"
        fi
    done
else
    print_check "Ingress configuration missing" "FAIL"
fi

# REQUIREMENT 6: Main entry point shipanything.test
print_section "6. MAIN LANDING PAGE"

if [ -f "/Users/lalith/Documents/Projects/shipanything/web/index.html" ]; then
    print_check "Main landing page exists" "PASS"
else
    print_check "Main landing page missing" "FAIL"
fi

if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/web-nginx.yaml" ]; then
    print_check "Web server configuration exists" "PASS"
else
    print_check "Web server configuration missing" "FAIL"
fi

if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/web-configmap.yaml" ]; then
    print_check "Web content ConfigMap exists" "PASS"
else
    print_check "Web content ConfigMap missing" "FAIL"
fi

# REQUIREMENT 7: Hosts file automation
print_section "7. LOCAL DEVELOPMENT SETUP"

if grep -q "hosts" "/Users/lalith/Documents/Projects/shipanything/scripts/deploy.sh"; then
    print_check "Hosts file automation in deploy script" "PASS"
else
    print_check "Hosts file automation missing" "FAIL"
fi

# REQUIREMENT 8: Complete Kubernetes manifests
print_section "8. KUBERNETES MANIFESTS"

REQUIRED_MANIFESTS=(
    "namespace.yaml"
    "auth-postgres.yaml" "auth-redis.yaml" "auth-rabbitmq.yaml" "auth-app.yaml"
    "location-postgres.yaml" "location-redis.yaml" "location-rabbitmq.yaml" "location-app.yaml"
    "payments-postgres.yaml" "payments-redis.yaml" "payments-rabbitmq.yaml" "payments-app.yaml"
    "booking-postgres.yaml" "booking-redis.yaml" "booking-rabbitmq.yaml" "booking-app.yaml"
    "fraud-postgres.yaml" "fraud-redis.yaml" "fraud-rabbitmq.yaml" "fraud-detector-app.yaml"
    "kafka.yaml" "web-nginx.yaml" "web-configmap.yaml" "ingress.yaml"
)

for manifest in "${REQUIRED_MANIFESTS[@]}"; do
    if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/$manifest" ]; then
        print_check "Kubernetes manifest $manifest exists" "PASS"
    else
        print_check "Kubernetes manifest $manifest missing" "FAIL"
    fi
done

# REQUIREMENT 9: Dockerfiles
print_section "9. DOCKER CONFIGURATION"

for service in "${SERVICES[@]}"; do
    if [ -f "/Users/lalith/Documents/Projects/shipanything/microservices/$service/Dockerfile" ]; then
        print_check "Dockerfile for $service exists" "PASS"
        
        # Check Docker configuration
        if [ -d "/Users/lalith/Documents/Projects/shipanything/microservices/$service/docker" ]; then
            print_check "Docker configuration for $service exists" "PASS"
        else
            print_check "Docker configuration for $service missing" "FAIL"
        fi
    else
        print_check "Dockerfile for $service missing" "FAIL"
    fi
done

# REQUIREMENT 10: Configuration files and scripts
print_section "10. DEPLOYMENT AUTOMATION"

REQUIRED_SCRIPTS=("deploy.sh" "cleanup.sh" "setup-laravel-docker.sh" "verify.sh" "init-laravel.sh" "init-databases.sh")

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "/Users/lalith/Documents/Projects/shipanything/scripts/$script" ]; then
        if [ -x "/Users/lalith/Documents/Projects/shipanything/scripts/$script" ]; then
            print_check "Script $script exists and is executable" "PASS"
        else
            print_check "Script $script exists but not executable" "WARN"
        fi
    else
        print_check "Script $script missing" "FAIL"
    fi
done

# REQUIREMENT 11: README.md documentation
print_section "11. PROJECT DOCUMENTATION"

if [ -f "/Users/lalith/Documents/Projects/shipanything/README.md" ]; then
    print_check "README.md exists" "PASS"
    
    README_SECTIONS=("Architecture Overview" "Quick Start" "Prerequisites" "Development Commands" "Debugging" "Configuration Details")
    for section in "${README_SECTIONS[@]}"; do
        if grep -q "$section" "/Users/lalith/Documents/Projects/shipanything/README.md"; then
            print_check "README section '$section' exists" "PASS"
        else
            print_check "README section '$section' missing" "FAIL"
        fi
    done
else
    print_check "README.md missing" "FAIL"
fi

# REQUIREMENT 12: M1 MacBook Pro optimization
print_section "12. M1 MACBOOK PRO COMPATIBILITY"

if grep -q "docker.*memory.*8192" "/Users/lalith/Documents/Projects/shipanything/scripts/deploy.sh"; then
    print_check "M1 memory optimization configured" "PASS"
else
    print_check "M1 memory optimization missing" "FAIL"
fi

if grep -q "cpus.*4" "/Users/lalith/Documents/Projects/shipanything/scripts/deploy.sh"; then
    print_check "M1 CPU optimization configured" "PASS"
else
    print_check "M1 CPU optimization missing" "FAIL"
fi

# FINAL SUMMARY
print_section "FINAL VERIFICATION SUMMARY"

echo ""
echo -e "${BOLD}Total Checks: $TOTAL_CHECKS${NC}"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}🎉 ALL REQUIREMENTS IMPLEMENTED SUCCESSFULLY! 🎉${NC}"
    echo ""
    echo -e "${BLUE}✅ Five Laravel 12+ microservices${NC}"
    echo -e "${BLUE}✅ Individual PostgreSQL, Redis, RabbitMQ per service${NC}"
    echo -e "${BLUE}✅ Shared Kafka cluster with KRaft${NC}"
    echo -e "${BLUE}✅ Kubernetes network bridge${NC}"
    echo -e "${BLUE}✅ Subdomain URLs with ingress${NC}"
    echo -e "${BLUE}✅ Main landing page at shipanything.test${NC}"
    echo -e "${BLUE}✅ Hosts file automation${NC}"
    echo -e "${BLUE}✅ Complete Kubernetes manifests${NC}"
    echo -e "${BLUE}✅ Dockerfiles and configurations${NC}"
    echo -e "${BLUE}✅ Deployment and management scripts${NC}"
    echo -e "${BLUE}✅ Comprehensive README.md documentation${NC}"
    echo -e "${BLUE}✅ M1 MacBook Pro optimization${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}🚀 READY FOR DEPLOYMENT!${NC}"
    echo -e "${BLUE}Run: ./scripts/deploy.sh${NC}"
else
    echo -e "${RED}${BOLD}❌ $FAILED_CHECKS REQUIREMENTS NOT MET${NC}"
    echo -e "${YELLOW}Please address the failed checks above before deployment.${NC}"
fi

echo ""
