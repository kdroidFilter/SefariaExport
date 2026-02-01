@echo off
echo ==========================================
echo Sefaria Export - Local Docker Runner
echo ==========================================

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running. Please start Docker and try again.
    exit /b 1
)

REM Check if docker-compose is available
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: docker-compose is not installed.
    echo Please install docker-compose: https://docs.docker.com/compose/install/
    exit /b 1
)

REM Create .env file if it doesn't exist
if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
    echo Please edit .env file if you need to customize settings.
)

REM Create directories for outputs
if not exist exports mkdir exports
if not exist releases mkdir releases

echo.
echo Building Docker images...
docker-compose build

echo.
echo Starting services...
docker-compose up --abort-on-container-exit

echo.
echo ==========================================
echo Workflow finished!
echo ==========================================
echo.
echo Check the following directories for outputs:
echo   - .\exports\    - Exported files
echo   - .\releases\   - Release archives
