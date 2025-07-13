# 🚀 ShipAnything - Microservices Platform

A complete microservices architecture built with Laravel 12+, running on Kubernetes with Docker. This project demonstrates a scalable, production-ready microservices setup with comprehensive infrastructure components.

## 📋 Table of Contents

- [🏗️ Architecture Overview](#%EF%B8%8F-architecture-overview)
- [🌟 Key Features](#-key-features)
- [🧩 Microservices as Git Submodules](#-microservices-as-git-submodules)
- [🆕 Recent Improvements](#-recent-improvements)
- [📋 Prerequisites](#-prerequisites)
- [🚀 Quick Start Guide](#-quick-start-guide)
- [📂 Project Structure](#-project-structure)
- [🔧 Script Integration Flow](#%EF%B8%8F-script-integration-flow)
- [🛠️ Development Commands](#%EF%B8%8F-development-commands)
- [🐛 Debugging Guide](#-debugging-guide)
- [🔧 Configuration Details](#%EF%B8%8F-configuration-details)
- [📊 Monitoring and Observability](#-monitoring-and-observability)
- [🧹 Cleanup](#-cleanup)
- [🚀 Production Deployment](#-production-deployment)
- [🤝 Contributing](#-contributing)

## 🏗️ Architecture Overview

ShipAnything is built using a distributed microservices architecture where each service has its own dedicated infrastructure:

### 🔧 Microservices

- **🔐 Auth Service** (`auth.shipanything.test`) - Authentication, authorization, and identity management
- **📍 Location Service** (`location.shipanything.test`) - Geolocation, tracking, and location-based services
- **💳 Payments Service** (`payments.shipanything.test`) - Payment processing, billing, and transaction management
- **📅 Booking Service** (`booking.shipanything.test`) - Reservation management and scheduling system
- **🔍 Fraud Detector** (`fraud.shipanything.test`) - Real-time fraud detection and risk assessment

### 🎯 Infrastructure Components

- **Laravel 12+** - Modern PHP framework for each microservice
- **Kubernetes** - Container orchestration and management
- **Kind** - Local Kubernetes cluster (Kubernetes IN Docker)
- **PostgreSQL** - Dedicated database per microservice
- **Redis** - Caching and session storage per microservice
- **RabbitMQ** - Message queuing per microservice
- **Kafka (KRaft)** - Shared event streaming across all services
- **Docker** - Containerization
- **NGINX Ingress** - Load balancing and routing

## 🌟 Key Features

- ✅ **Service Isolation**: Each microservice has its own database, cache, and message queue
- ✅ **Scalable Architecture**: Kubernetes-native with horizontal pod autoscaling ready
- ✅ **Event-Driven Communication**: Kafka for cross-service communication
- ✅ **Dual Access Methods**: Services accessible via both localhost ports and custom subdomains
- ✅ **Local Development Ready**: Complete local setup with custom domains
- ✅ **Production-Grade**: Health checks, resource limits, and monitoring ready
- ✅ **Beautiful UI**: Modern landing page with service navigation
- ✅ **Enhanced Monitoring**: Real-time deployment progress with detailed pod status and events
- ✅ **Reliable Testing**: Improved connectivity tests with ingress-first approach and NodePort fallback
- ✅ **Robust Error Handling**: Comprehensive error reporting and troubleshooting guidance
- ✅ **Cross-Platform Compatibility**: Scripts work reliably across different shell environments

## 🧩 Microservices as Git Submodules

This project uses **Git submodules** to manage each microservice as a separate repository. This allows independent development, versioning, and deployment of each service while keeping them organized under the main platform.

### Submodule Structure

Each microservice in `microservices/` is a Git submodule:

| Service          | Submodule Path                     | Repository URL                                                      |
| ---------------- | ---------------------------------- | ------------------------------------------------------------------- |
| Auth Service     | `microservices/auth-app`           | https://github.com/lalithhakari/shipanything-auth-app.git           |
| Booking Service  | `microservices/booking-app`        | https://github.com/lalithhakari/shipanything-booking-app.git        |
| Fraud Detector   | `microservices/fraud-detector-app` | https://github.com/lalithhakari/shipanything-fraud-detector-app.git |
| Location Service | `microservices/location-app`       | https://github.com/lalithhakari/shipanything-location-app.git       |
| Payments Service | `microservices/payments-app`       | https://github.com/lalithhakari/shipanything-payments-app.git       |

The submodule configuration is tracked in the `.gitmodules` file.

### Cloning with Submodules

When cloning this repository, use the `--recurse-submodules` flag to automatically initialize and fetch all microservices:

```bash
git clone --recurse-submodules https://github.com/lalithhakari/shipanything.git
```

If you already cloned without submodules, run:

```bash
git submodule update --init --recursive
```

### Keeping Submodules Up to Date

To update all submodules to their latest commits:

```bash
git submodule update --remote --merge
```

### Adding or Changing Submodules

To add a new microservice as a submodule:

```bash
git submodule add <repo-url> microservices/<service-folder>
```

To change the remote URL of a submodule, edit `.gitmodules` and run:

```bash
git submodule sync
```

## 🆕 Recent Improvements

### 🔧 **Enhanced Deployment Experience**

- **Multi-Mode Support**: The `deploy.sh` script supports both Docker Compose (development) and Kubernetes (production-like) deployment modes
- **Real-time Monitoring**: Shows detailed pod status, readiness probe information, and events during deployment
- **Intelligent Cleanup**: Automatically handles cleanup of previous deployments with multiple cleanup options
- **Comprehensive Status Checks**: Displays pod readiness states, restart counts, and ages

### 🛠️ **Comprehensive Script Collection**

- **Unified Management**: All scripts follow consistent patterns with robust error handling
- **Development Tools**: Complete set of utilities for Laravel microservice management
- **Enhanced Documentation**: Updated project documentation to accurately reflect current capabilities
- **Cross-Platform Compatibility**: Scripts work reliably across different shell environments

### **Production-Ready Features**

- **Health Checks**: Each service includes liveness and readiness probes with health endpoints
- **Resource Management**: Proper resource requests and limits for all components
- **Event Streaming**: Kafka integration for cross-service communication
- **Service Isolation**: Each microservice has dedicated infrastructure (database, cache, messaging)

## 📋 Prerequisites

Before setting up ShipAnything, ensure you have the following installed on your macOS system:

- **Docker Desktop** (with Kubernetes enabled)
- **Kind** (`brew install kind`) - **Recommended for local Kubernetes development**
- **kubectl** (`brew install kubectl`)
- **Laravel Installer** (`composer global require laravel/installer`)
- **PHP 8.2+** and **Composer**

### Verify Prerequisites

```bash
# Check Docker
docker --version

# Check Kind (Recommended)
kind version

# Check kubectl
kubectl version --client

# Check Laravel installer (optional)
laravel --version
```

## 🌟 **Why Kind?**

**Kind (Kubernetes IN Docker)** is the ideal choice for local Kubernetes development:

- ✅ **Consistent networking** across all platforms
- ✅ **Fast startup/teardown** - clusters ready in seconds
- ✅ **Reliable port forwarding** - no networking issues
- ✅ **Multi-node support** - test complex scenarios locally
- ✅ **CI/CD ready** - same tool used in production pipelines
- ✅ **Lightweight** - minimal resource overhead

## 🚀 Quick Start Guide

### Step 1: Choose Your Deployment Mode

The `deploy.sh` script supports multiple deployment modes:

```bash
# Navigate to the project directory
cd /Users/lalith/Documents/Projects/shipanything

# Run the deployment script - it will prompt you to choose a mode
./scripts/deploy.sh
```

**Available Modes:**

1. **Docker Compose (Development)** - Fast startup with hot reload for development
2. **Kind Kubernetes (Production-like)** - Full Kubernetes experience for testing
3. **Clean Kind Deployment** - Fresh Kubernetes deployment with cleanup

**Why use different modes?**

- **Docker Compose**: Perfect for active development with instant code changes
- **Kind Kubernetes**: Test production-like scenarios and Kubernetes features locally

This script will:

**For Docker Compose Mode:**

- Stop any existing containers
- Build and start all services with hot reload
- Update your `/etc/hosts` file for custom domains
- Display access URLs and service information

**For Kubernetes Mode:**

- Create a Kind cluster with proper port mappings
- Install NGINX Ingress Controller with real-time status monitoring
- Build Docker images for all services with progress tracking
- Deploy all Kubernetes resources with detailed status updates
- Create NodePort services for direct access
- Update your `/etc/hosts` file for custom domains (uses 127.0.0.1 for Kind)
- Display access URLs and troubleshooting information

**Important Note**: The deployment script automatically configures your `/etc/hosts` file with localhost entries (127.0.0.1) for Kind cluster access. This ensures custom domains work properly with Kind's networking.

**Production-Ready Setup**: All Laravel applications come pre-configured and fully operational with:

- ✅ PostgreSQL database connections (with migrations completed)
- ✅ Redis cache connections
- ✅ RabbitMQ queue connections
- ✅ Kafka event streaming connections
- ✅ Health checks and monitoring endpoints
- ✅ Kubernetes resource limits and requests

### Step 2: Access Your Services

**Direct Access via Localhost**: Services are accessible via both localhost ports and custom domains:

````bash
# Localhost Access (works immediately):
🌟 Main Dashboard: http://localhost:8080
🔐 Auth Service: http://localhost:8081
📍 Location Service: http://localhost:8082
💳 Payments Service: http://localhost:8083
📅 Booking Service: http://localhost:8084
🔍 Fraud Detector: http://localhost:8085

# Custom Domain Access (after hosts file update):
🌟 Main Dashboard: http://shipanything.test
🔐 Auth Service: http://auth.shipanything.test
📍 Location Service: http://location.shipanything.test
💳 Payments Service: http://payments.shipanything.test
📅 Booking Service: http://booking.shipanything.test
🔍 Fraud Detector: http://fraud.shipanything.test

## 🐳 Docker Compose Development Setup

For local development with instant code reload:

```bash
# Choose Docker Compose mode when running deploy script
./scripts/deploy.sh

# Or manually start Docker Compose
docker compose up --build
````

Add these lines to your `/etc/hosts` for custom domain support:

```
127.0.0.1 auth.shipanything.test
127.0.0.1 location.shipanything.test
127.0.0.1 payments.shipanything.test
127.0.0.1 booking.shipanything.test
127.0.0.1 fraud.shipanything.test
```

Edit your code in the microservices folders and changes will be reflected instantly.

### Step 2.5: Verify Deployment

After deployment, verify everything is working correctly:

```bash
# Check all pods are running (should show 1/1 Ready for all pods)
kubectl get pods -n shipanything

# Test localhost access
curl -I http://localhost:8080

# Test custom domain access (ensure hosts file is configured)
curl -I http://shipanything.test

# Quick status check (check pods and services)
kubectl get pods -n shipanything
kubectl get services -n shipanything
```

**Expected Output**: All services should return HTTP 200 status codes, and you should see the ShipAnything landing page with service navigation.

### Step 3: Verify Deployment

After deployment, verify all services are working correctly:

```bash
# Check all pods are running (should show 1/1 Ready for all pods)
kubectl get pods -n shipanything

# Test localhost access
curl -I http://localhost:8080

# Test custom domain access (ensure hosts file is configured)
curl -I http://shipanything.test

# Check ingress configuration
kubectl get ingress -n shipanything
```

## 📂 Project Structure

```
shipanything/
├── .gitmodules              # Git submodules configuration
├── README.md                # This file
├── docker-compose.yml       # Docker Compose configuration for development
├── k8s/                     # Kubernetes manifests
│   ├── namespace.yaml       # Kubernetes namespace
│   ├── auth-app.yaml        # Auth service deployment
│   ├── auth-postgres.yaml   # Auth PostgreSQL database
│   ├── auth-rabbitmq.yaml   # Auth RabbitMQ instance
│   ├── auth-redis.yaml      # Auth Redis cache
│   ├── booking-app.yaml     # Booking service deployment
│   ├── booking-postgres.yaml # Booking PostgreSQL database
│   ├── booking-rabbitmq.yaml # Booking RabbitMQ instance
│   ├── booking-redis.yaml   # Booking Redis cache
│   ├── fraud-detector-app.yaml # Fraud detection service deployment
│   ├── fraud-postgres.yaml  # Fraud PostgreSQL database
│   ├── fraud-rabbitmq.yaml  # Fraud RabbitMQ instance
│   ├── fraud-redis.yaml     # Fraud Redis cache
│   ├── location-app.yaml    # Location service deployment
│   ├── location-postgres.yaml # Location PostgreSQL database
│   ├── location-rabbitmq.yaml # Location RabbitMQ instance
│   ├── location-redis.yaml  # Location Redis cache
│   ├── payments-app.yaml    # Payments service deployment
│   ├── payments-postgres.yaml # Payments PostgreSQL database
│   ├── payments-rabbitmq.yaml # Payments RabbitMQ instance
│   ├── payments-redis.yaml  # Payments Redis cache
│   ├── kafka.yaml           # Shared Kafka cluster
│   ├── web-configmap.yaml   # Web content configuration
│   ├── web-nginx.yaml       # Web frontend deployment
│   ├── ingress.yaml         # Ingress routing rules
│   └── kind-config.yaml     # Kind cluster configuration
├── microservices/           # Laravel applications (Git submodules)
│   ├── auth-app/            # Authentication service
│   ├── location-app/        # Location service
│   ├── payments-app/        # Payments service
│   ├── booking-app/         # Booking service
│   └── fraud-detector-app/  # Fraud detection service
├── nginx/                   # Nginx configuration files
│   └── nginx.conf           # Main nginx configuration
├── scripts/                 # Utility scripts
│   ├── deploy.sh            # 🚀 Main deployment script (multi-mode support)
│   ├── cleanup.sh           # 🧹 Environment cleanup
│   ├── verify.sh            # ✅ Prerequisites verification
│   ├── create-all-apps.sh   # 🏗️ Create Laravel apps (development)
│   ├── setup-laravel-docker.sh # 🐳 Docker setup per app (development)
│   ├── laravel-manager.sh   # 📦 Laravel application management
│   ├── test-deployment-modes.sh # 🧪 Test different deployment modes
│   ├── update-manifests.sh  # 🔄 Update Kubernetes manifests
│   ├── init-databases.sh    # 💾 Database initialization (internal)
│   ├── init-laravel.sh      # ⚙️ Laravel initialization (internal)
│   └── utils.sh             # 🔧 Shared utility functions
└── web/                     # Landing page assets
    ├── index.html           # Main landing page
    └── nginx.conf           # Web frontend nginx configuration
```

## 🔧 Script Integration Flow

The scripts are intelligently integrated to provide a seamless experience:

### 🚀 **Main Deployment Flow**

- `deploy.sh` → **Multi-mode deployment** → Automatic environment setup and validation

### ✅ **Verification Flow**

- `verify.sh` → **Prerequisites validation** → Environment readiness check

### 📊 **Available Tools**

- `cleanup.sh` - Environment cleanup with Kind cluster management
- `laravel-manager.sh` - Laravel application lifecycle management
- `test-deployment-modes.sh` - Test different deployment configurations
- `update-manifests.sh` - Update and manage Kubernetes manifests

### 🛠️ **Development Tools**

- `create-all-apps.sh` - Creates Laravel microservices (development setup)
- `setup-laravel-docker.sh` - Docker configuration per app (called by create-all-apps.sh)
- `init-databases.sh` - Database initialization (internal)
- `init-laravel.sh` - Laravel initialization (internal)
- `utils.sh` - Shared utility functions used across all scripts

**Key Features**:

- ✅ **Multi-Mode Deployment**: Support for both Docker Compose (development) and Kubernetes (production) modes
- ✅ **Enhanced Monitoring**: Real-time deployment progress with comprehensive status updates
- ✅ **Robust Architecture**: All scripts follow consistent patterns with proper error handling
- ✅ **Development Tools**: Complete toolkit for Laravel microservice development and management

## 🛠️ Development Commands

### Managing the Cluster

```bash
# Create Kind cluster
kind create cluster --config k8s/kind-config.yaml

# Delete Kind cluster
kind delete cluster --name shipanything

# List Kind clusters
kind get clusters

# Load Docker image into Kind cluster
kind load docker-image <image-name> --name shipanything
```

### Kubernetes Operations

```bash
# Check all pods
kubectl get pods -n shipanything

# Check services
kubectl get services -n shipanything

# Check ingress
kubectl get ingress -n shipanything

# View logs for a specific service
kubectl logs -f deployment/auth-app -n shipanything

# Scale a service
kubectl scale deployment auth-app --replicas=3 -n shipanything

# Restart a deployment
kubectl rollout restart deployment/auth-app -n shipanything
```

### Docker Operations

```bash
# Build a specific service
cd microservices/auth-app
docker build -t auth-app:latest .

# Load image into Kind cluster
kind load docker-image auth-app:latest --name shipanything

# List Docker images
docker images

# Remove unused images
docker system prune -f
```

## 🐛 Debugging Guide

### Common Issues and Solutions

**Important**: ShipAnything provides **dual access methods** for reliability:

- **Localhost ports** (8080-8085) - Always work immediately after deployment
- **Custom subdomains** (\*.shipanything.test) - Require hosts file configuration

If custom domains don't work, you can always use localhost ports as a fallback.

#### 1. Cannot Access Services

**Problem**: Services not accessible via localhost or custom domains.

**Solutions**:

```bash
# Check if Kind cluster is running
kind get clusters

# Verify pods are running
kubectl get pods -n shipanything

# Check service endpoints
kubectl get endpoints -n shipanything

# Test service connectivity
curl -I http://localhost:8080
```

#### 2. Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n shipanything

# Check events
kubectl get events -n shipanything --sort-by='.lastTimestamp'

# Check logs
kubectl logs -f deployment/auth-app -n shipanything
```

#### 3. Service Connectivity Issues

**Problem**: Services show as running but connectivity tests fail.

**Solutions**:

```bash
# Run manual connectivity tests
# Check if Kind cluster is running
kind get clusters

# Verify pods are running
kubectl get pods -n shipanything

# Check service endpoints
kubectl get endpoints -n shipanything

# Test service connectivity
curl -I http://localhost:8080

# Check ingress configuration
kubectl describe ingress -n shipanything

# Verify ingress controller is running
kubectl get pods -n ingress-nginx

# Test NodePort connectivity (direct access)
curl http://localhost:30080  # Main Dashboard
curl http://localhost:30081  # Auth Service
```

#### 4. Custom Domains Not Working

**Problem**: Custom domains (\*.shipanything.test) not accessible, even though localhost ports work.

**Common Cause**: Incorrect IP addresses in hosts file or hosts file not configured.

**Solutions**:

```bash
# Check if hosts file entries exist and verify IPs
cat /etc/hosts | grep shipanything

# Remove any incorrect entries
sudo sed -i '' '/shipanything.test/d' /etc/hosts

# Add correct entries for Kind cluster (should always be 127.0.0.1)
sudo sh -c 'cat >> /etc/hosts << EOF
127.0.0.1 shipanything.test
127.0.0.1 auth.shipanything.test
127.0.0.1 location.shipanything.test
127.0.0.1 payments.shipanything.test
127.0.0.1 booking.shipanything.test
127.0.0.1 fraud.shipanything.test
EOF'

# Test subdomain connectivity
curl -I http://shipanything.test

# Verify ingress is working
kubectl get ingress -n shipanything
```

**Note**: Kind always uses localhost (127.0.0.1) for cluster access, providing consistent networking across all platforms.

#### 5. Database Connection Issues

```bash
# Check PostgreSQL pod logs
kubectl logs -f statefulset/auth-postgres -n shipanything

# Connect to database directly
kubectl exec -it auth-postgres-0 -n shipanything -- psql -U auth_user -d auth_db
```

## 🔧 Configuration Details

### Database Configuration

Each microservice has its own PostgreSQL database:

- **Auth DB**: `auth_db` (user: `auth_user`)
- **Location DB**: `location_db` (user: `location_user`)
- **Payments DB**: `payments_db` (user: `payments_user`)
- **Booking DB**: `booking_db` (user: `booking_user`)
- **Fraud DB**: `fraud_db` (user: `fraud_user`)

### Redis Configuration

Each service has its own Redis instance for caching:

- `auth-redis:6379`
- `location-redis:6379`
- `payments-redis:6379`
- `booking-redis:6379`
- `fraud-redis:6379`

### RabbitMQ Configuration

Each service has its own RabbitMQ instance:

- Management UI accessible at `<service>-rabbitmq:15672`
- AMQP connection at `<service>-rabbitmq:5672`

### Kafka Configuration

Shared Kafka cluster using KRaft mode:

- Bootstrap servers: `kafka:29092`
- Internal communication: `kafka:9093`

### Laravel Environment Configuration

Each Laravel microservice is configured with the following environment variables:

#### Database Configuration (PostgreSQL)

```bash
DB_CONNECTION=pgsql
DB_HOST=<service>-postgres  # e.g., auth-postgres, location-postgres
DB_PORT=5432
DB_DATABASE=<service>_db    # e.g., auth_db, location_db
DB_USERNAME=<service>_user  # e.g., auth_user, location_user
DB_PASSWORD=<service>_password
```

#### Redis Configuration

```bash
REDIS_CLIENT=phpredis
REDIS_HOST=<service>-redis  # e.g., auth-redis, location-redis
REDIS_PASSWORD=null
REDIS_PORT=6379
```

#### RabbitMQ Configuration

```bash
QUEUE_CONNECTION=rabbitmq
RABBITMQ_HOST=<service>-rabbitmq  # e.g., auth-rabbitmq, location-rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_USER=<service>_user      # e.g., auth_user, location_user
RABBITMQ_PASSWORD=<service>_password
```

#### Kafka Configuration

```bash
KAFKA_BROKERS=kafka:29092
```

## 🧹 Cleanup

To completely remove the deployment:

```bash
# Quick cleanup - delete Kind cluster
kind delete cluster --name shipanything

# Or use the cleanup script for thorough cleanup
./scripts/cleanup.sh

# This will:
# - Delete the Kind cluster
# - Remove Docker images
# - Clean up hosts file entries
# - Remove any temporary files
```

## 📊 Monitoring and Observability

### Health Checks

All services include:

- **Liveness Probes**: Check if the container is running
- **Readiness Probes**: Check if the service is ready to accept traffic

### Resource Management

Each component has defined:

- **Resource Requests**: Minimum guaranteed resources
- **Resource Limits**: Maximum allowed resources

### Logging

```bash
# View logs for all services
kubectl logs -f deployment/auth-app -n shipanything
kubectl logs -f deployment/location-app -n shipanything
kubectl logs -f deployment/payments-app -n shipanything
kubectl logs -f deployment/booking-app -n shipanything
kubectl logs -f deployment/fraud-detector-app -n shipanything
```

## 🔒 Security Considerations

- All inter-service communication happens within the Kubernetes cluster
- Database credentials are configured as environment variables
- Services are isolated with their own network policies
- Ingress handles external traffic routing securely

## 🚀 Production Deployment

This setup is designed for local development. For production:

1. **Replace Kind** with a managed Kubernetes service (EKS, GKE, AKS)
2. **Use managed databases** instead of in-cluster PostgreSQL
3. **Implement proper secrets management** (Kubernetes Secrets, Vault)
4. **Add TLS certificates** for HTTPS
5. **Configure monitoring** (Prometheus, Grafana)
6. **Set up CI/CD pipelines** for automated deployments
7. **Implement backup strategies** for data persistence

## 🚀 Usage Instructions

### For M1 MacBook Pro Setup

1. **Prerequisites Check**:

   ```bash
   # Ensure Docker Desktop is running
   docker ps

   # Verify Kind installation
   kind version

   # Check kubectl
   kubectl version --client
   ```

2. **Deploy the Stack**:

   ```bash
   # Navigate to project
   cd /Users/lalith/Documents/Projects/shipanything

   # Deploy the platform
   ./scripts/deploy.sh
   ```

3. **Verify Deployment**:

   ```bash
   # Check all pods are running
   kubectl get pods -n shipanything

   # Check services
   kubectl get services -n shipanything

   # Check ingress
   kubectl get ingress -n shipanything
   ```

4. **Access Services**:

   ```bash
   # Open main dashboard
   open http://localhost:8080

   # Check service status
   kubectl get pods -n shipanything
   kubectl get services -n shipanything
   ```

### Troubleshooting M1 Specific Issues

If you encounter issues on M1 MacBook Pro:

```bash
# Ensure Docker Desktop has adequate resources:
# - Memory: 8GB+
# - CPUs: 4+
# - Swap: 2GB+

# Check if Kind cluster is running
kind get clusters

# Restart Kind cluster if needed
kind delete cluster --name shipanything
./scripts/deploy.sh
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- Laravel team for the amazing framework
- Kubernetes community for excellent orchestration tools
- Docker for containerization technology
- The open-source community for all the tools used in this project
- https://github.com/kubernetes/minikube/issues/13951

---

**Built with ❤️ for microservices architecture enthusiasts**

For questions or support, please open an issue in the repository.

## 🛠️ Running Laravel Commands in Containers

When using Docker Compose mode, you can execute Laravel artisan and composer commands inside any container using the `cmd.sh` script located in each app's `docker/` folder:

```bash
# Navigate to any Laravel app's docker folder
cd microservices/auth-app/docker

# Run any Laravel artisan command
./cmd.sh php artisan migrate
./cmd.sh php artisan make:controller UserController
./cmd.sh php artisan tinker

# Run composer commands
./cmd.sh composer install
./cmd.sh composer require laravel/sanctum
```

Each microservice has its own `cmd.sh` script that automatically targets the correct container. The script checks if containers are running and provides helpful error messages if they're not.

Edit your code in the microservices folders and changes will be reflected instantly.
