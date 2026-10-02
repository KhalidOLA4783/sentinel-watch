@echo off
title SentinelWatch - Audit de Securite Endpoint
cd /d "%~dp0sentinel-watch\agent"

echo ======================================================================
echo    SENTINELWATCH - SCAN DE SECURITE DU POSTE (SCORE & REMEDIATION)
echo ======================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\sentinel_audit.ps1" -ApiUrl "http://127.0.0.1:8000/api/v1/audits"

echo.
echo ======================================================================
echo Scan termine. Appuyez sur une touche pour fermer.
pause >nul
