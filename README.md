# ShipAnything - Microservices Project

A comprehensive microservices architecture for shipping and logistics management built with Laravel microservices, Kubernetes, Kong API Gateway, and service mesh technologies.

## Project Architecture

This project implements a modern microservices architecture with the following key components:

- **5 Laravel Microservices** running in separate containers
- **Kong API Gateway** for routing and JWT processing
- **Kong Service Mesh** for mTLS and traffic policies
- **Kubernetes** orchestration with Kind for local development
- **Infrastructure Services**: PostgreSQL, Redis, RabbitMQ, Kafka
- **Automated deployment** with comprehensive tooling

## Repository Structure

This project uses **git submodules** for Laravel microservices management. Each microservice is maintained in its own repository:

- [Auth App](https://github.com/lalithhakari/shipanything-auth-app) - Authentication service
- [Booking App](https://github.com/lalithhakari/shipanything-booking-app) - Booking management service
- [Detector App](https://github.com/lalithhakari/shipanything-detector-app) - Detection/tracking service
- [Location App](https://github.com/lalithhakari/shipanything-location-app) - Location management service
- [Payments App](https://github.com/lalithhakari/shipanything-payments-app) - Payment processing service

## Project Structure

```
.
├── microservices/          # Individual microservice applications (git submodules)
│   ├── auth-app/           # Authentication service (Laravel)
│   ├── booking-app/        # Booking management service (Laravel)
│   ├── detector-app/       # Detection/tracking service (Laravel)
│   ├── location-app/       # Location management service (Laravel)
│   └── payments-app/       # Payment processing service (Laravel)
├── k8s/                    # Kubernetes infrastructure configurations
│   ├── postgres.yaml       # PostgreSQL databases (one per service)
│   ├── redis.yaml          # Shared Redis cache cluster
│   ├── rabbitmq.yaml       # RabbitMQ message broker cluster
│   ├── kafka.yaml          # Kafka event streaming platform
│   └── production/         # Production environment configs
├── kong/                   # API Gateway & Service Mesh configurations
│   ├── kong-api-gateway.yaml  # Kong Gateway with JWT processing & ingress
│   └── kong-mesh.yaml         # Service mesh mTLS & traffic policies
├── scripts/                # Deployment and utility scripts
│   ├── deploy.sh           # Main automated deployment script
│   ├── cleanup.sh          # Clean up all resources
│   ├── fix-permissions.sh  # Fix Laravel storage permissions
│   ├── start-access.sh     # Start Kong port forwarding
│   └── helper-scripts/     # Helper automation scripts
│       ├── install-prereqs.sh # Install required CLI tools
│       ├── view-logs.sh        # View application logs
│       ├── exec-app.sh         # Execute commands in pods
│       └── check-ingress.sh    # Check ingress status
├── kind-config.yaml        # Kind cluster configuration (multi-node)
├── kong-proxy-fix.yaml     # Kong proxy configuration fixes
├── setup-kong-access.sh    # Kong access setup script
└── README.md              # This file
```

## Services Overview

- **Auth App**: Handles user authentication and authorization with JWT tokens (Laravel)
- **Booking App**: Manages shipping bookings and orders (Laravel)
- **Detector App**: Handles package detection and tracking (Laravel)
- **Location App**: Manages locations and routing (Laravel)
- **Payments App**: Processes payments and billing (Laravel)

Each microservice runs as a separate Laravel application with its own:

- Dedicated PostgreSQL database
- Docker container
- Kubernetes deployment
- Service mesh integration

## Required CLI Tools

Before deploying the project, ensure you have the following tools installed:

- **Docker** (v20.10+): Container runtime
- **kubectl** (v1.25+): Kubernetes command-line tool
- **kind** (v0.17+): Kubernetes in Docker for local development
- **helm** (v3.10+): Kubernetes package manager

### Quick Installation

Run the automated installation script to install missing tools:

```bash
./scripts/helper-scripts/install-prereqs.sh
```

Or install manually:

**macOS (with Homebrew):**

```bash
brew install docker kubectl kind helm
```

**Linux:**

```bash
# Docker
curl -fsSL https://get.docker.com | sh

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x kind && sudo mv kind /usr/local/bin/

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Git Submodules Setup

### Initial Clone with Submodules

When cloning this repository for the first time:

```bash
# Clone the main repository with all submodules
git clone --recursive https://github.com/lalithhakari/shipanything.git

# Or if you already cloned without --recursive:
git clone https://github.com/lalithhakari/shipanything.git
cd shipanything
git submodule init
git submodule update
```

### Working with Submodules

**Update all submodules to latest commits:**

```bash
# Update all submodules to their latest commits on main branch
git submodule update --remote

# Update specific submodule
git submodule update --remote microservices/auth-app
```

**Making changes in a submodule:**

```bash
# Navigate to the submodule
cd microservices/auth-app

# Make your changes
git add .
git commit -m "Your commit message"
git push origin main

# Return to main repository and update submodule reference
cd ../..
git add microservices/auth-app
git commit -m "Update auth-app submodule"
git push origin main
```

**Check submodule status:**

```bash
# Show current submodule commit hashes
git submodule status

# Show if submodules have uncommitted changes
git submodule foreach git status
```

**Pull latest changes from all repositories:**

```bash
# Update main repository
git pull origin main

# Update all submodules
git submodule update --remote

# Alternative: pull all in one command
git pull --recurse-submodules
```

**Reset submodules to committed state:**

```bash
# Reset all submodules to their committed state
git submodule update --init --recursive

# Reset specific submodule
git submodule update microservices/auth-app
```

### Team Development Workflow

**For team members joining the project:**

1. Clone with submodules: `git clone --recursive https://github.com/lalithhakari/shipanything.git`
2. Always pull with submodules: `git pull --recurse-submodules`
3. When switching branches: `git checkout <branch> && git submodule update`

**When working on features:**

1. Create feature branch in main repo: `git checkout -b feature/new-feature`
2. Work in relevant submodules and push changes to their repositories
3. Update main repo to reference new submodule commits
4. Push main repo feature branch
5. Create pull request for main repository

**Important Notes:**

- Always commit and push submodule changes before updating main repository
- Use `git submodule foreach git pull origin main` to pull latest in all submodules
- Submodules point to specific commits, not branches
- When deploying, ensure all team members have the same submodule commit references

## Local Development Setup

### 1. Deploy to Kind Cluster

Run the deployment script and select local mode:

```bash
./scripts/deploy.sh
```

Select option `1` for local deployment. The script will:

- ✅ Check prerequisites (Docker, kubectl, kind, helm)
- 🔧 Create Kind cluster with multi-node setup (control-plane + 2 workers)
- � Create `shipanything` namespace
- 🧹 Clean up conflicting resources from previous deployments
- 🗄️ Deploy PostgreSQL databases (dedicated per microservice)
- 🔴 Deploy Redis cache cluster
- 🐰 Deploy RabbitMQ message broker with operator
- 📊 Deploy Kafka event streaming platform
- 🦍 Deploy Kong API Gateway with JWT processing & ingress controller
- 🕸️ Configure Kong service mesh with mTLS and traffic policies
- 🏗️ Build and load Docker images for all Laravel microservices
- 🚀 Deploy microservice applications with auto-scaling
- 🔧 Fix Laravel storage permissions automatically
- 🌐 Start Kong port forwarding for local access

### 2. Configure Local DNS

Add the following entries to your `/etc/hosts` file:

```bash
sudo tee -a /etc/hosts << EOF
127.0.0.1 auth.shipanything.test
127.0.0.1 booking.shipanything.test
127.0.0.1 detector.shipanything.test
127.0.0.1 location.shipanything.test
127.0.0.1 payments.shipanything.test
EOF
```

### 3. Access Services

After deployment, your services will be available at:

- **Auth Service**: http://auth.shipanything.test:8080
- **Booking Service**: http://booking.shipanything.test:8080
- **Detector Service**: http://detector.shipanything.test:8080
- **Location Service**: http://location.shipanything.test:8080
- **Payments Service**: http://payments.shipanything.test:8080

**Note**: The deployment script automatically starts Kong port forwarding on port 8080.

### 4. Development Commands

**View logs:**

```bash
./scripts/helper-scripts/view-logs.sh auth-app
./scripts/helper-scripts/view-logs.sh auth-app -f  # Follow logs
```

**Execute commands in containers:**

```bash
./scripts/helper-scripts/exec-app.sh auth-app
./scripts/helper-scripts/exec-app.sh auth-app php artisan --version
```

**Check ingress status:**

```bash
./scripts/helper-scripts/check-ingress.sh
```

**Monitor resources:**

```bash
kubectl get pods -n shipanything
kubectl get services -n shipanything
kubectl get ingress -n shipanything
```

### 5. Manual Development Workflow

When developing and testing individual microservices, you may need to rebuild and redeploy specific services without running the full deployment script.

**Rebuild and reload a single microservice:**

```bash
# 1. Navigate to the specific microservice submodule
cd microservices/auth-app

# 2. Make your changes and commit them
git add .
git commit -m "Your changes"
git push origin main

# 3. Return to main repository root
cd ../..

# 4. Build the Docker image locally
docker build -t "auth-app:latest" ./microservices/auth-app/

# 5. Load the image into the Kind cluster
kind load docker-image "auth-app:latest" --name="shipanything"

# 6. Restart the deployment to use the new image
kubectl rollout restart deployment/auth-app -n shipanything

# 7. Wait for the rollout to complete
kubectl rollout status deployment/auth-app -n shipanything

# 8. Update main repository to reference the new submodule commit
git add microservices/auth-app
git commit -m "Update auth-app submodule with latest changes"
git push origin main
```

**When to use these commands:**

- **After code changes**: When you've modified code in a specific microservice and want to test the changes
- **During development**: For rapid iteration without full cluster rebuild
- **Debugging**: When you need to deploy a specific version with debug flags or logging
- **Hot fixes**: For quick fixes that don't require infrastructure changes

**For multiple services:**

```bash
# Update all submodules first
cd microservices
for service in auth-app booking-app detector-app location-app payments-app; do
    echo "Updating $service submodule..."
    cd $service
    git pull origin main
    cd ..
done
cd ..

# Update main repository to reference new commits
git add microservices/
git commit -m "Update all microservice submodules"

# Rebuild all services (example sequence)
for service in auth-app booking-app detector-app location-app payments-app; do
    echo "Rebuilding $service..."
    docker build -t "$service:latest" "./microservices/$service/"
    kind load docker-image "$service:latest" --name="shipanything"
    kubectl rollout restart "deployment/$service" -n shipanything
done

# Wait for all deployments
kubectl wait --for=condition=Available deployment --all -n shipanything --timeout=300s
```

**Fix Laravel permissions after deployment:**

```bash
./scripts/fix-permissions.sh
```

## Git Submodules Troubleshooting

### Common Issues and Solutions

**Issue: Submodule directories are empty after clone**

```bash
# Solution: Initialize and update submodules
git submodule init
git submodule update
```

**Issue: Submodule shows "dirty" status with uncommitted changes**

```bash
# Check what's changed
cd microservices/auth-app
git status

# If you want to discard changes:
git checkout .

# If you want to commit changes:
git add .
git commit -m "Your changes"
git push origin main
cd ../..
git add microservices/auth-app
git commit -m "Update auth-app submodule"
```

**Issue: Submodule is ahead/behind remote**

```bash
# Pull latest changes in submodule
cd microservices/auth-app
git pull origin main
cd ../..

# Update main repo to point to new commit
git add microservices/auth-app
git commit -m "Update auth-app submodule to latest"
```

**Issue: Cannot switch branches because of submodule conflicts**

```bash
# Update submodules when switching branches
git checkout <branch-name>
git submodule update --init --recursive
```

**Issue: Submodule URL has changed**

```bash
# Update submodule URL
git submodule set-url microservices/auth-app https://github.com/lalithhakari/new-auth-app.git

# Sync and update
git submodule sync
git submodule update --init --recursive
```

**Issue: Remove a submodule completely**

```bash
# Remove submodule from .gitmodules
git submodule deinit microservices/old-app

# Remove submodule directory
git rm microservices/old-app

# Remove submodule cache
rm -rf .git/modules/microservices/old-app

# Commit changes
git commit -m "Remove old-app submodule"
```

### Useful Git Aliases for Submodules

Add these to your `~/.gitconfig` for easier submodule management:

```bash
git config --global alias.sub-status 'submodule foreach git status'
git config --global alias.sub-pull 'submodule foreach git pull origin main'
git config --global alias.sub-update 'submodule update --remote'
git config --global alias.clone-recursive 'clone --recursive'
```

## Production Deployment

### 1. Deploy to Production

Run the deployment script and select production mode:

```bash
./scripts/deploy.sh
```

Select option `2` for production deployment. The script will:

- 🏗️ Build Docker images for all microservices
- 📤 Push images to registry (`registry.example.com`)
- 🚀 Deploy production manifests from `k8s/production/`

### 2. Prerequisites for Production

- Configure your Docker registry credentials:

  ```bash
  docker login registry.example.com
  ```

- Create production manifests in `k8s/production/` directory
- Ensure your Kubernetes cluster is configured and accessible

### 3. Production Configuration

Update the registry URL in `scripts/deploy.sh` if using a different registry:

```bash
REGISTRY="your-registry.com"
```

## Architecture Overview

### Microservices Layer

- **5 Laravel Applications**: Each service runs independently with its own codebase, database, and business logic
- **Container Isolation**: Each service runs in its own Docker container with optimized Laravel runtime
- **Auto-scaling**: Kubernetes HPA (Horizontal Pod Autoscaler) manages service replicas based on load
- **Health Checks**: Kubernetes readiness and liveness probes ensure service reliability

### API Gateway & Service Mesh

- **Kong Gateway**:
  - Routes requests to microservices based on subdomains (`auth.shipanything.test`, etc.)
  - JWT token processing and validation
  - Request/response transformation
  - Rate limiting and security policies
- **Kong Service Mesh**:
  - Provides mTLS (mutual TLS) for secure service-to-service communication
  - Traffic policies and circuit breakers
  - Service discovery and load balancing
  - Observability and tracing
- **Ingress Controller**: Kong ingress controller manages Kubernetes ingress resources
- **Load Balancing**: Distributes traffic across service replicas with health-aware routing

### Data Layer

- **PostgreSQL**: Dedicated database per microservice following database-per-service pattern
- **Redis**: Shared cache cluster for sessions, temporary data, and inter-service caching
- **RabbitMQ**: Message queue cluster for asynchronous communication and event-driven patterns
- **Kafka**: Event streaming platform for real-time data processing and event sourcing

### Infrastructure & Orchestration

- **Kubernetes**: Container orchestration with automated deployment, scaling, and management
- **Kind Cluster**: Multi-node local Kubernetes cluster (1 control-plane + 2 worker nodes)
- **Helm**: Package manager for Kubernetes applications and dependencies
- **Docker**: Containerization with optimized Laravel images

### Local Development Features

- **Kind Cluster**: Lightweight Kubernetes cluster running in Docker containers
- **Port Forwarding**: Direct access via localhost with automatic Kong proxy setup
- **Host-based Routing**: Subdomain routing through `/etc/hosts` configuration
- **Hot Reloading**: Support for rapid development cycles with manual image rebuild
- **Automated Setup**: One-command deployment with prerequisite checking

## Cleanup

To clean up all resources:

```bash
./scripts/cleanup.sh
```

This will:

- Delete the Kind cluster
- Remove Docker images
- Clean up unused resources
- Reset the environment

## Troubleshooting

### Common Issues

**Services not accessible:**

1. Check `/etc/hosts` entries are correct
2. Verify Kind cluster is running: `kind get clusters`
3. Check Kong port forwarding: `ps aux | grep "kubectl port-forward"`
4. Restart port forwarding: `./scripts/start-access.sh`
5. Check ingress status: `./scripts/helper-scripts/check-ingress.sh`

**Build failures:**

1. Ensure Docker is running: `docker info`
2. Check Dockerfile syntax in microservice directories
3. Verify base images are accessible
4. Clear Docker cache: `docker system prune -f`

**Deployment issues:**

1. Check pod status: `kubectl get pods -n shipanything`
2. View pod logs: `./scripts/helper-scripts/view-logs.sh <service-name>`
3. Describe failed resources: `kubectl describe pod <pod-name> -n shipanything`
4. Check resource limits: `kubectl top pods -n shipanything`

**Laravel-specific issues:**

1. Fix storage permissions: `./scripts/fix-permissions.sh`
2. Check Laravel logs: `./scripts/helper-scripts/exec-app.sh auth-app tail -f storage/logs/laravel.log`
3. Run artisan commands: `./scripts/helper-scripts/exec-app.sh auth-app php artisan config:cache`
4. Check database connectivity: `./scripts/helper-scripts/exec-app.sh auth-app php artisan migrate:status`

### Getting Help

- Check service status: `kubectl get all -n shipanything`
- View detailed events: `kubectl get events -n shipanything --sort-by='.lastTimestamp'`
- Access Kong admin: `kubectl port-forward -n kong service/kong-admin 8001:8001`
- Monitor cluster resources: `kubectl top nodes && kubectl top pods -n shipanything`
- Check Kind cluster info: `kubectl cluster-info --context kind-shipanything`

### Performance Monitoring

- **CPU/Memory usage**: `kubectl top pods -n shipanything`
- **Service mesh metrics**: Access Kong admin at `localhost:8001` during port forwarding
- **Application logs**: Use `./scripts/helper-scripts/view-logs.sh <service>` for real-time monitoring
- **Database connections**: Check PostgreSQL logs in respective pods

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Make your changes and test locally
4. Commit your changes: `git commit -am 'Add new feature'`
5. Push to the branch: `git push origin feature/new-feature`
6. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
