@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Skin Selector SAFE

rem --- folder: arg1 or current ---
set "TARGET=%~1"
if not defined TARGET set "TARGET=."

pushd "%TARGET%" >nul 2>&1
if errorlevel 1 (
  echo [ERR] Cannot enter folder: "%TARGET%"
  goto :fail
)

set "JSON=selected.json"
set "PREV="

rem --- read previous selection from selected.json (field: selected) ---
if exist "%JSON%" (
  for /f "usebackq delims=" %%A in (`
    powershell -NoProfile -Command ^
      "try{$j=Get-Content -LiteralPath '%JSON%' -Raw | ConvertFrom-Json; if($j.selected){$j.selected}}catch{}"
  `) do set "PREV=%%A"
)

rem --- build list of bases that have base.png AND base_e.png, excluding F1 ---
set "COUNT=0"
for /f "usebackq delims=" %%F in (`dir /b /a-d "*_e.png" 2^>nul`) do (
  set "N=%%~nF"
  set "BASE=!N:_e=!"
  if /I not "!BASE!"=="F1" (
    if exist "!BASE!.png" (
      set /a COUNT+=1
      set "TEX[!COUNT!]=!BASE!"
    )
  )
)

if "%COUNT%"=="0" (
  echo [INFO] No pairs found: base.png + base_e.png; excluding F1
  goto :done_ok
)

echo.
echo Found %COUNT% pair(s):
echo -------------------------
for /L %%I in (1,1,%COUNT%) do (
  echo %%I^) !TEX[%%I]!.png  plus  !TEX[%%I]!_e.png
)
echo -------------------------
echo.

:ask
set "CHOICE="
set /p "CHOICE=Pick number (1-%COUNT%) or 0 to exit: "
if not defined CHOICE goto :ask

echo %CHOICE%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
  echo [ERR] Numbers only
  goto :ask
)

if "%CHOICE%"=="0" goto :done_ok

set /a NCHOICE=%CHOICE% >nul 2>&1
if %NCHOICE% LSS 1 (
  echo [ERR] Out of range
  goto :ask
)
if %NCHOICE% GTR %COUNT% (
  echo [ERR] Out of range
  goto :ask
)

set "SEL=!TEX[%NCHOICE%]!"
echo.
echo [INFO] Selected: "%SEL%"

call :get_ts TS

rem --- restore old F1 to PREV name (only if PREV exists) ---
if defined PREV (
  call :restore_prev "%PREV%" "%TS%"
) else (
  echo [WARN] selected.json missing or empty, will not restore old F1 name
)

rem --- apply selected pair to F1 ---
call :apply_selected "%SEL%"
if errorlevel 1 goto :fail

rem --- write selected.json ---
powershell -NoProfile -Command ^
  "$o=[pscustomobject]@{selected='%SEL%'}; $o|ConvertTo-Json -Depth 5 | Set-Content -LiteralPath '%JSON%' -Encoding UTF8" >nul 2>&1

echo.
echo [OK] Done. F1.png and F1_e.png now point to "%SEL%".
goto :done_ok


:get_ts
set "%~1="
for /f "usebackq delims=" %%T in (`
  powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"
`) do set "%~1=%%T"
exit /b 0


:restore_prev
set "PREVNAME=%~1"
set "TS=%~2"

rem NOTE: Do NOT print '>' anywhere (it is redirection in CMD)

if exist "F1.png" (
  if not exist "%PREVNAME%.png" (
    ren "F1.png" "%PREVNAME%.png" >nul
    echo [INFO] Renamed F1.png to %PREVNAME%.png
  ) else (
    ren "F1.png" "%PREVNAME%_fromF1_%TS%.png" >nul
    echo [WARN] %PREVNAME%.png exists, renamed F1.png to %PREVNAME%_fromF1_%TS's%.png
  )
)

if exist "F1_e.png" (
  if not exist "%PREVNAME%_e.png" (
    ren "F1_e.png" "%PREVNAME%_e.png" >nul
    echo [INFO] Renamed F1_e.png to %PREVNAME%_e.png
  ) else (
    ren "F1_e.png" "%PREVNAME%_e_fromF1_%TS%.png" >nul
    echo [WARN] %PREVNAME%_e.png exists, renamed F1_e.png to %PREVNAME%_e_fromF1_%TS%.png
  )
)

exit /b 0


:apply_selected
set "NAME=%~1"

if not exist "%NAME%.png" (
  echo [ERR] Missing file: "%NAME%.png"
  exit /b 1
)
if not exist "%NAME%_e.png" (
  echo [ERR] Missing file: "%NAME%_e.png"
  exit /b 1
)

rem If anything named F1 still exists, move it aside to prevent rename conflict
if exist "F1.png"  ren "F1.png"  "F1_leftover_%RANDOM%.png" >nul
if exist "F1_e.png" ren "F1_e.png" "F1_e_leftover_%RANDOM%.png" >nul

ren "%NAME%.png" "F1.png" >nul
if errorlevel 1 (
  echo [ERR] Failed to rename %NAME%.png to F1.png
  exit /b 1
)

ren "%NAME%_e.png" "F1_e.png" >nul
if errorlevel 1 (
  echo [ERR] Failed to rename %NAME%_e.png to F1_e.png
  exit /b 1
)

echo [INFO] Applied selected texture to F1 names
exit /b 0


:done_ok
popd >nul 2>&1
echo.
pause
exit /b 0


:fail
popd >nul 2>&1
echo.
echo [FAIL] Execution error
pause
exit /b 1
