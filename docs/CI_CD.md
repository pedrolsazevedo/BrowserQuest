# CI/CD Documentation

This document describes the Continuous Integration and Continuous Deployment
setup for BrowserQuest using GitHub Actions.

## Overview

The CI/CD pipeline includes:

- **Pre-commit Checks** - Code quality and linting
- **Tests** - Unit tests and server startup verification
- **Docker Build** - Container image building and testing

## Workflows

### 1. Pre-commit Checks (.github/workflows/pre-commit.yml)

Runs on:

- Pull requests (opened, synchronized, reopened)
- Pushes to main/master/develop branches

**What it does:**

- Sets up Python 3.11 and Node.js 20
- Installs npm dependencies
- Installs pre-commit
- Caches pre-commit hooks for faster runs
- Runs pre-commit on changed files (PRs) or all files (pushes)
- Comments on PR if checks fail

**Run locally:**

```bash
pre-commit run --all-files
```

### 2. Tests (.github/workflows/test.yml)

Runs on:

- Pull requests (opened, synchronized, reopened)
- Pushes to main/master/develop branches

**Test Matrix:**

- Node.js versions: 20.x, 22.x
- OS: Ubuntu latest

**What it does:**

**Test Job:**

- Runs Jest tests
- Security audit (npm audit)
- Code formatting check

**Server Startup Job:**

- Starts server in background
- Waits for server to be ready (30s timeout)
- Tests `/status` endpoint
- Shows logs on failure

**Run locally:**

```bash
npm test
npm audit
npm run format:check
```

### 3. Docker Build (.github/workflows/docker.yml)

Runs on:

- Pull requests touching Docker files or source code
- Pushes to main/master
- Tags matching `v*` (releases)

**What it does:**

- Sets up Docker Buildx
- Builds Docker image
- Tests the built image:
  - Starts container
  - Waits for server (60s timeout)
  - Tests status endpoint
- On main/master: Pushes to GitHub Container Registry (GHCR)
- Generates build attestation for security

**Registry:**

- Images pushed to: `ghcr.io/OWNER/REPO`
- Requires `GITHUB_TOKEN` (automatic)

**Run locally:**

```bash
docker build -t browserquest:test .
docker run -d --name test -p 8000:8000 browserquest:test
curl http://localhost:8000/status
docker stop test && docker rm test
```

## GitHub Actions Setup

### Required Secrets

No secrets required! The workflows use:

- `GITHUB_TOKEN` - Automatically provided by GitHub

### Permissions

The workflows require these permissions (set in workflow files):

**Docker workflow:**

- `contents: read` - Read repository
- `packages: write` - Push to GHCR

### Branch Protection

Recommended branch protection rules for main/master:

1. Require pull request reviews
2. Require status checks to pass:
   - Pre-commit Checks / Run Pre-commit Hooks
   - Tests / Run Tests
   - Tests / Test Server Startup
   - Docker Build / Build Docker Image (optional)
3. Require branches to be up to date
4. Do not allow bypassing

**Setup:** Repository Settings → Branches → Add rule

## Pull Request Workflow

When you open a PR, GitHub Actions will:

1. **Pre-commit checks** (1-3 min)
   - Lint and format code
   - Check for security issues
   - Validate commit messages

2. **Tests** (2-4 min)
   - Run on Node 20.x and 22.x
   - Execute test suite
   - Verify server starts
   - Check security vulnerabilities

3. **Docker build** (3-5 min, if applicable)
   - Build container image
   - Test the image works
   - Verify health checks

If any check fails:

- PR cannot be merged (if branch protection is enabled)
- Review the logs in the "Checks" tab
- Fix issues locally
- Push changes (CI re-runs automatically)

## Merge to Main Workflow

When a PR is merged to main:

1. All checks run again
2. Docker image is built and pushed to GHCR
3. Image is tagged with:
   - `latest`
   - `main-<sha>`
   - Branch name
4. Build provenance attestation is generated

## Release Workflow

To create a release:

1. Create and push a tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

2. GitHub Actions will:
   - Build Docker image
   - Tag with version (v1.0.0, 1.0, 1)
   - Push to GHCR
   - Generate attestation

3. Pull the release:

```bash
docker pull ghcr.io/OWNER/REPO:v1.0.0
```

## Caching Strategy

### Pre-commit Cache

- Caches: `~/.cache/pre-commit`
- Key: OS + pre-commit config hash
- Speeds up hook installation

### npm Cache

- Caches: `~/.npm`
- Managed by `actions/setup-node`
- Speeds up dependency installation

### Docker Build Cache

- Uses GitHub Actions cache (type=gha)
- Caches Docker layers
- Significantly speeds up builds

## Workflow Files Reference

### Pre-commit Workflow

```yaml
# Triggers
on:
  pull_request: [opened, synchronize, reopened]
  push:
    branches: [main, master, develop]

# Key steps
- Setup Python 3.11
- Setup Node.js 20
- Install dependencies
- Run pre-commit
```

### Test Workflow

```yaml
# Matrix strategy
strategy:
  matrix:
    node-version: [20.x, 22.x]

# Jobs
- test: Run Jest, audit, format check
- server-startup: Verify server starts
```

### Docker Workflow

```yaml
# Conditional push
if: github.event_name != 'pull_request'

# Outputs
- Images pushed to GHCR
- Tags: latest, branch, sha, semver
```

## Troubleshooting CI/CD

### Pre-commit Failing

**Check locally:**

```bash
pre-commit run --all-files --show-diff-on-failure
```

**Common issues:**

- Trailing whitespace
- Missing newline at end of file
- ESLint errors
- Conventional commit format

**Fix:**

```bash
npm run format  # Auto-fix formatting
npm run lint    # Auto-fix linting
```

### Tests Failing

**Check locally:**

```bash
npm test
npm audit
```

**Common issues:**

- Breaking changes in dependencies
- Server startup timeout
- Network issues

**Debug:**

```bash
# Run tests with verbose output
npm test -- --verbose

# Check security issues
npm audit --audit-level=moderate
```

### Docker Build Failing

**Check locally:**

```bash
docker build -t test .
```

**Common issues:**

- Missing dependencies
- File not found (check .dockerignore)
- Permission errors

**Debug:**

```bash
# Build with no cache
docker build --no-cache -t test .

# Run build with BuildKit for better errors
DOCKER_BUILDKIT=1 docker build -t test .
```

### Workflow Not Running

**Check:**

1. Workflow file syntax (YAML validation)
2. Branch name matches triggers
3. File paths match (for docker.yml)
4. Repository permissions

**Validate workflow:**

```bash
# Install actionlint
brew install actionlint  # macOS
# or download from https://github.com/rhysd/actionlint

# Validate workflows
actionlint .github/workflows/*.yml
```

## Best Practices

### Commit Messages

Use conventional commits to pass pre-commit checks:

```bash
feat(server): add new feature
fix(client): resolve bug
docs: update README
test: add unit tests
chore: update dependencies
```

### Before Opening PR

Run checks locally:

```bash
# Pre-commit
pre-commit run --all-files

# Tests
npm test

# Format check
npm run format:check

# Audit
npm audit
```

### Keep CI Fast

- Use caching (npm, pre-commit, Docker)
- Run heavy checks only when needed
- Use matrix strategy for parallel jobs
- Skip checks with `[skip ci]` in commit message (use sparingly)

### Security

- Never commit secrets (pre-commit will catch this)
- Use GitHub secrets for sensitive data
- Enable Dependabot for security updates
- Review security audit failures

## Monitoring CI/CD

### GitHub Actions Dashboard

View workflow runs:

```
https://github.com/OWNER/REPO/actions
```

### Status Badges

Add to README:

```markdown
[![Pre-commit](https://github.com/OWNER/REPO/workflows/Pre-commit%20Checks/badge.svg)](https://github.com/OWNER/REPO/actions)
[![Tests](https://github.com/OWNER/REPO/workflows/Tests/badge.svg)](https://github.com/OWNER/REPO/actions)
[![Docker](https://github.com/OWNER/REPO/workflows/Docker%20Build/badge.svg)](https://github.com/OWNER/REPO/actions)
```

### Notifications

Configure notifications:

- Repository Settings → Notifications
- Watch repository for workflow failures
- Enable email notifications

## Advanced Configuration

### Custom Runners

Use self-hosted runners for private infrastructure:

```yaml
runs-on: self-hosted
```

### Environment Secrets

For deployment to environments:

```yaml
environment:
  name: production
  url: https://browserquest.example.com
```

### Deployment

Add deployment step to docker.yml:

```yaml
- name: Deploy to production
  if: github.ref == 'refs/heads/main'
  run: |
    # Deploy commands here
    kubectl set image deployment/browserquest browserquest=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
```

## Cost Optimization

GitHub Actions is free for public repositories. For private repos:

- 2,000 minutes/month free
- Pre-commit: ~3 min/run
- Tests: ~4 min/run (x2 for matrix)
- Docker: ~5 min/run

**Total per PR: ~15 minutes**

**Optimize:**

- Use caching
- Skip redundant jobs
- Use conditional execution
- Combine workflows when possible

## Related Documentation

- [PRE_COMMIT_SETUP.md](PRE_COMMIT_SETUP.md) - Pre-commit configuration
- [DOCKER.md](DOCKER.md) - Docker usage guide
- [MODERNIZATION.md](MODERNIZATION.md) - Overall modernization plan
