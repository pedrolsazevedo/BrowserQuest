# BrowserQuest Modernization Guide

This document tracks the modernization efforts to update the 14-year-old
BrowserQuest codebase to work with modern Node.js and dependencies.

## Phase 1: Foundation ✅ COMPLETED

### What Was Done

#### 1. Node.js Update

- **Target**: Node.js 20+ LTS (currently tested with v25.2.1)
- **Updated**: `package.json` now specifies `"engines": { "node": ">=20.0.0" }`

#### 2. Dependency Modernization

**Replaced Dependencies:**

- ❌ `websocket-server` (unpublished in 2014) → ✅ `ws` v8.18.0
- ❌ `websocket` (old Worlize library) → ✅ `ws` v8.18.0
- ❌ `log` v6.3.2 (incompatible API) → ✅ Custom logger (`server/js/logger.js`)
- ✅ `bison` v1.1.1 (kept - still works)
- ✅ `underscore` v1.13.7 (updated from loose ">0")
- ✅ `sanitizer` v0.1.3 (updated from loose ">0")

**Optional Dependencies:**

- ✅ `memcached` v2.2.2 (for metrics, if needed)

**Dev Dependencies:**

- ✅ `jest` v29.7.0 (testing framework)
- ✅ `eslint` v8.57.0 (JavaScript linting)
- ✅ `prettier` v3.4.2 (code formatting)
- ✅ `eslint-config-prettier` v9.1.0 (ESLint + Prettier integration)

#### 3. Code Fixes

**WebSocket Implementation** ([server/js/ws.js](server/js/ws.js))

- Completely rewrote to use modern `ws` library
- Removed support for obsolete WebSocket protocols (draft-75, draft-76, hybi-00)
- Modern browsers all support the standard WebSocket protocol
- Maintained backward-compatible API for existing code
- Added `ModernWebSocketConnection` class
- Kept compatibility aliases for `worlizeWebSocketConnection` and
  `miksagoWebSocketConnection`

**Logger Implementation** ([server/js/logger.js](server/js/logger.js))

- Created custom logger to replace incompatible `log` package
- Provides same API as old `log` package: `new Log(Log.INFO)`
- Supports ERROR, INFO, and DEBUG levels
- Uses native `console.log` and `console.error`

**Deprecated API Fixes**

- [server/js/map.js](server/js/map.js): Replaced `path.exists()` → `fs.access()`
  (path.exists was removed in modern Node.js)
- Added proper error handling for file operations

#### 4. Testing Framework

**Setup:**

- Added Jest as testing framework
- Created [jest.config.js](jest.config.js) with Node.js environment
- Created initial tests in
  [server/js/**tests**/server.test.js](server/js/__tests__/server.test.js)
- All tests passing ✅

**Run tests:**

```bash
npm test
```

#### 5. Security Audit

- ✅ `npm audit`: **0 vulnerabilities**
- All dependencies are up-to-date and secure
- Package lock file generated for reproducible builds

#### 6. Code Quality & Pre-commit Hooks

**Pre-commit Configuration:**

- Added [.pre-commit-config.yaml](.pre-commit-config.yaml) with comprehensive
  hooks
- Automated code formatting with Prettier
- JavaScript linting with ESLint
- Security checks (detect-secrets, private key detection)
- Shell script validation (ShellCheck)
- Markdown linting
- Conventional commit message enforcement

**Setup:**

```bash
# Quick setup
./setup-pre-commit.sh

# Or manual setup
pip install pre-commit
pre-commit install
```

**Usage:**

```bash
npm run format       # Format all files
npm run lint         # Lint JavaScript files
npm run format:check # Check formatting
```

See [PRE_COMMIT_SETUP.md](PRE_COMMIT_SETUP.md) for detailed information.

### How to Run

#### Install Dependencies

```bash
npm install
```

#### Server Management

**Using the Management Script (Recommended):**

The [browserquest.sh](browserquest.sh) script provides easy server management:

```bash
# Start the server (runs in background)
./browserquest.sh start

# Check server status and player counts
./browserquest.sh status

# View server logs
./browserquest.sh logs

# Follow logs in real-time
./browserquest.sh logs -f

# Stop the server
./browserquest.sh stop

# Restart the server
./browserquest.sh restart

# Show help
./browserquest.sh help
```

**Using npm scripts:**

```bash
npm run server:start    # Start server in background
npm run server:status   # Check status
npm run server:logs     # View logs
npm run server:stop     # Stop server
npm run server:restart  # Restart server
```

**Direct execution:**

```bash
npm start
# or
node server/js/main.js
```

The server runs on port 8000 (configurable in `server/config.json`).

#### Check Server Status

```bash
curl http://localhost:8000/status
# Returns: [0,0,0,0,0] - player counts for 5 worlds
```

#### Run Tests

```bash
npm test
```

### Scripts Added to package.json

**Server Management:**

- `npm start` - Start the game server (foreground)
- `npm run server:start` - Start server in background with management script
- `npm run server:stop` - Stop background server
- `npm run server:restart` - Restart background server
- `npm run server:status` - Show server status and player counts
- `npm run server:logs` - View server logs

**Development & Quality:**

- `npm test` - Run Jest tests
- `npm run lint` - Lint JavaScript files with ESLint
- `npm run format` - Format all files with Prettier
- `npm run format:check` - Check formatting without changes
- `npm run build` - Build client (uses existing build.sh)

### Breaking Changes from Original

1. **No longer supports ancient browsers**: The old code supported WebSocket
   draft-75, draft-76, and hybi-00 for compatibility with very old browsers.
   Modern implementation only supports the standard WebSocket protocol (RFC
   6455). All modern browsers support this.

2. **Config file notice**: On startup, you may see "Could not open config file:
   ./server/config_local.json" - this is normal. The server uses default config
   from `server/config.json`. Copy `server/config_local.json-dist` to
   `server/config_local.json` if you want custom settings.

### Files Modified

- [package.json](package.json) - Updated dependencies and added scripts
- [server/js/ws.js](server/js/ws.js) - Rewritten for modern `ws` library
- [server/js/main.js](server/js/main.js) - Use custom logger
- [server/js/worldserver.js](server/js/worldserver.js) - Use custom logger
- [server/js/map.js](server/js/map.js) - Fix deprecated `path.exists()`

### Files Created

**Core Functionality:**

- [server/js/logger.js](server/js/logger.js) - Custom logger implementation
- [browserquest.sh](browserquest.sh) - Server management script
- [setup-pre-commit.sh](setup-pre-commit.sh) - Pre-commit setup automation
  script

**Testing:**

- [jest.config.js](jest.config.js) - Jest configuration
- [server/js/**tests**/server.test.js](server/js/__tests__/server.test.js) -
  Initial tests

**Code Quality:**

- [.pre-commit-config.yaml](.pre-commit-config.yaml) - Pre-commit hooks
  configuration
- [.eslintrc.json](.eslintrc.json) - ESLint rules
- [.prettierrc.json](.prettierrc.json) - Prettier formatting rules
- [.prettierignore](.prettierignore) - Prettier exclusions
- [.markdownlint.json](.markdownlint.json) - Markdown linting rules
- [.secrets.baseline](.secrets.baseline) - Detect-secrets baseline

**Docker & Deployment:**

- [Dockerfile](Dockerfile) - Multi-stage production Dockerfile
- [docker-compose.yml](docker-compose.yml) - Docker Compose configuration
- [.dockerignore](.dockerignore) - Docker build exclusions

**CI/CD:**

- [.github/workflows/pre-commit.yml](.github/workflows/pre-commit.yml) -
  Pre-commit checks workflow
- [.github/workflows/test.yml](.github/workflows/test.yml) - Test suite workflow
- [.github/workflows/docker.yml](.github/workflows/docker.yml) - Docker build
  and push workflow

**Documentation:**

- [MODERNIZATION.md](MODERNIZATION.md) - This file
- [DOCKER.md](DOCKER.md) - Docker setup and deployment guide
- [CI_CD.md](CI_CD.md) - GitHub Actions CI/CD documentation
- [MANAGEMENT_SCRIPT_README.md](MANAGEMENT_SCRIPT_README.md) - Server management
  guide
- [PRE_COMMIT_SETUP.md](PRE_COMMIT_SETUP.md) - Pre-commit hooks guide

**Build Artifacts:**

- [package-lock.json](package-lock.json) - Dependency lock file

### Files Updated

- [package.json](package.json) - Updated dependencies and added scripts
- [README.md](README.md) - Added quick start guide
- [.gitignore](.gitignore) - Added server management files, coverage, npm
  artifacts, and pre-commit files
- [server/js/ws.js](server/js/ws.js) - Rewritten for modern `ws` library
- [server/js/main.js](server/js/main.js) - Use custom logger
- [server/js/worldserver.js](server/js/worldserver.js) - Use custom logger
- [server/js/map.js](server/js/map.js) - Fix deprecated `path.exists()`

---

## Phase 2: Module System (Planned)

The next phase will modernize the module system and build tools:

### Planned Changes

1. Migrate from RequireJS (AMD) to ES6 modules
2. Update build system from RequireJS Optimizer to Vite
3. Remove jQuery dependency, use vanilla JS
4. Convert custom class.js inheritance to native ES6 classes
5. Add hot module replacement for development

### Why This Matters

- ES6 modules are the standard for modern JavaScript
- Vite provides much faster build times and better developer experience
- Removing jQuery reduces bundle size
- Native ES6 classes are cleaner and more maintainable

---

## Phase 3: Developer Experience (Planned)

### Planned Changes

1. Add TypeScript (gradual migration)
2. Add ESLint + Prettier for code quality
3. Set up hot module replacement
4. Add comprehensive test coverage
5. Document architecture and setup

---

## Phase 4: Enhancement (Planned)

### Planned Changes

1. Improve mobile/responsive design
2. Add PWA capabilities (service workers, manifest)
3. Containerize with Docker
4. Add proper database persistence (currently uses optional memcache)
5. Modern deployment setup (Heroku, Railway, fly.io)
6. Add error tracking (Sentry) and analytics

---

## Current Status

✅ **Phase 1 Complete** - The game server now runs on modern Node.js with
updated dependencies and zero security vulnerabilities.

The server is fully functional and ready for development. You can now start the
game and connect clients to it.

### Next Steps

Ready to proceed with Phase 2 when you are!
