@echo off
rem SentinelWatch EDR - Execution silencieuse du daemon d'audit
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0sentinel_audit.ps1" -ApiUrl "https://sentinel-watch-ssty.onrender.com/api/v1/audits"
