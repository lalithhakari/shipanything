# 🚀 ShipAnything - Microservices Platform

A complete microservices architecture built with Laravel 11+, running on Kubernetes with Docker. This project demonstrates a scalable, production-ready microservices setup with comprehensive infrastructure components.

## 📋 Table of Contents

- [🏗️ Architecture Overview](#%EF%B8%8F-architecture-overview)
- [🌟 Key Features](#-key-features)
- [📋 Prerequisites](#-prerequisites)
- [🚀 Quick Start](#-quick-start)
- [📂 Project Structure](#-project-structure)
- [🐳 Docker Compose Configuration](#-docker-compose-configuration)
- [🧩 Microservices as Git Submodules](#-microservices-as-git-submodules)
- [🛠️ Development](#-development)
- [🐛 Debugging Guide](#-debugging-guide)
- [🧹 Cleanup](#-cleanup)
- [🤝 Contributing](#-contributing)

## 🏗️ Architecture Overview

ShipAnything demonstrates a distributed microservices architecture where each service operates independently with its own dedicated infrastructure.

### 🔧 Microservices

- **🔐 Auth Service** (`auth.shipanything.test`) - Authentication, authorization, JWT token management, and API gateway integration
- **📍 Location Service** (`location.shipanything.test`) - Geolocation, tracking, and location-based services (Protected by Auth Gateway)
- **💳 Payments Service** (`payments.shipanything.test`) - Payment processing, billing, and transaction management (Protected by Auth Gateway)
- **📅 Booking Service** (`booking.shipanything.test`) - Reservation management and scheduling system (Protected by Auth Gateway)
- **🔍 Fraud Detector** (`fraud.shipanything.test`) - Real-time fraud detection and risk assessment (Protected by Auth Gateway)

**All services except Auth require Bearer token authentication via the NGINX API Gateway.**

### 🎯 Infrastructure Components

- **Laravel 11+** - Modern PHP framework for each microservice
- **Kubernetes** - Container orchestration and management (Kind for local development)
- **PostgreSQL** - Dedicated database per microservice
- **Redis** - Caching and session storage per microservice
- **RabbitMQ** - Message queuing per microservice
- **Kafka (KRaft)** - Shared event streaming across all services
- **Docker** - Containerization
- **NGINX Ingress** - Load balancing and routing

## 🌟 Key Features

- ✅ **Service Isolation**: Each microservice has its own database, cache, and message queue
- ✅ **Scalable Architecture**: Kubernetes-native with horizontal pod autoscaling ready
- ✅ **Event-Driven Communication**: Kafka for cross-service communication and RabbitMQ for internal messaging
- ✅ **Comprehensive Testing**: Built-in test endpoints for database, cache, RabbitMQ, and Kafka connectivity
- ✅ **Dual Deployment**: Both Docker Compose (development) and Kubernetes (production-like) support
- ✅ **Local Development Ready**: Complete local setup with custom domains and hot reload
- ✅ **Production-Grade**: Health checks, resource limits, and monitoring ready
- ✅ **Modern UI**: Beautiful landing page with service navigation
- ✅ **API Gateway & Authentication**: NGINX-based gateway with JWT authentication for all protected services
- ✅ **Security**: Rate limiting, token validation, and secure inter-service communication

## 📋 Prerequisites

Ensure you have the following installed on your macOS system:

- **Docker Desktop** (with Kubernetes enabled)
- **Kind** (`brew install kind`) - For local Kubernetes development
- **kubectl** (`brew install kubectl`)
- **PHP 8.2+** and **Composer** (for local development)

### Verify Prerequisites

```bash
# Check Docker
docker --version

# Check Kind
kind version

# Check kubectl
kubectl version --client
```

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/lalithhakari/shipanything.git
cd shipanything

# Run the deployment script
./scripts/deploy.sh
```

The script will prompt you to choose between:

1. **Docker Compose (Development)** - Fast startup with hot reload
2. **Kind Kubernetes (Production-like)** - Full Kubernetes experience
3. **Clean Kind Deployment** - Fresh Kubernetes deployment with cleanup

### Option 2: Manual Docker Compose

```bash
# Start all services
docker compose up --build -d

# Add to /etc/hosts
echo "127.0.0.1 auth.shipanything.test location.shipanything.test payments.shipanything.test booking.shipanything.test fraud.shipanything.test shipanything.test" | sudo tee -a /etc/hosts
```

### Access Your Services

**Main Dashboard**: http://shipanything.test or http://localhost:8080

**Individual Services**:

- 🔐 Auth: http://auth.shipanything.test or http://localhost:8081
- 📍 Location: http://location.shipanything.test or http://localhost:8082
- 💳 Payments: http://payments.shipanything.test or http://localhost:8083
- 📅 Booking: http://booking.shipanything.test or http://localhost:8084
- 🔍 Fraud: http://fraud.shipanything.test or http://localhost:8085

**Management UIs**:

- 🐰 RabbitMQ: http://localhost:15672-15676 (varies by service, see individual microservice READMEs)
- 📊 Kafka UI: http://localhost:8090 (Docker Compose) or http://shipanything.test:8090 (Kubernetes)

**Test Endpoints**:

- Database/Cache/Redis: `/api/test/dbs`
- RabbitMQ: `/api/test/rabbitmq`
- Kafka: `/api/test/kafka`

## 🔐 Authentication & API Gateway Architecture

The ShipAnything platform implements a **centralized authentication system** using NGINX as an **API Gateway** with JWT token validation. This approach provides secure, scalable authentication across all microservices.

### **API Gateway (NGINX) - Your Entry Point**

**🌐 Local Development Access:**

- **Main Dashboard**: http://shipanything.test or http://localhost:8080
- **API Gateway Entry Points**: All `*.shipanything.test` domains route through NGINX

**🔧 API Gateway Functions:**

- **Request Routing**: Routes traffic to appropriate microservices
- **Authentication**: Validates JWT tokens for all protected endpoints
- **User Context**: Injects user information into requests
- **Rate Limiting**: Protects against abuse (10 req/min auth, 100 req/min API)
- **Load Balancing**: Distributes traffic across service instances

### **Authentication Flow:**

```
Client Request → NGINX API Gateway → Auth Validation → Target Service
     ↓
1. Client sends request to *.shipanything.test
2. NGINX gateway intercepts and validates Bearer token
3. Auth service validates JWT and returns user context
4. NGINX forwards request + user context to target service
5. Target service processes with authenticated user context
6. Response returns through gateway to client
```

### **Quick Authentication Setup:**

1. **Register a user:**

```bash
curl -X POST http://auth.shipanything.test/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com", "password": "password123", "password_confirmation": "password123"}'
```

2. **Login and get access token:**

```bash
curl -X POST http://auth.shipanything.test/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "john@example.com", "password": "password123"}'
```

3. **Access protected services via API Gateway:**

```bash
curl -X GET http://location.shipanything.test/api/locations \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

curl -X GET http://payments.shipanything.test/api/payments \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### **Deployment Modes:**

**Mode 1 (Docker Compose):**

- NGINX as reverse proxy + API gateway
- Direct container-to-container communication
- Custom domain routing via hosts file

**Mode 2 (Kubernetes):**

- NGINX Ingress Controller as API gateway
- Kubernetes-native service discovery
- Advanced authentication annotations

**📖 Complete Setup Guide:** See [AUTHENTICATION.md](AUTHENTICATION.md) for detailed configuration and examples.

## **Why Kind?**

**Kind (Kubernetes IN Docker)** is the ideal choice for local Kubernetes development:

- ✅ **Consistent networking** across all platforms
- ✅ **Fast startup/teardown** - clusters ready in seconds
- ✅ **Reliable port forwarding** - no networking issues
- ✅ **Multi-node support** - test complex scenarios locally
- ✅ **CI/CD ready** - same tool used in production pipelines
- ✅ **Lightweight** - minimal resource overhead

## 🔐 API Gateway & Authentication Approach

### **Recommended Architecture (Currently Implemented)**

The ShipAnything platform follows **Approach 1** - a centralized API Gateway pattern:

```
Client Request → NGINX API Gateway → Auth Service (Token Validation) → Target Microservice
```

**How it works:**

1. **All requests** to `*.shipanything.test` domains go through NGINX API Gateway
2. **NGINX validates** the Bearer token by calling the auth service internally
3. **Auth service** validates JWT and returns user context (ID, email, roles)
4. **NGINX forwards** the request to the target service with user context headers
5. **Target service** processes business logic with authenticated user context
6. **Response flows back** through NGINX to the client

### **Why This Approach?**

✅ **Centralized Security**: Single point for authentication logic
✅ **Service Isolation**: Microservices don't handle auth complexity
✅ **Performance**: Token validation cached and optimized at gateway
✅ **Scalability**: Easy to add new services without auth code duplication
✅ **Flexibility**: Support for different auth methods (JWT, API keys, OAuth)
✅ **Rate Limiting**: Built-in protection against abuse
✅ **Monitoring**: Centralized logging and security analytics

### **Implementation Details**

**Mode 1 (Docker Compose):**

- Uses `nginx/nginx-auth.conf` for authentication
- NGINX `auth_request` module validates tokens
- User context passed via HTTP headers (`X-User-ID`, `X-User-Email`)

**Mode 2 (Kubernetes):**

- Uses `k8s/ingress-auth.yaml` with NGINX Ingress Controller
- Advanced annotations for authentication and rate limiting
- Native Kubernetes service discovery and load balancing

## 🧩 Microservices as Git Submodules

Each microservice is managed as a separate Git repository using submodules:

| Service          | Repository URL                                                      |
| ---------------- | ------------------------------------------------------------------- |
| Auth Service     | https://github.com/lalithhakari/shipanything-auth-app.git           |
| Booking Service  | https://github.com/lalithhakari/shipanything-booking-app.git        |
| Fraud Detector   | https://github.com/lalithhakari/shipanything-fraud-detector-app.git |
| Location Service | https://github.com/lalithhakari/shipanything-location-app.git       |
| Payments Service | https://github.com/lalithhakari/shipanything-payments-app.git       |

### Submodule Commands

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/lalithhakari/shipanything.git

# If already cloned, initialize submodules
git submodule update --init --recursive

# Update all submodules
git submodule update --remote --merge
```

## 🛠️ Development

### Authentication Testing

Test the complete authentication flow:

```bash
# 1. Register a new user
curl -X POST http://auth.shipanything.test/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'

# 2. Login and extract token
RESPONSE=$(curl -s -X POST http://auth.shipanything.test/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}')

TOKEN=$(echo $RESPONSE | jq -r '.access_token')

# 3. Test protected endpoints via API Gateway
curl -X GET http://location.shipanything.test/api/locations \
  -H "Authorization: Bearer $TOKEN"

curl -X GET http://payments.shipanything.test/api/payments \
  -H "Authorization: Bearer $TOKEN"

curl -X GET http://booking.shipanything.test/api/bookings \
  -H "Authorization: Bearer $TOKEN"

curl -X GET http://fraud.shipanything.test/api/fraud/reports \
  -H "Authorization: Bearer $TOKEN"
```

### Switching Between Authentication Modes

The project supports two authentication configurations:

**Basic Mode (No Authentication) - `nginx/nginx.conf`:**

```bash
# Copy basic NGINX config (current default)
cp nginx/nginx.conf nginx/nginx.conf.backup
```

**Protected Mode (Full Authentication) - `nginx/nginx-auth.conf`:**

```bash
# For Docker Compose (Mode 1) - Enable authentication
cp nginx/nginx-auth.conf nginx/nginx.conf
docker compose down && docker compose up --build -d

# For Kubernetes (Mode 2) - Use auth-enabled ingress
kubectl apply -f k8s/ingress-auth.yaml
```

**Note**: The auth-enabled configurations provide enterprise-grade security with JWT validation, rate limiting, and user context injection.

### Running Laravel Commands

Execute Laravel artisan and composer commands inside containers:

```bash
# Navigate to any microservice's docker folder
cd microservices/auth-app/docker

# Run Laravel commands
./cmd.sh php artisan migrate
./cmd.sh php artisan make:controller UserController
./cmd.sh composer install
```

### Development Scripts

```bash
# Verify all services are working (including authentication)
./scripts/verify.sh

# Clean up resources
./scripts/cleanup.sh

# Initialize databases with proper auth setup
./scripts/init-databases.sh
```

### Hot Reload Development

When using Docker Compose mode, code changes are reflected instantly. Edit files in the `microservices/` folders and see changes immediately.

### Testing Protected Services

All services except Auth require authentication. Here's how to test them:

```bash
# Step 1: Get authentication token
AUTH_RESPONSE=$(curl -s -X POST http://auth.shipanything.test/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "your@email.com", "password": "yourpassword"}')

TOKEN=$(echo $AUTH_RESPONSE | jq -r '.access_token')

# Step 2: Test each protected service
echo "Testing Location Service..."
curl -X GET http://location.shipanything.test/api/locations \
  -H "Authorization: Bearer $TOKEN"

echo "Testing Payments Service..."
curl -X GET http://payments.shipanything.test/api/payments \
  -H "Authorization: Bearer $TOKEN"

echo "Testing Booking Service..."
curl -X GET http://booking.shipanything.test/api/bookings \
  -H "Authorization: Bearer $TOKEN"

echo "Testing Fraud Detector..."
curl -X GET http://fraud.shipanything.test/api/fraud/reports \
  -H "Authorization: Bearer $TOKEN"
```

## 📂 Project Structure

```
shipanything/
├── .gitmodules              # Git submodules configuration
├── README.md                # This file - Main project documentation
├── docker-compose.yml       # 🐳 Docker Compose configuration for development
├── k8s/                     # Kubernetes manifests for production deployment
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
│   ├── kafka.yaml           # Shared Kafka cluster (KRaft mode)
│   ├── web-configmap.yaml   # Web content configuration
│   ├── web-nginx.yaml       # Web frontend deployment
│   ├── ingress.yaml         # Ingress routing rules
│   ├── namespace.yaml       # Kubernetes namespace definition
│   └── kind-config.yaml     # Kind cluster configuration
├── microservices/           # Laravel 11+ applications (Git submodules)
│   ├── auth-app/            # 🔐 Authentication service (see README.md)
│   ├── location-app/        # 📍 Location service (see README.md)
│   ├── payments-app/        # 💳 Payments service (see README.md)
│   ├── booking-app/         # 📅 Booking service (see README.md)
│   └── fraud-detector-app/  # 🔍 Fraud detection service (see README.md)
├── nginx/                   # Main nginx configuration
│   └── nginx.conf           # Reverse proxy configuration
├── scripts/                 # 🛠️ Automation and utility scripts
│   ├── deploy.sh            # 🚀 Main deployment script (Docker/K8s modes)
│   ├── cleanup.sh           # 🧹 Environment cleanup and reset
│   ├── verify.sh            # ✅ Prerequisites verification
│   ├── create-all-apps.sh   # 🏗️ Create Laravel apps (development)
│   ├── setup-laravel-docker.sh # 🐳 Docker setup per app
│   ├── laravel-manager.sh   # 📦 Laravel application lifecycle management
│   ├── test-deployment-modes.sh # 🧪 Test deployment configurations
│   ├── update-manifests.sh  # 🔄 Update Kubernetes manifests
│   ├── init-databases.sh    # 💾 Database initialization (internal)
│   ├── init-laravel.sh      # ⚙️ Laravel initialization (internal)
│   └── utils.sh             # 🔧 Shared utility functions
└── web/                     # 🌐 Landing page and static assets
    ├── index.html           # Main dashboard and service navigation
    └── nginx.conf           # Web frontend nginx configuration
```

### 📝 Individual Service Documentation

Each microservice has its own comprehensive README.md with:

- ✅ **Service-specific features and endpoints**
- ✅ **Database connection strings and credentials**
- ✅ **RabbitMQ management UI access details**
- ✅ **Redis connection information**
- ✅ **Docker Compose port mappings**
- ✅ **Development commands and examples**

**Quick Access:**

- [Auth Service README](microservices/auth-app/README.md) - Authentication & identity management
- [Location Service README](microservices/location-app/README.md) - Geolocation & tracking
- [Payments Service README](microservices/payments-app/README.md) - Payment processing & billing
- [Booking Service README](microservices/booking-app/README.md) - Reservation management
- [Fraud Detector README](microservices/fraud-detector-app/README.md) - Risk assessment & fraud detection

## 🐳 Docker Compose Configuration

The `docker-compose.yml` file provides a complete development environment with:

### 🏗️ **Architecture Components:**

- **NGINX Reverse Proxy** - Routes traffic to services and handles custom domains
- **5 Laravel Microservices** - Each with dedicated infrastructure
- **5 PostgreSQL Databases** - Isolated data storage per service
- **5 Redis Instances** - Independent caching per service
- **5 RabbitMQ Instances** - Separate message queuing per service
- **1 Kafka Cluster** - Shared event streaming across all services
- **Web Dashboard** - Service navigation and monitoring

### 🌐 **Port Mappings:**

| Service        | Application | PostgreSQL | Redis | RabbitMQ AMQP | RabbitMQ UI |
| -------------- | ----------- | ---------- | ----- | ------------- | ----------- |
| Main Dashboard | 8080        | -          | -     | -             | -           |
| Auth           | 8081        | 5433       | 6380  | 5672          | 15672       |
| Location       | 8082        | 5434       | 6381  | 5673          | 15673       |
| Payments       | 8083        | 5435       | 6382  | 5674          | 15674       |
| Booking        | 8084        | 5436       | 6383  | 5675          | 15675       |
| Fraud Detector | 8085        | 5437       | 6384  | 5676          | 15676       |

### 🚀 **Quick Start with Docker Compose:**

```bash
# Start all services in development mode
docker compose up --build -d

# View logs
docker compose logs -f

# Stop all services
docker compose down

# Clean up (remove volumes)
docker compose down -v
```

**Access URLs:** All services available via localhost ports or custom domains (\*.shipanything.test)

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

## 🧹 Cleanup

## � Cleanup

```bash
# Clean up all resources
./scripts/cleanup.sh

# Docker Compose cleanup
docker compose down -v
docker system prune -f

# Kubernetes cleanup
kind delete cluster --name shipanything
```

## �🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

**Built with ❤️ for microservices architecture enthusiasts**

For questions or support, please open an issue in the repository.

┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Client │───▶│ API Gateway │───▶│ Auth Service│───▶│Target Service│
│ │ │ (NGINX) │ │ (JWT Verify)│ │(Business Logic)│
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘

┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Client │───▶│ API Gateway │───▶│ Auth Service│───▶│Target Service│
│ │ │ (NGINX) │ │ (JWT Verify)│ │(Business Logic)│
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
