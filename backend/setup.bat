@echo off
REM Undhiyu Catering App - Backend Setup Script (Windows)
REM This script sets up the backend environment

echo.
echo ================================
echo Undhiyu Backend Setup
echo ================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo X Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo + Node.js version: %NODE_VERSION%

for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
echo + npm version: %NPM_VERSION%
echo.

REM Navigate to backend directory
cd backend
if %ERRORLEVEL% NEQ 0 (
    echo X Failed to navigate to backend directory
    pause
    exit /b 1
)

echo Downloading dependencies...
call npm install

if %ERRORLEVEL% NEQ 0 (
    echo X Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo + Dependencies installed successfully!
echo.
echo ================================
echo Setup Complete!
echo ================================
echo.
echo To start the backend server, run:
echo   npm run dev (for development with auto-reload)
echo   npm start (for production)
echo.
echo The server will be available at:
echo   http://localhost:5000
echo.
echo API Documentation:
echo   Menu API: http://localhost:5000/api/menu
echo   Billing API: http://localhost:5000/api/billing
echo   Health Check: http://localhost:5000/health
echo.
pause
