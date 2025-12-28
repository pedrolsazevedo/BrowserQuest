#!/bin/bash

# BrowserQuest Server Management Script
# Usage: ./browserquest.sh {start|stop|restart|status|logs}

set -e

# Configuration
PID_FILE="./browserquest.pid"
LOG_FILE="./browserquest.log"
SERVER_PORT=8000

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if server is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        else
            # PID file exists but process is not running
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Function to get server PID
get_pid() {
    if [ -f "$PID_FILE" ]; then
        cat "$PID_FILE"
    else
        echo ""
    fi
}

# Function to start the server
start_server() {
    if is_running; then
        print_warning "Server is already running (PID: $(get_pid))"
        return 0
    fi

    print_info "Starting BrowserQuest server..."

    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_warning "node_modules not found. Running npm install..."
        npm install
    fi

    # Start server in background
    nohup node server/js/main.js >> "$LOG_FILE" 2>&1 &
    SERVER_PID=$!

    # Save PID
    echo $SERVER_PID > "$PID_FILE"

    # Wait a moment and check if it's actually running
    sleep 2

    if is_running; then
        print_info "Server started successfully (PID: $SERVER_PID)"
        print_info "Listening on port $SERVER_PORT"
        print_info "Log file: $LOG_FILE"

        # Try to get status
        if command -v curl &> /dev/null; then
            sleep 1
            STATUS=$(curl -s http://localhost:$SERVER_PORT/status 2>/dev/null || echo "")
            if [ ! -z "$STATUS" ]; then
                print_info "Server status: $STATUS"
            fi
        fi
    else
        print_error "Server failed to start. Check $LOG_FILE for details."
        tail -20 "$LOG_FILE"
        rm -f "$PID_FILE"
        exit 1
    fi
}

# Function to stop the server
stop_server() {
    if ! is_running; then
        print_warning "Server is not running"
        return 0
    fi

    PID=$(get_pid)
    print_info "Stopping BrowserQuest server (PID: $PID)..."

    # Send SIGTERM
    kill "$PID" 2>/dev/null || true

    # Wait for process to stop (max 10 seconds)
    for i in {1..10}; do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    # If still running, force kill
    if ps -p "$PID" > /dev/null 2>&1; then
        print_warning "Server did not stop gracefully, forcing shutdown..."
        kill -9 "$PID" 2>/dev/null || true
        sleep 1
    fi

    # Clean up PID file
    rm -f "$PID_FILE"

    if ! is_running; then
        print_info "Server stopped successfully"
    else
        print_error "Failed to stop server"
        exit 1
    fi
}

# Function to restart the server
restart_server() {
    print_info "Restarting BrowserQuest server..."
    stop_server
    sleep 1
    start_server
}

# Function to show server status
show_status() {
    if is_running; then
        PID=$(get_pid)
        print_info "Server is running (PID: $PID)"

        # Show memory usage
        if command -v ps &> /dev/null; then
            MEM=$(ps -p "$PID" -o rss= 2>/dev/null | awk '{printf "%.1f MB", $1/1024}')
            if [ ! -z "$MEM" ]; then
                print_info "Memory usage: $MEM"
            fi
        fi

        # Try to get player counts
        if command -v curl &> /dev/null; then
            STATUS=$(curl -s http://localhost:$SERVER_PORT/status 2>/dev/null || echo "")
            if [ ! -z "$STATUS" ]; then
                print_info "Player counts per world: $STATUS"

                # Calculate total players
                TOTAL=$(echo "$STATUS" | grep -o '[0-9]\+' | awk '{sum+=$1} END {print sum}')
                print_info "Total players online: $TOTAL"
            else
                print_warning "Unable to connect to status endpoint"
            fi
        fi

        # Show uptime
        if command -v ps &> /dev/null; then
            UPTIME=$(ps -p "$PID" -o etime= 2>/dev/null | xargs)
            if [ ! -z "$UPTIME" ]; then
                print_info "Uptime: $UPTIME"
            fi
        fi
    else
        print_warning "Server is not running"
    fi
}

# Function to show logs
show_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        print_warning "Log file not found: $LOG_FILE"
        return 0
    fi

    # Check if tail has -f option
    if [ "$1" = "-f" ] || [ "$1" = "--follow" ]; then
        print_info "Following log file (Ctrl+C to exit)..."
        tail -f "$LOG_FILE"
    else
        print_info "Last 50 lines of log file:"
        tail -50 "$LOG_FILE"
    fi
}

# Function to show help
show_help() {
    cat << EOF
BrowserQuest Server Management Script

Usage: $0 {start|stop|restart|status|logs}

Commands:
    start       Start the BrowserQuest server
    stop        Stop the BrowserQuest server
    restart     Restart the BrowserQuest server
    status      Show server status and player counts
    logs        Show last 50 lines of server logs
    logs -f     Follow server logs in real-time
    help        Show this help message

Examples:
    $0 start            # Start the server
    $0 stop             # Stop the server
    $0 status           # Check if server is running
    $0 logs -f          # Watch logs in real-time

Server Configuration:
    Port: $SERVER_PORT
    PID file: $PID_FILE
    Log file: $LOG_FILE

EOF
}

# Main script logic
case "$1" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        print_error "No command specified"
        echo ""
        show_help
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

exit 0
