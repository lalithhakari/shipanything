#!/bin/bash

# 🔍 ShipAnything - Comprehensive Verification Script
# Combines basic and comprehensive verification into one script
set -e

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

echo "🔍 ShipAnything - Comprehensive Verification"
echo "============================================="
echo ""

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
ERRORS=0

# Enhanced print functions with counters
print_check() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ "$2" = "PASS" ]; then
        echo -e "${GREEN}[✓]${NC} $1"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$2" = "FAIL" ]; then
        echo -e "${RED}[✗]${NC} $1"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        ERRORS=$((ERRORS + 1))
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

# SECTION 1: Prerequisites Check
print_section "1. PREREQUISITES"

if check_docker; then
    print_check "Docker is installed and running" "PASS"
else
    print_check "Docker is not running" "FAIL"
fi

if check_kind; then
    print_check "Kind is installed" "PASS"
else
    print_check "Kind is not installed" "FAIL"
fi

if check_kubectl; then
    print_check "kubectl is installed" "PASS"
else
    print_check "kubectl is not installed" "FAIL"
fi

if command -v laravel &> /dev/null; then
    print_check "Laravel installer is available" "PASS"
else
    print_check "Laravel installer not found (optional for deployment)" "WARN"
fi

# SECTION 2: Laravel Applications
print_section "2. LARAVEL MICROSERVICES"

for app in "${LARAVEL_APPS[@]}"; do
    if [ -d "/Users/lalith/Documents/Projects/shipanything/microservices/$app" ]; then
        print_check "Laravel microservice $app exists" "PASS"
        
        # Check Laravel version
        if [ -f "/Users/lalith/Documents/Projects/shipanything/microservices/$app/composer.json" ]; then
            VERSION=$(grep -o '"laravel/framework": "[^"]*"' "/Users/lalith/Documents/Projects/shipanything/microservices/$app/composer.json" | cut -d'"' -f4 2>/dev/null || echo "unknown")
            print_check "Laravel version for $app: $VERSION" "PASS"
        else
            print_check "composer.json missing for $app" "FAIL"
        fi
        
        # Check if Dockerfile exists
        if [ -f "/Users/lalith/Documents/Projects/shipanything/microservices/$app/Dockerfile" ]; then
            print_check "Dockerfile for $app exists" "PASS"
        else
            print_check "Dockerfile for $app missing" "FAIL"
        fi
        
        # Check if Docker configuration exists
        if [ -d "/Users/lalith/Documents/Projects/shipanything/microservices/$app/docker" ]; then
            print_check "Docker configuration for $app exists" "PASS"
        else
            print_check "Docker configuration for $app missing" "WARN"
        fi
    else
        print_check "Laravel microservice $app not found" "FAIL"
    fi
done

# SECTION 3: Infrastructure Configuration
print_section "3. INFRASTRUCTURE CONFIGURATION"

# Check for dedicated infrastructure per service
for service in "${LARAVEL_APPS[@]}"; do
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
done

# Check Kafka
if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/kafka.yaml" ]; then
    print_check "Kafka configuration exists" "PASS"
    
    # Check for KRaft configuration
    if grep -q "KAFKA_PROCESS_ROLES" "/Users/lalith/Documents/Projects/shipanything/k8s/kafka.yaml"; then
        print_check "Kafka configured in KRaft mode" "PASS"
    else
        print_check "Kafka KRaft configuration missing" "FAIL"
    fi
else
    print_check "Kafka configuration missing" "FAIL"
fi

# SECTION 4: Kubernetes Manifests
print_section "4. KUBERNETES MANIFESTS"

K8S_FILES=(
    "namespace.yaml"
    "auth-postgres.yaml" "auth-redis.yaml" "auth-app.yaml"
    "location-postgres.yaml" "location-redis.yaml" "location-app.yaml"
    "payments-postgres.yaml" "payments-redis.yaml" "payments-app.yaml"
    "booking-postgres.yaml" "booking-redis.yaml" "booking-app.yaml"
    "fraud-postgres.yaml" "fraud-redis.yaml" "fraud-detector-app.yaml"
    "kafka.yaml" "web-nginx.yaml" "web-configmap.yaml" "ingress.yaml"
)

for file in "${K8S_FILES[@]}"; do
    if [ -f "/Users/lalith/Documents/Projects/shipanything/k8s/$file" ]; then
        print_check "Kubernetes manifest $file exists" "PASS"
    else
        print_check "Kubernetes manifest $file missing" "FAIL"
    fi
done

# SECTION 5: Web Content and Ingress
print_section "5. WEB CONTENT AND INGRESS"

if [ -f "/Users/lalith/Documents/Projects/shipanything/web/index.html" ]; then
    print_check "Main landing page exists" "PASS"
else
    print_check "Main landing page missing" "FAIL"
fi

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

# SECTION 6: Scripts and Configuration
print_section "6. DEPLOYMENT SCRIPTS"

REQUIRED_SCRIPTS=("deploy.sh" "cleanup.sh" "verify.sh" "utils.sh" "laravel-manager.sh")
OPTIONAL_SCRIPTS=("test-deployment-modes.sh" "init-databases.sh")
REMOVED_SCRIPTS=("create-all-apps.sh" "init-laravel.sh" "setup-laravel-docker.sh" "laravel-docker-start.sh")

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

# Check optional scripts
for script in "${OPTIONAL_SCRIPTS[@]}"; do
    if [ -f "/Users/lalith/Documents/Projects/shipanything/scripts/$script" ]; then
        if [ -x "/Users/lalith/Documents/Projects/shipanything/scripts/$script" ]; then
            print_check "Optional script $script exists and is executable" "PASS"
        else
            print_check "Optional script $script exists but not executable" "WARN"
        fi
    else
        print_check "Optional script $script missing (this is OK)" "WARN"
    fi
done

# Check removed scripts (should be cleaned up)
for script in "${REMOVED_SCRIPTS[@]}"; do
    if [ -f "/Users/lalith/Documents/Projects/shipanything/scripts/$script" ]; then
        print_check "Removed script $script still exists (should be cleaned up)" "WARN"
    else
        print_check "Removed script $script properly cleaned up" "PASS"
    fi
done

# Check Docker Compose file
if [ -f "/Users/lalith/Documents/Projects/shipanything/docker-compose.yml" ]; then
    print_check "Docker Compose configuration exists" "PASS"
    
    # Test Docker Compose syntax
    if docker compose config >/dev/null 2>&1; then
        print_check "Docker Compose syntax is valid" "PASS"
    else
        print_check "Docker Compose has syntax errors" "FAIL"
    fi
else
    print_check "Docker Compose configuration missing" "FAIL"
fi

# FINAL SUMMARY
print_section "VERIFICATION SUMMARY"

echo ""
echo -e "${BOLD}Total Checks: $TOTAL_CHECKS${NC}"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}🎉 ALL CHECKS PASSED! 🎉${NC}"
    echo ""
    echo -e "${BLUE}✅ Five Laravel microservices verified${NC}"
    echo -e "${BLUE}✅ Individual PostgreSQL and Redis per service${NC}"
    echo -e "${BLUE}✅ Shared Kafka cluster configuration${NC}"
    echo -e "${BLUE}✅ Kubernetes manifests complete${NC}"
    echo -e "${BLUE}✅ Subdomain URLs configured${NC}"
    echo -e "${BLUE}✅ Main landing page ready${NC}"
    echo -e "${BLUE}✅ Deployment scripts ready${NC}"
    echo -e "${BLUE}✅ Docker configurations complete${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}🚀 READY FOR DEPLOYMENT!${NC}"
    echo -e "${BLUE}Run: ./scripts/deploy.sh${NC}"
    echo ""
else
    echo -e "${RED}${BOLD}❌ $FAILED_CHECKS CHECKS FAILED${NC}"
    echo -e "${YELLOW}Please address the failed checks above before deployment.${NC}"
    echo ""
    echo -e "${BLUE}After fixing issues, run this script again to verify.${NC}"
fi

echo ""

exit $FAILED_CHECKS
