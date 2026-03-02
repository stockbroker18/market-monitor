@echo off
setlocal EnableDelayedExpansion
title Market Monitor — Starting...
color 0A
cls

echo.
echo  ============================================================
echo   MARKET MONITOR — Starting Up
echo  ============================================================
echo.

:: Load config
if not exist "%~dp0config.env" (
    echo  ERROR: Setup has not been completed.
    echo  Please run SETUP.bat first.
    echo.
    pause
    exit /b 1
)

for /f "usebackq tokens=1,2 delims==" %%A in ("%~dp0config.env") do set "%%A=%%B"

if "!BLP_PYTHON!"=="" (
    echo  ERROR: Python path missing. Please re-run SETUP.bat.
    pause
    exit /b 1
)

:: Check Bloomberg Terminal
echo  [1/4]  Checking Bloomberg Terminal...
tasklist /fi "imagename eq bbcomm.exe" 2>nul | find /i "bbcomm.exe" >nul
if !errorlevel! neq 0 (
    echo.
    echo    Bloomberg Terminal is not running.
    echo    Please open Terminal and log in, then press any key.
    echo.
    pause
)
echo    Bloomberg Terminal detected.

:: Start backend
echo.
echo  [2/4]  Starting Market Monitor backend...
start "Market Monitor Backend" /min cmd /c ^
    "cd /d "%~dp0backend" && "!BLP_PYTHON!" -m uvicorn main:app --host 127.0.0.1 --port 8000"

:: Wait for backend to be ready
echo    Waiting for backend...
set "READY=NO"
for /l %%i in (1,1,15) do (
    if "!READY!"=="NO" (
        timeout /t 1 /nobreak >nul
        "!BLP_PYTHON!" -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)" >nul 2>&1
        if !errorlevel!==0 set "READY=YES"
    )
)
if "!READY!"=="YES" (
    echo    Backend ready.
) else (
    echo    Backend still starting — app may take a moment to load.
)

:: Start Cloudflare Tunnel
echo.
echo  [3/4]  Starting secure tunnel...

if not exist "%~dp0cloudflared.exe" (
    echo    Tunnel tool not found. Downloading now...
    powershell -NoProfile -Command ^
        "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile '%~dp0cloudflared.exe' -UseBasicParsing" >nul 2>&1
)

if not exist "%~dp0cloudflared.exe" (
    echo    WARNING: Could not download tunnel tool.
    echo    The app will only be accessible on this PC.
) else (
    :: First time on this machine — authenticate with Cloudflare
    if not exist "%~dp0.cf-authenticated" (
        echo.
        echo    First time setup for secure tunnel.
        echo    A browser window will open — log in with your
        echo    Cloudflare account. This only happens once.
        echo.
        "%~dp0cloudflared.exe" tunnel login
        echo. > "%~dp0.cf-authenticated"
    )
    start "Market Monitor Tunnel" /min cmd /c ^
        ""%~dp0cloudflared.exe" tunnel --url http://127.0.0.1:8000 run market-monitor-!MM_USERNAME!"
    echo    Tunnel started.
)

:: Register session
echo.
echo  [4/4]  Registering your session...
timeout /t 4 /nobreak >nul
"!BLP_PYTHON!" -c ^
    "import urllib.request, json, os; data=json.dumps({'username':os.environ.get('MM_USERNAME',''),'password':os.environ.get('MM_PASSWORD',''),'action':'register_session'}).encode(); req=urllib.request.Request('https://your-app.vercel.app/api/auth/register-tunnel',data=data,headers={'Content-Type':'application/json'}); urllib.request.urlopen(req,timeout=10)" ^
    >nul 2>&1
echo    Done.

:: Open browser
echo.
echo  ============================================================
echo   Market Monitor is ready!
echo  ============================================================
echo.
echo  Opening browser...
timeout /t 2 /nobreak >nul
start "" "https://your-app.vercel.app"
echo.
echo  Keep this window open while using Market Monitor.
echo  Close this window to stop.
echo.

:: Monitor loop — warn if Terminal closes
:monitor_loop
timeout /t 30 /nobreak >nul
tasklist /fi "imagename eq bbcomm.exe" 2>nul | find /i "bbcomm.exe" >nul
if !errorlevel! neq 0 (
    echo.
    echo  WARNING: Bloomberg Terminal has been closed.
    echo  Market data will stop until Terminal is reopened.
    echo.
)
goto :monitor_loop
