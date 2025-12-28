# BrowserQuest Dockerfile
# Multi-stage build for optimized production image

# Stage 1: Build stage
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (including devDependencies for potential build steps)
RUN npm ci

# Copy application source
COPY . .

# Build client if needed (uncomment if you want to build the client in Docker)
# RUN chmod +x bin/build.sh && npm run build

# Stage 2: Production stage
FROM node:20-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user for security
RUN addgroup -g 1001 -S browserquest && \
    adduser -S -u 1001 -G browserquest browserquest

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application files from builder
COPY --from=builder --chown=browserquest:browserquest /app/server ./server
COPY --from=builder --chown=browserquest:browserquest /app/shared ./shared
COPY --from=builder --chown=browserquest:browserquest /app/client ./client

# Copy configuration files
COPY --chown=browserquest:browserquest server/config.json ./server/

# Create directories for logs and pid files
RUN mkdir -p /app/logs && \
    chown -R browserquest:browserquest /app/logs

# Switch to non-root user
USER browserquest

# Expose port (default: 8000)
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:8000/status', (r) => {if(r.statusCode !== 200) throw new Error('Health check failed')})"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the server
CMD ["node", "server/js/main.js"]
