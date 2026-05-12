# Contoso HR Agent — Recover MCP Inspector tab URL (Windows)
#
# Why this exists:
#   The MCP Inspector CLI bakes an MCP_PROXY_AUTH_TOKEN into the URL it auto-opens
#   on launch. If you close that browser tab, http://localhost:6374 by itself
#   fails with "error connecting to proxy" because the bare URL has no token.
#   The Inspector process is still running — only the tab is gone.
#
#   This script reads the tokenized URL out of the Inspector's PowerShell job
#   stdout buffer and prints it so you can paste it back into a browser.
#
# Usage:
#   .\scripts\show-inspector-url.ps1            # print the URL
#   .\scripts\show-inspector-url.ps1 -Open      # print AND launch it in default browser

[CmdletBinding()]
param(
    [switch]$Open
)

Set-StrictMode -Version Latest

# Find every job whose command line mentions the MCP Inspector. Usually exactly one.
$inspectorJobs = Get-Job -ErrorAction SilentlyContinue |
    Where-Object { $_.Command -match "modelcontextprotocol/inspector" }

if (-not $inspectorJobs) {
    Write-Host "No running MCP Inspector job found in this PowerShell session." -ForegroundColor Red
    Write-Host "If you launched start.ps1 from a different window, run this script there." -ForegroundColor Yellow
    Write-Host "Otherwise, bounce the stack: .\scripts\stop.ps1 && .\scripts\start.ps1" -ForegroundColor Yellow
    exit 1
}

# Walk every Inspector job, scan its accumulated stdout for the tokenized URL.
# -Keep preserves the buffer so subsequent calls (or the start window's own log)
# still see the same output.
$foundUrl = $null
foreach ($job in $inspectorJobs) {
    $output = Receive-Job -Id $job.Id -Keep -ErrorAction SilentlyContinue

    # The Inspector has used a few URL formats across versions. Match the most
    # specific pattern first so we prefer the full tokenized form.
    foreach ($line in $output) {
        $text = $line.ToString()
        # Inspector 0.10+ format: http://localhost:6274/?MCP_PROXY_AUTH_TOKEN=...
        # Inspector 0.9-  format: http://localhost:6274/#MCP_PROXY_TOKEN=...
        if ($text -match 'https?://[^\s]+(MCP_PROXY_AUTH_TOKEN|MCP_PROXY_TOKEN)=\S+') {
            $foundUrl = $Matches[0].TrimEnd('.', ',', ')', ']', '"', "'")
            break
        }
    }
    if ($foundUrl) { break }
}

if (-not $foundUrl) {
    Write-Host "Inspector job is running but no tokenized URL was found in its log." -ForegroundColor Red
    Write-Host "The Inspector may still be starting up. Wait ~10s and re-run." -ForegroundColor Yellow
    Write-Host "Job IDs scanned: $($inspectorJobs.Id -join ', ')" -ForegroundColor DarkGray
    exit 2
}

Write-Host ""
Write-Host "MCP Inspector URL (paste into browser):" -ForegroundColor Cyan
Write-Host "  $foundUrl" -ForegroundColor White
Write-Host ""

if ($Open) {
    Start-Process $foundUrl
    Write-Host "Opened in default browser." -ForegroundColor Green
}
