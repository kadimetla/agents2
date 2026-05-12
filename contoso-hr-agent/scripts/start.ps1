# Contoso HR Agent — Start (Windows)
# One-command startup: kills all four project ports, launches watcher + MCP
# Inspector + engine, and auto-opens chat + Inspector in separate browser tabs.
# Press Ctrl+C in this window to stop everything.

Set-StrictMode -Version Latest

# Ports the project owns (engine, MCP SSE, Inspector proxy, Inspector UI)
$PROJECT_PORTS = @(8090, 8091, 5273, 6374)

Write-Host "`n=== Starting Contoso HR Agent ===" -ForegroundColor Cyan
Write-Host "  Web UI:        http://localhost:8090/chat.html" -ForegroundColor White
Write-Host "  API:           http://localhost:8090/api/" -ForegroundColor White
Write-Host "  MCP Inspector: auto-opens (or run scripts\show-inspector-url.ps1)" -ForegroundColor White
Write-Host "  Press Ctrl+C to stop`n" -ForegroundColor White

# Belt-and-suspenders: kill anything on our ports before binding.
# (engine.py and mcp_server/__main__.py also call force_kill_port() internally.)
function Clear-ProjectPorts {
    param([int[]]$Ports)
    foreach ($port in $Ports) {
        $netstatOutput = netstat -ano 2>$null | Select-String ":$port\s"
        foreach ($line in $netstatOutput) {
            $parts = $line.ToString().Trim() -split '\s+'
            $procId = $parts[-1]
            if ($procId -match '^\d+$' -and $procId -ne '0') {
                Write-Host "  Killing PID $procId on port $port" -ForegroundColor Yellow
                try { Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue } catch {}
                taskkill /PID $procId /F 2>$null | Out-Null
            }
        }
    }
}

Clear-ProjectPorts -Ports $PROJECT_PORTS
Start-Sleep -Milliseconds 500

# Start watcher as background job
$watcherJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    uv run hr-watcher
}
Write-Host "[watcher] Started (Job ID: $($watcherJob.Id))" -ForegroundColor Green

# Start MCP Inspector (stdio) as background job if npx is available.
# SERVER_PORT=Inspector proxy, CLIENT_PORT=Inspector browser UI.
$mcpJob = $null
if (Get-Command npx -ErrorAction SilentlyContinue) {
    $mcpJob = Start-Job -ScriptBlock {
        Set-Location $using:PWD
        $env:SERVER_PORT = "5273"
        $env:CLIENT_PORT = "6374"
        npx @modelcontextprotocol/inspector uv run hr-mcp --stdio
    }
    Write-Host "[mcp-inspector] Started (Job ID: $($mcpJob.Id)) — UI: http://localhost:6374" -ForegroundColor Green
} else {
    Write-Host "[mcp-inspector] Skipped — npx not found (install Node.js to enable)" -ForegroundColor Yellow
}

# Open the chat tab after the engine binds (~3s).
# DO NOT open the Inspector tab here — the Inspector CLI auto-opens its own
# tab with the MCP_PROXY_AUTH_TOKEN pre-filled in the URL. A manually-opened
# http://localhost:6374/ is missing that token and the proxy rejects it.
Start-Job -ScriptBlock {
    Start-Sleep 4
    Start-Process "http://localhost:8090/chat.html"
} | Out-Null

# Consolidated URI banner — last visible block before engine logs stream.
# Scroll up one screen during a live session to find these.
Write-Host "`n=== Services starting · open these URIs ===" -ForegroundColor Cyan
Write-Host "  Web UI:        http://localhost:8090/chat.html" -ForegroundColor White
Write-Host "  API:           http://localhost:8090/api/"      -ForegroundColor White
Write-Host "  API Docs:      http://localhost:8090/docs"      -ForegroundColor White
if ($mcpJob) {
    Write-Host "  MCP Inspector: auto-opens with auth token (do NOT paste 6374 manually)" -ForegroundColor White
    Write-Host "                 lost the tab? run scripts\show-inspector-url.ps1" -ForegroundColor DarkGray
} else {
    Write-Host "  MCP Inspector: (disabled - npx not installed)" -ForegroundColor DarkGray
}
Write-Host "===========================================`n" -ForegroundColor Cyan

# Start engine (foreground — blocks until Ctrl+C)
try {
    uv run hr-engine
} finally {
    Write-Host "`nStopping background jobs..." -ForegroundColor Yellow
    Stop-Job $watcherJob -ErrorAction SilentlyContinue
    Remove-Job $watcherJob -ErrorAction SilentlyContinue
    if ($mcpJob) {
        Stop-Job $mcpJob -ErrorAction SilentlyContinue
        Remove-Job $mcpJob -ErrorAction SilentlyContinue
    }
    # On graceful exit, sweep ports again so the next bounce is instant.
    Clear-ProjectPorts -Ports $PROJECT_PORTS
    Write-Host "All stopped. Ports cleared." -ForegroundColor Green
}
