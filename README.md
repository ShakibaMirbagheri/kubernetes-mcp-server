# Kubernetes MCP Server

A powerful Go-based Model Context Protocol (MCP) server that provides native Kubernetes and OpenShift cluster management capabilities.

## 🚀 Quick Start with Docker Compose

### Prerequisites

- Docker and Docker Compose installed
- A valid Kubernetes kubeconfig file
- Access to a Kubernetes cluster

### Option 1: Using start.sh (Recommended)

The easiest way to deploy the Kubernetes MCP Server:

```bash
# Set your kubeconfig path
export KUBECONFIG=/tmp/kubeconfig

# Run the startup script
./start.sh
```

The script will:
- ✅ Validate your kubeconfig exists
- ✅ Check Docker is running
- ✅ Build the Docker image
- ✅ Start the MCP server
- ✅ Wait for health checks
- ✅ Display all endpoints and useful commands

**Output:**
```
========================================
✓ Kubernetes MCP Server is ready!
========================================

  MCP Endpoint: http://localhost:8200/mcp
  SSE Endpoint: http://localhost:8200/sse
  Health Check: http://localhost:8200/healthz
```

### Option 2: Using docker-compose directly

```bash
# Build and start in detached mode
KUBECONFIG=/tmp/kubeconfig docker-compose up --build -d

# View logs
docker-compose logs -f

# Stop the service
docker-compose down
```

---

## ⚙️ Configuration

Configure the MCP server using environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `KUBECONFIG` | Path to kubeconfig file | `/tmp/kubeconfig` |
| `MCP_PORT` | HTTP server port | `8200` |
| `LOG_LEVEL` | Logging verbosity (0-9) | `1` |

### Examples

**Custom port and log level:**
```bash
KUBECONFIG=/tmp/kubeconfig MCP_PORT=9090 LOG_LEVEL=2 ./start.sh
```

**Using a different kubeconfig:**
```bash
KUBECONFIG=~/.kube/config ./start.sh
```

**Using .env file:**

Create a `.env` file in the project root:
```bash
KUBECONFIG=/home/user/.kube/config
MCP_PORT=8200
LOG_LEVEL=1
```

Then run:
```bash
./start.sh
# or
docker-compose up -d
```

---

## 🧪 Testing the MCP Server

### Health Check
```bash
curl http://localhost:8200/healthz
```

### List Available Tools
```bash
curl -X POST http://localhost:8200/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'
```

### List Kubernetes Namespaces
```bash
curl -X POST http://localhost:8200/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "namespaces_list",
      "arguments": {}
    }
  }'
```

### List Pods
```bash
curl -X POST http://localhost:8200/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "pods_list",
      "arguments": {}
    }
  }'
```

---

## 🛠️ Management Commands

### View Logs
```bash
# Follow logs in real-time
docker logs -f k8s-mcp-server

# Or with docker-compose
docker-compose logs -f
```

### Restart the Service
```bash
docker-compose restart
```

### Stop the Service
```bash
docker-compose down
```

### Rebuild and Restart
```bash
# Rebuild the image and restart
docker-compose up --build -d

# Or force rebuild without cache
docker-compose build --no-cache
docker-compose up -d
```

### Check Service Status
```bash
docker-compose ps
```

---

## 🔧 Available Endpoints

Once the server is running, the following endpoints are available:

| Endpoint | Description |
|----------|-------------|
| `/mcp` | Main MCP protocol endpoint (HTTP streaming) |
| `/sse` | Server-Sent Events endpoint |
| `/message` | SSE message endpoint |
| `/healthz` | Health check endpoint |
| `/.well-known/` | Well-known configuration endpoints |

---

## 🐛 Troubleshooting

### Issue: "Kubeconfig file not found"

**Solution:** Ensure the KUBECONFIG environment variable points to a valid file:
```bash
ls -l $KUBECONFIG
export KUBECONFIG=/path/to/your/kubeconfig
```

### Issue: "couldn't get current server API group list"

**Symptoms:** Errors in logs like:
```
Error: the server rejected our request for an unknown reason
```

**Common Causes:**
1. **Wrong protocol in kubeconfig** - Check if your kubeconfig uses `http://` instead of `https://`
2. **Incorrect server address** - If using `0.0.0.0`, change to `127.0.0.1` or `localhost`

**Fix for k3d clusters:**
```bash
# Regenerate kubeconfig with correct settings
k3d kubeconfig get <cluster-name> > /tmp/kubeconfig

# Verify the server URL
grep "server:" /tmp/kubeconfig

# Should be https://127.0.0.1:PORT or https://localhost:PORT
```

### Issue: Port already in use

**Solution:** Use a different port:
```bash
MCP_PORT=9090 ./start.sh
```

### Issue: Docker permission denied

**Solution:** Add your user to the docker group:
```bash
sudo usermod -aG docker $USER
# Log out and log back in
```

### View Detailed Logs

```bash
# Check server logs
docker logs k8s-mcp-server

# Check with timestamps
docker logs -t k8s-mcp-server

# Follow logs
docker logs -f k8s-mcp-server
```

---

## 🏗️ Manual Build (Without Docker Compose)

If you prefer to build and run manually:

```bash
# Build the Docker image
docker build -t kubernetes-mcp-server .

# Run the container
docker run -d \
  --name k8s-mcp-server \
  --network host \
  -v /tmp/kubeconfig:/kubeconfig:ro \
  kubernetes-mcp-server \
  --kubeconfig /kubeconfig \
  --port 8200
```

---

## 📦 Docker Compose Reference

The `docker-compose.yml` configuration:

```yaml
version: '3.8'

services:
  kubernetes-mcp-server:
    build:
      context: .
      dockerfile: Dockerfile
    image: kubernetes-mcp-server
    container_name: k8s-mcp-server
    network_mode: host
    restart: unless-stopped
    volumes:
      - ${KUBECONFIG:-/tmp/kubeconfig}:/kubeconfig:ro
    command:
      - --kubeconfig
      - /kubeconfig
      - --port
      - ${MCP_PORT:-8200}
      - --log-level
      - ${LOG_LEVEL:-1}
```

**Key Features:**
- Automatic build from Dockerfile
- Host network mode for cluster connectivity
- Persistent volume for kubeconfig (read-only)
- Health checks every 30 seconds
- Auto-restart unless manually stopped
- Environment variable support

---

## 📝 License

See [LICENSE](LICENSE) file for details.
