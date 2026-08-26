@echo off
rem ═══════════════════════════════════════════════════════════════
rem start-workshop.bat
rem Double-click to preview the workshop site locally, full-screen,
rem without deploying to GitHub Pages or running any commands
rem yourself. Starts the local static server (if not already
rem running), opens it kiosk/full-screen in Edge or Chrome, and
rem stops the server again once you close the browser.
rem ═══════════════════════════════════════════════════════════════
setlocal enableextensions
set "ROOT=%~dp0"
set "PORT=8081"
set "URL=http://localhost:%PORT%/"
set "STARTED_SERVER=0"

echo Checking for a local server on port %PORT% ...
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\check-port.ps1" -Port %PORT%
if errorlevel 1 (
  if not exist "%ROOT%docs\index.html" (
    echo.
    echo ERROR: docs\index.html not found. Render the site first ^(e.g. run render-all-profiles.sh^).
    pause
    exit /b 1
  )
  echo Starting local server ...
  start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%ROOT%scripts\static-server.ps1" -Root "%ROOT%docs" -Port %PORT%
  set "STARTED_SERVER=1"
  timeout /t 2 /nobreak >nul
) else (
  echo A server is already running on port %PORT% — reusing it.
)

set "EDGE=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" set "EDGE=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"

if exist "%EDGE%" (
  echo Opening the workshop full-screen in Edge — close the browser window when you're done.
  start "" /wait "%EDGE%" --kiosk "%URL%" --edge-kiosk-type=fullscreen --no-first-run --inprivate
) else if exist "%CHROME%" (
  echo Opening the workshop full-screen in Chrome — close the browser window when you're done.
  start "" /wait "%CHROME%" --kiosk "%URL%" --new-window --no-first-run --no-default-browser-check
) else (
  echo Could not find Microsoft Edge or Google Chrome — opening in your default browser instead.
  start "" "%URL%"
  echo.
  echo Press any key here once you're done to stop the local server...
  pause >nul
)

if "%STARTED_SERVER%"=="1" (
  echo Stopping the local server ...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\stop-static-server.ps1" -Port %PORT%
)

endlocal
