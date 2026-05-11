# Contoso HR Agent — Start MCP Server + MCP Inspector (Windows)
# Force-kills MCP ports first (also done inside hr-mcp, but belt-and-suspenders).
# Opens MCP Inspector in the browser.

Set-StrictMode -Version Latest

# Ports this script owns
$MCP_PORTS = @(8091, 5273, 6374)

Write-Host "`n=== Starting Contoso HR MCP Server ===" -ForegroundColor Cyan

function Clear-McpPorts {
    param([int[]]$Ports)
    foreach ($port in $Ports) {
        Write-Host "Checking port $port..." -ForegroundColor Yellow
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

Clear-McpPorts -Ports $MCP_PORTS
Start-Sleep -Milliseconds 500

# MCP Inspector (stdio mode) — Inspector spawns hr-mcp itself, no separate server process needed.
# PORT=Inspector proxy, CLIENT_PORT=Inspector browser UI.
if (Get-Command npx -ErrorAction SilentlyContinue) {
    Write-Host "`nLaunching MCP Inspector (stdio mode)..." -ForegroundColor Cyan
    Write-Host "  Inspector UI: http://localhost:6374" -ForegroundColor White
    Write-Host "  Press Ctrl+C to stop`n" -ForegroundColor White
    $env:SERVER_PORT = "5273"
    $env:CLIENT_PORT = "6374"
    npx @modelcontextprotocol/inspector uv run hr-mcp --stdio
} else {
    Write-Host "`n[!] npx not found — MCP Inspector not launched." -ForegroundColor Yellow
    Write-Host "    Install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    Write-Host "`nFalling back to SSE mode on port 8091..." -ForegroundColor Yellow
    uv run hr-mcp
}
