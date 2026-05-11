#!/usr/bin/env bash
# Contoso HR Agent — Start (Unix)
# Force-kills all four project ports up front so a clean bounce always works.
set -e

# Ports the project owns (engine, MCP SSE, Inspector proxy, Inspector UI)
PROJECT_PORTS=(8090 8091 5273 6374)

echo ""
echo "=== Starting Contoso HR Agent ==="
echo "  Web UI:        http://localhost:8090/chat.html"
echo "  API:           http://localhost:8090/api/"
echo "  MCP SSE:       http://localhost:8091/sse"
echo "  MCP Inspector: http://localhost:6374"
echo "  Press Ctrl+C to stop"
echo ""

# Belt-and-suspenders: kill anything on our ports before binding.
clear_project_ports() {
    for port in "${PROJECT_PORTS[@]}"; do
        if command -v fuser &>/dev/null; then
            fuser -k "${port}/tcp" 2>/dev/null && echo "  Killed process on port $port" || true
        elif command -v lsof &>/dev/null; then
            lsof -ti "tcp:${port}" 2>/dev/null | xargs -r kill -9 2>/dev/null && echo "  Killed process on port $port" || true
        fi
    done
}

clear_project_ports
sleep 0.5

# Start watcher in background
uv run hr-watcher &
WATCHER_PID=$!
echo "[watcher] Started (PID: $WATCHER_PID)"

# Start MCP Inspector (stdio) in background if npx available.
# PORT=Inspector proxy, CLIENT_PORT=Inspector browser UI.
MCP_PID=""
if command -v npx &>/dev/null; then
    SERVER_PORT=5273 CLIENT_PORT=6374 npx @modelcontextprotocol/inspector uv run hr-mcp --stdio &
    MCP_PID=$!
    echo "[mcp-inspector] Started (PID: $MCP_PID) — UI: http://localhost:6374"
else
    echo "[mcp-inspector] Skipped — npx not found (install Node.js to enable)"
fi

# Open both tabs after services have time to bind.
# Engine binds in ~3s; Inspector takes ~8-12s on first npx run (cached after).
open_url() {
    open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || true
}
(sleep 4 && open_url "http://localhost:8090/chat.html") &
if [ -n "$MCP_PID" ]; then
    (sleep 12 && open_url "http://localhost:6374") &
fi

cleanup() {
    echo ""
    echo "Stopping background processes..."
    [ -n "$WATCHER_PID" ] && kill "$WATCHER_PID" 2>/dev/null || true
    [ -n "$MCP_PID" ] && kill "$MCP_PID" 2>/dev/null || true
    clear_project_ports
}
trap cleanup EXIT INT TERM

# Start engine (foreground)
uv run hr-engine
