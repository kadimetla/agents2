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
echo "  MCP Inspector: auto-opens (or run scripts/show-inspector-url.sh)"
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

# Open the chat tab after the engine binds (~3s).
# DO NOT open the Inspector tab here — the Inspector CLI auto-opens its own
# tab with the MCP_PROXY_AUTH_TOKEN pre-filled in the URL. A manually-opened
# http://localhost:6374/ is missing that token and the proxy rejects it.
open_url() {
    open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || true
}
(sleep 4 && open_url "http://localhost:8090/chat.html") &

cleanup() {
    echo ""
    echo "Stopping background processes..."
    [ -n "$WATCHER_PID" ] && kill "$WATCHER_PID" 2>/dev/null || true
    [ -n "$MCP_PID" ] && kill "$MCP_PID" 2>/dev/null || true
    clear_project_ports
}
trap cleanup EXIT INT TERM

# Consolidated URI banner — last visible block before engine logs stream.
# Scroll up one screen during a live session to find these.
echo ""
echo "=== Services starting · open these URIs ==="
echo "  Web UI:        http://localhost:8090/chat.html"
echo "  API:           http://localhost:8090/api/"
echo "  API Docs:      http://localhost:8090/docs"
if [ -n "$MCP_PID" ]; then
    echo "  MCP Inspector: auto-opens with auth token (do NOT paste 6374 manually)"
    echo "                 lost the tab? run scripts/show-inspector-url.sh"
else
    echo "  MCP Inspector: (disabled - npx not installed)"
fi
echo "==========================================="
echo ""

# Start engine (foreground)
uv run hr-engine
