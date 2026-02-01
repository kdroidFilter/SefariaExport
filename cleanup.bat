@echo off
echo ==========================================
echo Sefaria Export - Cleanup Script
echo ==========================================
echo.
echo This will remove:
echo   - Docker containers and volumes
echo   - exports/ directory
echo   - releases/ directory
echo   - Temporary files
echo.
set /p confirm="Are you sure? (y/N): "
if /i not "%confirm%"=="y" (
    echo Cleanup cancelled.
    exit /b 0
)

echo.
echo Stopping and removing Docker containers...
docker-compose down -v

echo.
echo Removing output directories...
if exist exports rmdir /s /q exports
if exist releases rmdir /s /q releases

echo.
echo Removing temporary files...
if exist ts.txt del /q ts.txt
if exist ts_env.sh del /q ts_env.sh
if exist mongo_dump_pkg rmdir /s /q mongo_dump_pkg
if exist Sefaria-Project rmdir /s /q Sefaria-Project

echo.
echo ==========================================
echo Cleanup completed!
echo ==========================================
