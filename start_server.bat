@echo off
title Undhiyu Backend Server
echo ========================================================
echo               Undhiyu Backend Server
echo ========================================================
echo.
echo [1/2] Stopping any existing process running on Port 5000...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000 ^| findstr LISTENING 2^>nul') do (
    echo Stopping process PID: %%a...
    taskkill /f /pid %%a >nul 2>&1
)

echo [2/2] Starting Node.js Server...
echo.
cd /d "%~dp0backend"
node server.js

pause
