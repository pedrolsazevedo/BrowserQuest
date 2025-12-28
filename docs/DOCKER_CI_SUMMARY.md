# Docker & CI/CD Setup Summary

## Overview

BrowserQuest now includes complete Docker containerization and GitHub Actions
CI/CD pipelines for automated testing and deployment.

## What Was Added

### Docker Files

1. **[Dockerfile](Dockerfile)** - Multi-stage production Dockerfile
   - Stage 1: Builder (installs all dependencies)
   - Stage 2: Production (minimal runtime image)
   - Uses Node.js 20 Alpine Linux
   - Runs as non-root user (browserquest:1001)
   - Includes health check on `/status` endpoint
   - Size-optimized with multi-stage build

2. **[docker-compose.yml](docker-compose.yml)** - Orchestration configuration
   - BrowserQuest server service (port 8000)
   - Optional memcached service for metrics
   - Network isolation
   - Volume mounts for logs and config
   - Auto-restart and health checks

3. **[.dockerignore](.dockerignore)** - Build context exclusions
   - Excludes node_modules, tests, docs
   - Reduces build context size
   - Faster builds

### GitHub Actions Workflows

1. **[.github/workflows/pre-commit.yml](.github/workflows/pre-commit.yml)**
   - Runs on: PRs (opened, sync, reopened) and pushes to main/master/develop
   - Checks: Code quality, linting, formatting, security
   - Uses caching for faster runs
   - Comments on PR when checks fail
   - Runtime: ~1-3 minutes

2. **[.github/workflows/test.yml](.github/workflows/test.yml)**
   - Runs on: PRs and pushes to main/master/develop
   - Matrix: Node.js 20.x and 22.x
   - Tests: Jest, npm audit, formatting
   - Server startup verification
   - Runtime: ~2-4 minutes

3. **[.github/workflows/docker.yml](.github/workflows/docker.yml)**
   - Runs on: PRs (when Docker files change), pushes to main/master, version tags
   - Builds Docker image with caching
   - Tests the built image
   - Pushes to GitHub Container Registry (GHCR)
   - Generates build attestation
   - Runtime: ~3-5 minutes

### Documentation

1. **[DOCKER.md](DOCKER.md)** - Complete Docker guide (300+ lines)
   - Quick start
   - Docker Compose usage
   - Production deployment
   - Security best practices
   - Troubleshooting
   - Advanced usage

2. **[CI_CD.md](CI_CD.md)** - GitHub Actions documentation (400+ lines)
   - Workflow descriptions
   - Pull request process
   - Release workflow
   - Troubleshooting
   - Best practices
   - Cost optimization

## Quick Start

### Using Docker Compose

```bash
# Start server
docker-compose up -d

# Check status
curl http://localhost:8000/status

# View logs
docker-compose logs -f browserquest

# Stop server
docker-compose down
```

### Using Docker CLI

```bash
# Build
docker build -t browserquest .

# Run
docker run -d -p 8000:8000 --name browserquest browserquest

# Logs
docker logs -f browserquest

# Stop
docker stop browserquest && docker rm browserquest
```

### Pull from GitHub Container Registry

```bash
# Once pushed to GHCR
docker pull ghcr.io/OWNER/browserquest:latest
docker run -d -p 8000:8000 ghcr.io/OWNER/browserquest:latest
```

## CI/CD Pipeline Flow

### On Pull Request

1. **Pre-commit checks** run first
   - Linting (ESLint)
   - Formatting (Prettier)
   - Security (detect-secrets)
   - Conventional commits

2. **Tests** run in parallel
   - Jest test suite on Node 20.x and 22.x
   - npm security audit
   - Formatting verification
   - Server startup test

3. **Docker build** (if relevant files changed)
   - Builds container image
   - Tests the image works
   - Verifies health check

All checks must pass before merge (with branch protection).

### On Merge to Main

1. All checks run again
2. Docker image is built
3. Image pushed to GHCR with tags:
   - `latest`
   - `main-<sha>`
   - Branch name
4. Build attestation generated

### On Release Tag

When you push a tag (e.g., `v1.0.0`):

1. Docker image built
2. Tagged with semver:
   - `v1.0.0`
   - `1.0`
   - `1`
   - `latest`
3. Pushed to GHCR
4. Ready for production deployment

## Docker Image Details

### Image Characteristics

- **Base**: node:20-alpine
- **Size**: ~150MB (optimized multi-stage build)
- **User**: Non-root (browserquest:1001)
- **Port**: 8000
- **Health**: HTTP check on /status
- **Init**: dumb-init for signal handling

### Security Features

- ✅ Non-root user
- ✅ Alpine Linux (minimal attack surface)
- ✅ Multi-stage build (no build tools in final image)
- ✅ Health checks
- ✅ Proper signal handling
- ✅ No secrets in image

### Environment Variables

```bash
NODE_ENV=production  # Set production mode
PORT=8000           # Server port (optional)
```

### Volumes

```bash
# Configuration
/app/server/config_local.json  # Custom server config

# Logs
/app/logs  # Application logs
```

## GitHub Actions Features

### Caching Strategy

1. **Pre-commit cache**: Speeds up hook installation
2. **npm cache**: Faster dependency installation
3. **Docker layer cache**: Significantly faster builds

### Matrix Testing

Tests run on multiple Node.js versions:
- Node.js 20.x (LTS)
- Node.js 22.x (Current)

Ensures compatibility across versions.

### Conditional Execution

- Pre-commit runs on changed files (PRs) or all files (pushes)
- Docker workflow skips non-Docker changes
- Push to registry only on main/master

### Security

- Uses `GITHUB_TOKEN` (automatic)
- No secrets required
- Read-only permissions by default
- Packages write permission for GHCR

## Production Deployment

### Cloud Platforms

**AWS ECS/Fargate:**
```bash
aws ecs create-service \
  --cluster browserquest \
  --service-name browserquest \
  --task-definition browserquest:1 \
  --desired-count 2
```

**Google Cloud Run:**
```bash
gcloud run deploy browserquest \
  --image ghcr.io/OWNER/browserquest:latest \
  --platform managed \
  --port 8000
```

**Azure Container Instances:**
```bash
az container create \
  --resource-group browserquest-rg \
  --name browserquest \
  --image ghcr.io/OWNER/browserquest:latest \
  --ports 8000
```

**Railway/fly.io:**
- Use Docker deployment
- Point to Dockerfile
- Auto-deploys on push to main

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: browserquest
spec:
  replicas: 3
  selector:
    matchLabels:
      app: browserquest
  template:
    metadata:
      labels:
        app: browserquest
    spec:
      containers:
      - name: browserquest
        image: ghcr.io/OWNER/browserquest:latest
        ports:
        - containerPort: 8000
        livenessProbe:
          httpGet:
            path: /status
            port: 8000
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
```

## Monitoring & Logging

### Health Checks

```bash
# Manual health check
curl http://localhost:8000/status

# Docker health status
docker inspect browserquest --format='{{.State.Health.Status}}'

# Compose health
docker-compose ps
```

### Logs

```bash
# Docker logs
docker logs -f browserquest

# Compose logs
docker-compose logs -f browserquest

# Since timestamp
docker logs --since 30m browserquest
```

### Metrics

Enable memcached for metrics:
```bash
docker-compose up -d memcached browserquest
```

## Troubleshooting

### Docker Build Fails

```bash
# Build with no cache
docker build --no-cache -t browserquest .

# Check build context size
du -sh .dockerignore
```

### Container Won't Start

```bash
# Check logs
docker logs browserquest

# Run interactively
docker run -it --rm browserquest sh

# Check port binding
netstat -tuln | grep 8000
```

### CI/CD Failures

```bash
# Run pre-commit locally
pre-commit run --all-files

# Run tests
npm test

# Build Docker locally
docker build -t test .
```

## File Reference

### Docker Files
- [Dockerfile](Dockerfile) - Container build definition
- [docker-compose.yml](docker-compose.yml) - Multi-container setup
- [.dockerignore](.dockerignore) - Build exclusions

### CI/CD Files
- [.github/workflows/pre-commit.yml](.github/workflows/pre-commit.yml)
- [.github/workflows/test.yml](.github/workflows/test.yml)
- [.github/workflows/docker.yml](.github/workflows/docker.yml)

### Documentation
- [DOCKER.md](DOCKER.md) - Complete Docker guide
- [CI_CD.md](CI_CD.md) - GitHub Actions guide
- [MODERNIZATION.md](MODERNIZATION.md) - Overall modernization plan

## Benefits

### Docker
✅ Consistent environment (dev, staging, prod)
✅ Easy deployment
✅ Resource isolation
✅ Horizontal scaling
✅ Platform independent

### CI/CD
✅ Automated testing on every PR
✅ Consistent code quality
✅ Fast feedback loop
✅ Automated deployments
✅ Reduced human error
✅ Better collaboration

## Next Steps

1. **Set up branch protection** - Require CI checks to pass
2. **Configure deployment** - Choose cloud platform
3. **Add monitoring** - Prometheus, Grafana, or cloud native
4. **Set up alerts** - Get notified of failures
5. **Add staging environment** - Test before production

For detailed documentation, see:
- [DOCKER.md](DOCKER.md)
- [CI_CD.md](CI_CD.md)
