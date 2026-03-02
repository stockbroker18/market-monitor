@echo off
setlocal EnableDelayedExpansion
title Market Monitor — Setup
color 0A
cls

echo.
echo  ============================================================
echo   MARKET MONITOR — First Time Setup
echo  ============================================================
echo.
echo  Please keep Bloomberg Terminal open during setup.
echo.

:: ── Determine a writable working directory ─────────────────────────────────
set "WORK_DIR=%~dp0"
echo test > "%WORK_DIR%_writetest.tmp" 2>nul
if exist "%WORK_DIR%_writetest.tmp" (
    del "%WORK_DIR%_writetest.tmp" >nul 2>&1
) else (
    set "WORK_DIR=%TEMP%\MarketMonitor\"
    if not exist "!WORK_DIR!" mkdir "!WORK_DIR!" >nul 2>&1
)

set "LOG=!WORK_DIR!setup.log"
if not exist "%~dp0logs" mkdir "%~dp0logs" >nul 2>&1
set "LOG=%~dp0logs\setup.log"

echo Setup started: %DATE% %TIME% > "!LOG!"
echo Machine: %COMPUTERNAME% >> "!LOG!"
echo User: %USERNAME% >> "!LOG!"
echo Work dir: !WORK_DIR! >> "!LOG!"

:: ── PHASE 1: SILENT MACHINE SURVEY ────────────────────────────────────────
echo  Checking this machine...
echo.

set "IS_ADMIN=NO"
net session >nul 2>&1
if !errorlevel!==0 set "IS_ADMIN=YES"
echo [SURVEY] Admin: !IS_ADMIN! >> "!LOG!"

set "PS_WEB=NO"
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://www.google.com' -UseBasicParsing -TimeoutSec 8 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if !errorlevel!==0 set "PS_WEB=YES"
echo [SURVEY] PowerShell web: !PS_WEB! >> "!LOG!"

set "URL_PYTHON=NO"
set "URL_BLPAPI=NO"
set "URL_PIP=NO"
set "URL_GITHUB=NO"

if "!PS_WEB!"=="YES" (
    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://www.python.org' -UseBasicParsing -TimeoutSec 8 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel!==0 set "URL_PYTHON=YES"
    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://blpapi.bloomberg.com' -UseBasicParsing -TimeoutSec 8 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel!==0 set "URL_BLPAPI=YES"
    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://bootstrap.pypa.io' -UseBasicParsing -TimeoutSec 8 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel!==0 set "URL_PIP=YES"
    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://github.com' -UseBasicParsing -TimeoutSec 8 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel!==0 set "URL_GITHUB=YES"
)
echo [SURVEY] URLs: python=!URL_PYTHON! blpapi=!URL_BLPAPI! pip=!URL_PIP! github=!URL_GITHUB! >> "!LOG!"

set "PYTHON="
set "PYTHON_NO_BLPAPI="

for %%P in (
    "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python39\python.exe"
    "C:\blp\DAPI\python\python.exe"
    "C:\blp\DAPI\Python313\python.exe"
    "C:\blp\DAPI\Python312\python.exe"
    "C:\blp\DAPI\Python311\python.exe"
    "C:\blp\DAPI\Python310\python.exe"
    "C:\blp\DAPI\Python39\python.exe"
    "C:\blp\DAPI\Python38\python.exe"
    "C:\Bloomberg\DAPI\python\python.exe"
    "%LOCALAPPDATA%\spyder-6\python.exe"
    "%LOCALAPPDATA%\spyder-5\python.exe"
    "%USERPROFILE%\anaconda3\python.exe"
    "%LOCALAPPDATA%\anaconda3\python.exe"
    "%PROGRAMDATA%\Anaconda3\python.exe"
    "%USERPROFILE%\Miniconda3\python.exe"
    "%PROGRAMDATA%\Miniconda3\python.exe"
    "%PROGRAMFILES%\Python313\python.exe"
    "%PROGRAMFILES%\Python312\python.exe"
    "%PROGRAMFILES%\Python311\python.exe"
    "%PROGRAMFILES%\Python310\python.exe"
) do (
    if exist %%P (
        %%P -c "print('ok')" >nul 2>&1
        if !errorlevel!==0 (
            echo [SURVEY] Python found: %%~P >> "!LOG!"
            %%P -c "import blpapi" >nul 2>&1
            if !errorlevel!==0 (
                if "!PYTHON!"=="" set "PYTHON=%%~P"
            ) else (
                if "!PYTHON_NO_BLPAPI!"=="" set "PYTHON_NO_BLPAPI=%%~P"
            )
        )
    )
)

for /f "tokens=* delims=" %%i in ('where python 2^>nul') do (
    "%%i" -c "print('ok')" >nul 2>&1
    if !errorlevel!==0 (
        "%%i" -c "import blpapi" >nul 2>&1
        if !errorlevel!==0 (
            if "!PYTHON!"=="" set "PYTHON=%%i"
        ) else (
            if "!PYTHON_NO_BLPAPI!"=="" set "PYTHON_NO_BLPAPI=%%i"
        )
    )
)

set "BUNDLED_WHL="
for /r "C:\blp" %%W in (blpapi*.whl) do if "!BUNDLED_WHL!"=="" set "BUNDLED_WHL=%%W"
for /r "C:\Bloomberg" %%W in (blpapi*.whl) do if "!BUNDLED_WHL!"=="" set "BUNDLED_WHL=%%W"

echo [SURVEY] Python+blpapi: !PYTHON! >> "!LOG!"
echo [SURVEY] Python only: !PYTHON_NO_BLPAPI! >> "!LOG!"

:: ── PHASE 2: STRATEGY SELECTION ───────────────────────────────────────────
echo  [1/4]  Setting up Python and Bloomberg API...
echo.

:: STRATEGY A — Python + blpapi already present
if "!PYTHON!" neq "" (
    echo    Bloomberg API ready.
    echo [STRATEGY] A >> "!LOG!"
    goto :install_deps
)

:: STRATEGY B — Python found, need blpapi
if "!PYTHON_NO_BLPAPI!" neq "" (
    set "PYTHON=!PYTHON_NO_BLPAPI!"
    echo    Installing Bloomberg API...
    echo [STRATEGY] B >> "!LOG!"

    if "!BUNDLED_WHL!" neq "" (
        "!PYTHON!" -m pip install --quiet "!BUNDLED_WHL!" >> "!LOG!" 2>&1
        "!PYTHON!" -c "import blpapi" >nul 2>&1
        if !errorlevel!==0 ( echo    Done. & echo [STRATEGY] B1 >> "!LOG!" & goto :install_deps )
    )

    if "!URL_BLPAPI!"=="YES" (
        set "WHL_FILE=!WORK_DIR!blpapi.whl"
        powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://blpapi.bloomberg.com/repository/releases/python/blpapi-3.26.1.1-py3-none-win_amd64.whl' -OutFile '!WHL_FILE!' -UseBasicParsing" >nul 2>&1
        if exist "!WHL_FILE!" (
            "!PYTHON!" -m pip install --quiet "!WHL_FILE!" >> "!LOG!" 2>&1
            "!PYTHON!" -c "import blpapi" >nul 2>&1
            if !errorlevel!==0 ( echo    Done. & echo [STRATEGY] B2 >> "!LOG!" & goto :install_deps )
        )
        "!PYTHON!" -m pip install --quiet --index-url https://blpapi.bloomberg.com/repository/releases/python/simple blpapi >> "!LOG!" 2>&1
        "!PYTHON!" -c "import blpapi" >nul 2>&1
        if !errorlevel!==0 ( echo    Done. & echo [STRATEGY] B3 >> "!LOG!" & goto :install_deps )
    )

    set "PYTHON="
    echo [STRATEGY] B failed >> "!LOG!"
)

:: STRATEGY C — No Python, download embeddable
if "!URL_PYTHON!"=="YES" (
    echo    Downloading Python (one-time, ~25MB)...
    echo [STRATEGY] C >> "!LOG!"

    set "EMBED_DIR=!WORK_DIR!python-embed"
    set "EMBED_ZIP=!WORK_DIR!python-embed.zip"

    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip' -OutFile '!EMBED_ZIP!' -UseBasicParsing; Write-Host '    Download complete.'" 2>>"!LOG!"
    if not exist "!EMBED_ZIP!" goto :no_python

    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Expand-Archive -Path '!EMBED_ZIP!' -DestinationPath '!EMBED_DIR!' -Force; Write-Host '    Extracted.'" >nul 2>&1
    del "!EMBED_ZIP!" >nul 2>&1
    powershell -NoProfile -Command "Get-ChildItem '!EMBED_DIR!\*._pth' | ForEach-Object { (Get-Content $_.FullName) -replace '#import site','import site' | Set-Content $_.FullName }" >nul 2>&1

    if "!URL_PIP!"=="YES" (
        powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile '!EMBED_DIR!\get-pip.py' -UseBasicParsing" >nul 2>&1
        "!EMBED_DIR!\python.exe" "!EMBED_DIR!\get-pip.py" --quiet >nul 2>&1
    )

    set "PYTHON=!EMBED_DIR!\python.exe"

    if "!BUNDLED_WHL!" neq "" (
        "!PYTHON!" -m pip install --quiet "!BUNDLED_WHL!" >> "!LOG!" 2>&1
        "!PYTHON!" -c "import blpapi" >nul 2>&1
        if !errorlevel!==0 ( echo    Done. & echo [STRATEGY] C+B1 >> "!LOG!" & goto :install_deps )
    )
    if "!URL_BLPAPI!"=="YES" (
        set "WHL_FILE=!WORK_DIR!blpapi.whl"
        powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://blpapi.bloomberg.com/repository/releases/python/blpapi-3.26.1.1-py3-none-win_amd64.whl' -OutFile '!WHL_FILE!' -UseBasicParsing" >nul 2>&1
        if exist "!WHL_FILE!" (
            "!PYTHON!" -m pip install --quiet "!WHL_FILE!" >> "!LOG!" 2>&1
            "!PYTHON!" -c "import blpapi" >nul 2>&1
            if !errorlevel!==0 ( echo    Done. & echo [STRATEGY] C+B2 >> "!LOG!" & goto :install_deps )
        )
        "!PYTHON!" -m pip install --quiet --index-url https://blpapi.bloomberg.com/repository/releases/python/simple blpapi >> "!LOG!" 2>&1
        "!PYTHON!" -c "import blpapi" >nul 2>&1
        if !errorlevel!==0 ( echo    Done. & echo [STRATEGY] C+B3 >> "!LOG!" & goto :install_deps )
    )
    set "PYTHON="
    echo [STRATEGY] C failed >> "!LOG!"
)

:no_python
echo.
echo  ============================================================
echo   Setup could not complete automatically.
echo  ============================================================
echo.
if "!PS_WEB!"=="NO" (
    echo  Reason: PowerShell cannot access the internet on this machine.
    echo  Please ask IT to allow PowerShell web access.
) else (
    echo  Reason: Required websites are blocked on this network.
    echo  Please ask IT to whitelist:
    echo    https://www.python.org
    echo    https://blpapi.bloomberg.com
    echo    https://bootstrap.pypa.io
)
echo.
echo  Please email logs\setup.log to: support@your-app.com
echo.
pause
exit /b 1

:: ── PHASE 3: Backend dependencies ─────────────────────────────────────────
:install_deps
echo.
echo  [2/4]  Installing Market Monitor components...

"!PYTHON!" -m pip install --quiet --no-warn-script-location "fastapi==0.109.0" "uvicorn==0.27.0" "python-socketio==5.11.0" "python-dotenv==1.0.0" "httpx==0.26.0" "pydantic==2.5.0" "aiofiles==23.2.1" >> "!LOG!" 2>&1

if !errorlevel! neq 0 (
    echo  ERROR: Could not install components. Check internet connection.
    echo  Details: !LOG!
    pause
    exit /b 1
)
echo    Done.
echo BLP_PYTHON=!PYTHON!> "%~dp0config.env"

:: ── PHASE 4: Bloomberg Terminal ────────────────────────────────────────────
echo.
echo  [3/4]  Checking Bloomberg Terminal...

:check_terminal
"!PYTHON!" -c "import blpapi; s=blpapi.Session(); ok=s.start(); s.stop() if ok else None; exit(0 if ok else 1)" >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo    Terminal not responding. Open Bloomberg and log in fully.
    choice /c CS /n /m "    C = Check again,  S = Skip: "
    if !errorlevel!==2 goto :skip_bbg
    goto :check_terminal
)
echo    Bloomberg Terminal connected.
:skip_bbg

:: ── PHASE 5: Credentials ──────────────────────────────────────────────────
echo.
echo  [4/4]  Enter your Market Monitor account details
echo.
echo    No account? Visit: https://your-app.vercel.app/register
echo.

:get_user
set "MM_USER="
set /p "MM_USER=    Username: "
if "!MM_USER!"=="" goto :get_user

:get_pass
set "MM_PASS="
set /p "MM_PASS=    Password: "
if "!MM_PASS!"=="" goto :get_pass

echo MM_USERNAME=!MM_USER!>> "%~dp0config.env"
echo MM_PASSWORD=!MM_PASS!>> "%~dp0config.env"
echo API_URL=https://your-app.vercel.app>> "%~dp0config.env"
echo    Saved.

if not exist "%~dp0cloudflared.exe" (
    if "!URL_GITHUB!"=="YES" (
        echo.
        echo    Downloading connection tool...
        powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile '%~dp0cloudflared.exe' -UseBasicParsing" >nul 2>&1
        if exist "%~dp0cloudflared.exe" ( echo    Done. ) else ( echo    Will retry on first START. )
    )
)

echo.
choice /c YN /n /m "    Create desktop shortcut? (Y/N): "
if !errorlevel!==1 (
    powershell -NoProfile -Command "$s=(New-Object -COM WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop')+'\Market Monitor.lnk');$s.TargetPath='%~dp0START.bat';$s.WorkingDirectory='%~dp0';$s.IconLocation='%SystemRoot%\System32\shell32.dll,23';$s.Save()" >nul 2>&1
    echo    Shortcut created.
)

echo.
echo  ============================================================
echo   Setup Complete!
echo  ============================================================
echo.
echo  Each day:
echo    1. Open Bloomberg Terminal
echo    2. Double-click START.bat (or your Desktop shortcut)
echo    3. Your browser opens automatically
echo.
pause
