# 🚀 ShipAnything - Microservices Platform

A complete microservices architecture built with Laravel 12+, running on Kubernetes with Docker. This project demonstrates a scalable, production-ready microservices setup with comprehensive infrastructure components.

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
- **Kind** - Local Kubernetes cluster (Docker-based)
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

## 🆕 Recent Improvements

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

### 🔧 **Enhanced Deployment Script (`deploy.sh`)**

- **Real-time Monitoring**: Shows detailed pod status, readiness probe information, and events during deployment
- **Better Timeout Handling**: Provides informative feedback when services take longer to start
- **Comprehensive Status Checks**: Displays pod readiness states, restart counts, and ages
- **Event Tracking**: Shows Kubernetes events for problematic pods to aid debugging

### 🧪 **Improved Testing Script (`test-services.sh`)**

- **Dual Testing Approach**: Primary ingress testing with NodePort fallback for maximum reliability
- **Enhanced Compatibility**: Removed bash-specific associative arrays for broader shell support
- **Better Error Reporting**: Shows pod status when services fail, with actionable troubleshooting steps
- **Comprehensive Validation**: Tests both connectivity and response content validation

### 🛠️ **Standardized Scripts**

- **Consistent Error Handling**: All startup scripts follow identical patterns with robust error detection
- **Fixed Syntax Issues**: Resolved `local` variable scope issues and bash compatibility problems
- **Cleaned Codebase**: Removed redundant and problematic scripts for a cleaner project structure
- **Enhanced Documentation**: Updated README with current script capabilities and usage patterns

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

### Step 1: Deploy to Kubernetes with Kind

```bash
# Navigate to the project directory
cd /Users/lalith/Documents/Projects/shipanything

# Deploy the entire platform
./scripts/deploy.sh
```

**Why Kind is the best choice**: Kind provides consistent networking across all platforms and doesn't have the limitations of other local Kubernetes solutions.

This script will:

- Create a Kind cluster with proper port mappings
- Install NGINX Ingress Controller with real-time status monitoring
- Build Docker images for all services with progress tracking
- Deploy all Kubernetes resources with detailed pod status updates
- Create NodePort services for direct access
- Update your `/etc/hosts` file for custom domains (uses 127.0.0.1 for Kind)
- Run comprehensive connectivity tests automatically
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

```bash
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

## 🐳 Docker Compose Hot Reload Setup

docker-compose -f docker-compose.yml -f docker-compose.override.yml up --build
For local development with instant code reload, add these lines to your /etc/hosts:

```

127.0.0.1 auth.shipanything.test
127.0.0.1 location.shipanything.test
127.0.0.1 payments.shipanything.test
127.0.0.1 booking.shipanything.test
127.0.0.1 fraud.shipanything.test

```

Then run:

```

docker-compose up --build

```

Edit your code in the microservices folders and changes will be reflected instantly.
```

### Step 2.5: Verify Deployment

After deployment, verify everything is working correctly:

```bash
# Check all pods are running (should show 1/1 Ready for all pods)
kubectl get pods -n shipanything

# Test localhost access
curl -I http://localhost:8080

# Test custom domain access (ensure hosts file is configured)
curl -I http://shipanything.test

# Quick status check
./scripts/status-report.sh
```

**Expected Output**: All services should return HTTP 200 status codes, and you should see the ShipAnything landing page with service navigation.

### Step 3: Test Services

After deployment, verify all services are working correctly:

```bash
# Run comprehensive service connectivity tests
./scripts/test-services.sh
```

This script will:

- Test all services via ingress (primary method)
- Fallback to NodePort testing if ingress fails
- Show detailed pod status for debugging
- Provide troubleshooting guidance if issues are found

## 📂 Project Structure

```
shipanything/
├── README.md                 # This file
├── k8s/                     # Kubernetes manifests
│   ├── namespace.yaml       # Kubernetes namespace
│   ├── *-postgres.yaml      # PostgreSQL databases
│   ├── *-redis.yaml         # Redis instances
│   ├── *-rabbitmq.yaml      # RabbitMQ instances
│   ├── kafka.yaml           # Shared Kafka cluster
│   ├── *-app.yaml           # Laravel application deployments
│   ├── web-*.yaml           # Landing page components
│   ├── ingress.yaml         # Ingress routing rules
│   └── kind-config.yaml     # Kind cluster configuration
├── microservices/           # Laravel applications
│   ├── auth-app/            # Authentication service
│   ├── location-app/        # Location service
│   ├── payments-app/        # Payments service
│   ├── booking-app/         # Booking service
│   └── fraud-detector-app/  # Fraud detection service
├── scripts/                 # Utility scripts
│   ├── deploy.sh            # 🚀 Main deployment script (enhanced monitoring)
│   ├── test-services.sh     # 🧪 Service connectivity tests (improved reliability)
│   ├── cleanup.sh           # 🧹 Environment cleanup
│   ├── status-report.sh     # � Real-time platform status
│   ├── verify.sh            # ✅ Prerequisites verification
│   ├── final-check.sh       # 🔍 Comprehensive requirements check
│   ├── create-all-apps.sh   # 🏗️ Create Laravel apps (development)
│   ├── setup-laravel-docker.sh # 🐳 Docker setup per app (development)
│   ├── init-databases.sh    # 💾 Database initialization (internal)
│   └── init-laravel.sh      # ⚙️ Laravel initialization (internal)
├── web/                     # Landing page assets
│   └── index.html           # Main landing page
```

## � Script Integration Flow

The scripts are intelligently integrated to provide a seamless experience:

### 🚀 **Main Deployment Flow**

- `deploy.sh` → **Enhanced with real-time monitoring** → `test-services.sh` (automatic post-deployment validation)

### ✅ **Verification Flow**

- `verify.sh` → **Automatically calls** → `final-check.sh` (comprehensive validation)

### 📊 **Standalone Tools**

- `status-report.sh` - Real-time platform status with detailed cluster information
- `cleanup.sh` - Environment cleanup with Kind cluster management
- `test-services.sh` - Improved connectivity testing with ingress and NodePort fallback

### 🛠️ **Development Tools**

- `create-all-apps.sh` - Creates Laravel microservices (development setup)
- `setup-laravel-docker.sh` - Docker configuration per app (called by create-all-apps.sh)
- `init-databases.sh` - Database initialization (internal)
- `init-laravel.sh` - Laravel initialization (internal)

**Key Improvements**:

- ✅ **Enhanced Monitoring**: Real-time deployment progress with pod status and events
- ✅ **Reliable Testing**: Improved connectivity tests using ingress-first approach
- ✅ **Better Error Handling**: Comprehensive error reporting and troubleshooting guidance
- ✅ **Robust Architecture**: All scripts follow consistent patterns with proper error handling

## �🛠️ Development Commands

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
# Run the comprehensive service test script (improved version)
./scripts/test-services.sh

# This script now provides:
# - Dual testing approach (ingress + NodePort fallback)
# - Detailed pod status for debugging
# - Enhanced compatibility across shell environments
# - Actionable troubleshooting guidance

# Manual checks if needed:
# Check ingress configuration
kubectl describe ingress -n shipanything

# Verify ingress controller is running
kubectl get pods -n ingress-nginx

# Test NodePort connectivity (direct access)
curl http://localhost:30080  # Main Dashboard
curl http://localhost:30081  # Auth Service
```

**Note**: The updated `test-services.sh` script now handles connectivity issues more robustly by testing both ingress and NodePort methods automatically.

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

## 🆕 Recent Improvements

### Enhanced Deployment Experience

- **Real-time Monitoring**: The `deploy.sh` script now provides detailed progress tracking with pod status, events, and readiness probe information
- **Improved Error Handling**: All scripts have been standardized with robust error handling and consistent patterns
- **Better Testing**: The `test-services.sh` script has been completely rewritten to use reliable ingress testing with NodePort fallback

### Script Optimization

- **Removed Redundant Scripts**: Cleaned up `quick-fix.sh`, `quick-access.sh`, `status.sh`, and backup files
- **Fixed Syntax Issues**: Resolved `local` variable errors and bash syntax problems
- **Consistent Architecture**: All microservice startup scripts now follow identical patterns

### Reliability Improvements

- **Ingress-First Testing**: Replaced problematic port-forwarding with reliable ingress testing
- **Enhanced Monitoring**: Real-time feedback during deployment with detailed pod status and event tracking
- **Robust Fallbacks**: NodePort testing as fallback when ingress tests fail

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
kubectl logs -f deployment/fraud-app -n shipanything
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

   # Run comprehensive service tests
   ./scripts/test-services.sh
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
