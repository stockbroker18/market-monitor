@echo off
setlocal EnableDelayedExpansion
title Bloomberg Backend
color 0A
cls

echo.
echo  ============================================================
echo   MARKET MONITOR — Starting Up
echo  ============================================================
echo.

:: ── Load config ──────────────────────────────────────────────────────────────
if not exist "%~dp0config.env" (
    echo  ERROR: config.env not found. Please create it first.
    pause
    exit /b 1
)

for /f "usebackq tokens=1,2 delims==" %%A in ("%~dp0config.env") do set "%%A=%%B"

if "!BLP_PYTHON!"=="" (
    echo  ERROR: BLP_PYTHON not set in config.env
    pause
    exit /b 1
)

:: ── Check Bloomberg Terminal ──────────────────────────────────────────────────
echo  [1/4]  Checking Bloomberg Terminal...
tasklist /fi "imagename eq bbcomm.exe" 2>nul | find /i "bbcomm.exe" >nul
if !errorlevel! neq 0 (
    echo.
    echo    Bloomberg Terminal is not running.
    echo    Please open Terminal and log in, then press any key.
    pause
)
echo    Bloomberg Terminal detected.

:: ── Start Cloudflare Tunnel ───────────────────────────────────────────────────
echo.
echo  [2/4]  Starting tunnel...

if not exist "%~dp0cloudflared.exe" (
    echo  ERROR: cloudflared.exe not found.
    pause
    exit /b 1
)

:: Start cloudflared and capture its output to a temp file
set "CF_LOG=%TEMP%\cf_tunnel.log"
if exist "!CF_LOG!" del "!CF_LOG!"

start "CF Tunnel" /min cmd /c ""%~dp0cloudflared.exe" tunnel --url http://127.0.0.1:8000 > "!CF_LOG!" 2>&1"

:: Wait for tunnel URL to appear in log
echo    Waiting for tunnel URL...
set "TUNNEL_URL="
set /a ATTEMPTS=0

:wait_tunnel
timeout /t 2 /nobreak >nul
set /a ATTEMPTS+=1

:: Look for the trycloudflare URL in the log
for /f "tokens=* delims=" %%L in ('findstr /i "trycloudflare.com" "!CF_LOG!" 2^>nul') do (
    set "LINE=%%L"
    :: Extract URL from the line using PowerShell
    for /f "tokens=* delims=" %%U in ('powershell -NoProfile -Command "$line='!LINE!'; if($line -match 'https://[a-z0-9-]+\.trycloudflare\.com'){$matches[0]}"') do (
        set "TUNNEL_URL=%%U"
    )
)

if "!TUNNEL_URL!"=="" (
    if !ATTEMPTS! lss 15 goto :wait_tunnel
    echo    WARNING: Could not detect tunnel URL after 30 seconds.
    echo    Continuing without tunnel registration.
    goto :start_backend
)

echo    Tunnel URL: !TUNNEL_URL!

:: Update TUNNEL_URL in config.env
powershell -NoProfile -Command ^
    "$content = Get-Content '%~dp0config.env' -Raw;" ^
    "if($content -match 'TUNNEL_URL=.*'){$content = $content -replace 'TUNNEL_URL=.*','TUNNEL_URL=!TUNNEL_URL!'}else{$content += \"`nTUNNEL_URL=!TUNNEL_URL!\"};" ^
    "Set-Content '%~dp0config.env' $content.TrimEnd()"

echo    config.env updated.

:: ── Start Backend ─────────────────────────────────────────────────────────────
:start_backend
echo.
echo  [3/4]  Starting backend...

start "Bloomberg Backend" /min cmd /c ^
    "cd /d "%~dp0backend" && "!BLP_PYTHON!" -m uvicorn main:app --host 127.0.0.1 --port 8000"

:: Wait for backend to be ready
echo    Waiting for backend...
set "READY=NO"
for /l %%i in (1,1,20) do (
    if "!READY!"=="NO" (
        timeout /t 1 /nobreak >nul
        "!BLP_PYTHON!" -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)" >nul 2>&1
        if !errorlevel!==0 set "READY=YES"
    )
)

if "!READY!"=="YES" (
    echo    Backend ready.
) else (
    echo    Backend taking longer than expected — check the Backend window.
)

:: ── Done ──────────────────────────────────────────────────────────────────────
echo.
echo  [4/4]  Opening browser...
timeout /t 2 /nobreak >nul
start "" "https://market-monitor-taupe.vercel.app"

echo.
echo  ============================================================
echo   Market Monitor is running!
echo  ============================================================
echo.
echo  Tunnel: !TUNNEL_URL!
echo.
echo  Keep this window open. Press Ctrl+C to stop.
echo.

:monitor_loop
timeout /t 30 /nobreak >nul
tasklist /fi "imagename eq bbcomm.exe" 2>nul | find /i "bbcomm.exe" >nul
if !errorlevel! neq 0 (
    echo  WARNING: Bloomberg Terminal closed. Data will stop until reopened.
)
goto :monitor_loop
