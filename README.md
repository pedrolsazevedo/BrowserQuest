# BrowserQuest

BrowserQuest is a HTML5/JavaScript multiplayer game experiment.

## 🚀 Quick Start (Modernized Version)

This codebase has been updated to work with modern Node.js. See
[MODERNIZATION.md](MODERNIZATION.md) for details.

### Requirements

- Node.js 20+ (tested with v25.2.1)
- npm 9+

### Installation & Running

```bash
# Install dependencies
npm install

# Start server in background
./browserquest.sh start

# Check server status
./browserquest.sh status

# View logs
./browserquest.sh logs

# Stop server
./browserquest.sh stop
```

The server runs on `http://localhost:8000`

### Docker Deployment

Run BrowserQuest in Docker:

```bash
# Using Docker Compose (recommended)
docker-compose up -d

# Using Docker CLI
docker build -t browserquest .
docker run -d -p 8000:8000 browserquest
```

See [DOCKER.md](DOCKER.md) for complete Docker documentation.

### Available Commands

```bash
# Server management
npm start              # Run server (foreground)
npm run server:start   # Start server in background
npm run server:stop    # Stop background server
npm run server:status  # Show status and player counts
npm run server:logs    # View server logs

# Development
npm test              # Run tests
npm run lint          # Lint JavaScript files
npm run format        # Format code with Prettier
```

### For Contributors

This project uses pre-commit hooks for code quality. Set them up with:

```bash
./setup-pre-commit.sh
```

See [PRE_COMMIT_SETUP.md](PRE_COMMIT_SETUP.md) for details.

---

See [MODERNIZATION.md](MODERNIZATION.md) for complete modernization details and
roadmap.

## Documentation

- [MODERNIZATION.md](MODERNIZATION.md) - Modernization guide and roadmap
- [DOCKER.md](DOCKER.md) - Docker setup and deployment
- [CI_CD.md](CI_CD.md) - GitHub Actions workflows
- [PRE_COMMIT_SETUP.md](PRE_COMMIT_SETUP.md) - Code quality hooks
- [MANAGEMENT_SCRIPT_README.md](MANAGEMENT_SCRIPT_README.md) - Server management

Original documentation is located in client and server directories.

## License

Code is licensed under MPL 2.0. Content is licensed under CC-BY-SA 3.0. See the
LICENSE file for details.

## Credits

Created by [Little Workshop](http://www.littleworkshop.fr):

- Franck Lecollinet - [@whatthefranck](http://twitter.com/whatthefranck)
- Guillaume Lecollinet - [@glecollinet](http://twitter.com/glecollinet)
