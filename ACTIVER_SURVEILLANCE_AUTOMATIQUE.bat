@echo off
title SentinelWatch - Activation de la Surveillance EDR Automatique
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0activer_surveillance.ps1"
