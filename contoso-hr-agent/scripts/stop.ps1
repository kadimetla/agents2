# Contoso HR Agent — Stop (Windows)
# Kills any process on the four project ports. Safe to run anytime — even
# after a crashed start.ps1 that orphaned hr-engine/hr-watcher/MCP/Inspector.

Set-StrictMode -Version Latest

$PROJECT_PORTS = @(8090, 8091, 5273, 6374)

Write-Host "`n=== Stopping Contoso HR Agent ===" -ForegroundColor Cyan

$killedAny = $false
foreach ($port in $PROJECT_PORTS) {
    $netstatOutput = netstat -ano 2>$null | Select-String ":$port\s"
    foreach ($line in $netstatOutput) {
        $parts = $line.ToString().Trim() -split '\s+'
        $procId = $parts[-1]
        if ($procId -match '^\d+$' -and $procId -ne '0') {
            $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
            $name = if ($proc) { $proc.ProcessName } else { "<gone>" }
            Write-Host "  Killing PID $procId ($name) on port $port" -ForegroundColor Yellow
            try { Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue } catch {}
            taskkill /PID $procId /F 2>$null | Out-Null
            $killedAny = $true
        }
    }
}

# Also clean up any background jobs from this PowerShell session.
$jobs = Get-Job -ErrorAction SilentlyContinue
if ($jobs) {
    $jobs | Stop-Job -ErrorAction SilentlyContinue
    $jobs | Remove-Job -ErrorAction SilentlyContinue
    Write-Host "  Removed $($jobs.Count) background job(s)" -ForegroundColor Yellow
}

if (-not $killedAny -and -not $jobs) {
    Write-Host "  Nothing to stop. All project ports were already free." -ForegroundColor Green
}

Write-Host "`nAll stopped." -ForegroundColor Green
