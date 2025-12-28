# BrowserQuest Server Management Script

The `browserquest.sh` script provides an easy way to manage the BrowserQuest
game server with background process support, logging, and status monitoring.

## Features

- ✅ Start/stop/restart server in background
- ✅ Real-time server status with player counts
- ✅ Memory usage monitoring
- ✅ Uptime tracking
- ✅ Log viewing (tail or follow mode)
- ✅ PID-based process management
- ✅ Colored output for better readability
- ✅ Graceful shutdown with fallback to force kill

## Usage

### Basic Commands

```bash
# Start the server in background
./browserquest.sh start

# Stop the server
./browserquest.sh stop

# Restart the server
./browserquest.sh restart

# Show server status
./browserquest.sh status

# View last 50 lines of logs
./browserquest.sh logs

# Follow logs in real-time (like tail -f)
./browserquest.sh logs -f

# Show help
./browserquest.sh help
```

### Using npm Scripts

You can also use the npm scripts defined in package.json:

```bash
npm run server:start    # Start in background
npm run server:stop     # Stop server
npm run server:restart  # Restart server
npm run server:status   # Show status
npm run server:logs     # View logs
```

## Server Status Information

When you run `./browserquest.sh status`, you'll see:

- **PID**: Process ID of the running server
- **Memory usage**: Current RAM consumption in MB
- **Player counts**: Array showing players in each of the 5 worlds
- **Total players**: Sum of all players online
- **Uptime**: How long the server has been running

Example output:

```
[INFO] Server is running (PID: 12574)
[INFO] Memory usage: 82.8 MB
[INFO] Player counts per world: [0,0,0,0,0]
[INFO] Total players online: 0
[INFO] Uptime: 00:12:34
```

## Files Created

When the server runs, it creates:

- **browserquest.pid** - Contains the process ID of the running server
- **browserquest.log** - Server log output (both stdout and stderr)

These files are automatically managed by the script and are included in
`.gitignore`.

## Configuration

The script uses these default settings (defined at the top of the script):

```bash
PID_FILE="./browserquest.pid"
LOG_FILE="./browserquest.log"
SERVER_PORT=8000
```

You can modify these values in the script if needed.

## Error Handling

The script includes robust error handling:

1. **Already running**: Won't start if server is already running
2. **Not running**: Gracefully handles stop/restart when server isn't running
3. **Stale PID files**: Automatically cleans up PID files for dead processes
4. **Graceful shutdown**: Attempts SIGTERM first, then SIGKILL if needed
5. **Startup validation**: Checks if server actually started successfully

## Troubleshooting

### Server won't start

```bash
# Check the logs for errors
./browserquest.sh logs

# Or follow logs while starting
./browserquest.sh logs -f &
./browserquest.sh start
```

### Server status shows as running but isn't responding

```bash
# Force stop and restart
./browserquest.sh stop
./browserquest.sh start
```

### Can't find the script

```bash
# Make sure it's executable
chmod +x browserquest.sh
```

### Permission denied

```bash
# The script needs execute permission
chmod +x browserquest.sh
```

## Integration with Other Tools

### systemd service

You could create a systemd service to manage BrowserQuest:

```ini
[Unit]
Description=BrowserQuest Game Server
After=network.target

[Service]
Type=forking
WorkingDirectory=/path/to/BrowserQuest
ExecStart=/path/to/BrowserQuest/browserquest.sh start
ExecStop=/path/to/BrowserQuest/browserquest.sh stop
PIDFile=/path/to/BrowserQuest/browserquest.pid
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Docker

The script works in Docker containers. Just ensure the container has bash and
standard Unix utilities.

### CI/CD

Use in GitHub Actions or other CI/CD pipelines:

```yaml
- name: Start BrowserQuest Server
  run: ./browserquest.sh start

- name: Run tests against server
  run: npm test

- name: Stop server
  run: ./browserquest.sh stop
```

## Requirements

The script requires:

- bash shell
- Node.js (for running the server)
- Standard Unix utilities: ps, kill, tail, curl (optional)

## License

Same as BrowserQuest - MPL 2.0 for code.
