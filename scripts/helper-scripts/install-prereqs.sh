#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Install Prerequisites for ShipAnything ===${NC}"
echo ""

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "$ID"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Docker
install_docker() {
    echo -e "${YELLOW}Installing Docker...${NC}"
    
    local os="$1"
    
    case "$os" in
        "macos")
            if command_exists brew; then
                brew install --cask docker
            else
                echo -e "${RED}Homebrew not found. Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop${NC}"
                return 1
            fi
            ;;
        "ubuntu"|"debian")
            # Update package index
            sudo apt-get update
            
            # Install dependencies
            sudo apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker's official GPG key
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Set up stable repository
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker Engine
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            
            # Add user to docker group
            sudo usermod -aG docker "$USER"
            ;;
        "centos"|"rhel"|"fedora")
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker "$USER"
            ;;
        *)
            echo -e "${RED}Unsupported OS for automatic Docker installation. Please install Docker manually.${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✓ Docker installation initiated${NC}"
}

# Function to install kubectl
install_kubectl() {
    echo -e "${YELLOW}Installing kubectl...${NC}"
    
    local os="$1"
    
    case "$os" in
        "macos")
            if command_exists brew; then
                brew install kubectl
            else
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
                chmod +x kubectl
                sudo mv kubectl /usr/local/bin/
            fi
            ;;
        "linux"|"ubuntu"|"debian"|"centos"|"rhel"|"fedora")
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
            ;;
        *)
            echo -e "${RED}Unsupported OS for automatic kubectl installation. Please install kubectl manually.${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✓ kubectl installed${NC}"
}

# Function to install Kind
install_kind() {
    echo -e "${YELLOW}Installing Kind...${NC}"
    
    local os="$1"
    
    case "$os" in
        "macos")
            if command_exists brew; then
                brew install kind
            else
                curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
                chmod +x ./kind
                sudo mv ./kind /usr/local/bin/kind
            fi
            ;;
        "linux"|"ubuntu"|"debian"|"centos"|"rhel"|"fedora")
            curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
            ;;
        *)
            echo -e "${RED}Unsupported OS for automatic Kind installation. Please install Kind manually.${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✓ Kind installed${NC}"
}

# Function to install Helm
install_helm() {
    echo -e "${YELLOW}Installing Helm...${NC}"
    
    local os="$1"
    
    case "$os" in
        "macos")
            if command_exists brew; then
                brew install helm
            else
                curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            fi
            ;;
        "linux"|"ubuntu"|"debian"|"centos"|"rhel"|"fedora")
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            ;;
        *)
            echo -e "${RED}Unsupported OS for automatic Helm installation. Please install Helm manually.${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✓ Helm installed${NC}"
}

# Function to check and install tools
check_and_install() {
    local os
    os=$(detect_os)
    
    echo -e "${YELLOW}Detected OS: ${os}${NC}"
    echo ""
    
    local tools_to_install=()
    
    # Check Docker
    if command_exists docker; then
        echo -e "${GREEN}✓ Docker is already installed${NC}"
    else
        tools_to_install+=("docker")
    fi
    
    # Check kubectl
    if command_exists kubectl; then
        echo -e "${GREEN}✓ kubectl is already installed${NC}"
    else
        tools_to_install+=("kubectl")
    fi
    
    # Check Kind
    if command_exists kind; then
        echo -e "${GREEN}✓ Kind is already installed${NC}"
    else
        tools_to_install+=("kind")
    fi
    
    # Check Helm
    if command_exists helm; then
        echo -e "${GREEN}✓ Helm is already installed${NC}"
    else
        tools_to_install+=("helm")
    fi
    
    # Install missing tools
    if [ ${#tools_to_install[@]} -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ All prerequisites are already installed!${NC}"
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}Missing tools: ${tools_to_install[*]}${NC}"
    echo ""
    
    # Ask for confirmation
    read -p "Do you want to install the missing tools? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        return 1
    fi
    
    # Install each missing tool
    for tool in "${tools_to_install[@]}"; do
        case "$tool" in
            "docker")
                install_docker "$os" || echo -e "${RED}Failed to install Docker${NC}"
                ;;
            "kubectl")
                install_kubectl "$os" || echo -e "${RED}Failed to install kubectl${NC}"
                ;;
            "kind")
                install_kind "$os" || echo -e "${RED}Failed to install Kind${NC}"
                ;;
            "helm")
                install_helm "$os" || echo -e "${RED}Failed to install Helm${NC}"
                ;;
        esac
        echo ""
    done
}

# Function to verify installation
verify_installation() {
    echo -e "${YELLOW}Verifying installation...${NC}"
    echo ""
    
    local all_good=true
    
    # Check Docker
    if command_exists docker; then
        local docker_version
        docker_version=$(docker --version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ Docker: ${docker_version}${NC}"
        
        # Check if Docker is running
        if docker info &> /dev/null; then
            echo -e "${GREEN}  Docker daemon is running${NC}"
        else
            echo -e "${YELLOW}  Docker daemon is not running. Please start Docker.${NC}"
            all_good=false
        fi
    else
        echo -e "${RED}✗ Docker: Not found${NC}"
        all_good=false
    fi
    
    # Check kubectl
    if command_exists kubectl; then
        local kubectl_version
        kubectl_version=$(kubectl version --client --short 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ kubectl: ${kubectl_version}${NC}"
    else
        echo -e "${RED}✗ kubectl: Not found${NC}"
        all_good=false
    fi
    
    # Check Kind
    if command_exists kind; then
        local kind_version
        kind_version=$(kind --version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ Kind: ${kind_version}${NC}"
    else
        echo -e "${RED}✗ Kind: Not found${NC}"
        all_good=false
    fi
    
    # Check Helm
    if command_exists helm; then
        local helm_version
        helm_version=$(helm version --short 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ Helm: ${helm_version}${NC}"
    else
        echo -e "${RED}✗ Helm: Not found${NC}"
        all_good=false
    fi
    
    echo ""
    if [ "$all_good" = true ]; then
        echo -e "${GREEN}✓ All prerequisites are installed and ready!${NC}"
        echo ""
        echo -e "${BLUE}You can now run the deployment script:${NC}"
        echo "  ./scripts/deploy.sh"
    else
        echo -e "${RED}✗ Some prerequisites are missing or not working${NC}"
        echo ""
        echo -e "${YELLOW}Please install the missing tools manually and try again.${NC}"
        return 1
    fi
}

# Function to show manual installation instructions
show_manual_instructions() {
    echo ""
    echo -e "${YELLOW}Manual installation instructions:${NC}"
    echo ""
    echo -e "${BLUE}Docker:${NC}"
    echo "  macOS: https://docs.docker.com/desktop/mac/install/"
    echo "  Linux: https://docs.docker.com/engine/install/"
    echo "  Windows: https://docs.docker.com/desktop/windows/install/"
    echo ""
    echo -e "${BLUE}kubectl:${NC}"
    echo "  https://kubernetes.io/docs/tasks/tools/install-kubectl/"
    echo ""
    echo -e "${BLUE}Kind:${NC}"
    echo "  https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    echo ""
    echo -e "${BLUE}Helm:${NC}"
    echo "  https://helm.sh/docs/intro/install/"
}

# Main function
main() {
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo -e "${YELLOW}Usage:${NC}"
        echo "  $0                  # Check and install prerequisites"
        echo "  $0 --verify         # Only verify existing installation"
        echo "  $0 --manual         # Show manual installation instructions"
        echo ""
        exit 0
    fi
    
    if [ "$1" = "--verify" ]; then
        verify_installation
    elif [ "$1" = "--manual" ]; then
        show_manual_instructions
    else
        check_and_install
        echo ""
        verify_installation
    fi
}

# Run main function
main "$@"
