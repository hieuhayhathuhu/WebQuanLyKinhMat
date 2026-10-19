@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0QuanLyKinhMatWeb\scripts\Stop-Web.ps1" %*
if errorlevel 1 pause
