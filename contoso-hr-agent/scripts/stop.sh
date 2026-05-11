#!/usr/bin/env bash
# Contoso HR Agent — Stop (Unix)
# Kills any process on the four project ports. Safe to run anytime — even
# after a crashed start.sh that orphaned hr-engine/hr-watcher/MCP/Inspector.

set +e

PROJECT_PORTS=(8090 8091 5273 6374)

echo ""
echo "=== Stopping Contoso HR Agent ==="

killed_any=0
for port in "${PROJECT_PORTS[@]}"; do
    if command -v fuser &>/dev/null; then
        if fuser -k "${port}/tcp" 2>/dev/null; then
            echo "  Killed process(es) on port $port"
            killed_any=1
        fi
    elif command -v lsof &>/dev/null; then
        pids=$(lsof -ti "tcp:${port}" 2>/dev/null)
        if [ -n "$pids" ]; then
            echo "$pids" | xargs kill -9 2>/dev/null
            echo "  Killed PID(s) $(echo $pids | tr '\n' ' ')on port $port"
            killed_any=1
        fi
    fi
done

if [ "$killed_any" -eq 0 ]; then
    echo "  Nothing to stop. All project ports were already free."
fi

echo ""
echo "All stopped."
