@echo off
echo ==========================================
echo Sefaria Export - Requirements Check
echo ==========================================
echo.

set "all_ok=1"

REM Check Docker
echo [1/3] Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo   [X] Docker is NOT installed
    echo       Download from: https://www.docker.com/products/docker-desktop
    set "all_ok=0"
) else (
    for /f "tokens=*" %%i in ('docker --version') do echo   [OK] %%i
)

REM Check Docker running
docker info >nul 2>&1
if errorlevel 1 (
    echo   [X] Docker is NOT running
    echo       Please start Docker Desktop
    set "all_ok=0"
) else (
    echo   [OK] Docker is running
)

REM Check docker-compose
echo.
echo [2/3] Checking docker-compose...
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo   [X] docker-compose is NOT installed
    echo       Download from: https://docs.docker.com/compose/install/
    set "all_ok=0"
) else (
    for /f "tokens=*" %%i in ('docker-compose --version') do echo   [OK] %%i
)

REM Check disk space
echo.
echo [3/3] Checking disk space...
for /f "tokens=3" %%a in ('dir /-c ^| find "bytes free"') do set free_bytes=%%a
set /a free_gb=%free_bytes:~0,-9%
if %free_gb% LSS 20 (
    echo   [!] Warning: Only %free_gb%GB free space
    echo       Recommended: at least 20GB
) else (
    echo   [OK] %free_gb%GB free space available
)

echo.
echo ==========================================
if "%all_ok%"=="1" (
    echo [OK] All requirements met!
    echo      You can run: run_local.bat
) else (
    echo [X] Some requirements are missing
    echo     Please install missing components
)
echo ==========================================
