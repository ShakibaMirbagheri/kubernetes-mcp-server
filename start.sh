#!/bin/bash

# Kubernetes MCP Server Startup Script
# This script starts the Kubernetes MCP Server using Docker Compose

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DEFAULT_KUBECONFIG="/tmp/kubeconfig"
DEFAULT_PORT="8200"
DEFAULT_LOG_LEVEL="1"

# Get KUBECONFIG from environment variable or use default
KUBECONFIG="${KUBECONFIG:-$DEFAULT_KUBECONFIG}"
MCP_PORT="${MCP_PORT:-$DEFAULT_PORT}"
LOG_LEVEL="${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Kubernetes MCP Server Startup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Validate kubeconfig file exists
if [ ! -f "$KUBECONFIG" ]; then
    echo -e "${RED}ERROR: Kubeconfig file not found: $KUBECONFIG${NC}"
    echo -e "${YELLOW}Please set the KUBECONFIG environment variable:${NC}"
    echo -e "  export KUBECONFIG=/path/to/your/kubeconfig"
    echo -e "  $0"
    exit 1
fi

echo -e "${GREEN}✓${NC} Kubeconfig found: $KUBECONFIG"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Docker is not running${NC}"
    echo -e "${YELLOW}Please start Docker and try again${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker is running"

# Export environment variables for docker-compose
export KUBECONFIG
export MCP_PORT
export LOG_LEVEL

echo ""
echo -e "${GREEN}Building and starting Kubernetes MCP Server...${NC}"
echo -e "  Kubeconfig: ${YELLOW}$KUBECONFIG${NC}"
echo -e "  Port: ${YELLOW}$MCP_PORT${NC}"
echo -e "  Log Level: ${YELLOW}$LOG_LEVEL${NC}"
echo ""

# Build and start the service using docker-compose
docker-compose up --build -d

# Wait for the service to be ready
echo -e "${YELLOW}Waiting for service to be ready...${NC}"
sleep 5

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q '^k8s-mcp-server$'; then
    echo -e "${GREEN}✓${NC} Container is running"
    
    # Test the health endpoint with retries
    for i in {1..10}; do
        if curl -s -f http://localhost:$MCP_PORT/healthz > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Health check passed"
            echo ""
            echo -e "${GREEN}========================================${NC}"
            echo -e "${GREEN}✓ Kubernetes MCP Server is ready!${NC}"
            echo -e "${GREEN}========================================${NC}"
            echo ""
            echo -e "  MCP Endpoint: ${YELLOW}http://localhost:$MCP_PORT/mcp${NC}"
            echo -e "  SSE Endpoint: ${YELLOW}http://localhost:$MCP_PORT/sse${NC}"
            echo -e "  Health Check: ${YELLOW}http://localhost:$MCP_PORT/healthz${NC}"
            echo ""
            echo -e "${YELLOW}Useful Commands:${NC}"
            echo -e "  View logs:     ${GREEN}docker logs -f k8s-mcp-server${NC}"
            echo -e "  Stop server:   ${GREEN}docker-compose down${NC}"
            echo -e "  Restart:       ${GREEN}docker-compose restart${NC}"
            echo -e "  Rebuild:       ${GREEN}docker-compose up --build -d${NC}"
            echo ""
            echo -e "${YELLOW}Test MCP Server:${NC}"
            echo -e "  ${GREEN}curl http://localhost:$MCP_PORT/healthz${NC}"
            echo ""
            exit 0
        fi
        echo -e "${YELLOW}⏳${NC} Waiting for health check... (attempt $i/10)"
        sleep 2
    done
    
    echo -e "${YELLOW}⚠${NC} Health check did not pass within timeout"
    echo -e "The service may still be starting. Check logs:"
    echo -e "  ${YELLOW}docker logs k8s-mcp-server${NC}"
else
    echo -e "${RED}ERROR: Container failed to start${NC}"
    echo -e "Check logs: ${YELLOW}docker logs k8s-mcp-server${NC}"
    exit 1
fi

