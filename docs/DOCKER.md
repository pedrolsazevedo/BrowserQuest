# Docker Setup for BrowserQuest

This guide covers running BrowserQuest in Docker containers for development and
production.

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Build and start the server
docker-compose up -d

# Check server status
curl http://localhost:8000/status

# View logs
docker-compose logs -f

# Stop the server
docker-compose down
```

### Using Docker CLI

```bash
# Build the image
docker build -t browserquest:latest .

# Run the container
docker run -d -p 8000:8000 --name browserquest browserquest:latest

# Check logs
docker logs browserquest

# Stop the container
docker stop browserquest
docker rm browserquest
```

## Docker Compose Configuration

The [docker-compose.yml](docker-compose.yml) includes:

- **browserquest** - Main game server (port 8000)
- **memcached** - Optional metrics storage (port 11211)

### Environment Variables

Configure the server using environment variables:

```yaml
environment:
  - NODE_ENV=production
  - PORT=8000 # Server port (optional, defaults to config)
```

### Volumes

Mount volumes for persistence and configuration:

```yaml
volumes:
  # Custom server configuration
  - ./server/config_local.json:/app/server/config_local.json:ro

  # Logs directory
  - ./logs:/app/logs
```

## Dockerfile Details

The Dockerfile uses a **multi-stage build** for optimization:

### Stage 1: Builder

- Uses Node.js 20 Alpine
- Installs all dependencies (including devDependencies)
- Copies source code
- Optional: Builds client assets

### Stage 2: Production

- Uses Node.js 20 Alpine
- Installs `dumb-init` for proper signal handling
- Creates non-root user `browserquest:browserquest` (UID/GID 1001)
- Installs only production dependencies
- Copies built application from builder stage
- Exposes port 8000
- Includes health check

## Building the Image

### Development Build

```bash
docker build -t browserquest:dev .
```

### Production Build with Tags

```bash
docker build -t browserquest:latest -t browserquest:1.0.0 .
```

### Build with Custom Arguments

```bash
docker build \
  --build-arg NODE_VERSION=20 \
  -t browserquest:latest \
  .
```

## Running Containers

### Basic Run

```bash
docker run -d -p 8000:8000 browserquest:latest
```

### With Custom Configuration

```bash
docker run -d \
  -p 8000:8000 \
  -v $(pwd)/server/config_local.json:/app/server/config_local.json:ro \
  -v $(pwd)/logs:/app/logs \
  --name browserquest \
  browserquest:latest
```

### With Memcached

```bash
# Start memcached
docker run -d --name memcached memcached:1.6-alpine

# Start BrowserQuest linked to memcached
docker run -d \
  -p 8000:8000 \
  --link memcached:memcached \
  --name browserquest \
  browserquest:latest
```

### With Custom Network

```bash
# Create network
docker network create browserquest-net

# Run containers
docker run -d --network browserquest-net --name memcached memcached:1.6-alpine
docker run -d --network browserquest-net -p 8000:8000 --name browserquest browserquest:latest
```

## Health Checks

The container includes a health check that:

- Runs every 30 seconds
- Checks the `/status` endpoint
- Allows 40 seconds for startup
- Retries 3 times before marking unhealthy

Check container health:

```bash
docker ps # Shows health status
docker inspect browserquest --format='{{.State.Health.Status}}'
```

## Docker Compose Commands

### Start Services

```bash
# Start in foreground
docker-compose up

# Start in background (detached)
docker-compose up -d

# Rebuild and start
docker-compose up -d --build
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f browserquest

# Last 100 lines
docker-compose logs --tail=100 browserquest
```

### Stop Services

```bash
# Stop containers (keeps data)
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes
docker-compose down -v
```

### Scale Services

```bash
# Run multiple game server instances
docker-compose up -d --scale browserquest=3
```

Note: You'll need to configure load balancing for multiple instances.

## Production Deployment

### Using Docker Compose

1. Create production docker-compose override:

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  browserquest:
    restart: always
    environment:
      - NODE_ENV=production
    logging:
      driver: json-file
      options:
        max-size: '10m'
        max-file: '3'
```

2. Deploy:

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Environment-Specific Configuration

Create environment-specific config files:

```bash
# Development
server/config_local.json

# Production
server/config_production.json
```

Mount the appropriate config:

```bash
docker run -v ./server/config_production.json:/app/server/config_local.json:ro ...
```

## Security Considerations

### Non-Root User

The container runs as non-root user `browserquest` (UID 1001):

```dockerfile
USER browserquest
```

### Read-Only Filesystem

For extra security, mount root filesystem as read-only:

```bash
docker run --read-only -v /app/logs:rw ...
```

### Resource Limits

Set memory and CPU limits:

```bash
docker run --memory=512m --cpus=1.0 browserquest:latest
```

In docker-compose:

```yaml
services:
  browserquest:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs browserquest

# Inspect container
docker inspect browserquest

# Run interactively for debugging
docker run -it --rm browserquest:latest sh
```

### Server Not Responding

```bash
# Check if server is listening
docker exec browserquest netstat -tuln | grep 8000

# Test from inside container
docker exec browserquest curl -s http://localhost:8000/status
```

### Permission Issues

```bash
# Check file ownership
docker exec browserquest ls -la /app

# Fix log directory permissions on host
sudo chown -R 1001:1001 ./logs
```

### Container Health Check Failing

```bash
# View health check logs
docker inspect browserquest --format='{{json .State.Health}}' | jq

# Manually run health check
docker exec browserquest node -e "require('http').get('http://localhost:8000/status', (r) => console.log(r.statusCode))"
```

## Image Size Optimization

Current optimizations:

- ✅ Multi-stage build (reduces image size)
- ✅ Alpine Linux base (minimal footprint)
- ✅ Production-only dependencies
- ✅ .dockerignore excludes unnecessary files

Check image size:

```bash
docker images browserquest:latest
```

## Advanced Usage

### Custom Build Target

Build only the builder stage:

```bash
docker build --target builder -t browserquest:builder .
```

### Docker Build Cache

Use BuildKit for better caching:

```bash
DOCKER_BUILDKIT=1 docker build -t browserquest:latest .
```

### Export/Import Images

```bash
# Save image to tar
docker save browserquest:latest | gzip > browserquest.tar.gz

# Load image from tar
gunzip -c browserquest.tar.gz | docker load
```

### Push to Registry

```bash
# Tag for registry
docker tag browserquest:latest registry.example.com/browserquest:latest

# Push to registry
docker push registry.example.com/browserquest:latest
```

## GitHub Container Registry

Images are automatically built and pushed to GitHub Container Registry on push
to main/master:

```bash
# Pull from GHCR
docker pull ghcr.io/OWNER/browserquest:latest

# Run from GHCR
docker run -d -p 8000:8000 ghcr.io/OWNER/browserquest:latest
```

See [.github/workflows/docker.yml](.github/workflows/docker.yml) for CI/CD
configuration.

## Files Reference

- [Dockerfile](Dockerfile) - Multi-stage production Dockerfile
- [docker-compose.yml](docker-compose.yml) - Compose configuration with
  memcached
- [.dockerignore](.dockerignore) - Files excluded from Docker build context
- [.github/workflows/docker.yml](.github/workflows/docker.yml) - Automated
  Docker builds

## Next Steps

- Configure reverse proxy (nginx, Traefik)
- Set up SSL/TLS certificates
- Configure automated backups
- Set up monitoring and logging
- Deploy to cloud platform (AWS, GCP, Azure)
