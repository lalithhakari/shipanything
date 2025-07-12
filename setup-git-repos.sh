#!/bin/bash
set -e

echo "🚀 Setting up Git Repositories for ShipAnything"
echo "==============================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# GitHub username (replace with your username)
GITHUB_USERNAME="your-github-username"
GITHUB_ORG="shipanything-org"  # Optional: use organization instead

print_info "Update GITHUB_USERNAME variable in this script before running!"
print_info "Repositories to create on GitHub:"
echo ""
echo "1. Main repository: $GITHUB_USERNAME/shipanything"
echo "2. Auth service: $GITHUB_USERNAME/shipanything-auth"
echo "3. Location service: $GITHUB_USERNAME/shipanything-location"
echo "4. Payments service: $GITHUB_USERNAME/shipanything-payments"
echo "5. Booking service: $GITHUB_USERNAME/shipanything-booking"
echo "6. Fraud detector: $GITHUB_USERNAME/shipanything-fraud-detector"
echo ""

# Function to create GitHub repo using CLI (requires gh CLI)
create_github_repo() {
    local repo_name=$1
    local description=$2
    
    print_step "Creating GitHub repository: $repo_name"
    
    # Check if gh CLI is available
    if command -v gh &> /dev/null; then
        if gh repo create "$GITHUB_USERNAME/$repo_name" --description "$description" --public; then
            print_success "Created repository: $GITHUB_USERNAME/$repo_name"
        else
            print_info "Repository might already exist: $GITHUB_USERNAME/$repo_name"
        fi
    else
        print_info "GitHub CLI not found. Please create manually:"
        print_info "  Repository: $GITHUB_USERNAME/$repo_name"
        print_info "  Description: $description"
        print_info "  Visibility: Public"
        echo ""
    fi
}

print_step "Creating GitHub repositories..."
echo ""

# Create repositories
create_github_repo "shipanything" "🚀 ShipAnything - Complete Microservices Platform with Kubernetes"
create_github_repo "shipanything-auth" "🔐 ShipAnything Auth Service - Laravel 12+ Authentication Microservice"
create_github_repo "shipanything-location" "📍 ShipAnything Location Service - Laravel 12+ Geolocation Microservice"
create_github_repo "shipanything-payments" "💳 ShipAnything Payments Service - Laravel 12+ Payment Processing Microservice"
create_github_repo "shipanything-booking" "📅 ShipAnything Booking Service - Laravel 12+ Reservation Management Microservice"
create_github_repo "shipanything-fraud-detector" "🔍 ShipAnything Fraud Detector - Laravel 12+ AI-Powered Fraud Detection Microservice"

echo ""
print_success "Repository creation process completed!"
print_info "Next steps:"
echo "1. Run setup-main-repo.sh to initialize the main repository"
echo "2. Run setup-submodules.sh to configure Git submodules"
echo "3. Run push-microservices.sh to push each microservice"
