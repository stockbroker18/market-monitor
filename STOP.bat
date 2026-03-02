@echo off
title Market Monitor — Stopping
color 0C
cls

echo.
echo  ============================================================
echo   MARKET MONITOR — Shutting Down
echo  ============================================================
echo.
echo  Stopping all Market Monitor processes...
echo.

taskkill /f /fi "windowtitle eq Market Monitor Backend*" >nul 2>&1
echo  Backend stopped.

taskkill /f /fi "windowtitle eq Market Monitor Tunnel*" >nul 2>&1
taskkill /f /im cloudflared.exe >nul 2>&1
echo  Tunnel stopped.

echo.
echo  Market Monitor stopped.
echo  You can now close Bloomberg Terminal if needed.
echo.
timeout /t 3 /nobreak >nul
