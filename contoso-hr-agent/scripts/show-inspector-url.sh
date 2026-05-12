#!/usr/bin/env bash
# Contoso HR Agent — Recover MCP Inspector tab URL (Unix)
#
# Why this exists:
#   The MCP Inspector CLI bakes an MCP_PROXY_AUTH_TOKEN into the URL it auto-
#   opens on launch. If you close that tab, http://localhost:6374 by itself
#   fails with "error connecting to proxy" because the bare URL has no token.
#
# Unix limitation:
#   Unlike PowerShell jobs, bash background processes don't have an addressable
#   stdout buffer we can re-read. The token URL was printed once to the
#   terminal that ran start.sh and isn't easily recoverable.
#
# Best options, in order:
#   1. Scroll up in the start.sh terminal — search for "MCP_PROXY_AUTH_TOKEN"
#   2. If you ran start.sh inside tmux/screen, search the scrollback buffer
#   3. Bounce the stack:  ./scripts/stop.sh && ./scripts/start.sh
#
# Usage:
#   ./scripts/show-inspector-url.sh

set -u

# Confirm an Inspector process is actually running so the user knows whether
# they need to bounce or just scroll.
inspector_pid=""
if command -v pgrep &>/dev/null; then
    inspector_pid=$(pgrep -f "modelcontextprotocol/inspector" | head -1 || true)
fi

if [ -z "$inspector_pid" ]; then
    echo "No MCP Inspector process is running."
    echo "Run ./scripts/start.sh to launch the stack."
    exit 1
fi

echo "MCP Inspector is running (PID $inspector_pid)."
echo ""
echo "The tokenized URL was printed by start.sh on launch. To recover it:"
echo "  1. Scroll up in the start.sh terminal — search for 'MCP_PROXY_AUTH_TOKEN'"
echo "  2. If you ran start.sh inside tmux/screen, search the scrollback buffer"
echo "  3. Or bounce the stack:  ./scripts/stop.sh && ./scripts/start.sh"
echo ""
echo "Tip: redirect start.sh stdout to a file next time:"
echo "  ./scripts/start.sh 2>&1 | tee /tmp/hr-agent.log"
echo "Then: grep MCP_PROXY_AUTH_TOKEN /tmp/hr-agent.log"
