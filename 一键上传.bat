@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 > nul

echo =====================================================
echo   One-click: git commit/push + jsDelivr URL list
echo   Working dir: %CD%
echo =====================================================
echo.

rem ---- 1) Sanity: git + powershell + git repo ----
where git >nul 2>nul
if errorlevel 1 (
    echo [ERROR] git not in PATH. Install Git for Windows.
    pause
    exit /b 1
)
where powershell >nul 2>nul
if errorlevel 1 (
    echo [ERROR] powershell not found.
    pause
    exit /b 1
)
git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo [ERROR] %CD% is not a git repository.
    pause
    exit /b 1
)

rem ---- 2) Remote & branch ----
for /f "delims=" %%i in ('git remote get-url origin 2^>nul') do set "REMOTE=%%i"
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "BRANCH=%%i"
if "!REMOTE!"=="" (
    echo [ERROR] No 'origin' remote. Run:  git remote add origin ^<url^>
    pause
    exit /b 1
)
if "!BRANCH!"=="" set "BRANCH=main"

echo Remote : !REMOTE!
echo Branch : !BRANCH!
echo.

rem ---- 3) Pending changes ----
echo --- Pending changes ---
git status --short
echo.

git status --porcelain | findstr /r "." >nul
set NEEDS_COMMIT=0
if not errorlevel 1 set NEEDS_COMMIT=1

rem ---- 4) Commit + push if needed ----
if "!NEEDS_COMMIT!"=="1" (
    set "MSG="
    set /p MSG="Commit message (empty = auto): "
    if "!MSG!"=="" set "MSG=auto update %date:~0,10% %time:~0,5%"
    echo.
    git add -A
    if errorlevel 1 (
        echo [ERROR] git add failed.
        pause
        exit /b 1
    )
    git commit -m "!MSG!"
    if errorlevel 1 (
        echo [ERROR] git commit failed.
        pause
        exit /b 1
    )
    git push origin !BRANCH!
    if errorlevel 1 (
        echo [WARN] git push failed. Resolve and re-run.
        pause
        exit /b 1
    )
    echo.
    echo === Pushed OK ===
) else (
    echo No changes to commit, skip push.
)
echo.

rem ---- 5) Generate jsDelivr URL list via PowerShell ----
echo === Generating jsDelivr URL list ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0生成链接.ps1"
if errorlevel 1 (
    echo [ERROR] URL generation failed.
    pause
    exit /b 1
)

echo.
echo All done. URL list: files_list.txt
pause
endlocal