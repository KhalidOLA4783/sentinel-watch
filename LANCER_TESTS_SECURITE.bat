@echo off
title SentinelWatch - Banc de Test et de Demonstration SOC
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tester_securite.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [INFO] Le test s'est termine avec le code %ERRORLEVEL%.
    pause
)
