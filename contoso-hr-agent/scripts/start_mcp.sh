#!/usr/bin/env bash
# Contoso HR Agent — Start MCP Inspector (Unix)
# Force-kills MCP ports first, then launches MCP Inspector pointing at hr-mcp (stdio).

set -e

# Ports this script owns (MCP SSE, Inspector proxy, Inspector UI)
MCP_PORTS=(8091 5273 6374)

echo ""
echo "=== Starting Contoso HR MCP Inspector ==="

clear_mcp_ports() {
    for port in "${MCP_PORTS[@]}"; do
        echo "Checking port $port..."
        if command -v fuser &>/dev/null; then
            fuser -k "${port}/tcp" 2>/dev/null && echo "  Killed process on port $port" || true
        elif command -v lsof &>/dev/null; then
            lsof -ti "tcp:${port}" 2>/dev/null | xargs -r kill -9 2>/dev/null && echo "  Killed process on port $port" || true
        fi
    done
}

clear_mcp_ports
sleep 0.5

# MCP Inspector (stdio mode) — Inspector spawns hr-mcp itself, no separate server process needed.
# PORT=Inspector proxy, CLIENT_PORT=Inspector browser UI.
if command -v npx &>/dev/null; then
    echo ""
    echo "Launching MCP Inspector (stdio mode)..."
    echo "  Inspector UI: http://localhost:6374"
    echo "  Press Ctrl+C to stop"
    echo ""
    SERVER_PORT=5273 CLIENT_PORT=6374 npx @modelcontextprotocol/inspector uv run hr-mcp --stdio
else
    echo ""
    echo "[!] npx not found — MCP Inspector not launched."
    echo "    Install Node.js from https://nodejs.org/"
    echo ""
    echo "Falling back to SSE mode on port 8091..."
    uv run hr-mcp
fi
