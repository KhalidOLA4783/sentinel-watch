@echo off
title SentinelWatch - Analyse VirusTotal
cd /d "%~dp0sentinel-watch\agent"

echo ======================================================================
echo    SENTINELWATCH - VERIFICATION VIRUSTOTAL (HASH SHA-256)
echo ======================================================================
echo.

if "%~1"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\check_virustotal.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\check_virustotal.ps1" -FilePath "%~1"
)

echo.
pause
